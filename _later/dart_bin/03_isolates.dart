// ============================================================
// الدرس 3: Isolates — التنفيذ المتوازي الحقيقي
// التشغيل: dart run bin/03_isolates.dart
// ============================================================
//
// async/await لا يعني "خيط جديد"! كل شيء يعمل على نفس الـ Isolate.
// إذا كان لدينا حساب ثقيل (معالجة صورة، JSON ضخم، تشفير)
// سيتجمّد الـ UI لأن الخيط مشغول.
//
// الـ Isolate = عامل مستقل له ذاكرته الخاصة (لا يشارك المتغيرات)
// والتواصل بينه وبين الـ Isolate الرئيسي يتم عبر الرسائل فقط.

import 'dart:async';
import 'dart:isolate';

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

Future<void> main() async {
  const limit = 3000000;

  // ------------------------------------------------------------
  // 1) بدون Isolate: الخيط الرئيسي مشغول بالكامل
  //    في Flutter هذا يعني UI متجمّد وفقدان إطارات (jank)
  // ------------------------------------------------------------
  // مؤقت يحاكي الـ UI: يطبع "نبضة" كل 200ms إذا كان الخيط الرئيسي حراً
  var beats = 0;
  final heartbeat = Timer.periodic(
    const Duration(milliseconds: 200),
    (_) => beats++,
  );

  var sw = Stopwatch()..start();
  final syncResult = countPrimes(limit);
  // نعطي المؤقت فرصة ليعمل ثم نقرأ عدد النبضات
  await Future.delayed(Duration.zero);
  print('بدون Isolate: $syncResult ← ${sw.elapsedMilliseconds}ms '
      '— نبضات الـ UI: $beats 💀 (متجمّد)');

  // ------------------------------------------------------------
  // 2) Isolate.run: الطريقة الأسهل والأشهر (Dart 2.19+)
  //    تنشئ Isolate، تنفّذ الدالة، تعيد النتيجة، ثم تغلقه تلقائياً
  //    في Flutter يمكن استخدام compute(countPrimes, limit) بنفس الفكرة
  // ------------------------------------------------------------
  beats = 0;
  sw = Stopwatch()..start();
  final result = await Isolate.run(() => countPrimes(limit));
  print('Isolate.run: $result ← ${sw.elapsedMilliseconds}ms '
      '— نبضات الـ UI: $beats ❤️ (يعمل بسلاسة)');
  heartbeat.cancel();
  // 📌 لاحظ: الوقت تقريباً نفسه! الـ Isolate لا يجعل الحساب أسرع،
  //    بل يُبعده عن الخيط الرئيسي فيبقى الـ UI سلساً

  // ------------------------------------------------------------
  // 3) تشغيل عدة حسابات بالتوازي على أنوية مختلفة
  //    هنا نربح وقتاً فعلاً: 3 حسابات بوقت أطولها تقريباً (وليس مجموعها)
  // ------------------------------------------------------------
  sw = Stopwatch()..start();
  final parallel = await Future.wait([
    Isolate.run(() => countPrimes(1000000)),
    Isolate.run(() => countPrimes(2000000)),
    Isolate.run(() => countPrimes(3000000)),
  ]);
  print('3 Isolates معاً: $parallel ← ${sw.elapsedMilliseconds}ms');

  // ------------------------------------------------------------
  // 4) Isolate.spawn + Ports: عامل دائم لعدة مهام
  //    مفيد عندما تتكرر المهام (مثلاً معالجة كل رسالة واردة)
  // ------------------------------------------------------------
  print('\n--- عامل دائم عبر SendPort/ReceivePort ---');
  final mainReceivePort = ReceivePort();
  await Isolate.spawn(workerEntryPoint, mainReceivePort.sendPort);

  // نحوّل المنفذ إلى broadcast stream لنقرأ منه أكثر من مرة
  final messages = mainReceivePort.asBroadcastStream();

  // أول رسالة من العامل هي الـ SendPort الخاص به
  final workerSendPort = await messages.first as SendPort;

  for (final n in [10000, 50000, 100000]) {
    workerSendPort.send(n); // نرسل مهمة
    print(await messages.first); // ننتظر الرد
  }

  workerSendPort.send('exit');
  mainReceivePort.close();

  // 📌 ملاحظات:
  // - الـ Isolates لا تشارك الذاكرة، البيانات تُنسخ عند الإرسال
  // - إنشاء Isolate له تكلفة، فلا تستخدمه لمهام صغيرة
  // - في Flutter Web لا توجد Isolates حقيقية (compute تعمل على نفس الخيط)
}
