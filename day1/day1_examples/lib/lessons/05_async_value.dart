// ============================================================
// الدرس 5 (Riverpod): التعامل مع AsyncValue (loading / data / error)
// في التطبيق: القائمة ← الدرس 5  ·  في العرض: شرائح الدرس 5
// ============================================================
//
// أي FutureProvider أو StreamProvider أو AsyncNotifier يعيد AsyncValue<T>
// وهو sealed class له 3 حالات:
//   AsyncLoading ← جاري التحميل
//   AsyncData    ← وصلت البيانات (value)
//   AsyncError   ← حدث خطأ (error + stackTrace)
//
// الفائدة: لا حاجة لمتغيرات isLoading و error يدوياً في كل شاشة.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _random = Random();

// Provider يفشل أحياناً عمداً لنرى حالة الخطأ
final quoteProvider = FutureProvider<String>(
  (ref) async {
    await Future.delayed(const Duration(seconds: 1));
    if (_random.nextBool()) {
      throw Exception('فشل الاتصال بالخادم');
    }
    const quotes = [
      'البساطة هي قمة التعقيد',
      'الكود النظيف يُقرأ كالنثر',
      'اجعله يعمل، ثم اجعله صحيحاً، ثم اجعله سريعاً',
    ];
    return quotes[_random.nextInt(quotes.length)];
  },
  // في Riverpod 3 الـ providers تعيد المحاولة تلقائياً عند الخطأ.
  // نوقف ذلك هنا لنرى حالة الخطأ مباشرة في العرض.
  retry: (retryCount, error) => null,
);

class AsyncValueScreen extends ConsumerWidget {
  const AsyncValueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quote = ref.watch(quoteProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 5: AsyncValue')),
      // RefreshIndicator: السحب للتحديث
      // ref.refresh(...future) يعيد التحميل ويعيد Future ينتظره المؤشر
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(quoteProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ------------------------------------------------------------
            // الطريقة 1: switch مع الأنماط (Dart 3) ← المفضّلة حالياً
            // ------------------------------------------------------------
            const Text('الطريقة 1: switch'),
            SizedBox(
              height: 120,
              child: Center(
                child: switch (quote) {
                  // إذا كانت هناك بيانات قديمة أثناء إعادة التحميل نعرضها
                  AsyncData(:final value) => Text(
                      '«$value»',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  AsyncError(:final error) => Text(
                      '❌ $error',
                      style: const TextStyle(color: Colors.red),
                    ),
                  _ => const CircularProgressIndicator(),
                },
              ),
            ),
            const Divider(),

            // ------------------------------------------------------------
            // الطريقة 2: when ← تجبرك على كتابة الحالات الثلاث
            // ------------------------------------------------------------
            const Text('الطريقة 2: when'),
            quote.when(
              data: (value) => const ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('تم التحميل بنجاح'),
              ),
              error: (error, stackTrace) => ListTile(
                leading: const Icon(Icons.error, color: Colors.red),
                title: const Text('حدث خطأ'),
                trailing: TextButton(
                  // invalidate: أعد التحميل في المرة القادمة التي يُقرأ فيها
                  onPressed: () => ref.invalidate(quoteProvider),
                  child: const Text('إعادة المحاولة'),
                ),
              ),
              loading: () => const ListTile(
                leading: CircularProgressIndicator(),
                title: Text('جاري التحميل...'),
              ),
            ),
            const Divider(),

            // ------------------------------------------------------------
            // خصائص مفيدة
            // ------------------------------------------------------------
            Text('isLoading: ${quote.isLoading}'),
            Text('hasValue: ${quote.hasValue}'),
            Text('hasError: ${quote.hasError}'),
            // isRefreshing: جاري التحديث مع وجود بيانات قديمة (لا نخفيها)
            Text('isRefreshing: ${quote.isRefreshing}'),
            const SizedBox(height: 16),
            const Text('↓ اسحب للأسفل للتحديث (نجاح أو فشل عشوائي)'),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) RefreshIndicator + ref.refresh(provider.future) = سحب للتحديث في سطر واحد،
//    والمؤشر يختفي تلقائياً عند وصول النتيجة.
//
// 2) أثناء التحديث تبقى البيانات القديمة في AsyncData، لذلك switch يعرضها
//    بدل مؤشر تحميل يغطي الشاشة — أفضل تجربة للمستخدم.
//    استخدم isRefreshing لإظهار مؤشر صغير فوق البيانات.
//
// 3) ref.invalidate(p) مقابل ref.refresh(p):
//    invalidate ← "أعد التحميل عند الحاجة" (لا يعيد قيمة)
//    refresh    ← "أعد التحميل الآن وأعطني النتيجة"
//
// 4) في Riverpod 3 الـ providers تعيد المحاولة تلقائياً عند الخطأ.
//    لإيقافها لكل التطبيق: ProviderScope(retry: (retryCount, error) => null, ...)
//
// 5) اكتب Widget واحداً لعرض الأخطاء (ErrorView مع زر "إعادة المحاولة")
//    واستخدمه في كل الشاشات بدل تكرار نفس الكود.
