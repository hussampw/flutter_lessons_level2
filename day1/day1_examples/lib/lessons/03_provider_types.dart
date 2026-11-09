// ============================================================
// الدرس 3 (Riverpod): أنواع الـ Providers
// في التطبيق: القائمة ← الدرس 3  ·  في العرض: شرائح الدرس 3
// Provider · NotifierProvider · AsyncNotifierProvider · StreamProvider
// ============================================================
//
// كيف أختار؟
//   قيمة ثابتة أو محسوبة من providers أخرى     ← Provider
//   حالة متزامنة تتغير (عداد، سلة، فلتر)         ← NotifierProvider
//   حالة غير متزامنة تتغير (قائمة من API + إضافة) ← AsyncNotifierProvider
//   قراءة فقط من Future                           ← FutureProvider
//   قيم مستمرة (شات، موقع، مؤقت)                  ← StreamProvider

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ------------------------------------------------------------
// 1) Provider: قيم ثابتة أو مشتقّة (derived)
// ------------------------------------------------------------
final taxRateProvider = Provider<double>((ref) => 0.15);

// Provider يعتمد على providers أخرى: يُعاد حسابه تلقائياً عند تغيّرها
final cartTotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartProvider);
  final tax = ref.watch(taxRateProvider);
  final subtotal = items.fold<double>(0, (sum, item) => sum + item.price);
  return subtotal * (1 + tax);
});

// ------------------------------------------------------------
// 2) NotifierProvider: سلة مشتريات
// ------------------------------------------------------------
typedef CartItem = ({String name, double price});

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  // ⚠️ الحالة immutable: لا نعدّل القائمة (state.add) بل ننشئ قائمة جديدة
  // وإلا لن يعرف Riverpod أن الحالة تغيّرت ولن يعيد البناء
  void add(CartItem item) => state = [...state, item];
  void removeAt(int index) => state = [...state]..removeAt(index);
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

// ------------------------------------------------------------
// 3) AsyncNotifierProvider: قائمة مهام تُحمَّل من "API" ويمكن الإضافة عليها
// ------------------------------------------------------------
class TodosNotifier extends AsyncNotifier<List<String>> {
  // build هنا async: Riverpod يعرض loading تلقائياً حتى تنتهي
  @override
  Future<List<String>> build() async {
    await Future.delayed(const Duration(seconds: 1)); // محاكاة طلب شبكة
    return ['مراجعة Futures', 'تجربة Streams'];
  }

  Future<void> add(String title) async {
    final current = state.value ?? [];
    // AsyncValue.guard: ينفّذ ويلتقط الخطأ ويحوّله إلى AsyncError تلقائياً
    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(milliseconds: 400)); // POST للـ API
      return [...current, title];
    });
  }
}

final todosProvider = AsyncNotifierProvider<TodosNotifier, List<String>>(
  TodosNotifier.new,
);

// ------------------------------------------------------------
// 4) StreamProvider: ساعة حية تتحدث كل ثانية
// ------------------------------------------------------------
final clockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
  // Riverpod يلغي الاشتراك تلقائياً عند عدم الحاجة — لا نحتاج cancel يدوياً
});

class ProviderTypesScreen extends ConsumerWidget {
  const ProviderTypesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);
    final todos = ref.watch(todosProvider);
    final clock = ref.watch(clockProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 3: أنواع الـ Providers')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- StreamProvider ---
          _Section(
            title: 'StreamProvider — ساعة حية',
            child: Text(
              // AsyncValue.value: آخر قيمة أو null أثناء التحميل
              clock.value?.toIso8601String().substring(11, 19) ?? '...',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),

          // --- NotifierProvider + Provider المشتق ---
          _Section(
            title: 'NotifierProvider — السلة (${cart.length})',
            child: Column(
              children: [
                for (final (i, item) in cart.indexed)
                  ListTile(
                    dense: true,
                    title: Text(item.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () =>
                          ref.read(cartProvider.notifier).removeAt(i),
                    ),
                  ),
                Text('الإجمالي مع الضريبة (Provider): '
                    '${total.toStringAsFixed(2)} ر.س'),
                TextButton.icon(
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('أضف منتج'),
                  onPressed: () => ref
                      .read(cartProvider.notifier)
                      .add((name: 'منتج ${cart.length + 1}', price: 50)),
                ),
              ],
            ),
          ),

          // --- AsyncNotifierProvider ---
          _Section(
            title: 'AsyncNotifierProvider — المهام',
            // .when تعالج الحالات الثلاث (سنتعمق بها في الدرس 5)
            child: todos.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('خطأ: $e'),
              data: (items) => Column(
                children: [
                  for (final t in items)
                    ListTile(dense: true, title: Text('✔ $t')),
                  TextButton(
                    onPressed: () => ref
                        .read(todosProvider.notifier)
                        .add('مهمة ${items.length + 1}'),
                    child: const Text('أضف مهمة'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              child,
            ],
          ),
        ),
      );
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) داخل provider آخر، انتظر AsyncNotifier أو FutureProvider عبر .future:
//      final todos = await ref.watch(todosProvider.future);
//
// 2) state.value يعيد null أثناء التحميل أو عند الخطأ،
//    أما state.requireValue فيرمي خطأ إذا لم توجد قيمة — استخدمه عندما تكون متأكداً.
//
// 3) لإعادة تحميل الـ AsyncNotifier من داخله: ref.invalidateSelf();
//
// 4) Provider المشتق (مثل cartTotalProvider) أفضل من حساب القيمة داخل build:
//    يُحسب مرة واحدة ويُخزَّن، ويُعاد حسابه فقط عند تغيّر ما يعتمد عليه.
//
// 5) التحديث المتفائل (Optimistic update): حدّث state فوراً قبل رد الـ API،
//    وإذا فشل الطلب أرجع القيمة القديمة — الواجهة تبدو أسرع بكثير.
