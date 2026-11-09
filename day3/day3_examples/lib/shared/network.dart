// ============================================================
// أدوات شبكة مشتركة (الدروس 3 و 4 و 7 و 8)
// Dio عبر Provider — نفس نمط اليوم الثاني — مع زر «محاكاة عدم الاتصال»
// ============================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// مفتاح «محاكاة عدم الاتصال»: نجرّب حالة الأوفلاين بدون فصل الإنترنت فعلاً
class OfflineMode extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

final offlineModeProvider = NotifierProvider<OfflineMode, bool>(OfflineMode.new);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://dummyjson.com',
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );
  // Interceptor (اليوم الثاني): نرفض الطلب فوراً إذا كانت المحاكاة مفعّلة
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (ref.read(offlineModeProvider)) {
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionError,
              message: 'محاكاة: لا يوجد اتصال',
            ),
          );
        }
        handler.next(options);
      },
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});

/// رسالة خطأ ودّية بالعربية بدل نص الاستثناء الطويل
String friendlyNetworkError(Object error) {
  if (error is DioException) {
    return switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout =>
        'لا يوجد اتصال بالإنترنت — نعرض ما هو محفوظ محلياً',
      DioExceptionType.receiveTimeout => 'الخادم بطيء جداً، حاول لاحقاً',
      DioExceptionType.badResponse =>
        'ردّ الخادم بخطأ ${error.response?.statusCode ?? ''}',
      _ => 'تعذّر الوصول إلى الخادم',
    };
  }
  return 'خطأ غير متوقع: $error';
}
