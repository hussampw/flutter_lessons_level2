// ============================================================
// الدرس 3 (Testing): اختبار الـ Providers و Widget tests
// في التطبيق: القائمة ← الدرس 3  ·  في العرض: شرائح الدرس 3
// ============================================================
//
// نفس منطق الدرس 2 لكن داخل Riverpod، ومعه شاشة متجر صغيرة.
// نختبره على مستويين:
//   1) Provider tests  ← test/03_providers_test.dart
//      ProviderContainer.test + overrides (بدون أي Widget)
//   2) Widget tests    ← test/03_shop_widget_test.dart
//      pumpWidget ← find ← tap ← pump ← expect (شاشة حقيقية في بيئة وهمية سريعة)
//
// التشغيل:  flutter test test/03_providers_test.dart test/03_shop_widget_test.dart
//
// 💡 فعّل "محاكاة انقطاع الشبكة" في الشاشة لترى حالة الخطأ — نفس ما يختبره الاختبار.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '01_extension_methods.dart';
import '02_unit_tests.dart';

// ------------------------------------------------------------
// 1) الـ Providers: سلسلة اعتماديات قابلة للاستبدال في الاختبار
// ------------------------------------------------------------
final offlineProvider = NotifierProvider<OfflineNotifier, bool>(
  OfflineNotifier.new,
);

class OfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
}

// الاختبار يستبدل هذا الـ provider بـ MockProductApi
final productApiProvider = Provider<ProductApi>(
  (ref) => LocalProductApi(offline: ref.watch(offlineProvider)),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(productApiProvider)),
);

// ⚠️ Riverpod 3 يعيد المحاولة تلقائياً عند الخطأ (retry) — الـ Future لا يكتمل
// بالخطأ إلا بعد انتهاء المحاولات. هنا نوقفها لنرى حالة الخطأ فوراً (وفي الاختبارات)
final productsProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).getProducts(),
  retry: (retryCount, error) => null, // null = لا إعادة محاولة
);

// السلة: Notifier يغلّف Cart من الدرس 2 (منطق مُختبَر مسبقاً ✅)
final cartProvider = NotifierProvider<CartNotifier, Cart>(CartNotifier.new);

class CartNotifier extends Notifier<Cart> {
  @override
  Cart build() => const Cart();

  void add(Product p) => state = state.add(p);
  void remove(String sku) => state = state.remove(sku);

  // يعيد false بدل رمي الخطأ للـ UI
  bool applyCoupon(String code) {
    try {
      state = state.applyCoupon(code);
      return true;
    } on ArgumentError {
      return false;
    }
  }
}

// Provider مشتق: الشاشة تراقب العدد فقط
final cartCountProvider = Provider<int>((ref) => ref.watch(cartProvider).count);

// ------------------------------------------------------------
// 2) الشاشة — لاحظ الـ Keys: الاختبار يجد العناصر بها
// ------------------------------------------------------------
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final count = ref.watch(cartCountProvider);
    final offline = ref.watch(offlineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدرس 3: اختبار Providers و Widgets'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Badge(
              label: Text('$count', key: const Key('cart-count')),
              isLabelVisible: count > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            key: const Key('offline-switch'),
            title: const Text('محاكاة انقطاع الشبكة'),
            value: offline,
            onChanged: (_) => ref.read(offlineProvider.notifier).toggle(),
          ),
          Expanded(
            // AsyncValue من اليوم الأول: loading / error / data
            child: switch (products) {
              AsyncData(:final value) => ListView(
                children: [
                  for (final p in value)
                    ListTile(
                      title: Text(p.name),
                      subtitle: Text('${p.price} ر.س'),
                      trailing: IconButton(
                        key: Key('add-${p.sku}'),
                        tooltip: 'أضف ${p.name}',
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () {
                          ref.read(cartProvider.notifier).add(p);
                          context.showSnack('أُضيف ${p.name}');
                        },
                      ),
                    ),
                  const _HowToTest(),
                ],
              ),
              AsyncError(:final error) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 12,
                  children: [
                    Text('⚠️ $error'),
                    FilledButton(
                      key: const Key('retry'),
                      onPressed: () => ref.invalidate(productsProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _HowToTest extends StatelessWidget {
  const _HowToTest();

  @override
  Widget build(BuildContext context) {
    const rows = [
      (
        'Provider test',
        'ProviderContainer.test + overrideWithValue(mock)',
        'flutter test test/03_providers_test.dart',
      ),
      (
        'Widget test',
        'pumpWidget ← tap(find.byKey) ← pump ← expect',
        'flutter test test/03_shop_widget_test.dart',
      ),
    ];
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text('كيف نختبر هذه الشاشة؟', style: context.textTheme.titleMedium),
            for (final (kind, how, cmd) in rows) ...[
              Text('$kind: $how'),
              SelectableText(
                cmd,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: context.colors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) container.listen(provider, (prev, next) {...}) يسجّل كل تغيّر في الحالة
//    ← مفيد للتحقق من ترتيب الحالات: loading ثم data (انظر الاختبار).
//
// 2) Widget test لا يعمل فيه الوقت الحقيقي: pump() = إطار واحد،
//    pump(Duration) = نقدّم الساعة، pumpAndSettle() = حتى تنتهي كل الأنيميشن.
//    ⚠️ مع أنيميشن repeat() لا تنتهي أبداً ← pumpAndSettle يفشل بـ timeout.
//
// 3) اعثر على العناصر بالـ Key عندما يتكرر النص:
//      await tester.tap(find.byKey(const Key('add-kb')));
//    و find.byTooltip / find.bySemanticsLabel تختبر إمكانية الوصول أيضاً.
//
// 4) في widget test يلزم MaterialApp حول الشاشة (Theme و Directionality و Navigator)،
//    و ProviderScope(overrides: [...]) حولها إذا كانت تستخدم Riverpod.
//
// 5) Riverpod 3 يعيد المحاولة تلقائياً عند الخطأ ← اختبار الخطأ ينتظر طويلاً أو يفشل.
//    أوقفها للحاوية كلها في الاختبار (أو لكل provider كما في productsProvider):
//      ProviderContainer.test(retry: (retryCount, error) => null)
