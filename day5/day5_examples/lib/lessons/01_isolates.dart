// ============================================================
// الدرس 1 (Dart): Isolates — نقل العمل الثقيل بعيداً عن الـ UI
// في التطبيق: القائمة ← الدرس 1  ·  في العرض: شرائح الدرس 1
// ============================================================
//
// async/await لا يعني "خيط جديد"! كل شيء يعمل على نفس الـ Isolate الرئيسي.
// إذا كان لدينا حساب ثقيل (معالجة صورة، JSON ضخم، تشفير)
// سيتجمّد الـ UI لأن الخيط مشغول ولا يستطيع رسم الإطار التالي.
//
// الـ Isolate = عامل مستقل له ذاكرته الخاصة (لا يشارك المتغيرات)
// والتواصل بينه وبين الـ Isolate الرئيسي يتم عبر الرسائل فقط.
//
// 💡 في الشاشة: الشعار الدوّار + عدّاد "أطول توقف" يكشفان التجمّد بالعين.
//    شغّل نفس الحساب على الـ Isolate الرئيسي ثم عبر Isolate.run وقارن.

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// ------------------------------------------------------------
// عملية ثقيلة لحساب الأعداد الأولية (تستهلك المعالج)
// ⚠️ يجب أن تكون دالة top-level أو static لتُرسل إلى Isolate آخر
// ------------------------------------------------------------
int countPrimes(int limit) {
  var count = 0;
  for (var n = 2; n <= limit; n++) {
    var isPrime = true;
    for (var d = 2; d * d <= n; d++) {
      if (n % d == 0) {
        isPrime = false;
        break;
      }
    }
    if (isPrime) count++;
  }
  return count;
}

const _limit = 2000000;

// ------------------------------------------------------------
// المثال الواقعي: JSON ضخم من الخادم (مثلاً 150 ألف منتج)
// ------------------------------------------------------------
class Product {
  const Product({required this.id, required this.title, required this.price});

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        title: json['title'] as String,
        price: (json['price'] as num).toDouble(),
      );

  final int id;
  final String title;
  final double price;
}

// نصنع نص JSON كبيراً يشبه رد API حقيقي
String buildBigJson(int count) => jsonEncode([
      for (var i = 0; i < count; i++)
        {'id': i, 'title': 'منتج رقم $i', 'price': i * 1.5, 'tags': ['a', 'b']},
    ]);

// دالة التحويل: top-level لتعمل مع compute و Isolate.run
List<Product> parseProducts(String body) {
  final list = jsonDecode(body) as List<dynamic>;
  return [for (final m in list) Product.fromJson(m as Map<String, dynamic>)];
}

// ------------------------------------------------------------
// Isolate طويل العمر: يستقبل أوامر ويرد عليها
// هذه الدالة هي نقطة دخول الـ Isolate الجديد
// ------------------------------------------------------------
void workerEntryPoint(SendPort mainSendPort) {
  // 1) ننشئ منفذ استقبال خاص بالعامل
  final workerReceivePort = ReceivePort();

  // 2) نرسل "عنوان" العامل إلى الرئيسي ليتمكن من مراسلته
  mainSendPort.send(workerReceivePort.sendPort);

  // 3) نستمع للأوامر
  workerReceivePort.listen((message) {
    if (message == 'exit') {
      workerReceivePort.close();
      Isolate.exit(); // إنهاء العامل
    }
    final limit = message as int;
    mainSendPort.send('عدد الأوليات حتى $limit = ${countPrimes(limit)}');
  });
}

class IsolatesScreen extends StatefulWidget {
  const IsolatesScreen({super.key});

  @override
  State<IsolatesScreen> createState() => _IsolatesScreenState();
}

class _IsolatesScreenState extends State<IsolatesScreen>
    with TickerProviderStateMixin {
  // الشعار الدوّار: يتحرك فقط إذا كان الـ Isolate الرئيسي حراً ليرسم الإطارات
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  // مراقب الإطارات: نقيس أطول فجوة بين إطارين متتاليين
  late final Ticker _frameWatch = createTicker(_onTick);
  Duration _lastTick = Duration.zero;
  int _worstGapMs = 0;

  final _logs = <String>[];
  bool _busy = false;
  String? _bigJson; // نُنشئه مرة واحدة ونعيد استخدامه

  @override
  void initState() {
    super.initState();
    _frameWatch.start(); // يستدعي _onTick مع كل إطار يُرسم
  }

  void _onTick(Duration elapsed) {
    final gap = (elapsed - _lastTick).inMilliseconds;
    _lastTick = elapsed;
    // نقيس فقط أثناء تنفيذ مثال (فتح الشاشة نفسه قد يأخذ إطاراً طويلاً)
    if (_busy && gap > _worstGapMs) setState(() => _worstGapMs = gap);
  }

  @override
  void dispose() {
    _frameWatch.dispose();
    _spin.dispose();
    super.dispose();
  }

  void _log(String line) {
    if (!mounted) return;
    setState(() => _logs.add(line));
  }

  Future<void> _run(String title, Future<void> Function() demo) async {
    setState(() {
      _busy = true;
      _worstGapMs = 0;
      _logs
        ..clear()
        ..add('▶ $title');
    });
    // نعطي الشاشة فرصة لرسم "جاري التنفيذ" قبل أن نبدأ
    await Future<void>.delayed(const Duration(milliseconds: 80));
    try {
      await demo();
    } catch (e) {
      _log('⚠️ $e');
    }
    // ننتظر إطاراً لتظهر قيمة "أطول توقف" الحقيقية
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (mounted) setState(() => _busy = false);
    _log('أطول توقف بين إطارين: $_worstGapMs ms '
        '${_worstGapMs > 100 ? '💀 تجمّد' : '❤️ سلس'}');
  }

  // ------------------------------------------------------------
  // 1) بدون Isolate: الخيط الرئيسي مشغول بالكامل ← الشعار يتوقف (jank)
  // ------------------------------------------------------------
  Future<void> _onMainIsolate() async {
    final sw = Stopwatch()..start();
    final result = countPrimes(_limit); // ❌ يحجز الـ UI حتى ينتهي
    _log('بدون Isolate: $result ← ${sw.elapsedMilliseconds}ms');
  }

  // ------------------------------------------------------------
  // 2) Isolate.run: الطريقة الأسهل والأشهر (Dart 2.19+)
  //    تنشئ Isolate، تنفّذ الدالة، تعيد النتيجة، ثم تغلقه تلقائياً
  // ------------------------------------------------------------
  Future<void> _withIsolateRun() async {
    final sw = Stopwatch()..start();
    final result = await Isolate.run(() => countPrimes(_limit));
    _log('Isolate.run: $result ← ${sw.elapsedMilliseconds}ms');
    // 📌 الوقت تقريباً نفسه! الـ Isolate لا يجعل الحساب أسرع،
    //    بل يُبعده عن الخيط الرئيسي فيبقى الـ UI سلساً
  }

  // ------------------------------------------------------------
  // 3) compute من Flutter: نفس الفكرة + تعمل على الويب (على نفس الخيط)
  // ------------------------------------------------------------
  Future<void> _withCompute() async {
    final sw = Stopwatch()..start();
    final result = await compute(countPrimes, _limit);
    _log('compute: $result ← ${sw.elapsedMilliseconds}ms');
  }

  // ------------------------------------------------------------
  // 4) عدة حسابات بالتوازي على أنوية مختلفة
  //    هنا نربح وقتاً فعلاً: الوقت ≈ أطولها وليس مجموعها
  // ------------------------------------------------------------
  Future<void> _parallel() async {
    final sw = Stopwatch()..start();
    final results = await Future.wait([
      Isolate.run(() => countPrimes(_limit ~/ 2)),
      Isolate.run(() => countPrimes(_limit)),
      Isolate.run(() => countPrimes(_limit)),
    ]);
    _log('3 Isolates معاً: $results ← ${sw.elapsedMilliseconds}ms');
  }

  // ------------------------------------------------------------
  // 5) JSON ضخم: jsonDecode على الرئيسي مقابل compute
  // ------------------------------------------------------------
  Future<String> _json() async {
    final cached = _bigJson;
    if (cached != null) return cached;
    // حتى إنشاء النص الضخم نفسه ثقيل ← نُنشئه أيضاً في Isolate
    final json = await compute(buildBigJson, 150000);
    _bigJson = json;
    return json;
  }

  Future<void> _jsonOnMain() async {
    final body = await _json();
    final sw = Stopwatch()..start();
    final products = parseProducts(body); // ❌ على الـ Isolate الرئيسي
    _log('JSON على الرئيسي: ${products.length} منتج ← '
        '${sw.elapsedMilliseconds}ms');
  }

  Future<void> _jsonWithCompute() async {
    final body = await _json();
    final sw = Stopwatch()..start();
    // ✅ التحويل كاملاً في Isolate آخر، والنتيجة تعود جاهزة
    final products = await compute(parseProducts, body);
    _log('JSON عبر compute: ${products.length} منتج ← '
        '${sw.elapsedMilliseconds}ms — آخر منتج: ${products.last.title}');
  }

  // ------------------------------------------------------------
  // 6) Isolate.spawn + Ports: عامل دائم لعدة مهام
  //    مفيد عندما تتكرر المهام (مثلاً معالجة كل رسالة واردة)
  // ------------------------------------------------------------
  Future<void> _longLivedWorker() async {
    final mainReceivePort = ReceivePort();
    await Isolate.spawn(workerEntryPoint, mainReceivePort.sendPort);

    // نحوّل المنفذ إلى broadcast stream لنقرأ منه أكثر من مرة
    final messages = mainReceivePort.asBroadcastStream();

    // أول رسالة من العامل هي الـ SendPort الخاص به
    final workerSendPort = await messages.first as SendPort;

    for (final n in [10000, 50000, 100000]) {
      workerSendPort.send(n); // نرسل مهمة
      _log('${await messages.first}'); // ننتظر الرد
    }

    workerSendPort.send('exit');
    mainReceivePort.close();
  }

  @override
  Widget build(BuildContext context) {
    final demos = <(String, Future<void> Function())>[
      ('1) على الرئيسي ❌', _onMainIsolate),
      ('2) Isolate.run ✅', _withIsolateRun),
      ('3) compute ✅', _withCompute),
      ('4) 3 بالتوازي', _parallel),
      ('5أ) JSON على الرئيسي ❌', _jsonOnMain),
      ('5ب) JSON عبر compute ✅', _jsonWithCompute),
      ('6) عامل دائم (spawn)', _longLivedWorker),
    ];
    final frozen = _worstGapMs > 100;

    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 1: Isolates')),
      body: Column(
        children: [
          // ------------------------------------------------------------
          // مؤشر السلاسة: شعار يدور + أطول توقف بين إطارين
          // ------------------------------------------------------------
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                spacing: 16,
                children: [
                  RotationTransition(
                    turns: _spin,
                    child: const FlutterLogo(size: 64),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 6,
                      children: [
                        const LinearProgressIndicator(),
                        Text(
                          'أطول توقف بين إطارين: $_worstGapMs ms',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: frozen ? Colors.red : Colors.green,
                          ),
                        ),
                        const Text(
                          'إطار سلس = 16ms تقريباً (60 إطار/ثانية). '
                          'أكثر من 100ms = المستخدم يرى التجمّد.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (kIsWeb)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '⚠️ على الويب لا توجد Isolates حقيقية: Isolate.run غير مدعومة، '
                'و compute تعمل على نفس الخيط. جرّب على Android أو Linux.',
              ),
            ),
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
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
        ],
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) القاعدة الذهبية: أي عمل متزامن يأخذ أكثر من ~16ms (إطار واحد) انقله
//    إلى Isolate. قِس أولاً بـ Stopwatch أو DevTools (الدرس 2) قبل أن تنقل.
//
// 2) الـ closure المرسلة إلى Isolate.run تُنسخ مع كل ما تلتقطه من متغيرات.
//    لا تلتقط this أو context أو Widget — مرّر القيم البسيطة فقط:
//      final limit = _limit;
//      await Isolate.run(() => countPrimes(limit));
//
// 3) Dio يقرأ الـ JSON على الرئيسي افتراضياً. للردود الضخمة استخدم
//    BackgroundTransformer (يحوّل النص في Isolate عندما يكون الرد كبيراً):
//      dio.transformer = BackgroundTransformer();
//
// 4) Isolate.exit (التي يستخدمها Isolate.run داخلياً) تنقل النتيجة بدون نسخ،
//    لذلك إعادة قائمة كبيرة من Isolate.run سريعة.
//
// 5) لاستدعاء plugins (مثل shared_preferences) من Isolate خلفي، سجّل أولاً:
//      BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
//    حيث rootToken = RootIsolateToken.instance! يُقرأ في الـ Isolate الرئيسي.
