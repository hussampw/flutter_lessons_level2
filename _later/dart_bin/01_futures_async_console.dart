// ============================================================
// الدرس 1: Futures و async/await بالتفصيل
// التشغيل: dart run bin/01_futures_async.dart
// ============================================================
//
// الـ Future هو "وعد" بقيمة ستصل لاحقاً (أو خطأ).
// Dart تعمل على خيط واحد (Single Thread) مع حلقة أحداث (Event Loop)،
// لذلك الانتظار لا يوقف البرنامج، بل يسمح لمهام أخرى بالعمل.

import 'dart:async';

// ------------------------------------------------------------
// دالة تحاكي طلب شبكة يستغرق وقتاً
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

// ------------------------------------------------------------
// 1) الطريقة القديمة: then / catchError / whenComplete
// ------------------------------------------------------------
Future<void> thenStyle() {
  print('\n--- 1) أسلوب then ---');
  return fetchUserName(1)
      .then((name) => print('وصل الاسم: $name'))
      .catchError((e) => print('خطأ: $e'))
      .whenComplete(() => print('انتهى (مثل finally)'));
}

// ------------------------------------------------------------
// 2) الطريقة الحديثة: async / await مع try / catch / finally
//    الكود يُقرأ من الأعلى للأسفل كأنه متزامن
// ------------------------------------------------------------
Future<void> awaitStyle() async {
  print('\n--- 2) أسلوب async/await ---');
  try {
    final name = await fetchUserName(-5); // سيفشل عمداً
    print(name);
  } on ArgumentError catch (e) {
    // on لالتقاط نوع خطأ محدد
    print('خطأ متوقع: ${e.message}');
  } catch (e, stack) {
    // catch عامة لأي خطأ آخر، ومعها الـ StackTrace
    print('خطأ غير متوقع: $e\n$stack');
  } finally {
    print('finally تعمل دائماً');
  }
}

// ------------------------------------------------------------
// 3) تسلسلي مقابل متوازي — من أهم نقاط الأداء
// ------------------------------------------------------------
Future<void> sequentialVsParallel() async {
  print('\n--- 3) تسلسلي مقابل متوازي ---');

  // تسلسلي: الطلب الثاني لا يبدأ إلا بعد انتهاء الأول ≈ 1200ms
  var sw = Stopwatch()..start();
  final a = await fetchUserName(1);
  final b = await fetchOrdersCount();
  print('تسلسلي: $a / $b طلب  ← ${sw.elapsedMilliseconds}ms');

  // متوازي باستخدام Future.wait: كل الطلبات تبدأ معاً ≈ 700ms
  // عيبه: النتيجة List<Object> فنحتاج تحويل الأنواع يدوياً
  sw = Stopwatch()..start();
  final results = await Future.wait([fetchUserName(2), fetchOrdersCount()]);
  print('Future.wait: $results  ← ${sw.elapsedMilliseconds}ms');

  // متوازي باستخدام Records (Dart 3): الأنواع محفوظة لكل عنصر ✅
  sw = Stopwatch()..start();
  final (name, count) = await (fetchUserName(3), fetchOrdersCount()).wait;
  print('Record.wait: $name / $count  ← ${sw.elapsedMilliseconds}ms');
}

// ------------------------------------------------------------
// 4) المهلة الزمنية timeout و Future.any
// ------------------------------------------------------------
Future<void> timeoutAndAny() async {
  print('\n--- 4) timeout و Future.any ---');
  try {
    // إذا لم تنتهِ العملية خلال 200ms نرمي TimeoutException
    await fetchUserName(1).timeout(const Duration(milliseconds: 200));
  } on TimeoutException {
    print('انتهت المهلة! الخادم بطيء');
  }

  // Future.any: نأخذ أول نتيجة تصل (مثلاً من عدة خوادم)
  final fastest = await Future.any([
    Future.delayed(const Duration(milliseconds: 300), () => 'الخادم A'),
    Future.delayed(const Duration(milliseconds: 100), () => 'الخادم B'),
  ]);
  print('الأسرع: $fastest');
}

// ------------------------------------------------------------
// 5) Completer: تحويل كود يعتمد على callbacks إلى Future
// ------------------------------------------------------------
Future<String> legacyApiAsFuture() {
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
Future<void> eventLoopOrder() async {
  print('\n--- 6) ترتيب حلقة الأحداث ---');
  print('A: كود متزامن');
  Future(() => print('D: Event (Future عادي)'));
  scheduleMicrotask(() => print('C: Microtask'));
  Future.microtask(() => print('C2: Microtask آخر'));
  print('B: كود متزامن');
  // الناتج: A, B, C, C2, D
  // لأن الـ microtasks تُنفَّذ كلها قبل أي event جديد
  await Future.delayed(const Duration(milliseconds: 10));
}

Future<void> main() async {
  await thenStyle();
  await awaitStyle();
  await sequentialVsParallel();
  await timeoutAndAny();
  print('\n--- 5) Completer ---');
  print(await legacyApiAsFuture());
  await eventLoopOrder();

  // ⚠️ تنبيه: نسيان await يعني أن الخطأ قد يضيع ولا يُلتقط!
  // استخدم lint: unawaited_futures لاكتشاف ذلك
}
