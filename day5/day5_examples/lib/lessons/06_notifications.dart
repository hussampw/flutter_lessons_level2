// ============================================================
// الدرس 6 (Native): الإشعارات — المحلية (flutter_local_notifications) و FCM
// في التطبيق: القائمة ← الدرس 6  ·  في العرض: شرائح الدرس 6
// ============================================================
//
// نوعان من الإشعارات:
//   محلية (Local): التطبيق نفسه يعرضها — تذكير، انتهاء تحميل، مؤقت
//                 تعمل بدون إنترنت وبدون خادم (وتعمل على Linux أيضاً!)
//   بعيدة (Push / FCM): الخادم يرسلها عبر Firebase ← تصل والتطبيق مغلق
//                 الكود في ملف منفصل: lib/lessons/06_fcm_service.dart
//
// إعداد Android لهذا الدرس (موجود في المشروع):
//   AndroidManifest.xml ← POST_NOTIFICATIONS + receivers للإشعارات المجدولة
//   app/build.gradle.kts ← isCoreLibraryDesugaringEnabled = true (تطلبه المكتبة)

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '06_fcm_service.dart';

// ------------------------------------------------------------
// كائن واحد للتطبيق كله (عادةً يُهيّأ في main قبل runApp)
// ------------------------------------------------------------
final notifications = FlutterLocalNotificationsPlugin();

// Android 8+: كل إشعار يتبع "قناة" يتحكم المستخدم بها من الإعدادات
const _channel = AndroidNotificationDetails(
  'orders', // معرّف القناة (ثابت لا يتغير)
  'الطلبات', // الاسم الذي يراه المستخدم في الإعدادات
  channelDescription: 'إشعارات حالة الطلبات',
  importance: Importance.high,
  priority: Priority.high,
);

const _details = NotificationDetails(
  android: _channel,
  iOS: DarwinNotificationDetails(),
  linux: LinuxNotificationDetails(),
);

bool _initialized = false;

Future<void> initNotifications(
  void Function(NotificationResponse response) onTap,
) async {
  if (_initialized) return;
  await notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      // false: لا نطلب الصلاحية عند التهيئة، بل عند الحاجة (الدرس 5)
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      linux: LinuxInitializationSettings(defaultActionName: 'فتح'),
    ),
    // المستخدم ضغط الإشعار ← payload يخبرنا أين نذهب
    onDidReceiveNotificationResponse: onTap,
  );
  tz.initializeTimeZones(); // للإشعارات المجدولة
  _initialized = true;
}

// طلب الصلاحية: Android 13+ و iOS (باقي المنصات لا تحتاج)
Future<bool> requestNotificationPermission() async {
  final android = notifications.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  final ios = notifications.resolvePlatformSpecificImplementation<
      IOSFlutterLocalNotificationsPlugin>();
  final granted = await android?.requestNotificationsPermission() ??
      await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
      true;
  return granted;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _logs = <String>[];

  void _log(String line) {
    if (!mounted) return;
    setState(() => _logs.insert(0, line));
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on MissingPluginException {
      _log('📱 الإشعارات المحلية تعمل على Android و iOS و Linux و الويب — '
          'وليس داخل flutter test.');
    } catch (e) {
      _log('⚠️ $e');
    }
  }

  Future<void> _ensureInit() => initNotifications((response) {
        _log('👆 ضغط المستخدم الإشعار — payload: ${response.payload}');
      });

  // ------------------------------------------------------------
  // 1) إشعار فوري
  // ------------------------------------------------------------
  Future<void> _showNow() => _guard(() async {
        await _ensureInit();
        if (!await requestNotificationPermission()) {
          _log('🚫 رفض المستخدم صلاحية الإشعارات');
          return;
        }
        await notifications.show(
          id: 1,
          title: 'تم شحن طلبك 🚚',
          body: 'الطلب رقم 1024 في الطريق إليك',
          notificationDetails: _details,
          payload: 'order:1024', // نقرأه عند الضغط لفتح الشاشة الصحيحة
        );
        _log('✅ أُرسل إشعار فوري');
      });

  // ------------------------------------------------------------
  // 2) إشعار مجدول بعد 10 ثوانٍ (يعمل حتى لو أُغلق التطبيق)
  // ------------------------------------------------------------
  Future<void> _schedule() => _guard(() async {
        if (kIsWeb || defaultTargetPlatform == TargetPlatform.linux) {
          _log('⏰ الجدولة مدعومة على Android و iOS فقط');
          return;
        }
        await _ensureInit();
        await notifications.zonedSchedule(
          id: 2,
          title: 'تذكير ⏰',
          body: 'سلّتك تنتظرك — أكمل الطلب قبل نفاد الكمية',
          scheduledDate:
              tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10)),
          notificationDetails: _details,
          // inexact: لا يحتاج صلاحية "المنبهات الدقيقة" في Android 14+
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'cart',
        );
        _log('⏰ جُدول إشعار بعد 10 ثوانٍ — أغلق التطبيق وانتظر');
      });

  Future<void> _cancelAll() => _guard(() async {
        await _ensureInit();
        await notifications.cancelAll();
        _log('🧹 أُلغيت كل الإشعارات');
      });

  // ------------------------------------------------------------
  // 3) FCM: محمي — يعمل فقط بعد flutterfire configure
  // ------------------------------------------------------------
  Future<void> _initFcm() async {
    final error = await FcmService.init();
    if (error != null) {
      _log('🔥 $error');
      return;
    }
    try {
      final id = await FcmService.requestPermissionAndRegister();
      _log('🔑 معرّف FCM لهذا الجهاز: $id');
      await FcmService.listen(
        onForeground: (RemoteMessage m) {
          _log('📩 وصلت رسالة والتطبيق مفتوح: ${m.notification?.title}');
          // نعرضها كإشعار محلي لأن Android لا يعرضها في الواجهة الأمامية
          _guard(() async {
            await _ensureInit();
            await notifications.show(
              id: m.hashCode,
              title: m.notification?.title,
              body: m.notification?.body,
              notificationDetails: _details,
              payload: m.data['route'] as String?,
            );
          });
        },
        onOpened: (m) => _log('👆 فُتح التطبيق من إشعار FCM: ${m.data}'),
      );
    } catch (e) {
      _log('⚠️ FCM: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 6: الإشعارات')),
      body: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.notifications_active),
            title: Text('إشعارات محلية'),
            subtitle: Text('flutter_local_notifications — بدون خادم'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(onPressed: _showNow, child: const Text('1) إشعار الآن')),
                FilledButton.tonal(
                  onPressed: _schedule,
                  child: const Text('2) بعد 10 ثوانٍ'),
                ),
                OutlinedButton(
                  onPressed: _cancelAll,
                  child: const Text('إلغاء الكل'),
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('3) Push من الخادم (FCM)'),
            subtitle: const Text(
              'يحتاج مشروع Firebase: flutterfire configure — '
              'بدونه نعرض رسالة ولا ينهار التطبيق',
            ),
            trailing: OutlinedButton(
              onPressed: _initFcm,
              child: const Text('تهيئة FCM'),
            ),
          ),
          // الكونسول
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
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
// 1) استخدم payload لتوجيه المستخدم: 'order:1024' ← افتح شاشة الطلب مباشرة
//    (مع go_router من اليوم الثاني: context.go('/orders/1024')).
//
// 2) التطبيق فُتح من إشعار محلي وهو مغلق؟ اقرأ التفاصيل عند البدء:
//      final details = await notifications.getNotificationAppLaunchDetails();
//      if (details?.didNotificationLaunchApp ?? false) { ... }
//
// 3) رسالة FCM فيها notification تُعرض تلقائياً والتطبيق في الخلفية،
//    أما رسالة data فقط فتصل صامتة إلى firebaseMessagingBackgroundHandler.
//
// 4) لا ترسل للجميع بمعرّفات الأجهزة: استخدم Topics للمجموعات (عروض، أخبار):
//      FirebaseMessaging.instance.subscribeToTopic('offers');
//
// 5) Android: الأيقونة الصغيرة للإشعار يجب أن تكون بيضاء وشفافة
//    (ضعها في res/drawable ومرّر اسمها لـ AndroidInitializationSettings)،
//    وإلا تظهر مربعاً رمادياً.
