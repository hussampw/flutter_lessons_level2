// ============================================================
// الدرس 3 (go_router): الإعداد + تمرير الباراميترات (path / query / extra)
// في التطبيق: القائمة ← الدرس 3  ·  في العرض: شرائح الدرس 3
// ============================================================
//
// go_router = تنقّل مبني على الروابط (URL): كل شاشة لها مسار مثل /l3/product/7
// الفائدة: نفس الرابط يعمل من زر داخل التطبيق، من شريط المتصفح (Web)،
// ومن رابط خارجي Deep link (الدرس 5).
//
// الإعداد في main.dart (انظره الآن):
//   1) GoRouter(routes: [...]) ← جدول المسارات
//   2) MaterialApp.router(routerConfig: router) بدل MaterialApp(home: ...)
//   3) قائمة الدروس نفسها مسار '/' وكل درس مسار فرعي: '/l1' ... '/l9'
//
// هذا الملف يضيف مسارات الدرس 3 تحت '/l3' (انظر lesson3Route في الأسفل).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// بيانات ثابتة للعرض (في الدرس 7 تأتي من الشبكة)
// Record (الدرس 1) نمرّره كـ extra بدون إنشاء class
typedef ProductPreview = ({int id, String title, double price});

const _catalog = <ProductPreview>[
  (id: 1, title: 'هاتف ذكي', price: 899),
  (id: 2, title: 'سماعات لاسلكية', price: 149),
  (id: 3, title: 'ساعة رياضية', price: 249),
];

// ============================================================
// تعريف المسارات — يُضاف إلى routes في main.dart
// ============================================================
final lesson3Route = GoRoute(
  path: 'l3', // مسار فرعي من '/' ← الرابط الكامل '/l3'
  builder: (context, state) => const CatalogScreen(),
  routes: [
    // 1) Path parameter: ‎:id جزء من الرابط نفسه ← /l3/product/7
    GoRoute(
      path: 'product/:id',
      name: 'l3-product', // اسم المسار: للتنقّل بـ pushNamed بدل كتابة الرابط
      builder: (context, state) => ProductDetailsScreen(
        // الباراميترات دائماً String ← نحوّلها بأمان (قد يكتب المستخدم رابطاً خاطئاً)
        id: int.tryParse(state.pathParameters['id'] ?? ''),
        // 2) Query parameter: اختياري بعد ? ← /l3/product/7?tab=reviews
        tab: state.uri.queryParameters['tab'] ?? 'details',
        // 3) extra: كائن Dart يمر بدون الرابط (يضيع في Deep link و Web refresh)
        preview: state.extra as ProductPreview?,
      ),
    ),
    GoRoute(
      path: 'search',
      builder: (context, state) => SearchResultsScreen(
        query: state.uri.queryParameters['q'] ?? '',
        sort: state.uri.queryParameters['sort'] ?? 'relevance',
      ),
    ),
    // شاشة تُرجع نتيجة لمن فتحها: context.pop(value)
    GoRoute(
      path: 'pick-color',
      builder: (context, state) => const PickColorScreen(),
    ),
  ],
);

// شريط صغير يعرض الرابط الحالي — لنرى ما يحدث في كل خطوة
class CurrentUrlBar extends StatelessWidget {
  const CurrentUrlBar({super.key});

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'الرابط الحالي: ${Uri.decodeFull(uri.toString())}',
        textDirection: TextDirection.ltr,
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _pickedColor = 'لم يُختر بعد';

  // 6) نافذة تُرجع نتيجة: push<T> ينتظر حتى تُغلق بـ context.pop(value)
  Future<void> _pickColor() async {
    final color = await context.push<String>('/l3/pick-color');
    if (!mounted) return;
    setState(() => _pickedColor = color ?? 'أُغلقت بدون اختيار');
  }

  @override
  Widget build(BuildContext context) {
    final (:id, :title, :price) = _catalog.first;
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 3: go_router والباراميترات')),
      body: Column(
        children: [
          const CurrentUrlBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const _Section('المنتجات — اضغط لفتح التفاصيل (path + extra)'),
                for (final p in _catalog)
                  ListTile(
                    leading: CircleAvatar(child: Text('${p.id}')),
                    title: Text(p.title),
                    subtitle: Text('${p.price} ر.س'),
                    // 1) + 3) الرابط يحمل id، و extra يحمل الكائن كاملاً
                    onTap: () => context.push(
                      '/l3/product/${p.id}',
                      extra: p,
                    ),
                  ),
                const _Section('طرق التنقّل'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // 2) query: نبني الرابط بـ Uri ليُرمَّز النص العربي تلقائياً
                    FilledButton.tonal(
                      onPressed: () => context.push(
                        Uri(
                          path: '/l3/search',
                          queryParameters: {'q': 'سماعات', 'sort': 'price'},
                        ).toString(),
                      ),
                      child: const Text('2) بحث ?q=&sort='),
                    ),
                    // 4) المسار المسمّى: لا نكتب الرابط يدوياً
                    FilledButton.tonal(
                      onPressed: () => context.pushNamed(
                        'l3-product',
                        pathParameters: {'id': '$id'},
                        queryParameters: {'tab': 'reviews'},
                      ),
                      child: Text('4) pushNamed: $title'),
                    ),
                    // 5) بدون extra (كأنه Deep link): الشاشة تتصرف بدونه
                    FilledButton.tonal(
                      onPressed: () => context.push('/l3/product/3'),
                      child: const Text('5) بدون extra'),
                    ),
                    FilledButton.tonal(
                      onPressed: _pickColor,
                      child: const Text('6) نتيجة من شاشة'),
                    ),
                    // 7) رابط غير موجود ← errorBuilder في main.dart
                    OutlinedButton(
                      onPressed: () => context.push('/l3/not-found'),
                      child: const Text('7) رابط خاطئ'),
                    ),
                    OutlinedButton(
                      onPressed: () => context.push('/l3/product/abc'),
                      child: const Text('8) id غير رقمي'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('اللون المختار: $_pickedColor · أول سعر: $price'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({
    super.key,
    required this.id,
    required this.tab,
    this.preview,
  });

  final int? id;
  final String tab;
  final ProductPreview? preview;

  @override
  Widget build(BuildContext context) {
    // extra موجود ← نعرضه فوراً، غير موجود ← نبحث بالـ id (في الواقع: طلب API)
    final product =
        preview ?? _catalog.where((p) => p.id == id).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 3: تفاصيل المنتج')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CurrentUrlBar(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: switch ((id, product)) {
              // أنماط Records (الدرس 1): نفحص القيمتين معاً
              (null, _) => const Text('❌ الرابط يحتوي id غير رقمي'),
              (_, null) => Text('🔍 لا يوجد منتج برقم $id'),
              (_, final ProductPreview p) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    p.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text('السعر: ${p.price} ر.س · التبويب (query): $tab'),
                  Text(
                    preview != null
                        ? '✅ وصل الكائن عبر extra (بدون طلب جديد)'
                        : '⚠️ لا يوجد extra ← بحثنا بالـ id من الرابط',
                  ),
                ],
              ),
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // go: يبني المكدّس من شكل الرابط ← الرجوع يعود إلى /l3
                OutlinedButton(
                  onPressed: () => context.go('/l3/product/2'),
                  child: const Text('go → منتج 2'),
                ),
                // push: يضيف فوق المكدّس الحالي ← الرجوع يعود لهذه الشاشة
                OutlinedButton(
                  onPressed: () => context.push('/l3/product/2'),
                  child: const Text('push → منتج 2'),
                ),
                if (context.canPop())
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('pop ←'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({
    super.key,
    required this.query,
    required this.sort,
  });

  final String query;
  final String sort;

  @override
  Widget build(BuildContext context) {
    final results = _catalog.where((p) => p.title.contains(query)).toList();
    if (sort == 'price') results.sort((a, b) => a.price.compareTo(b.price));
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 3: نتائج البحث')),
      body: Column(
        children: [
          const CurrentUrlBar(),
          ListTile(title: Text('q = «$query» · sort = $sort')),
          for (final p in results)
            ListTile(
              title: Text(p.title),
              // go من صفحة البحث: الرجوع يذهب إلى /l3 وليس للبحث (قارن مع push)
              onTap: () => context.go('/l3/product/${p.id}', extra: p),
            ),
          if (results.isEmpty) const ListTile(title: Text('لا توجد نتائج')),
        ],
      ),
    );
  }
}

class PickColorScreen extends StatelessWidget {
  const PickColorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 3: اختر لوناً')),
      body: Column(
        children: [
          for (final color in ['أحمر', 'أخضر', 'أزرق'])
            ListTile(
              title: Text(color),
              // نعيد القيمة لمن استدعى push<String>
              onTap: () => context.pop(color),
            ),
        ],
      ),
    );
  }
}

// صفحة الخطأ لكل رابط غير معروف — مربوطة في main.dart عبر errorBuilder
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key, required this.state});

  final GoRouterState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 3: الصفحة غير موجودة')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            const Icon(Icons.link_off, size: 64),
            Text(
              Uri.decodeFull(state.uri.toString()),
              textDirection: TextDirection.ltr,
            ),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('العودة إلى قائمة الدروس'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) لا تبنِ روابط query بدمج النصوص يدوياً ('/search?q=$text') — النص العربي
//    والمسافات و & تكسر الرابط. استخدم Uri:
//      Uri(path: '/l3/search', queryParameters: {'q': text}).toString()
//
// 2) extra لا يُحفظ في الرابط: يضيع عند Deep link وعند تحديث الصفحة على Web.
//    لذلك مرّر دائماً id في الرابط، واجعل extra مجرد "تسريع" للعرض الأول.
//
// 3) أثناء التطوير فعّل سجلّ التنقّل في الكونسول:
//      GoRouter(debugLogDiagnostics: true, routes: [...])
//
// 4) go أم push؟ go = "اذهب إلى هذا الرابط" (يبني المكدّس من شكل الرابط)،
//    push = "افتح فوق الحالية" (للتفاصيل والنوافذ التي تُرجع نتيجة).
//
// 5) على Web أزل علامة # من الروابط (‎/#/l3 ← ‎/l3) قبل runApp
//    (بعد إضافة flutter_web_plugins: {sdk: flutter} إلى pubspec.yaml):
//      import 'package:flutter_web_plugins/url_strategy.dart';
//      usePathUrlStrategy();
