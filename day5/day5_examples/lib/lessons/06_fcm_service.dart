// ============================================================
// الدرس 6 (Native): إشعارات FCM (Firebase Cloud Messaging) — ملف منفصل
// في التطبيق: القائمة ← الدرس 6  ·  في العرض: شرائح الدرس 6
// ============================================================
//
// ⚠️ هذا المشروع التعليمي لا يحتوي ملفات Firebase (لكل مشروع ملفاته الخاصة)،
//    لذلك كل الدوال هنا "محمية": إن لم يكن Firebase مُعدّاً نعيد رسالة عربية
//    ولا ينهار التطبيق. بعد الإعداد يعمل نفس الكود بدون أي تعديل.
//
// خطوات الإعداد (مرة واحدة لكل مشروع):
//   1) أنشئ مشروعاً في https://console.firebase.google.com
//   2) ثبّت الأدوات:
//        npm install -g firebase-tools   ثم   firebase login
//        dart pub global activate flutterfire_cli
//   3) من مجلد المشروع:
//        flutterfire configure
//      ينشئ: lib/firebase_options.dart
//            android/app/google-services.json
//            ios/Runner/GoogleService-Info.plist
//   4) في main.dart قبل runApp:
//        WidgetsFlutterBinding.ensureInitialized();
//        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
//   5) iOS فقط: Xcode ← Signing & Capabilities ← أضف Push Notifications
//      و Background Modes (Remote notifications — موجودة في Info.plist)،
//      ثم ارفع مفتاح APNs (.p8) في Firebase Console ← Project settings ← Cloud Messaging
//   6) جرّب: Firebase Console ← Messaging ← "Send test message" والصق المعرّف

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// ------------------------------------------------------------
// معالج الرسائل في الخلفية: يعمل في Isolate منفصل (الدرس 1!) والتطبيق مغلق
// يجب أن يكون top-level + @pragma حتى لا يحذفه المترجم في release
// ------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Isolate جديد = لا يوجد Firebase مُهيّأ بعد
  await Firebase.initializeApp();
  // هنا: حفظ الرسالة محلياً، تحديث عدّاد... (لا UI هنا)
  print('📩 رسالة في الخلفية: ${message.messageId}');
}

class FcmService {
  FcmService._();

  static StreamSubscription<RemoteMessage>? _onMessageSub;

  // ------------------------------------------------------------
  // التهيئة المحمية: تعيد null عند النجاح أو رسالة خطأ عربية
  // ------------------------------------------------------------
  static Future<String?> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        // بعد flutterfire configure:
        // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        await Firebase.initializeApp();
      }
      return null;
    } catch (e) {
      return 'Firebase غير مُعدّ في هذا المشروع (لا توجد ملفات الإعداد).\n'
          'نفّذ: flutterfire configure — الخطوات في أعلى 06_fcm_service.dart\n'
          '($e)';
    }
  }

  // ------------------------------------------------------------
  // الصلاحية + التسجيل: نحصل على "عنوان" هذا الجهاز عند Firebase
  // نرسله للـ backend ليستطيع إرسال إشعار لهذا المستخدم بالذات
  // (firebase_messaging 17: register() + onRegistered بدل getToken القديمة)
  // ------------------------------------------------------------
  static Future<String> requestPermissionAndRegister() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(); // iOS + Android 13+
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return 'رفض المستخدم الإشعارات';
    }
    final first = Completer<String>();
    // onRegistered: broadcast stream — يُطلق عند التسجيل وكلما تغيّر المعرّف
    // (إعادة تثبيت، مسح البيانات) ← حدّثه في الخادم في كل مرة
    messaging.onRegistered.listen((id) {
      print('🔄 معرّف FCM: $id');
      if (!first.isCompleted) first.complete(id);
    });
    await messaging.register();
    return first.future.timeout(const Duration(seconds: 20));
  }

  // ------------------------------------------------------------
  // الحالات الثلاث لوصول الرسالة
  // ------------------------------------------------------------
  static Future<void> listen({
    required void Function(RemoteMessage message) onForeground,
    required void Function(RemoteMessage message) onOpened,
  }) async {
    // 1) التطبيق مفتوح: Android لا يعرض إشعاراً تلقائياً ← نعرضه بأنفسنا محلياً
    await _onMessageSub?.cancel();
    _onMessageSub = FirebaseMessaging.onMessage.listen(onForeground);

    // 2) التطبيق في الخلفية والمستخدم ضغط الإشعار
    FirebaseMessaging.onMessageOpenedApp.listen(onOpened);

    // 3) التطبيق كان مغلقاً تماماً وفُتح من الإشعار
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) onOpened(initial);
  }

  // مواضيع (Topics): إرسال لمجموعة بدون حفظ tokens في الخادم
  static Future<void> subscribe(String topic) =>
      FirebaseMessaging.instance.subscribeToTopic(topic);
}
