// ============================================================
// الدرس 4 (go_router): المسارات المتداخلة و ShellRoute (شريط سفلي يحفظ حالته)
// في التطبيق: القائمة ← الدرس 4  ·  في العرض: شرائح الدرس 4
// ============================================================
//
// المسارات المتداخلة (routes داخل GoRoute): '/l4/feed/post/3' يبني المكدّس
//   [القائمة] ← [feed] ← [post 3] تلقائياً، وزر الرجوع يعمل كما نتوقع.
//
// ShellRoute: "إطار" ثابت (Scaffold + شريط سفلي) يتغيّر المحتوى داخله فقط.
//   ShellRoute العادي        ← Navigator واحد للمحتوى، الحالة تضيع عند تبديل التبويب
//   StatefulShellRoute ✅    ← Navigator مستقل لكل تبويب (branch):
//                              كل تبويب يحفظ مكدّسه وموضع التمرير وحالة الـ Widgets
//
// جرّب: افتح منشوراً في "الرئيسية"، انتقل إلى "بحث" واكتب نصاً وزِد العداد،
// ثم عُد إلى "الرئيسية" ← ستجد المنشور مفتوحاً كما تركته.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ============================================================
// تعريف المسارات — يُضاف إلى routes في main.dart
// rootKey = مفتاح الـ Navigator الرئيسي (خارج الإطار) من main.dart
// ============================================================
RouteBase lesson4Route(GlobalKey<NavigatorState> rootKey) {
  return StatefulShellRoute.indexedStack(
    // الإطار: يستقبل navigationShell = محتوى التبويب الحالي
    builder: (context, state, navigationShell) =>
        ShellScaffold(navigationShell: navigationShell),
    branches: [
      // التبويب 0: له Navigator خاص به ومسار متداخل للتفاصيل
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: 'l4/feed',
            builder: (context, state) => const FeedTab(),
            routes: [
              // متداخل داخل التبويب ← الشريط السفلي يبقى ظاهراً
              GoRoute(
                path: 'post/:id',
                builder: (context, state) =>
                    PostScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      // التبويب 1
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: 'l4/search',
            builder: (context, state) => const SearchTab(),
          ),
        ],
      ),
      // التبويب 2
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: 'l4/profile',
            builder: (context, state) => const ProfileTab(),
            routes: [
              // parentNavigatorKey: rootKey ← تُفتح فوق الإطار كاملاً (بدون شريط سفلي)
              GoRoute(
                path: 'settings',
                parentNavigatorKey: rootKey,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// ============================================================
// الإطار: Scaffold واحد + NavigationBar لكل التبويبات
// ============================================================
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 4: ShellRoute')),
      body: navigationShell, // محتوى التبويب الحالي (IndexedStack يحفظ الباقي)
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // الضغط على التبويب الحالي مرة ثانية ← العودة إلى أول شاشة فيه
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.search), label: 'بحث'),
          NavigationDestination(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}

class FeedTab extends StatelessWidget {
  const FeedTab({super.key});

  @override
  Widget build(BuildContext context) {
    // قائمة طويلة: مرّر للأسفل ثم بدّل التبويب وعُد ← موضع التمرير محفوظ
    return ListView.builder(
      itemCount: 30,
      itemBuilder: (context, i) => ListTile(
        leading: CircleAvatar(child: Text('${i + 1}')),
        title: Text('منشور رقم ${i + 1}'),
        subtitle: const Text('اضغط ← /l4/feed/post/:id'),
        onTap: () => context.go('/l4/feed/post/${i + 1}'),
      ),
    );
  }
}

class PostScreen extends StatelessWidget {
  const PostScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    // لا يوجد Scaffold هنا: نحن داخل الإطار، فالـ AppBar والشريط السفلي من ShellScaffold
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Text(
            'المنشور $id',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text(
            GoRouterState.of(context).uri.toString(),
            textDirection: TextDirection.ltr,
          ),
          const Text('بدّل التبويب ثم عُد: ستجد هذه الشاشة كما هي'),
          FilledButton.tonal(
            onPressed: () => context.pop(),
            child: const Text('رجوع إلى القائمة'),
          ),
        ],
      ),
    );
  }
}

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  // حالة محلية (State) — تبقى لأن StatefulShellRoute لا يحذف التبويب
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        spacing: 16,
        children: [
          const TextField(
            decoration: InputDecoration(
              labelText: 'اكتب شيئاً ثم بدّل التبويب',
              border: OutlineInputBorder(),
            ),
          ),
          Text('العداد: $_counter', style: Theme.of(context).textTheme.titleLarge),
          FilledButton.icon(
            onPressed: () => setState(() => _counter++),
            icon: const Icon(Icons.add),
            label: const Text('زِد العداد'),
          ),
        ],
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const ListTile(
          leading: CircleAvatar(child: Icon(Icons.person)),
          title: Text('سارة'),
          subtitle: Text('التبويب الثالث'),
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('الإعدادات'),
          subtitle: const Text('parentNavigatorKey ← تغطي الشريط السفلي'),
          onTap: () => context.go('/l4/profile/settings'),
        ),
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text('اذهب إلى المنشور 5 في تبويب الرئيسية'),
          subtitle: const Text('go يبدّل التبويب تلقائياً حسب الرابط'),
          onTap: () => context.go('/l4/feed/post/5'),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // هنا Scaffold كامل: الشاشة على الـ Navigator الرئيسي فوق الإطار
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 4: الإعدادات')),
      body: const Center(
        child: Text('شاشة كاملة فوق الإطار — لا يوجد شريط سفلي'),
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) لا تريد حفظ حالة التبويبات (مثلاً معالج خطوات Wizard)؟ استخدم ShellRoute العادي:
//      ShellRoute(builder: (context, state, child) => Frame(child: child), routes: [...])
//
// 2) حمّل تبويباً مسبقاً قبل أن يفتحه المستخدم (مثلاً لجلب بياناته مبكراً):
//      StatefulShellBranch(preload: true, routes: [...])
//
// 3) اعرض الشريط السفلي على الهاتف و NavigationRail على الشاشات العريضة
//    داخل نفس ShellScaffold — المسارات لا تتغير:
//      MediaQuery.sizeOf(context).width > 600 ? NavigationRail(...) : NavigationBar(...)
//
// 4) شاشة داخل تبويب لا تحتاج Scaffold خاصاً بها (الإطار يوفّره)،
//    أما الشاشة ذات parentNavigatorKey: rootKey فتحتاج Scaffold كاملاً.
