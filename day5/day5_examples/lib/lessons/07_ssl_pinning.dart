// ============================================================
// الدرس 7 (Security): SSL Pinning مع Dio — ملف منفصل
// في التطبيق: القائمة ← الدرس 7  ·  في العرض: شرائح الدرس 7
// (الشاشة وحيل الدرس في 07_security.dart)
// ============================================================
//
// HTTPS العادي يثق بأي شهادة موقّعة من أي جهة موثوقة في الجهاز.
// المهاجم الذي يثبّت شهادة على الجهاز (Proxy مثل Charles / mitmproxy)
// يستطيع قراءة كل الطلبات. SSL Pinning = "لا أثق إلا بشهادة خادمي أنا".
//
// الفكرة: بعد نجاح فحص النظام، نحسب بصمة SHA-256 للشهادة ونقارنها بقائمتنا.
//
// ⚠️ الشهادات تتجدد (Let's Encrypt كل 90 يوماً تقريباً):
//    ضع دائماً بصمة احتياطية (backup pin)، وحدّث التطبيق قبل انتهاء الشهادة،
//    وإلا يتوقف التطبيق عن الاتصال عند كل المستخدمين!
//
// ⚠️ على الويب لا يمكن الوصول إلى الشهادة (المتصفح يتحكم بـ TLS) ← لا pinning.

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

// بصمة SHA-256 لشهادة الخادم (DER) كنص hex
String certificateFingerprint(X509Certificate cert) =>
    sha256.convert(cert.der).toString();

Dio createPinnedDio({
  required Set<String> allowedFingerprints,
  void Function(String fingerprint)? onCertificate,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://dummyjson.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      // شهادة غير موثوقة من النظام؟ ارفض دائماً (لا تكتب => true أبداً!)
      client.badCertificateCallback = (cert, host, port) => false;
      return client;
    },
    // يُستدعى بعد قبول النظام للشهادة: نتأكد أنها شهادتنا بالضبط
    validateCertificate: (cert, host, port) {
      if (cert == null) return false;
      final fingerprint = certificateFingerprint(cert);
      onCertificate?.call(fingerprint);
      return allowedFingerprints.contains(fingerprint);
    },
  );
  return dio;
}
