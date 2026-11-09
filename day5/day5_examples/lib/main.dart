// ============================================================
// اليوم الخامس — الأداء · التكامل مع المنصة · الأمان · النشر (+ درس Dart قصير: Isolates)
// التشغيل: flutter run   (أو flutter run -d linux / -d chrome)
//          على Android: flutter run --flavor dev   (الافتراضي في pubspec.yaml)
//
// كل درس في القائمة له نفس الرقم في العرض التقديمي (presentation.html)
// وملفه في lib/lessons/ يبدأ بنفس الرقم، مثلاً: الدرس 4 ← 04_platform_channels.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lessons/01_isolates.dart';
import 'lessons/02_rebuilds_devtools.dart';
import 'lessons/03_lists_images.dart';
import 'lessons/04_platform_channels.dart';
import 'lessons/05_permissions_camera_location.dart';
import 'lessons/06_notifications.dart';
import 'lessons/07_security.dart';
import 'lessons/08_flavors_signing.dart';
import 'lessons/09_release.dart';

void main() {
  // 💡 في تطبيق حقيقي بعد flutterfire configure (الدرسان 6 و 9):
  //   WidgetsFlutterBinding.ensureInitialized();
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //   FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  //   CrashReporter.installHandlers();
  runApp(const ProviderScope(child: WorkshopApp()));
}

class WorkshopApp extends ConsumerWidget {
  const WorkshopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // الدرس 8: إعدادات النسخة (dev / prod) من --flavor
    final config = ref.watch(appConfigProvider);

    return MaterialApp(
      title: 'ورشة Flutter — اليوم الخامس',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      // اتجاه من اليمين لليسار لكل التطبيق
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: LessonsMenu(flavor: config.flavor.name),
    );
  }
}

// قائمة الدروس: (الرقم، النوع، العنوان، الوصف، الشاشة)
// الرقم = رقم الدرس في العرض التقديمي = بداية اسم الملف في lib/lessons/
final _lessons = <(int, String, String, String, Widget)>[
  (1, 'Dart', 'Isolates', 'Isolate.run · compute · spawn · JSON ضخم',
      const IsolatesScreen()),
  (2, 'Performance', 'DevTools وإعادة البناء',
      'const · تقسيم الـ Widgets · select · RepaintBoundary',
      const RebuildsScreen()),
  (3, 'Performance', 'القوائم الطويلة والصور',
      'ListView.builder · itemExtent · cacheWidth · precacheImage',
      const ListsImagesScreen()),
  (4, 'Native', 'Platform Channels و Pigeon',
      'MethodChannel · Kotlin · Swift · كود مولَّد',
      const PlatformChannelsScreen()),
  (5, 'Native', 'الصلاحيات والكاميرا والموقع',
      'permission_handler · image_picker · geolocator',
      const PermissionsScreen()),
  (6, 'Native', 'الإشعارات', 'محلية · مجدولة · FCM',
      const NotificationsScreen()),
  (7, 'Security', 'الأمان',
      'SSL Pinning · Obfuscation · الأسرار · Root · التخزين الآمن',
      const SecurityScreen()),
  (8, 'Release', 'Flavors والتوقيع', 'dev / prod · productFlavors · key.properties',
      const FlavorsSigningScreen()),
  (9, 'Release', 'النشر و CI/CD والأعطال',
      'Play · App Store · GitHub Actions · Crashlytics',
      const ReleaseScreen()),
];

class LessonsMenu extends StatelessWidget {
  const LessonsMenu({super.key, required this.flavor});

  final String flavor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('اليوم الخامس: الأداء والمنصة والأمان والنشر'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Chip(label: Text(flavor)), // الدرس 8
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: _lessons.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final (number, kind, title, subtitle, screen) = _lessons[i];
          final isDart = kind == 'Dart';
          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  isDart ? colors.tertiaryContainer : colors.primaryContainer,
              child: Text('$number'),
            ),
            title: Text('الدرس $number: $title'),
            subtitle: Text('$kind · $subtitle'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => screen),
            ),
          );
        },
      ),
    );
  }
}
