// ============================================================
// الدرس 2: Streams و StreamController
// التشغيل: dart run bin/02_streams.dart
// ============================================================
//
// الـ Future = قيمة واحدة لاحقاً.
// الـ Stream = سلسلة قيم تصل مع الوقت (مثل: رسائل شات، موقع GPS، تقدّم تحميل).

import 'dart:async';

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
// 2) StreamController: نتحكم بنفسنا متى نرسل القيم
//    مثال عملي: خدمة شات بسيطة
// ------------------------------------------------------------
class ChatService {
  // broadcast يسمح بأكثر من مستمع في نفس الوقت
  // بدونها: مستمع واحد فقط (Single-subscription)
  final _controller = StreamController<String>.broadcast();

  // نكشف الـ Stream فقط (للقراءة) ونخفي الـ Sink (للكتابة)
  Stream<String> get messages => _controller.stream;

  void send(String text) {
    if (_controller.isClosed) return;
    _controller.add(text); // إرسال قيمة
  }

  void fail() => _controller.addError(Exception('انقطع الاتصال'));

  // مهم جداً: إغلاق الـ controller لتجنّب تسريب الذاكرة
  Future<void> dispose() => _controller.close();
}

Future<void> main() async {
  // --- await for: أبسط طريقة لاستهلاك Stream ---
  print('--- 1) async* + await for ---');
  await for (final n in countdown(3)) {
    print('العد: $n');
  }

  // --- التحويلات: where / map / take / distinct ---
  // تشبه دوال القوائم لكنها تعمل على قيم تصل مع الوقت
  print('\n--- 2) التحويلات ---');
  final evens = Stream.fromIterable([1, 2, 2, 3, 4, 4, 5, 6])
      .distinct() // تجاهل القيم المكررة المتتالية
      .where((n) => n.isEven) // الأرقام الزوجية فقط
      .map((n) => 'زوجي: $n') // تحويل كل قيمة
      .take(2); // أول قيمتين ثم يُغلق تلقائياً
  print(await evens.toList());

  // --- StreamController + listen + StreamSubscription ---
  print('\n--- 3) StreamController ---');
  final chat = ChatService();

  // المستمع الأول: يعرض الرسائل
  final sub1 = chat.messages.listen(
    (msg) => print('📩 شاشة الشات: $msg'),
    onError: (e) => print('❌ خطأ: $e'),
    onDone: () => print('✅ أُغلق الـ Stream'),
  );

  // المستمع الثاني (ممكن لأنه broadcast): يحسب الإشعارات
  var unread = 0;
  // ⚠️ كل مستمع يجب أن يعالج الأخطاء، وإلا يصبح الخطأ Unhandled ويُوقف البرنامج
  final sub2 = chat.messages.listen((_) => unread++, onError: (_) {});

  chat.send('مرحباً');
  chat.send('كيف الحال؟');
  chat.send('اخبارك');
  await Future.delayed(Duration.zero); // نعطي فرصة لوصول القيم

  sub1.pause(); // إيقاف مؤقت: الرسائل تُخزَّن (buffer) ولا تُعرض الآن
  chat.send('رسالة أثناء الإيقاف');
  await Future.delayed(Duration.zero);
  print('⏸️ استئناف المستمع الأول...');
  sub1.resume(); // تصل الرسائل المخزّنة الآن دفعة واحدة
  // 💡 إذا أردت تجاهل ما فات بدل تخزينه: cancel() ثم listen() من جديد

  chat.fail(); // إرسال خطأ عبر الـ Stream
  await Future.delayed(Duration.zero);
  print('عدد غير المقروء: $unread');

  // ⚠️ في Flutter: ألغِ الاشتراك في dispose() دائماً
  await sub2.cancel();
  await chat.dispose(); // يستدعي onDone عند sub1
  await sub1.cancel();

  // --- Stream.periodic: قيم كل فترة زمنية (مثل مؤقت) ---
  print('\n--- 4) Stream.periodic ---');
  final ticks = Stream.periodic(
    const Duration(milliseconds: 100),
    (i) => 'tick $i',
  ).take(3);
  await ticks.forEach(print);

  // --- StreamTransformer: منطق تحويل قابل لإعادة الاستخدام ---
  print('\n--- 5) StreamTransformer ---');
  final toUpper = StreamTransformer<String, String>.fromHandlers(
    handleData: (data, sink) => sink.add(data.toUpperCase()),
  );
  await Stream.fromIterable(['flutter', 'dart'])
      .transform(toUpper)
      .forEach(print);
}
