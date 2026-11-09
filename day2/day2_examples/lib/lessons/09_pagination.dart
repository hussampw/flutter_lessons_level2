// ============================================================
// الدرس 9 (Dio): التحميل على صفحات (Pagination) — تمرير لا نهائي
// في التطبيق: القائمة ← الدرس 9  ·  في العرض: شرائح الدرس 9
// ============================================================
//
// لا نحمّل 194 منتجاً مرة واحدة: نطلب صفحة صغيرة، وعند الاقتراب من نهاية
// القائمة نطلب الصفحة التالية:
//   GET /products?limit=20&skip=0    ← الصفحة 1
//   GET /products?limit=20&skip=20   ← الصفحة 2 (skip = عدد ما حمّلناه)
//   نتوقف عندما items.length == total
//
// كل ما تعلمناه اليوم يجتمع هنا:
//   ProductsPage (الدرس 2) · ProductsRepository + AppFailure + FailureView (الدرس 7)
//   AsyncNotifier + ref.mounted + RefreshIndicator (اليوم الأول)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '02_freezed_json.dart' show Product;
import '07_error_handling.dart'
    show AppFailure, FailureView, UnknownFailure, productsRepositoryProvider;

part '09_pagination.freezed.dart';

// ------------------------------------------------------------
// الحالة: freezed (الدرس 2) لنستخدم copyWith بدل إنشاء الحالة يدوياً
// ------------------------------------------------------------
@freezed
abstract class ProductsFeed with _$ProductsFeed {
  const ProductsFeed._(); // ليسمح بإضافة getter
  const factory ProductsFeed({
    @Default(<Product>[]) List<Product> items,
    @Default(0) int total,
    @Default(false) bool isLoadingMore, // تحميل الصفحة التالية (ليس الأولى)
    AppFailure? loadMoreError, // خطأ في صفحة لاحقة: لا نخفي ما حمّلناه
  }) = _ProductsFeed;

  bool get hasMore => items.length < total;
}

// ------------------------------------------------------------
// المنطق: AsyncNotifier
//   build()    ← الصفحة الأولى (AsyncLoading / AsyncError للشاشة كاملة)
//   loadMore() ← الصفحات التالية (isLoadingMore / loadMoreError في أسفل القائمة)
// ------------------------------------------------------------
class ProductsFeedNotifier extends AsyncNotifier<ProductsFeed> {
  static const pageSize = 20;

  @override
  Future<ProductsFeed> build() async {
    final page = await ref
        .watch(productsRepositoryProvider)
        .page(skip: 0, limit: pageSize);
    return ProductsFeed(items: page.products, total: page.total);
  }

  Future<void> loadMore() async {
    final feed = state.value;
    // حماية من الطلبات المكررة: التمرير يستدعي loadMore عشرات المرات في الثانية
    if (feed == null || feed.isLoadingMore || !feed.hasMore) return;

    state = AsyncData(feed.copyWith(isLoadingMore: true, loadMoreError: null));
    try {
      final page = await ref
          .read(productsRepositoryProvider)
          .page(skip: feed.items.length, limit: pageSize);
      if (!ref.mounted) return; // خرج المستخدم أثناء الانتظار
      state = AsyncData(
        feed.copyWith(
          items: [...feed.items, ...page.products], // قائمة جديدة (immutable)
          total: page.total,
          isLoadingMore: false,
        ),
      );
    } on AppFailure catch (failure) {
      if (!ref.mounted) return;
      state = AsyncData(
        feed.copyWith(isLoadingMore: false, loadMoreError: failure),
      );
    }
  }
}

final productsFeedProvider =
    AsyncNotifierProvider.autoDispose<ProductsFeedNotifier, ProductsFeed>(
      ProductsFeedNotifier.new,
    );

class PaginationScreen extends ConsumerWidget {
  const PaginationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(productsFeedProvider);
    final loaded = feed.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدرس 9: Pagination'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              loaded == null
                  ? 'جاري تحميل الصفحة الأولى...'
                  : 'تم تحميل ${loaded.items.length} من ${loaded.total}',
            ),
          ),
        ),
      ),
      body: switch (feed) {
        AsyncData(:final value) => RefreshIndicator(
          // السحب للتحديث ← build() من جديد = الصفحة الأولى
          onRefresh: () => ref.refresh(productsFeedProvider.future),
          child: NotificationListener<ScrollNotification>(
            // اقتربنا من النهاية (أقل من 600 بكسل متبقية)؟ اطلب الصفحة التالية
            onNotification: (notification) {
              if (notification.metrics.extentAfter < 600) {
                ref.read(productsFeedProvider.notifier).loadMore();
              }
              return false;
            },
            child: ListView.builder(
              // +1 لعنصر أخير: مؤشر تحميل / خطأ / "النهاية"
              itemCount: value.items.length + 1,
              itemBuilder: (context, i) => i < value.items.length
                  ? _ProductTile(product: value.items[i], index: i)
                  : _Footer(feed: value),
            ),
          ),
        ),
        AsyncError(:final error) => Padding(
          padding: const EdgeInsets.all(16),
          child: FailureView(
            failure: error is AppFailure ? error : UnknownFailure('$error'),
            onRetry: () => ref.invalidate(productsFeedProvider),
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.index});

  final Product product;
  final int index;

  @override
  Widget build(BuildContext context) {
    final thumbnail = product.thumbnail;
    return ListTile(
      leading: SizedBox.square(
        dimension: 56,
        child: thumbnail == null
            ? const Icon(Icons.image)
            : Image.network(
                thumbnail,
                // بدون إنترنت أو صورة معطوبة: أيقونة بدل خطأ أحمر
                errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
              ),
      ),
      title: Text(product.title),
      subtitle: Text('${product.category} · ⭐ ${product.rating}'),
      trailing: Text('${index + 1}\n${product.price}\$', textAlign: TextAlign.end),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.feed});

  final ProductsFeed feed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = feed.loadMoreError;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: switch ((feed.isLoadingMore, error, feed.hasMore)) {
          (true, _, _) => const CircularProgressIndicator(),
          // خطأ في صفحة لاحقة: زر صغير بدل شاشة خطأ كاملة
          (_, final AppFailure e, _) => TextButton.icon(
            onPressed: () => ref.read(productsFeedProvider.notifier).loadMore(),
            icon: const Icon(Icons.refresh),
            label: Text('${e.message} — أعد المحاولة'),
          ),
          (_, _, true) => TextButton(
            onPressed: () => ref.read(productsFeedProvider.notifier).loadMore(),
            child: const Text('تحميل المزيد'),
          ),
          _ => Text('🎉 وصلت إلى النهاية (${feed.total} منتج)'),
        },
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) الصفحة الأولى لا تملأ الشاشة (جهاز لوحي كبير)؟ لن يحدث تمرير فلا تُطلب
//    الصفحة الثانية — لذلك أبقينا زر "تحميل المزيد" في الأسفل، أو اجعل pageSize أكبر.
//
// 2) أعطِ ListView قيمة itemExtent (أو prototypeItem) إذا كانت العناصر بنفس
//    الارتفاع: حساب أسرع للتمرير مع آلاف العناصر.
//      ListView.builder(itemExtent: 72, ...)
//
// 3) API يستخدم cursor بدل skip (مثل next_cursor)؟ نفس الحالة تماماً،
//    فقط احفظ String? nextCursor بدل الاعتماد على items.length.
//
// 4) مع البحث: اجعل الـ provider family بنص البحث، فكل كلمة بحث لها
//    صفحاتها المستقلة، وautoDispose يحذف نتائج البحث القديمة:
//      productsFeedProvider(query)
