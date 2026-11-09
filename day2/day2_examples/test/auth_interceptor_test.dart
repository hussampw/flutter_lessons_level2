// ============================================================
// اختبار الدرس 8: AuthInterceptor بدون إنترنت (خادم وهمي)
// التشغيل: flutter test test/auth_interceptor_test.dart
// ============================================================
//
// FakeServer يحل محل الشبكة: نستبدل httpClientAdapter في Dio،
// فنتحكم بالرد (200 أو 401) ونعدّ كم مرة طُلب /auth/refresh.

import 'dart:convert';
import 'dart:typed_data';

import 'package:day2_examples/lessons/08_auth_tokens.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeServer implements HttpClientAdapter {
  String validAccess = 'new-access';
  int refreshCalls = 0;
  bool refreshFails = false;

  ResponseBody _json(Object body, int status) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/auth/refresh') {
      refreshCalls++;
      if (refreshFails) return _json({'message': 'Invalid refresh token'}, 403);
      return _json({
        'accessToken': validAccess,
        'refreshToken': 'new-refresh',
      }, 200);
    }
    // /auth/me: ينجح فقط مع التوكن الصالح
    final ok = options.headers['Authorization'] == 'Bearer $validAccess';
    return ok
        ? _json({'firstName': 'Emily'}, 200)
        : _json({'message': 'Invalid/Expired Token!'}, 401);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeServer server;
  late AuthTokens? tokens;
  late Dio dio;

  setUp(() {
    server = FakeServer();
    tokens = (access: 'expired', refresh: 'old-refresh');
    final plain = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'))
      ..httpClientAdapter = server;
    dio = Dio(BaseOptions(baseUrl: 'https://dummyjson.com'))
      ..httpClientAdapter = server
      ..interceptors.add(
        AuthInterceptor(
          readTokens: () => tokens,
          saveTokens: (t) => tokens = t,
          plainDio: plain,
        ),
      );
  });

  test('401 ← refresh ← إعادة الطلب تنجح بالتوكن الجديد', () async {
    final response = await dio.get<Map<String, dynamic>>('/auth/me');

    expect(response.statusCode, 200);
    expect(response.data?['firstName'], 'Emily');
    expect(tokens?.access, 'new-access'); // حُفظ التوكن الجديد
    expect(server.refreshCalls, 1);
  });

  test('3 طلبات معاً بتوكن منتهٍ ← تجديد واحد فقط (QueuedInterceptor)', () async {
    final responses = await Future.wait([
      dio.get<dynamic>('/auth/me'),
      dio.get<dynamic>('/auth/me'),
      dio.get<dynamic>('/auth/me'),
    ]);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(server.refreshCalls, 1);
  });

  test('فشل التجديد ← خروج إجباري (tokens = null) والخطأ 401 يصل للمستدعي', () async {
    server.refreshFails = true;

    await expectLater(
      dio.get<dynamic>('/auth/me'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
    expect(tokens, isNull);
  });
}
