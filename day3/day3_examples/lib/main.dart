// ============================================================
// اليوم الثالث — التخزين المحلي وقواعد البيانات + المعمارية
// (+ درسا Dart قصيران: Generics و Streams)
// التشغيل: flutter run   (أو flutter run -d chrome / -d linux)
//
// كل درس في القائمة له نفس الرقم في العرض التقديمي (presentation.html)
// وملفه في lib/lessons/ يبدأ بنفس الرقم، مثلاً: الدرس 5 ← 05_sql_drift_basics.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lessons/01_generics.dart';
import 'lessons/02_streams.dart';
import 'lessons/03_prefs_secure_storage.dart';
import 'lessons/04_files_path_provider.dart';
import 'lessons/05_sql_drift_basics.dart';
import 'lessons/06_drift_migrations_watch.dart';
import 'lessons/07_api_cache.dart';
import 'lessons/08_clean_architecture/presentation/quotes_screen.dart';
import 'lessons/09_offline_first_sync.dart';

Future<void> main() async {
  // نحتاجها قبل أي استدعاء لـ Plugin قبل runApp
  WidgetsFlutterBinding.ensureInitialized();

  // الدرس 3: تهيئة async مرة واحدة ← ثم override (نمط اليوم الأول، الدرس 7)
  final prefs = await initPreferences();

  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const WorkshopApp(),
    ),
  );
}

class WorkshopApp extends ConsumerWidget {
  const WorkshopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // الإعدادات المحفوظة من الدرس 3 تتحكم بثيم التطبيق كله وحجم الخط
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'ورشة Flutter — اليوم الثالث',
      debugShowCheckedModeBanner: false,
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      // اتجاه من اليمين لليسار لكل التطبيق + حجم الخط من الإعدادات
      // (سنتعلم الطريقة الكاملة مع intl و RTL في اليوم الرابع)
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(settings.fontScale),
        ),
        child: Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
      home: const LessonsMenu(),
    );
  }
}

// قائمة الدروس: (الرقم، النوع، العنوان، الوصف، الشاشة)
// الرقم = رقم الدرس في العرض التقديمي = بداية اسم الملف في lib/lessons/
final _lessons = <(int, String, String, String, Widget)>[
  (1, 'Dart', 'Generics', 'Box<T> · extends · Repository<T> · Result<T>',
      const GenericsScreen()),
  (2, 'Dart', 'Streams و StreamController',
      'async* · broadcast · pause · addError · close', const StreamsScreen()),
  (3, 'التخزين', 'الإعدادات والتخزين الآمن',
      'shared_preferences · flutter_secure_storage', const PrefsSecureStorageScreen()),
  (4, 'التخزين', 'الملفات مع path_provider', 'Documents · Cache · JSON · كاش صور',
      const FilesScreen()),
  (5, 'قواعد البيانات', 'SQL و Drift', 'جداول · CRUD · علاقة · JOIN',
      const SqlDriftScreen()),
  (6, 'قواعد البيانات', 'Migrations و watch()', 'schemaVersion · onUpgrade · Stream',
      const DriftMigrationsWatchScreen()),
  (7, 'قواعد البيانات', 'كاش بيانات الـ API', 'dummyjson ← Drift · stale-while-revalidate',
      const ApiCacheScreen()),
  (8, 'المعمارية', 'Clean Architecture', 'domain · data · presentation · Repository',
      const CleanArchitectureScreen()),
  (9, 'المعمارية', 'Offline-first والمزامنة', 'Outbox · sync · Last-Write-Wins',
      const OfflineFirstScreen()),
];

class LessonsMenu extends StatelessWidget {
  const LessonsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('اليوم الثالث: التخزين والمعمارية')),
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
