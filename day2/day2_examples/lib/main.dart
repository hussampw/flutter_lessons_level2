// ============================================================
// اليوم الثاني — التنقّل مع go_router والشبكة مع Dio
// (+ درسا Dart قصيران: Records و Sealed classes، و freezed)
// التشغيل: flutter run   (أو flutter run -d chrome / -d linux)
//
// كل درس في القائمة له نفس الرقم في العرض التقديمي (presentation.html)
// وملفه في lib/lessons/ يبدأ بنفس الرقم، مثلاً: الدرس 3 ← 03_go_router_basics.dart
//
// قبل أول تشغيل: dart run build_runner build -d   (ملفات freezed — الدرس 2)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'lessons/01_records_sealed.dart';
import 'lessons/02_freezed_json.dart';
import 'lessons/03_go_router_basics.dart';
import 'lessons/04_shell_route.dart';
import 'lessons/05_guards_deep_links.dart';
import 'lessons/06_dio_interceptors.dart';
import 'lessons/07_error_handling.dart';
import 'lessons/08_auth_tokens.dart';
import 'lessons/09_pagination.dart';

void main() {
  runApp(
    // ProviderScope (اليوم الأول): حالة كل الـ providers — والـ router نفسه provider
    const ProviderScope(
      // أوقفنا إعادة المحاولة التلقائية لنرى الأخطاء بوضوح في الدرس 7
      retry: _noRetry,
      child: WorkshopApp(),
    ),
  );
}

Duration? _noRetry(int retryCount, Object error) => null;

// ============================================================
// إعداد go_router (الدرس 3) — مع ShellRoute (الدرس 4) والحارس (الدرس 5)
// ============================================================

// مفتاح الـ Navigator الرئيسي: تحتاجه الشاشات التي تُفتح فوق الشريط السفلي (الدرس 4)
final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  // الدرس 5: كلما تغيّرت حالة الدخول ← أعد تقييم redirect
  final refresh = ValueNotifier<int>(0);
  ref.listen(demoSessionProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    // الدرس 5: يُستدعى قبل كل تنقّل (null = اسمح)
    redirect: (context, state) => lesson5Guard(
      loggedIn: ref.read(demoSessionProvider) != null,
      uri: state.uri,
    ),
    // الدرس 3: أي رابط غير معروف
    errorBuilder: (context, state) => NotFoundScreen(state: state),
    routes: [
      // '/' = قائمة الدروس، وكل درس مسار فرعي ← الرجوع من أي درس يعود للقائمة
      GoRoute(
        path: '/',
        builder: (context, state) => const LessonsMenu(),
        routes: [
          GoRoute(
            path: 'l1',
            builder: (context, state) => const RecordsSealedScreen(),
          ),
          GoRoute(
            path: 'l2',
            builder: (context, state) => const FreezedJsonScreen(),
          ),
          lesson3Route, // '/l3' ومساراته الفرعية
          lesson4Route(rootNavigatorKey), // '/l4/feed' · '/l4/search' · '/l4/profile'
          lesson5Route, // '/l5' ومساراته المحمية
          GoRoute(
            path: 'l6',
            builder: (context, state) => const DioInterceptorsScreen(),
          ),
          GoRoute(
            path: 'l7',
            builder: (context, state) => const ErrorHandlingScreen(),
          ),
          GoRoute(
            path: 'l8',
            builder: (context, state) => const AuthTokensScreen(),
          ),
          GoRoute(
            path: 'l9',
            builder: (context, state) => const PaginationScreen(),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class WorkshopApp extends ConsumerWidget {
  const WorkshopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'ورشة Flutter — اليوم الثاني',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      // routerConfig بدل home: go_router يقرّر أي شاشة تظهر حسب الرابط
      routerConfig: ref.watch(appRouterProvider),
      // اتجاه من اليمين لليسار لكل التطبيق
      // (سنتعلم الطريقة الكاملة مع intl و RTL في اليوم الرابع)
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
    );
  }
}

// قائمة الدروس: (الرقم، النوع، العنوان، الوصف، الرابط)
// الرقم = رقم الدرس في العرض التقديمي = بداية اسم الملف في lib/lessons/
const _lessons = <(int, String, String, String, String)>[
  (1, 'Dart', 'Records و Sealed classes', 'Records · sealed · Pattern matching',
      '/l1'),
  (2, 'Dart', 'freezed و JSON', 'fromJson · copyWith · Union', '/l2'),
  (3, 'go_router', 'الإعداد والباراميترات', 'path · query · extra · go/push',
      '/l3'),
  (4, 'go_router', 'ShellRoute والمسارات المتداخلة',
      'StatefulShellRoute · شريط سفلي', '/l4/feed'),
  (5, 'go_router', 'redirect و Deep links', 'حارس الدخول · day2://',
      '/l5'),
  (6, 'Dio', 'الإعداد و Interceptors', 'BaseOptions · headers · log',
      '/l6'),
  (7, 'Dio', 'معالجة الأخطاء', 'AppFailure · Result · AsyncValue', '/l7'),
  (8, 'Dio', 'Access و Refresh tokens', '401 ← refresh ← retry', '/l8'),
  (9, 'Dio', 'Pagination', 'limit · skip · تمرير لا نهائي', '/l9'),
];

class LessonsMenu extends StatelessWidget {
  const LessonsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('اليوم الثاني: go_router و Dio')),
      body: ListView.separated(
        itemCount: _lessons.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final (number, kind, title, subtitle, path) = _lessons[i];
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
            // التنقّل بالرابط (الدرس 3) بدل Navigator.push(MaterialPageRoute(...))
            // go يبني المكدّس من شكل الرابط: '/l3' تحت '/' ← زر الرجوع يعود للقائمة
            onTap: () => context.go(path),
          );
        },
      ),
    );
  }
}
