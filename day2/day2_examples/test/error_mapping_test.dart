// ============================================================
// اختبار الدرس 7: تحويل DioException إلى AppFailure
// التشغيل: flutter test test/error_mapping_test.dart
// ============================================================

import 'package:day2_examples/lessons/07_error_handling.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

final _options = RequestOptions(path: '/products/1');

DioException _badResponse(int status) => DioException.badResponse(
  statusCode: status,
  requestOptions: _options,
  response: Response(requestOptions: _options, statusCode: status),
);

void main() {
  test('رموز الحالة ← نوع الخطأ المناسب', () {
    expect(AppFailure.fromDio(_badResponse(401)), isA<UnauthorizedFailure>());
    expect(AppFailure.fromDio(_badResponse(404)), isA<NotFoundFailure>());
    expect(
      AppFailure.fromDio(_badResponse(503)),
      isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 503),
    );
  });

  test('لا إنترنت / مهلة / إلغاء', () {
    expect(
      AppFailure.fromDio(DioException.connectionError(
        requestOptions: _options,
        reason: 'offline',
      )),
      isA<NetworkFailure>(),
    );
    expect(
      AppFailure.fromDio(DioException.receiveTimeout(
        timeout: const Duration(seconds: 2),
        requestOptions: _options,
      )),
      isA<TimeoutFailure>(),
    );
    expect(
      AppFailure.fromDio(DioException.requestCancelled(
        requestOptions: _options,
        reason: 'خرج المستخدم',
      )),
      isA<CancelledFailure>(),
    );
  });
}
