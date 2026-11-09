// ============================================================
// الدرس 5 (go_router): حماية المسارات (redirect) و Deep links
// في التطبيق: القائمة ← الدرس 5  ·  في العرض: شرائح الدرس 5
// ============================================================
//
// redirect = دالة تُستدعى قبل كل تنقّل وتقرّر:
//   null      ← اسمح بالذهاب إلى الرابط المطلوب
//   '/رابط'   ← حوّل المستخدم إلى رابط آخر (مثلاً صفحة تسجيل الدخول)
//
// refreshListenable = "أعد تقييم redirect الآن" عند تغيّر حالة الدخول،
// فلا تحتاج شاشة تسجيل الدخول أن تتنقّل بنفسها (انظر appRouterProvider في main.dart).
//
// Deep link = رابط من خارج التطبيق (SMS، بريد، QR، إشعار) يفتح شاشة محددة.
// مع go_router لا نكتب أي كود إضافي في Dart: الرابط يمر بنفس الـ routes ونفس redirect.
//
// ------------------------------------------------------------
// إعداد المنصّات (مُضاف فعلاً في هذا المشروع):
// ------------------------------------------------------------
// Android ← android/app/src/main/AndroidManifest.xml داخل <activity>:
//   <intent-filter>
//     <action android:name="android.intent.action.VIEW" />
//     <category android:name="android.intent.category.DEFAULT" />
//     <category android:name="android.intent.category.BROWSABLE" />
//     <data android:scheme="day2" android:host="open" />
//   </intent-filter>
//
// iOS ← ios/Runner/Info.plist:
//   <key>CFBundleURLTypes</key>
//   <array><dict>
//     <key>CFBundleURLSchemes</key>
//     <array><string>day2</string></array>
//   </dict></array>
//
// الاختبار (والتطبيق مثبّت على المحاكي/الجهاز):
//   adb shell am start -a android.intent.action.VIEW -d "day2://open/l5/products/7?ref=sms"
//   xcrun simctl openurl booted "day2://open/l5/products/7?ref=sms"
//   Web: افتح ‎http://localhost:PORT/#/l5/products/7 مباشرة في المتصفح
//
// 📌 روابط https الحقيقية (App Links / Universal Links) تحتاج إضافة ملف تحقق
//    على موقعك: ‎/.well-known/assetlinks.json (Android) و apple-app-site-association (iOS)
//    مع android:autoVerify="true" و Associated Domains في Xcode.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '03_go_router_basics.dart' show CurrentUrlBar;

// ------------------------------------------------------------
// حالة الدخول (وهمية في هذا الدرس — الحقيقية مع التوكن في الدرس 8)
// ------------------------------------------------------------
class DemoSession extends Notifier<String?> {
  @override
  String? build() => null; // null = لم يسجّل الدخول

  void login(String name) => state = name;
  void logout() => state = null;
}

final demoSessionProvider = NotifierProvider<DemoSession, String?>(
  DemoSession.new,
);

// ------------------------------------------------------------
// الحارس: دالة عادية (سهلة الاختبار) — تُستدعى من redirect في main.dart
// ------------------------------------------------------------
// تأخذ Uri وليس GoRouterState ← نختبرها في سطر واحد (test/router_test.dart)
String? lesson5Guard({required bool loggedIn, required Uri uri}) {
  final path = uri.path; // بدون day2://open — المسار فقط
  final isProtected = path.startsWith('/l5/account');
  final isLogin = path == '/l5/login';

  // 1) غير مسجّل ويريد صفحة محمية ← صفحة الدخول مع تذكّر وجهته
  if (!loggedIn && isProtected) {
    return '/l5/login?from=${Uri.encodeComponent(path)}';
  }
  // 2) مسجّل وما زال في صفحة الدخول ← أعده إلى وجهته الأصلية
  if (loggedIn && isLogin) {
    return uri.queryParameters['from'] ?? '/l5';
  }
  return null; // 3) لا تغيير
}

// ============================================================
// تعريف المسارات — يُضاف إلى routes في main.dart
// ============================================================
final lesson5Route = GoRoute(
  path: 'l5',
  builder: (context, state) => const GuardsHomeScreen(),
  routes: [
    GoRoute(
      path: 'login',
      builder: (context, state) =>
          LoginScreen(from: state.uri.queryParameters['from']),
    ),
    GoRoute(
      path: 'account', // محمي بالحارس
      builder: (context, state) => const AccountScreen(),
      routes: [
        GoRoute(
          path: 'orders', // محمي أيضاً: يبدأ بـ /l5/account
          builder: (context, state) => const OrdersScreen(),
        ),
      ],
    ),
    // هدف الـ Deep link: عام (بدون حماية)
    GoRoute(
      path: 'products/:id',
      builder: (context, state) => DeepProductScreen(
        id: state.pathParameters['id']!,
        source: state.uri.queryParameters['ref'],
      ),
    ),
  ],
);

// ------------------------------------------------------------
// محاكاة Deep link من داخل التطبيق: نرسل للـ framework نفس الرسالة
// التي يرسلها Android/iOS عند فتح الرابط (القناة flutter/navigation)
// ------------------------------------------------------------
void simulateDeepLink(String link) {
  final message = SystemChannels.navigation.codec.encodeMethodCall(
    MethodCall('pushRouteInformation', {'location': link, 'state': null}),
  );
  ServicesBinding.instance.channelBuffers.push(
    SystemChannels.navigation.name,
    message,
    (_) {},
  );
}

class GuardsHomeScreen extends ConsumerWidget {
  const GuardsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(demoSessionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 5: redirect و Deep links')),
      body: Column(
        children: [
          const CurrentUrlBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                ListTile(
                  leading: Icon(user == null ? Icons.lock : Icons.lock_open),
                  title: Text(user == null ? 'غير مسجّل' : 'مسجّل باسم $user'),
                  trailing: user == null
                      ? null
                      : TextButton(
                          // logout ← refreshListenable ← redirect يُعاد تقييمه
                          onPressed: () =>
                              ref.read(demoSessionProvider.notifier).logout(),
                          child: const Text('خروج'),
                        ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: const Text('حسابي (محمي) /l5/account'),
                  subtitle: const Text('غير مسجّل؟ الحارس يحوّلك للدخول'),
                  onTap: () => context.go('/l5/account'),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('طلباتي (محمي) /l5/account/orders'),
                  subtitle: const Text('بعد الدخول تعود إلى هذا الرابط بالضبط'),
                  onTap: () => context.go('/l5/account/orders'),
                ),
                const Divider(),
                const ListTile(
                  title: Text('محاكاة Deep link (كأن الرابط فُتح من SMS)'),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: () =>
                          simulateDeepLink('day2://open/l5/products/7?ref=sms'),
                      child: const Text('day2://open/l5/products/7'),
                    ),
                    FilledButton.tonal(
                      onPressed: () =>
                          simulateDeepLink('day2://open/l5/account/orders'),
                      child: const Text('رابط لصفحة محمية'),
                    ),
                    OutlinedButton(
                      onPressed: () => simulateDeepLink('day2://open/l5/oops'),
                      child: const Text('رابط خاطئ'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key, this.from});

  final String? from;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 5: تسجيل الدخول')),
      body: Column(
        children: [
          const CurrentUrlBar(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              spacing: 16,
              children: [
                Text('بعد الدخول ستعود إلى: ${from ?? '/l5'}'),
                FilledButton(
                  // لا نكتب context.go هنا: تغيّر الحالة يكفي، والحارس يكمل الباقي
                  onPressed: () =>
                      ref.read(demoSessionProvider.notifier).login('سارة'),
                  child: const Text('دخول كـ سارة'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(demoSessionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 5: حسابي')),
      body: Column(
        children: [
          const CurrentUrlBar(),
          ListTile(title: Text('أهلاً $user 👋 — هذه صفحة محمية')),
          ListTile(
            leading: const Icon(Icons.receipt_long),
            title: const Text('طلباتي'),
            onTap: () => context.go('/l5/account/orders'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('خروج (ستُطرد من هذه الصفحة تلقائياً)'),
            onTap: () => ref.read(demoSessionProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 5: طلباتي')),
      body: const Column(
        children: [
          CurrentUrlBar(),
          ListTile(title: Text('طلب #1024 — قيد التوصيل')),
          ListTile(title: Text('طلب #1019 — تم التسليم')),
        ],
      ),
    );
  }
}

class DeepProductScreen extends StatelessWidget {
  const DeepProductScreen({super.key, required this.id, this.source});

  final String id;
  final String? source;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('الدرس 5: منتج $id')),
      body: Column(
        children: [
          const CurrentUrlBar(),
          ListTile(
            leading: const Icon(Icons.link),
            title: Text('فُتح من رابط خارجي — المنتج رقم $id'),
            subtitle: Text('المصدر (?ref): ${source ?? 'غير معروف'}'),
          ),
          const ListTile(
            title: Text(
              'زر الرجوع يعمل لأن المسار متداخل: / ← /l5 ← /l5/products/:id',
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
// 1) redirect على مستوى GoRoute واحد بدل التطبيق كله (يحمي المسار وكل ما تحته):
//      GoRoute(path: 'admin', redirect: (context, state) => isAdmin ? null : '/l5', ...)
//
// 2) احذر الحلقة اللانهائية: إذا حوّلت إلى '/login' فتأكد أن الحارس يعيد null
//    عندما يكون المستخدم في '/login' أصلاً. go_router يوقفها بعد redirectLimit (5).
//
// 3) اكتب الحارس دالة عادية خارج GoRouter تأخذ قيماً بسيطة (مثل lesson5Guard)
//    ← تختبره بدون واجهة في سطر واحد (انظر test/router_test.dart).
//
// 4) Deep link والتطبيق مغلق تماماً (cold start) يمر بنفس redirect ونفس routes،
//    فلا تحتاج كوداً خاصاً لـ "أول تشغيل" — جرّبه بإغلاق التطبيق ثم أمر adb.
//
// 5) تستخدم مكتبة روابط أخرى (مثل app_links) بجانب go_router؟ أوقف معالجة Flutter
//    الافتراضية حتى لا يُفتح الرابط مرتين — Android في AndroidManifest.xml:
//      <meta-data android:name="flutter_deeplinking_enabled" android:value="false" />
