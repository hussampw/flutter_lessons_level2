// ============================================================
// الدرس 7 (Dio): معالجة الأخطاء — DioException ← sealed AppFailure ← AsyncValue
// في التطبيق: القائمة ← الدرس 7  ·  في العرض: شرائح الدرس 7
// ============================================================
//
// المشكلة: DioException فيه تفاصيل تقنية كثيرة (type، statusCode، response...)
// والشاشة لا يجب أن تعرف شيئاً عن Dio.
//
// الحل في 3 طبقات:
//   1) AppFailure: sealed class (الدرس 1) بحالات يفهمها التطبيق
//   2) Repository: يلتقط DioException ويحوّله إلى AppFailure في مكان واحد
//   3) الشاشة: AsyncValue (اليوم الأول) + switch شامل على AppFailure
//
// والنماذج من الدرس 2: Product.fromJson (freezed).

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '02_freezed_json.dart' show Product, ProductsPage;
import '06_dio_interceptors.dart' show dioProvider;

// ============================================================
// 1) الأخطاء التي يفهمها التطبيق
// ============================================================
sealed class AppFailure implements Exception {
  const AppFailure(this.message);
  final String message;

  // التحويل في مكان واحد: كل DioException يصبح AppFailure
  factory AppFailure.fromDio(DioException e) {
    // switch شامل على enum: إذا أضافت Dio نوعاً جديداً ← خطأ ترجمة هنا
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const TimeoutFailure(),
      DioExceptionType.connectionError => const NetworkFailure(),
      DioExceptionType.cancel => const CancelledFailure(),
      DioExceptionType.badResponse => switch (e.response?.statusCode) {
        401 || 403 => const UnauthorizedFailure(),
        404 => const NotFoundFailure(),
        final int code when code >= 500 => ServerFailure(code),
        final code => ServerFailure(code ?? 0, 'طلب غير صالح ($code)'),
      },
      DioExceptionType.badCertificate ||
      DioExceptionType.transformTimeout ||
      DioExceptionType.unknown => UnknownFailure(e.message ?? '$e'),
    };
  }
}

class NetworkFailure extends AppFailure {
  const NetworkFailure() : super('لا يوجد اتصال بالإنترنت');
}

class TimeoutFailure extends AppFailure {
  const TimeoutFailure() : super('الخادم بطيء جداً، حاول مرة أخرى');
}

class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure() : super('انتهت الجلسة، سجّل الدخول من جديد');
}

class NotFoundFailure extends AppFailure {
  const NotFoundFailure() : super('العنصر غير موجود');
}

class ServerFailure extends AppFailure {
  const ServerFailure(this.statusCode, [String? message])
    : super(message ?? 'مشكلة في الخادم ($statusCode)');
  final int statusCode;
}

class CancelledFailure extends AppFailure {
  const CancelledFailure() : super('أُلغي الطلب');
}

class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message);
}

// ============================================================
// 2) Result: لنتيجة "فعل" لمرة واحدة (زر إرسال) بدل AsyncValue للشاشة
// ============================================================
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppFailure failure;
}

// ============================================================
// 3) Repository: الطبقة الوحيدة التي تعرف Dio
// ============================================================
class ProductsRepository {
  ProductsRepository(this._dio);
  final Dio _dio;

  // يرمي AppFailure ← مناسب لـ FutureProvider / AsyncNotifier
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw AppFailure.fromDio(e);
    }
  }

  Future<Product> product(String path, {Options? options}) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(path, options: options);
    return Product.fromJson(response.data!); // JSON ← Model (الدرس 2)
  });

  // صفحة من القائمة (يستخدمها الدرس 9) ← ProductsPage من الدرس 2
  Future<ProductsPage> page({required int skip, required int limit}) =>
      _guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/products',
          queryParameters: {
            'limit': limit,
            'skip': skip,
            'select': 'title,price,rating,thumbnail,category',
          },
        );
        return ProductsPage.fromJson(response.data!);
      });

  // يعيد Result ← لا يرمي أبداً، والمستدعي يفحص النتيجة بـ switch
  Future<Result<int>> addToCart(int productId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/carts/add',
        data: {
          'userId': 1,
          'products': [
            {'id': productId, 'quantity': 1},
          ],
        },
      );
      return Ok(response.data!['id'] as int);
    } on DioException catch (e) {
      return Err(AppFailure.fromDio(e));
    }
  }
}

final productsRepositoryProvider = Provider<ProductsRepository>(
  (ref) => ProductsRepository(ref.watch(dioProvider)),
);

// ============================================================
// سيناريوهات لنرى كل نوع خطأ بأعيننا
// ============================================================
enum Scenario {
  ok('✅ ناجح', '/products/1'),
  notFound('🔍 404', '/products/99999'),
  server('💥 500', '/http/500'),
  unauthorized('🔒 401', '/auth/me'),
  timeout('⏱ مهلة', '/products/1?delay=5000'),
  offline('📴 بدون إنترنت', 'https://offline.invalid/products/1');

  const Scenario(this.label, this.path);
  final String label;
  final String path;
}

// FutureProvider.family: لكل سيناريو حالة مستقلة (اليوم الأول، الدرس 6)
final scenarioProductProvider = FutureProvider.autoDispose
    .family<Product, Scenario>((ref, scenario) {
      return ref
          .watch(productsRepositoryProvider)
          .product(
            scenario.path,
            // مهلة قصيرة لهذا الطلب فقط ليظهر خطأ timeout بسرعة
            options: scenario == Scenario.timeout
                ? Options(receiveTimeout: const Duration(seconds: 2))
                : null,
          );
    });

class ErrorHandlingScreen extends ConsumerStatefulWidget {
  const ErrorHandlingScreen({super.key});

  @override
  ConsumerState<ErrorHandlingScreen> createState() =>
      _ErrorHandlingScreenState();
}

class _ErrorHandlingScreenState extends ConsumerState<ErrorHandlingScreen> {
  Scenario _scenario = Scenario.ok;

  // Result + switch: رسالة SnackBar لفعل لمرة واحدة
  Future<void> _addToCart(int id) async {
    final result = await ref.read(productsRepositoryProvider).addToCart(id);
    if (!mounted) return;
    final text = switch (result) {
      Ok(:final value) => '🛒 أُضيف إلى السلة رقم $value',
      Err(:final failure) => '❌ ${failure.message}',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(scenarioProductProvider(_scenario));

    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 7: معالجة الأخطاء')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          const Text('اختر سيناريو:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in Scenario.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: s == _scenario,
                  onSelected: (_) => setState(() => _scenario = s),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // AsyncValue + أنماط: كل حالة لها Widget
          switch (product) {
            AsyncData(:final value) => Card(
              child: ListTile(
                title: Text(value.title),
                subtitle: Text('${value.price}\$ · ⭐ ${value.rating}'),
                trailing: FilledButton(
                  onPressed: () => _addToCart(value.id),
                  child: const Text('أضف للسلة'),
                ),
              ),
            ),
            AsyncError(:final error) => FailureView(
              failure: error is AppFailure ? error : UnknownFailure('$error'),
              onRetry: () => ref.invalidate(scenarioProductProvider(_scenario)),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ],
      ),
    );
  }
}

// ============================================================
// Widget واحد لعرض أي خطأ — نعيد استخدامه في الدرسين 8 و 9
// ============================================================
class FailureView extends StatelessWidget {
  const FailureView({super.key, required this.failure, this.onRetry});

  final AppFailure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // switch شامل على sealed: أيقونة ونص زر مختلف لكل نوع
    final (icon, action) = switch (failure) {
      NetworkFailure() => (Icons.wifi_off, 'إعادة المحاولة'),
      TimeoutFailure() => (Icons.hourglass_bottom, 'إعادة المحاولة'),
      UnauthorizedFailure() => (Icons.lock, 'تسجيل الدخول'),
      NotFoundFailure() => (Icons.search_off, null),
      ServerFailure(statusCode: >= 500) => (Icons.cloud_off, 'إعادة المحاولة'),
      ServerFailure() => (Icons.report, null),
      CancelledFailure() => (Icons.cancel, null),
      UnknownFailure() => (Icons.error, 'إعادة المحاولة'),
    };
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 8,
          children: [
            Icon(icon, size: 40),
            Text(failure.message, textAlign: TextAlign.center),
            Text(
              failure.runtimeType.toString(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (action != null && onRetry != null)
              FilledButton.tonal(onPressed: onRetry, child: Text(action)),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) إعادة محاولة تلقائية ذكية في Riverpod 3: فقط لأخطاء الشبكة، وليس لـ 404:
//      ProviderScope(retry: (retryCount, error) =>
//          error is NetworkFailure && retryCount < 3 ? const Duration(seconds: 2) : null)
//
// 2) استخدم رسالة الخادم إن وُجدت (dummyjson يرسل {"message": "..."}):
//      final serverMessage = (e.response?.data as Map?)?['message'] as String?;
//
// 3) لا تعرض e.toString() للمستخدم أبداً (نص تقني بالإنجليزية) —
//    اعرض failure.message، وأرسل التفاصيل التقنية لـ Crashlytics / السجلّ.
//
// 4) AsyncValue يحتفظ بآخر بيانات أثناء الخطأ: عند فشل التحديث اعرض البيانات
//    القديمة مع شريط خطأ صغير بدل شاشة خطأ كاملة (product.hasValue && product.hasError).
