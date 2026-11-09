// ============================================================
// اليوم الأول — Riverpod (+ درس Dart قصير: Futures و async/await)
// التشغيل: flutter run   (أو flutter run -d chrome / -d linux)
//
// كل درس في القائمة له نفس الرقم في العرض التقديمي (presentation.html)
// وملفه في lib/lessons/ يبدأ بنفس الرقم، مثلاً: الدرس 3 ← 03_provider_types.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lessons/01_futures_async.dart';
import 'lessons/02_riverpod_basics.dart';
import 'lessons/03_provider_types.dart';
import 'lessons/04_riverpod_codegen.dart';
import 'lessons/05_async_value.dart';
import 'lessons/06_family_autodispose.dart';
import 'lessons/07_dependency_injection.dart';
import 'lessons/08_overrides.dart';

void main() {
  runApp(
    // ProviderScope: الحاوية التي تُخزَّن فيها حالة كل الـ providers
    // يجب أن تكون في أعلى الشجرة — بدونها يظهر خطأ عند أول ref.watch
    const ProviderScope(
      // 💡 مثال override على مستوى التطبيق (بيئة تطوير / عرض تجريبي) — الدرس 8:
      // overrides: [
      //   weatherRepositoryProvider.overrideWithValue(FakeWeatherRepository()),
      // ],
      child: WorkshopApp(),
    ),
  );
}

class WorkshopApp extends ConsumerWidget {
  const WorkshopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // الوضع الليلي من الدرس 4 (keepAlive) يتحكم بثيم التطبيق كله
    final dark = ref.watch(darkModeProvider);

    return MaterialApp(
      title: 'ورشة Flutter — اليوم الأول',
      debugShowCheckedModeBanner: false,
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      // اتجاه من اليمين لليسار لكل التطبيق
      // (سنتعلم الطريقة الكاملة مع intl و RTL في اليوم الرابع)
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const LessonsMenu(),
    );
  }
}

// قائمة الدروس: (الرقم، النوع، العنوان، الوصف، الشاشة)
// الرقم = رقم الدرس في العرض التقديمي = بداية اسم الملف في lib/lessons/
final _lessons = <(int, String, String, String, Widget)>[
  (1, 'Dart', 'Futures و async/await', 'then · await · متوازي · FutureBuilder',
      const FuturesScreen()),
  (2, 'Riverpod', 'الأساسيات و ref', 'ProviderScope · watch · read · listen',
      const BasicsScreen()),
  (3, 'Riverpod', 'أنواع الـ Providers',
      'Provider · Notifier · AsyncNotifier · Stream', const ProviderTypesScreen()),
  (4, 'Riverpod', 'توليد الكود', '@riverpod · keepAlive', const CodegenScreen()),
  (5, 'Riverpod', 'AsyncValue', 'loading · data · error · refresh',
      const AsyncValueScreen()),
  (6, 'Riverpod', 'family و autoDispose', 'باراميترات · كاش · onDispose',
      const FamilyScreen()),
  (7, 'Riverpod', 'حقن الاعتماديات', 'Repository عبر Provider',
      const DependencyInjectionScreen()),
  (8, 'Riverpod', 'Overrides', 'Fake · ProviderScope متداخل',
      const OverridesScreen()),
];

class LessonsMenu extends StatelessWidget {
  const LessonsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('اليوم الأول: Riverpod')),
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
