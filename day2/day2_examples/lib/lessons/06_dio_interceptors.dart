// ============================================================
// الدرس 6 (Dio): الإعداد و Interceptors (التسجيل، الـ headers، قياس الزمن)
// في التطبيق: القائمة ← الدرس 6  ·  في العرض: شرائح الدرس 6
// ============================================================
//
// Dio = عميل HTTP أقوى من package:http:
//   BaseOptions (رابط أساسي + مهلات + headers مشتركة) · Interceptors ·
//   تحويل JSON تلقائي · CancelToken · رفع الملفات مع نسبة التقدم.
//
// Interceptor = "نقطة تفتيش" يمر بها كل طلب وكل رد وكل خطأ بالترتيب:
//   الطلب:  onRequest (1 ← 2 ← 3) ← الخادم
//   الرد:   الخادم ← onResponse (بنفس الترتيب)    أو    onError
// كل مرحلة يجب أن تنادي handler.next(...) لتكمل، أو resolve / reject لتوقف السلسلة.
//
// نُنشئ Dio مرة واحدة عبر Provider (نفس نمط حقن الاعتماديات — اليوم الأول، الدرس 7)
// ونطبع كل ما يحدث في "كونسول" الشاشة.
//
// الـ API: https://dummyjson.com (يحتاج إنترنت — بدونه تظهر رسالة واضحة)

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '01_records_sealed.dart' show ConsoleView;

// ------------------------------------------------------------
// الكونسول المشترك: الدرسان 6 و 8 يكتبان فيه
// ------------------------------------------------------------
class NetworkLog extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void add(String line) => state = [...state, line];
  void clear() => state = [];
}

final networkLogProvider = NotifierProvider<NetworkLog, List<String>>(
  NetworkLog.new,
);

// ------------------------------------------------------------
// 1) Interceptor للـ headers: يُضاف لكل طلب بدل تكراره في كل مكان
// ------------------------------------------------------------
class HeadersInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = 'ar';
    options.headers['X-App-Version'] = '2.0.0';
    handler.next(options); // ⚠️ بدونها يبقى الطلب معلّقاً للأبد
  }
}

// ------------------------------------------------------------
// 2) Interceptor للتسجيل: يرى الطلب والرد والخطأ
// ------------------------------------------------------------
class ConsoleLogInterceptor extends Interceptor {
  ConsoleLogInterceptor(this.log);

  final void Function(String line) log;

  int _ms(RequestOptions o) {
    final started = o.extra['startedAt'] as DateTime?;
    return started == null
        ? 0
        : DateTime.now().difference(started).inMilliseconds;
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // نحفظ وقت البداية في extra (بيانات خاصة بالطلب لا تُرسل للخادم)
    options.extra['startedAt'] = DateTime.now();
    log('→ ${options.method} ${options.uri}');
    if (options.headers.isNotEmpty) log('   headers: ${options.headers}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log('← ${response.statusCode} في ${_ms(response.requestOptions)}ms');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // أنماط الكائنات (الدرس 1) لفحص نوع الخطأ ووجود رد من الخادم
    log(switch (err) {
      DioException(type: DioExceptionType.cancel) => '⛔ أُلغي الطلب: ${err.error}',
      DioException(response: Response(:final statusCode, :final data)) =>
        '✖ $statusCode — $data',
      // لا يوجد رد إطلاقاً: لا إنترنت أو انتهت المهلة
      _ => '✖ ${err.type.name} — تعذّر الوصول للخادم (هل الإنترنت متصل؟)',
    });
    handler.next(err); // نمرّر الخطأ ليصل إلى catch في الشاشة
  }
}

// ------------------------------------------------------------
// 3) Dio واحد للتطبيق عبر Provider
// ------------------------------------------------------------
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://dummyjson.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );

  // الترتيب مهم: HeadersInterceptor أولاً ليرى ConsoleLogInterceptor الـ headers المضافة
  dio.interceptors.addAll([
    HeadersInterceptor(),
    ConsoleLogInterceptor(ref.read(networkLogProvider.notifier).add),
  ]);

  ref.onDispose(dio.close); // إغلاق الاتصالات عند حذف الـ provider
  return dio;
});

class DioInterceptorsScreen extends ConsumerStatefulWidget {
  const DioInterceptorsScreen({super.key});

  @override
  ConsumerState<DioInterceptorsScreen> createState() =>
      _DioInterceptorsScreenState();
}

class _DioInterceptorsScreenState extends ConsumerState<DioInterceptorsScreen> {
  bool _busy = false;
  CancelToken? _cancelToken;

  void _log(String line) => ref.read(networkLogProvider.notifier).add(line);

  Future<void> _run(String title, Future<void> Function(Dio dio) demo) async {
    ref.read(networkLogProvider.notifier).clear();
    _log('▶ $title');
    setState(() => _busy = true);
    try {
      await demo(ref.read(dioProvider));
    } on DioException catch (e) {
      // الدرس 7 يحوّل هذا إلى رسائل مفهومة لكل نوع خطأ
      _log('catch في الشاشة: ${e.type.name}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ------------------------------------------------------------
  // 1) GET بسيط: response.data أصبح Map جاهزاً (Dio يحوّل JSON تلقائياً)
  // ------------------------------------------------------------
  Future<void> _getOne(Dio dio) async {
    final response = await dio.get<Map<String, dynamic>>('/products/1');
    _log('العنوان: ${response.data?['title']}');
  }

  // ------------------------------------------------------------
  // 2) queryParameters: Dio يبني ?q=...&limit=... ويرمّز النص
  // ------------------------------------------------------------
  Future<void> _search(Dio dio) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/products/search',
      queryParameters: {'q': 'phone', 'limit': 3, 'select': 'title,price'},
    );
    final products = response.data?['products'] as List? ?? [];
    for (final p in products) {
      _log('• ${p['title']} — ${p['price']}\$');
    }
  }

  // ------------------------------------------------------------
  // 3) POST مع body: الـ Map يتحوّل إلى JSON تلقائياً
  // ------------------------------------------------------------
  Future<void> _post(Dio dio) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/products/add',
      data: {'title': 'منتج من الورشة', 'price': 42},
    );
    _log('أنشأ الخادم المنتج رقم ${response.data?['id']}');
  }

  // ------------------------------------------------------------
  // 4) خطأ من الخادم: يمر عبر onError في الـ Interceptors
  // ------------------------------------------------------------
  Future<void> _notFound(Dio dio) => dio.get('/products/99999');

  // ------------------------------------------------------------
  // 5) CancelToken: إلغاء طلب بطيء (?delay=3000 يؤخّر الرد 3 ثوانٍ)
  // ------------------------------------------------------------
  Future<void> _cancellable(Dio dio) async {
    setState(() => _cancelToken = CancelToken()); // يفعّل زر "إلغاء"
    try {
      await dio.get(
        '/products/1',
        queryParameters: {'delay': 3000},
        cancelToken: _cancelToken,
      );
      _log('وصل الرد قبل الإلغاء');
    } finally {
      if (mounted) setState(() => _cancelToken = null);
    }
  }

  @override
  void dispose() {
    // نلغي أي طلب معلّق عند الخروج من الشاشة
    _cancelToken?.cancel('خرج المستخدم من الشاشة');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(networkLogProvider);
    final demos = <(String, Future<void> Function(Dio))>[
      ('1) GET', _getOne),
      ('2) query', _search),
      ('3) POST', _post),
      ('4) 404', _notFound),
      ('5) طلب بطيء', _cancellable),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 6: Dio و Interceptors')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, demo) in demos)
                  FilledButton.tonal(
                    onPressed: _busy ? null : () => _run(label, demo),
                    child: Text(label),
                  ),
                OutlinedButton.icon(
                  onPressed: _cancelToken == null
                      ? null
                      : () => _cancelToken?.cancel('ألغاه المستخدم'),
                  icon: const Icon(Icons.cancel),
                  label: const Text('إلغاء'),
                ),
              ],
            ),
          ),
          Expanded(child: ConsoleView(lines: logs, busy: _busy)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) Interceptor جاهز للتطوير يطبع كل شيء في Debug Console:
//      dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
//    وأضفه فقط في وضع التطوير: if (kDebugMode) ...
//
// 2) لا تريد كتابة class كاملة؟ InterceptorsWrapper يكفي لحالة صغيرة:
//      dio.interceptors.add(InterceptorsWrapper(
//        onRequest: (options, handler) { ...; handler.next(options); },
//      ));
//
// 3) مهلة مختلفة لطلب واحد (رفع ملف كبير مثلاً) بدون تغيير BaseOptions:
//      dio.get('/big', options: Options(receiveTimeout: const Duration(minutes: 2)));
//
// 4) Dio واحد للتطبيق كله (عبر Provider) وليس Dio() جديد في كل شاشة:
//    يعيد استخدام الاتصالات ويطبّق نفس الـ Interceptors في كل مكان.
//
// 5) مع Riverpod: ألغِ الطلب تلقائياً عند الخروج من الشاشة (autoDispose):
//      final token = CancelToken();
//      ref.onDispose(token.cancel);
//      await dio.get('/products', cancelToken: token);
