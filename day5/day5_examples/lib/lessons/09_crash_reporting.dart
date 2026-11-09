// ============================================================
// الدرس 9 (Release): تقارير الأعطال (Crash reporting) مع Firebase Crashlytics — ملف منفصل
// في التطبيق: القائمة ← الدرس 9  ·  في العرض: شرائح الدرس 9
// (الشاشة وحيل الدرس في 09_release.dart)
// ============================================================
//
// بعد النشر لا ترى الـ Console عند المستخدمين. Crashlytics يجمع كل خطأ
// مع الـ stack trace ونوع الجهاز ونسخة التطبيق ويرسلها إلى لوحة Firebase.
//
// ⚠️ مثل FCM (الدرس 6): المشروع بدون ملفات Firebase، لذلك كل شيء "محمي":
//    بدون إعداد نسجّل الأخطاء محلياً في قائمة ونعرضها على الشاشة.
//
// خطوات الإعداد:
//   1) flutterfire configure   (نفس خطوة الدرس 6 — مرة واحدة للمشروع)
//   2) في main.dart:
//        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//        CrashReporter.installHandlers();
//        runApp(...);
//   3) مع --obfuscate (الدرس 7) ارفع ملفات الرموز ليقرأ Crashlytics الأعطال:
//        firebase crashlytics:symbols:upload --app=<FIREBASE_APP_ID> build/symbols
//
// البديل: Sentry (يعمل أيضاً على الويب و Linux، ومفتوح المصدر):
//   flutter pub add sentry_flutter
//   await SentryFlutter.init((options) => options.dsn = '...',
//       appRunner: () => runApp(const App()));

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReporter {
  CrashReporter._();

  static bool _firebaseReady = false;

  // سجل محلي عندما لا يوجد Firebase (للعرض في الشاشة)
  static final localReports = ValueNotifier<List<String>>([]);

  static FlutterExceptionHandler? _previousFlutterHandler;
  static bool Function(Object, StackTrace)? _previousPlatformHandler;

  // ------------------------------------------------------------
  // التهيئة المحمية: null عند النجاح أو رسالة عربية
  // ------------------------------------------------------------
  static Future<String?> init() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      // لا نرسل أعطال وضع التطوير — تملأ اللوحة بلا فائدة
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
      _firebaseReady = true;
      return null;
    } catch (e) {
      _firebaseReady = false;
      return 'Firebase غير مُعدّ — الأخطاء تُسجَّل محلياً في هذه الشاشة.\n'
          'للإعداد: flutterfire configure (الخطوات في 09_crash_reporting.dart)';
    }
  }

  // ------------------------------------------------------------
  // التقاط كل الأخطاء غير المعالجة في التطبيق
  // ------------------------------------------------------------
  static void installHandlers() {
    // 1) أخطاء إطار Flutter (build / layout / paint)
    _previousFlutterHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      record(details.exception, details.stack, fatal: true);
      _previousFlutterHandler?.call(details); // نُبقي الطباعة في الـ Console
    };
    // 2) أخطاء async خارج Flutter (Future بدون catch مثلاً)
    _previousPlatformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack, fatal: true);
      return true; // true = عولج الخطأ
    };
  }

  // نعيد المعالجات السابقة (عند الخروج من شاشة الدرس)
  static void uninstallHandlers() {
    if (_previousFlutterHandler != null) {
      FlutterError.onError = _previousFlutterHandler;
    }
    PlatformDispatcher.instance.onError = _previousPlatformHandler;
    _previousFlutterHandler = null;
  }

  // ------------------------------------------------------------
  // تسجيل خطأ: إلى Crashlytics إن وُجد، وإلا محلياً
  // ------------------------------------------------------------
  static Future<void> record(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
    String? reason,
  }) async {
    if (_firebaseReady) {
      await FirebaseCrashlytics.instance
          .recordError(error, stack, reason: reason, fatal: fatal);
    }
    final firstLine = stack?.toString().split('\n').first ?? '';
    localReports.value = [
      '${fatal ? '💥 fatal' : '⚠️ non-fatal'}: $error'
          '${reason == null ? '' : ' — $reason'}\n   $firstLine',
      ...localReports.value,
    ];
  }

  // سياق يساعد عند قراءة العطل: من المستخدم؟ ماذا فعل قبله؟
  static Future<void> setUser(String id) async {
    if (_firebaseReady) await FirebaseCrashlytics.instance.setUserIdentifier(id);
  }

  static Future<void> log(String message) async {
    if (_firebaseReady) await FirebaseCrashlytics.instance.log(message);
  }
}
