// ============================================================
// اليوم الرابع — الاختبارات + واجهات متقدمة (+ درس Dart قصير: Extension methods)
// التشغيل: flutter run   (أو flutter run -d chrome / -d linux)
// الاختبارات: flutter test   ·   flutter test integration_test (على جهاز)
//
// كل درس في القائمة له نفس الرقم في العرض التقديمي (presentation.html)
// وملفه في lib/lessons/ يبدأ بنفس الرقم، مثلاً: الدرس 6 ← 06_slivers.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'lessons/01_extension_methods.dart';
import 'lessons/02_unit_tests.dart';
import 'lessons/03_provider_widget_tests.dart';
import 'lessons/04_integration_tests.dart';
import 'lessons/05_animations.dart';
import 'lessons/06_slivers.dart';
import 'lessons/07_custom_painter.dart';
import 'lessons/08_responsive_theming.dart';
import 'lessons/09_l10n_rtl_a11y.dart';

void main() {
  runApp(
    // ProviderScope: الحاوية التي تُخزَّن فيها حالة كل الـ providers (اليوم الأول)
    const ProviderScope(child: WorkshopApp()),
  );
}

class WorkshopApp extends ConsumerWidget {
  const WorkshopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // الثيم واللون من الدرس 8 يتحكمان بالتطبيق كله
    final settings = ref.watch(themeSettingsProvider);

    return MaterialApp(
      // العنوان مترجم (الدرس 9) — onGenerateTitle لأن context هنا تحت Localizations
      onGenerateTitle: (context) => context.l10n.appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: settings.mode,
      theme: buildTheme(settings.seed, Brightness.light),
      darkTheme: buildTheme(settings.seed, Brightness.dark),
      // الترجمة (الدرس 9): العربية ← Directionality.rtl تلقائياً للتطبيق كله
      // (في اليوم الأول كتبنا Directionality يدوياً — هذه هي الطريقة الكاملة)
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const LessonsMenu(),
    );
  }
}

// قائمة الدروس: (الرقم، النوع، العنوان، الوصف، الشاشة)
// الرقم = رقم الدرس في العرض التقديمي = بداية اسم الملف في lib/lessons/
final _lessons = <(int, String, String, String, Widget)>[
  (
    1,
    'Dart',
    'Extension methods',
    'extension types · BuildContext',
    const ExtensionsScreen(),
  ),
  (
    2,
    'Testing',
    'Unit tests و mocktail',
    'test · expect · when · verify',
    const UnitTestsScreen(),
  ),
  (
    3,
    'Testing',
    'اختبار Providers و Widgets',
    'ProviderContainer.test · pumpWidget',
    const ShopScreen(),
  ),
  (
    4,
    'Testing',
    'Integration tests',
    'integration_test · جهاز حقيقي',
    const IntegrationScreen(),
  ),
  (
    5,
    'UI',
    'الأنيميشن',
    'Implicit · AnimationController · Staggered',
    const AnimationsScreen(),
  ),
  (
    6,
    'UI',
    'Slivers',
    'CustomScrollView · SliverAppBar · pinned',
    const SliversScreen(),
  ),
  (
    7,
    'UI',
    'CustomPainter',
    'Canvas · shouldRepaint · repaint',
    const CustomPainterScreen(),
  ),
  (
    8,
    'UI',
    'Responsive و Theming',
    'LayoutBuilder · ColorScheme · داكن',
    const ResponsiveThemingScreen(),
  ),
  (
    9,
    'UI',
    'الترجمة و RTL و الوصول',
    'ARB · Directional · Semantics',
    const L10nRtlA11yScreen(),
  ),
];

class LessonsMenu extends StatelessWidget {
  const LessonsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors; // امتداد الدرس 1
    return Scaffold(
      appBar: AppBar(title: const Text('اليوم الرابع: الاختبارات و UI')),
      body: ListView.separated(
        itemCount: _lessons.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final (number, kind, title, subtitle, screen) = _lessons[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: switch (kind) {
                'Dart' => colors.tertiaryContainer,
                'Testing' => colors.secondaryContainer,
                _ => colors.primaryContainer,
              },
              child: Text('$number'),
            ),
            title: Text('الدرس $number: $title'),
            subtitle: Text('$kind · $subtitle'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () =>
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => screen)),
          );
        },
      ),
    );
  }
}
