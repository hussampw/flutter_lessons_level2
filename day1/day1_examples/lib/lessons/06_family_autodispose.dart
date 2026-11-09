// ============================================================
// الدرس 6 (Riverpod): family و autoDispose
// في التطبيق: القائمة ← الدرس 6  ·  في العرض: شرائح الدرس 6
// ============================================================
//
// family     ← provider يأخذ باراميتر (مثل: منتج حسب id)
//              كل قيمة باراميتر لها حالة مستقلة ومخزّنة منفصلة
// autoDispose ← حذف الحالة من الذاكرة عندما لا يستخدمها أي Widget
//              (مثلاً عند الخروج من شاشة التفاصيل)
//
// 💡 افتح Debug Console وراقب رسائل "إنشاء" و "حذف"

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef Product = ({int id, String name, double price});

// ------------------------------------------------------------
// 1) FutureProvider.autoDispose.family<النوع, الباراميتر>
// ------------------------------------------------------------
final productProvider = FutureProvider.autoDispose.family<Product, int>(
  (ref, id) async {
    debugPrint('🟢 إنشاء productProvider($id)');

    // onDispose: تنظيف (إلغاء طلبات، إغلاق streams...)
    ref.onDispose(() => debugPrint('🔴 حذف productProvider($id)'));

    await Future.delayed(const Duration(milliseconds: 800)); // GET /products/$id

    // ------------------------------------------------------------
    // keepAlive: نمنع الحذف مؤقتاً = كاش لمدة 10 ثوانٍ
    // إذا رجع المستخدم خلال 10 ثوانٍ تظهر البيانات فوراً بدون تحميل
    // ------------------------------------------------------------
    final link = ref.keepAlive();
    final timer = Timer(const Duration(seconds: 10), link.close);
    ref.onDispose(timer.cancel);

    return (id: id, name: 'منتج رقم $id', price: id * 25.0);
  },
);

// ------------------------------------------------------------
// 2) Notifier مع family: الباراميتر يصل عبر الـ constructor
//    (هذا أسلوب Riverpod 3)
// ------------------------------------------------------------
class QuantityNotifier extends Notifier<int> {
  QuantityNotifier(this.productId);
  final int productId;

  @override
  int build() {
    ref.onDispose(() => debugPrint('🔴 حذف الكمية للمنتج $productId'));
    return 1;
  }

  void increment() => state++;
  void decrement() => state = state > 1 ? state - 1 : 1;
}

// الأنواع الثلاثة: <الـ Notifier, نوع الحالة, نوع الباراميتر>
final quantityProvider =
    NotifierProvider.autoDispose.family<QuantityNotifier, int, int>(
  QuantityNotifier.new,
);

// ------------------------------------------------------------
// الشاشة الأولى: قائمة المنتجات
// ------------------------------------------------------------
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 6: family و autoDispose')),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          final id = index + 1;
          return ListTile(
            leading: CircleAvatar(child: Text('$id')),
            title: Text('منتج رقم $id'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProductDetails(id: id)),
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------
// الشاشة الثانية: تفاصيل منتج — عند الرجوع تُحذف الحالة (autoDispose)
// ------------------------------------------------------------
class ProductDetails extends ConsumerWidget {
  const ProductDetails({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // نمرّر الباراميتر كأننا نستدعي دالة
    final product = ref.watch(productProvider(id));
    final qty = ref.watch(quantityProvider(id));

    return Scaffold(
      appBar: AppBar(title: Text('تفاصيل $id')),
      body: Center(
        child: switch (product) {
          AsyncData(value: final p) => Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
                Text('${(p.price * qty).toStringAsFixed(0)} ر.س'),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () =>
                          ref.read(quantityProvider(id).notifier).decrement(),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$qty', style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      onPressed: () =>
                          ref.read(quantityProvider(id).notifier).increment(),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const Text(
                  'ارجع ثم ادخل مرة أخرى:\n'
                  'المنتج من الكاش (10 ثوانٍ) — الكمية تبدأ من 1 من جديد',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          AsyncError(:final error) => Text('$error'),
          _ => const CircularProgressIndicator(),
        },
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) باراميتر الـ family يجب أن يملك == صحيحة: int و String و enum و Record ✅
//    أما List جديدة أو كائن عادي ❌ ← provider جديد مع كل build (تسريب + طلبات متكررة).
//
// 2) تحتاج أكثر من باراميتر؟ استخدم Record (الدرس القادم من Dart):
//      FutureProvider.autoDispose.family<List<Product>, ({int page, String query})>(...)
//      ref.watch(searchProvider((page: 1, query: 'لابتوب')));
//
// 3) نمط الكاش المؤقت: ref.keepAlive() + Timer + ref.onDispose(timer.cancel)
//    (موجود في هذا الملف) — يقلل الطلبات عند التنقل ذهاباً وإياباً.
//
// 4) لإلغاء طلب شبكة عند الخروج من الشاشة:
//      final cancelToken = CancelToken();          // من Dio — اليوم الثاني
//      ref.onDispose(cancelToken.cancel);
//
// 5) ref.mounted (Riverpod 3): تحقّق منه بعد await داخل Notifier
//    قبل تعديل state، فقد يكون الـ provider حُذف أثناء الانتظار.
