// ============================================================
// الدرس 2 (Dart): Streams و StreamController
// في التطبيق: القائمة ← الدرس 2  ·  في العرض: شرائح الدرس 2
// ============================================================
//
// الـ Future = قيمة واحدة لاحقاً.
// الـ Stream = سلسلة قيم تصل مع الوقت (رسائل شات، موقع GPS، تقدّم تحميل…
// وأيضاً: نتائج قاعدة البيانات كلما تغيّرت — Drift watch() في الدرس 6).
//
// الشاشة فيها جزءان:
//   • أزرار أمثلة تكتب في "الكونسول" (async* · التحويلات · periodic · Transformer)
//   • شات حي: StreamController واحد ومستمعان + إيقاف مؤقت + خطأ + إغلاق

import 'dart:async';

import 'package:flutter/material.dart';

import '../shared/console_view.dart';

// ------------------------------------------------------------
// 1) إنشاء Stream بدالة async* و yield
// ------------------------------------------------------------
Stream<int> countdown(int from) async* {
  for (var i = from; i >= 0; i--) {
    await Future.delayed(const Duration(milliseconds: 200));
    yield i; // yield ترسل قيمة إلى من يستمع
  }
}

// ------------------------------------------------------------
// 2) StreamController: نتحكم بأنفسنا متى نرسل القيم
//    مثال عملي: خدمة شات بسيطة
// ------------------------------------------------------------
class ChatService {
  // broadcast يسمح بأكثر من مستمع في نفس الوقت
  // بدونها: مستمع واحد فقط (Single-subscription)
  final _controller = StreamController<String>.broadcast();

  // نكشف الـ Stream فقط (للقراءة) ونخفي الـ Sink (للكتابة)
  Stream<String> get messages => _controller.stream;

  bool get isClosed => _controller.isClosed;

  void send(String text) {
    if (_controller.isClosed) return;
    _controller.add(text); // إرسال قيمة
  }

  void fail() {
    if (_controller.isClosed) return;
    _controller.addError(Exception('انقطع الاتصال'));
  }

  // مهم جداً: إغلاق الـ controller لتجنّب تسريب الذاكرة
  Future<void> dispose() => _controller.close();
}

class StreamsScreen extends StatefulWidget {
  const StreamsScreen({super.key});

  @override
  State<StreamsScreen> createState() => _StreamsScreenState();
}

class _StreamsScreenState extends State<StreamsScreen> {
  final _logs = <String>[];
  bool _busy = false;

  void _log(String line) {
    if (!mounted) return;
    setState(() => _logs.add(line));
  }

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

  // --- await for: أبسط طريقة لاستهلاك Stream ---
  Future<void> _asyncStarDemo() async {
    await for (final n in countdown(3)) {
      _log('العد: $n');
    }
    _log('انتهى الـ Stream ← خرجنا من await for');
  }

  // --- التحويلات: where / map / take / distinct ---
  // تشبه دوال القوائم لكنها تعمل على قيم تصل مع الوقت
  Future<void> _transformDemo() async {
    final evens = Stream.fromIterable([1, 2, 2, 3, 4, 4, 5, 6])
        .distinct() // تجاهل القيم المكررة المتتالية
        .where((n) => n.isEven) // الأرقام الزوجية فقط
        .map((n) => 'زوجي: $n') // تحويل كل قيمة
        .take(2); // أول قيمتين ثم يُغلق تلقائياً
    _log('${await evens.toList()}');
  }

  // --- Stream.periodic: قيم كل فترة زمنية (مثل مؤقت) ---
  Future<void> _periodicDemo() async {
    final ticks = Stream.periodic(
      const Duration(milliseconds: 300),
      (i) => 'tick $i',
    ).take(4);
    await ticks.forEach(_log);
  }

  // --- StreamTransformer: منطق تحويل قابل لإعادة الاستخدام ---
  Future<void> _transformerDemo() async {
    final toUpper = StreamTransformer<String, String>.fromHandlers(
      handleData: (data, sink) => sink.add(data.toUpperCase()),
    );
    await Stream.fromIterable(['flutter', 'dart', 'drift'])
        .transform(toUpper)
        .forEach(_log);
  }

  @override
  Widget build(BuildContext context) {
    final demos = <(String, Future<void> Function())>[
      ('1) async* و await for', _asyncStarDemo),
      ('2) التحويلات', _transformDemo),
      ('3) Stream.periodic', _periodicDemo),
      ('4) StreamTransformer', _transformerDemo),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 2: Streams و StreamController')),
      body: Column(
        children: [
          DemoButtons(demos: demos, busy: _busy, onRun: _run),
          Expanded(flex: 2, child: ConsoleView(lines: _logs, busy: _busy)),
          const Expanded(flex: 3, child: _LiveChatDemo()),
        ],
      ),
    );
  }
}

// ============================================================
// 5) شات حي: StreamController + مستمعان + pause/resume + خطأ + إغلاق
// ============================================================
class _LiveChatDemo extends StatefulWidget {
  const _LiveChatDemo();

  @override
  State<_LiveChatDemo> createState() => _LiveChatDemoState();
}

class _LiveChatDemoState extends State<_LiveChatDemo> {
  late ChatService _chat;
  StreamSubscription<String>? _screenSub; // المستمع 1: شاشة الشات
  StreamSubscription<String>? _badgeSub; // المستمع 2: عدّاد الإشعارات

  final _messages = <String>[];
  int _unread = 0;
  int _sent = 0;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _chat = ChatService();

    // المستمع الأول: يعرض الرسائل
    _screenSub = _chat.messages.listen(
      (msg) => setState(() => _messages.add('📩 $msg')),
      onError: (Object e) => setState(() => _messages.add('❌ خطأ: $e')),
      onDone: () => setState(() => _messages.add('✅ أُغلق الـ Stream (onDone)')),
    );

    // المستمع الثاني (ممكن لأنه broadcast): يحسب الإشعارات
    // ⚠️ كل مستمع يجب أن يعالج الأخطاء، وإلا يصبح الخطأ Unhandled
    _badgeSub = _chat.messages.listen(
      (_) => setState(() => _unread++),
      onError: (Object _) {},
    );
  }

  void _send() {
    _sent++;
    _chat.send('رسالة رقم $_sent');
  }

  void _togglePause() {
    final sub = _screenSub;
    if (sub == null) return;
    setState(() {
      // إيقاف مؤقت: الرسائل تُخزَّن (buffer) ولا تُعرض الآن
      // استئناف: تصل الرسائل المخزّنة دفعة واحدة
      sub.isPaused ? sub.resume() : sub.pause();
    });
  }

  Future<void> _close() async {
    // مستمع متوقف لا يستلم حدث done حتى يُستأنف — نستأنفه قبل الإغلاق
    if (_screenSub?.isPaused ?? false) _screenSub!.resume();
    await _badgeSub?.cancel();
    await _chat.dispose(); // يستدعي onDone عند المستمع الأول
    await _screenSub?.cancel();
    if (mounted) setState(() {});
  }

  void _reconnect() {
    setState(() {
      _messages.add('🔄 اتصال جديد = StreamController جديد');
      _connect();
    });
  }

  @override
  void dispose() {
    // ⚠️ في Flutter: ألغِ الاشتراك وأغلق الـ controller في dispose() دائماً
    _screenSub?.cancel();
    _badgeSub?.cancel();
    _chat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paused = _screenSub?.isPaused ?? false;
    final closed = _chat.isClosed;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '5) شات حي: Controller واحد ← مستمعان',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Badge(
                  label: Text('$_unread'),
                  child: const Icon(Icons.notifications),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: closed ? null : _send,
                  icon: const Icon(Icons.send),
                  label: const Text('send()'),
                ),
                OutlinedButton(
                  onPressed: closed ? null : _togglePause,
                  child: Text(paused ? '▶ resume() المستمع 1' : '⏸ pause() المستمع 1'),
                ),
                OutlinedButton(
                  onPressed: closed ? null : _chat.fail,
                  child: const Text('addError()'),
                ),
                OutlinedButton(
                  onPressed: closed ? _reconnect : _close,
                  child: Text(closed ? 'اتصال جديد' : 'close()'),
                ),
              ],
            ),
            if (paused)
              const Text('⏸ المستمع 1 متوقف — الرسائل تُخزَّن، والعدّاد (المستمع 2) يستمر'),
            Expanded(
              child: ListView(
                reverse: true,
                children: [
                  for (final m in _messages.reversed)
                    Text(m, style: const TextStyle(fontSize: 15)),
                ],
              ),
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
// 1) في Flutter لا تحتاج listen يدوياً للعرض: StreamBuilder أو StreamProvider
//    (اليوم الأول، الدرس 3) يشتركان ويلغيان الاشتراك تلقائياً:
//      final notesProvider = StreamProvider((ref) => ref.watch(dbProvider).watchNotes());
//
// 2) single-subscription أم broadcast؟ إذا احتجت مستمعَين لـ Stream عادي حوّله:
//      final shared = controller.stream.asBroadcastStream();
//
// 3) Stream لم يُغلق = تسريب ذاكرة. أي StreamController تنشئه أغلقه:
//      ref.onDispose(controller.close);   // داخل provider
//
// 4) في الاختبارات تحقّق من ترتيب القيم بدل listen يدوي:
//      expect(countdown(2), emitsInOrder([2, 1, 0, emitsDone]));
//
// 5) Drift: كل select(...).watch() يعيد Stream<List<T>> يُرسل قائمة جديدة
//    بعد أي insert / update / delete على الجدول — نراه في الدرس 6.
