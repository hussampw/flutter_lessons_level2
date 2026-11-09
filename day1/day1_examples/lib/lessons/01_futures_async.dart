// ============================================================
// الدرس 1 (Dart): Futures و async/await
// في التطبيق: القائمة ← الدرس 1  ·  في العرض: شرائح الدرس 1
// ============================================================
//
// الـ Future هو "وعد" بقيمة ستصل لاحقاً (أو خطأ).
// Dart تعمل على خيط واحد (Single Thread) مع حلقة أحداث (Event Loop)،
// لذلك الانتظار لا يجمّد الشاشة، بل يسمح للـ UI بالرسم أثناء الانتظار.
//
// هذا الدرس هو الأساس لـ Riverpod: FutureProvider و AsyncNotifier و AsyncValue
// كلها مبنية على Future.
//
// 💡 كل زر في الشاشة ينفّذ مثالاً ويكتب النتيجة في "الكونسول" أسفل الشاشة.

import 'dart:async';

import 'package:flutter/material.dart';

// ------------------------------------------------------------
// دوال تحاكي طلبات شبكة تستغرق وقتاً
// ------------------------------------------------------------
Future<String> fetchUserName(int id) async {
  // ننتظر 500 ملي ثانية كأنها طلب API حقيقي
  await Future.delayed(const Duration(milliseconds: 500));
  if (id <= 0) {
    // رمي خطأ داخل دالة async يحوّله تلقائياً إلى Future فاشل
    throw ArgumentError('رقم المستخدم غير صالح: $id');
  }
  return 'مستخدم رقم $id';
}

Future<int> fetchOrdersCount() async {
  await Future.delayed(const Duration(milliseconds: 700));
  return 12;
}

class FuturesScreen extends StatefulWidget {
  const FuturesScreen({super.key});

  @override
  State<FuturesScreen> createState() => _FuturesScreenState();
}

class _FuturesScreenState extends State<FuturesScreen> {
  final _logs = <String>[];
  bool _busy = false;

  void _log(String line) {
    // ⚠️ بعد أي await قد يكون المستخدم خرج من الشاشة
    // لذلك نتحقق من mounted قبل استدعاء setState
    if (!mounted) return;
    setState(() => _logs.add(line));
  }

  // يشغّل مثالاً واحداً ويمنع الضغط المتكرر أثناء التنفيذ
  Future<void> _run(String title, Future<void> Function() demo) async {
    setState(() {
      _busy = true;
      _logs
        ..clear()
        ..add('▶ $title');
    });
    await demo();
    if (mounted) setState(() => _busy = false);
  }

  // ------------------------------------------------------------
  // 1) الطريقة القديمة: then / catchError / whenComplete
  // ------------------------------------------------------------
  Future<void> _thenStyle() {
    return fetchUserName(1)
        .then((name) => _log('وصل الاسم: $name'))
        .catchError((Object e) => _log('خطأ: $e'))
        .whenComplete(() => _log('انتهى (مثل finally)'));
  }

  // ------------------------------------------------------------
  // 2) الطريقة الحديثة: async / await مع try / catch / finally
  //    الكود يُقرأ من الأعلى للأسفل كأنه متزامن
  // ------------------------------------------------------------
  Future<void> _awaitStyle() async {
    try {
      final name = await fetchUserName(-5); // سيفشل عمداً
      _log(name);
    } on ArgumentError catch (e) {
      // on لالتقاط نوع خطأ محدد
      _log('خطأ متوقع: ${e.message}');
    } catch (e) {
      // catch عامة لأي خطأ آخر
      _log('خطأ غير متوقع: $e');
    } finally {
      _log('finally تعمل دائماً');
    }
  }

  // ------------------------------------------------------------
  // 3) تسلسلي مقابل متوازي — من أهم نقاط الأداء
  // ------------------------------------------------------------
  Future<void> _sequentialVsParallel() async {
    // تسلسلي: الطلب الثاني لا يبدأ إلا بعد انتهاء الأول ≈ 1200ms
    var sw = Stopwatch()..start();
    final a = await fetchUserName(1);
    final b = await fetchOrdersCount();
    _log('تسلسلي: $a / $b طلب ← ${sw.elapsedMilliseconds}ms');

    // متوازي باستخدام Future.wait: كل الطلبات تبدأ معاً ≈ 700ms
    // عيبه: النتيجة List<Object> فنحتاج تحويل الأنواع يدوياً
    sw = Stopwatch()..start();
    final results = await Future.wait([fetchUserName(2), fetchOrdersCount()]);
    _log('Future.wait: $results ← ${sw.elapsedMilliseconds}ms');

    // متوازي باستخدام Records (Dart 3): الأنواع محفوظة لكل عنصر ✅
    sw = Stopwatch()..start();
    final (name, count) = await (fetchUserName(3), fetchOrdersCount()).wait;
    _log('Record.wait: $name / $count ← ${sw.elapsedMilliseconds}ms');
  }

  // ------------------------------------------------------------
  // 4) المهلة الزمنية timeout و Future.any
  // ------------------------------------------------------------
  Future<void> _timeoutAndAny() async {
    try {
      // إذا لم تنتهِ العملية خلال 200ms نرمي TimeoutException
      await fetchUserName(1).timeout(const Duration(milliseconds: 200));
    } on TimeoutException {
      _log('انتهت المهلة! الخادم بطيء');
    }

    // Future.any: نأخذ أول نتيجة تصل (مثلاً من عدة خوادم)
    final fastest = await Future.any([
      Future.delayed(const Duration(milliseconds: 300), () => 'الخادم A'),
      Future.delayed(const Duration(milliseconds: 100), () => 'الخادم B'),
    ]);
    _log('الأسرع: $fastest');
  }

  // ------------------------------------------------------------
  // 5) Completer: تحويل كود يعتمد على callbacks إلى Future
  // ------------------------------------------------------------
  Future<String> _legacyApiAsFuture() {
    final completer = Completer<String>();

    // نتخيل مكتبة قديمة تعطينا النتيجة عبر callback
    Timer(const Duration(milliseconds: 300), () {
      completer.complete('نتيجة من API قديم'); // أو completer.completeError(...)
    });

    return completer.future; // نعيد الـ Future فوراً، ويكتمل لاحقاً
  }

  // ------------------------------------------------------------
  // 6) ترتيب التنفيذ: الكود المتزامن ← microtasks ← events
  //    سؤال مقابلات مشهور!
  // ------------------------------------------------------------
  Future<void> _eventLoopOrder() async {
    _log('A: كود متزامن');
    Future(() => _log('D: Event (Future عادي)'));
    scheduleMicrotask(() => _log('C: Microtask'));
    Future.microtask(() => _log('C2: Microtask آخر'));
    _log('B: كود متزامن');
    // الناتج: A, B, C, C2, D
    // لأن الـ microtasks تُنفَّذ كلها قبل أي event جديد
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Widget build(BuildContext context) {
    final demos = <(String, Future<void> Function())>[
      ('1) then', _thenStyle),
      ('2) async/await', _awaitStyle),
      ('3) تسلسلي vs متوازي', _sequentialVsParallel),
      ('4) timeout و any', _timeoutAndAny),
      ('5) Completer', () async => _log(await _legacyApiAsFuture())),
      ('6) Event Loop', _eventLoopOrder),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 1: Futures و async/await')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, demo) in demos)
                  FilledButton.tonal(
                    onPressed: _busy ? null : () => _run(label, demo),
                    child: Text(label),
                  ),
              ],
            ),
          ),
          // الكونسول: نعرض فيه نتائج الأمثلة بدل print
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView(
                children: [
                  for (final line in _logs)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        line,
                        style: const TextStyle(
                          color: Color(0xFFB8F5C8),
                          fontFamily: 'monospace',
                          fontSize: 15,
                        ),
                      ),
                    ),
                  if (_busy) const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
          const _FutureBuilderDemo(),
        ],
      ),
    );
  }
}

// ============================================================
// 7) Future داخل الـ UI: FutureBuilder والخطأ الأشهر
// ============================================================
//
// ❌ خطأ شائع: إنشاء الـ Future داخل build()
//    FutureBuilder(future: fetchOrdersCount(), ...)
//    كل إعادة بناء (setState، تدوير الشاشة، فتح الكيبورد) = طلب شبكة جديد!
//
// ✅ الحل: ننشئ الـ Future مرة واحدة (في initState) ونحفظه في متغير.
//
// 💡 Riverpod يحل هذه المشكلة تلقائياً: FutureProvider يخزّن النتيجة
//    ولا يعيد الطلب عند إعادة البناء — وهذا موضوع بقية دروس اليوم.

int _fetchCalls = 0;

Future<int> _countedFetch() {
  _fetchCalls++; // نعدّ كم مرة أُرسل "طلب الشبكة"
  return fetchOrdersCount();
}

class _FutureBuilderDemo extends StatefulWidget {
  const _FutureBuilderDemo();

  @override
  State<_FutureBuilderDemo> createState() => _FutureBuilderDemoState();
}

class _FutureBuilderDemoState extends State<_FutureBuilderDemo> {
  // ✅ الـ Future يُنشأ مرة واحدة فقط
  late final Future<int> _ordersFuture = _countedFetch();
  bool _wrongWay = false;

  @override
  Widget build(BuildContext context) {
    // ❌ في الوضع الخاطئ ننشئ Future جديداً في كل build = طلب شبكة جديد
    // ✅ في الوضع الصحيح نستخدم نفس الـ Future المحفوظ
    final future = _wrongWay ? _countedFetch() : _ordersFuture;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              '7) FutureBuilder — عدد طلبات الشبكة: $_fetchCalls',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_wrongWay
                  ? '❌ Future داخل build (طلب جديد مع كل إعادة بناء)'
                  : '✅ Future محفوظ في initState (طلب واحد فقط)'),
              value: _wrongWay,
              onChanged: (v) => setState(() => _wrongWay = v),
            ),
            FutureBuilder<int>(
              future: future,
              builder: (context, snapshot) {
                // ConnectionState + hasError + hasData = نفس فكرة AsyncValue
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('خطأ: ${snapshot.error}');
                }
                return Text('عدد الطلبات من الـ API: ${snapshot.data}');
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة البناء (setState)'),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) نسيت await؟ فعّل lint اسمه unawaited_futures في analysis_options.yaml
//    وإذا أردت فعلاً "أطلق ولا تنتظر" استخدم unawaited() من dart:async ليكون مقصوداً:
//      unawaited(analytics.logEvent('open_screen'));
//
// 2) Future.wait يكمل باقي الطلبات حتى لو فشل أحدها.
//    eagerError: true ← يرمي الخطأ فوراً بدون انتظار البقية:
//      await Future.wait([a(), b()], eagerError: true);
//
// 3) بعد await داخل Widget لا تستخدم context مباشرة:
//      await save();
//      if (!context.mounted) return;   ← في StatelessWidget أو داخل دالة تأخذ context
//      Navigator.pop(context);
//
// 4) لتأخير بسيط أثناء التجربة: await Future.delayed(const Duration(seconds: 1));
//    وفي الاختبارات لا تنتظر وقتاً حقيقياً — استخدم fakeAsync (اليوم الرابع).
//
// 5) لا تضع async على دالة لا تحتوي await — تُنشئ Future بلا داعٍ.
