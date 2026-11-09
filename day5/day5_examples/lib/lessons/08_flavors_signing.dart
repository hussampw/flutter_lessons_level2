// ============================================================
// الدرس 8 (Release): Flavors (dev / prod) وتوقيع التطبيق (App Signing)
// في التطبيق: القائمة ← الدرس 8  ·  في العرض: شرائح الدرس 8
// ============================================================
//
// Flavor = نسخة من نفس الكود بإعدادات مختلفة:
//   dev  ← خادم تجريبي، اسم "Day5 Dev"، معرّف .dev، سجلات مفعّلة
//   prod ← خادم الإنتاج، اسم "Day5"، المعرّف الحقيقي في المتجر
// النسختان تُثبّتان معاً على نفس الجهاز لأن applicationId مختلف.
//
// أين الإعداد؟ (جولة على ملفات حقيقية في المشروع)
//   Android: android/app/build.gradle.kts ← productFlavors + signingConfigs
//            android/key.properties.example ← مثال ملف التوقيع (بدون مفاتيح حقيقية)
//   iOS:     ios/Runner.xcodeproj/xcshareddata/xcschemes/dev.xcscheme و prod.xcscheme
//   Dart:    appFlavor (من package:flutter/services.dart) = قيمة --flavor
//   pubspec.yaml ← default-flavor: dev
//
// التشغيل:
//   flutter run --flavor dev
//   flutter run --flavor prod --dart-define-from-file=config/prod.json
//   flutter build appbundle --flavor prod --release   ← للرفع إلى Google Play

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Flavor { dev, prod }

// ------------------------------------------------------------
// إعدادات كل نسخة في مكان واحد
// ------------------------------------------------------------
class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.appName,
    required this.baseUrl,
    required this.showLogs,
    required this.color,
  });

  final Flavor flavor;
  final String appName;
  final String baseUrl;
  final bool showLogs;
  final Color color;

  // appFlavor = 'dev' أو 'prod' أو null (على منصة بدون flavors)
  factory AppConfig.fromFlavor(String? name) => switch (name) {
        'prod' => const AppConfig(
            flavor: Flavor.prod,
            appName: 'Day5',
            baseUrl: 'https://api.example.com',
            showLogs: false,
            color: Colors.indigo,
          ),
        // dev هو الافتراضي: الأمان أن نخطئ نحو بيئة التجربة لا الإنتاج
        _ => const AppConfig(
            flavor: Flavor.dev,
            appName: 'Day5 Dev',
            baseUrl: 'https://dummyjson.com',
            showLogs: true,
            color: Colors.orange,
          ),
      };
}

// Provider (اليوم الأول): أي شاشة تقرأ الإعدادات، وفي الاختبارات نستبدلها بـ override
final appConfigProvider =
    Provider<AppConfig>((ref) => AppConfig.fromFlavor(appFlavor));

class FlavorsSigningScreen extends ConsumerWidget {
  const FlavorsSigningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final isDev = config.flavor == Flavor.dev;

    // Banner "DEV" فوق الشاشة: لا يختلط على المختبِر أي نسخة بيده
    return Banner(
      message: isDev ? 'DEV' : 'PROD',
      location: BannerLocation.topStart,
      color: config.color,
      child: Scaffold(
        appBar: AppBar(title: const Text('الدرس 8: Flavors والتوقيع')),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              color: config.color.withValues(alpha: 0.15),
              child: ListTile(
                leading: Icon(isDev ? Icons.science : Icons.storefront),
                title: Text('النسخة الحالية: ${config.flavor.name}'),
                subtitle: Text('appFlavor = ${appFlavor ?? 'null'}\n'
                    'الاسم: ${config.appName}\n'
                    'الخادم: ${config.baseUrl}\n'
                    'السجلات: ${config.showLogs ? 'مفعّلة' : 'مغلقة'}'),
              ),
            ),
            const _Step(
              icon: Icons.android,
              title: 'Android: productFlavors في build.gradle.kts',
              body: 'flavorDimensions += "env"\n'
                  'create("dev") { applicationIdSuffix = ".dev" }\n'
                  'create("prod") { }\n'
                  'اسم التطبيق لكل نسخة: manifestPlaceholders["appLabel"]',
            ),
            const _Step(
              icon: Icons.phone_iphone,
              title: 'iOS: Schemes (dev / prod) في Xcode',
              body: 'flutter run --flavor dev يبحث عن Scheme اسمه dev.\n'
                  'المشروع فيه dev.xcscheme و prod.xcscheme (نسخ من Runner).\n'
                  'لمعرّف واسم مختلفين: Xcode ← Project ← Configurations\n'
                  'أنشئ Debug-dev و Release-dev و Release-prod...\n'
                  'وغيّر PRODUCT_BUNDLE_IDENTIFIER لكل منها.',
            ),
            const _Step(
              icon: Icons.vpn_key,
              title: 'التوقيع على Android (مرة واحدة)',
              body: '1) keytool -genkey ... -keystore upload-keystore.jks -alias upload\n'
                  '2) cp android/key.properties.example android/key.properties\n'
                  '3) build.gradle.kts يقرأ key.properties ← signingConfigs.release\n'
                  '4) فعّل Play App Signing: Google تحفظ مفتاح التوقيع النهائي،\n'
                  '   وأنت تحتفظ بمفتاح الرفع (upload key) فقط.',
            ),
            const _Step(
              icon: Icons.apple,
              title: 'التوقيع على iOS',
              body: 'Xcode ← Signing & Capabilities ← Automatically manage signing\n'
                  'يحتاج حساب Apple Developer (99\$ سنوياً) و Bundle ID مسجّلاً.\n'
                  'Codemagic / fastlane match يديران الشهادات في CI (الدرس 9).',
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(title),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(body, style: const TextStyle(height: 1.5))],
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) لكل flavor أيقونة مختلفة (لون برتقالي للـ dev) ← لا يخلط المختبِر بين النسختين.
//    ضع الأيقونات في android/app/src/dev/res/ و android/app/src/prod/res/
//    (مجلد باسم الـ flavor يتغلب على main تلقائياً).
//
// 2) اختبر نسخة release على جهاز حقيقي قبل الرفع دائماً:
//      flutter run --release --flavor prod
//    مشاكل R8/ProGuard والصلاحيات والإنترنت تظهر فقط في release.
//
// 3) احصل على بصمة SHA-1 / SHA-256 لمفتاحك (تطلبها Firebase و Google Sign-In):
//      cd android && ./gradlew signingReport
//
// 4) لا تكتب كلمات مرور المفتاح في الكود ولا في Git: في CI ضعها كـ Secrets
//    وأنشئ key.properties أثناء البناء (الدرس 9).
//
// 5) appFlavor ثابت const: يمكن استخدامه مع if لحذف كود dev من نسخة prod.
