// ============================================================
// الدرس 8 (Dio): المصادقة — Access token و Refresh token
// في التطبيق: القائمة ← الدرس 8  ·  في العرض: شرائح الدرس 8
// ============================================================
//
// تسجيل الدخول يعيد توكنين:
//   accessToken  ← قصير العمر (هنا دقيقة واحدة!) يُرسل مع كل طلب في header
//   refreshToken ← طويل العمر، نستخدمه فقط لطلب accessToken جديد
//
// التدفق الذي نبنيه في AuthInterceptor:
//   1) onRequest: نضيف Authorization: Bearer <access> لكل طلب
//   2) الخادم يرد 401 (انتهت صلاحية access)
//   3) onError: نطلب توكناً جديداً من /auth/refresh
//   4) نعيد إرسال الطلب الأصلي بالتوكن الجديد ← المستخدم لا يلاحظ شيئاً
//   5) فشل التجديد أيضاً؟ ← خروج إجباري (والحارس في الدرس 5 يحوّل للدخول)
//
// QueuedInterceptor: إذا فشلت 3 طلبات بـ 401 معاً، تُعالَج واحداً تلو الآخر
// ← تجديد واحد فقط بدل 3 تجديدات متسابقة.
//
// ⚠️ التوكنات هنا في الذاكرة فقط (Provider) وتضيع عند إغلاق التطبيق.
//    التخزين الآمن (flutter_secure_storage) هو موضوع اليوم الثالث.
//
// الحساب التجريبي الموثّق في dummyjson: emilys / emilyspass

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '01_records_sealed.dart' show ConsoleView;
import '06_dio_interceptors.dart' show ConsoleLogInterceptor, networkLogProvider;
import '07_error_handling.dart' show AppFailure;

// Record (الدرس 1) يكفي لتمثيل زوج التوكنات
typedef AuthTokens = ({String access, String refresh});

// ------------------------------------------------------------
// مخزن التوكنات (في الذاكرة)
// ------------------------------------------------------------
class TokenStore extends Notifier<AuthTokens?> {
  @override
  AuthTokens? build() => null; // null = غير مسجّل

  void save(AuthTokens? tokens) => state = tokens;
}

final tokenStoreProvider = NotifierProvider<TokenStore, AuthTokens?>(
  TokenStore.new,
);

// ============================================================
// AuthInterceptor: يضيف التوكن، ويجدّده عند 401 ثم يعيد المحاولة
// ============================================================
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.readTokens,
    required this.saveTokens,
    required this.plainDio,
    this.log,
  });

  final AuthTokens? Function() readTokens;
  final void Function(AuthTokens? tokens) saveTokens;
  // Dio بدون هذا الـ Interceptor: للتجديد ولإعادة المحاولة (وإلا: حلقة أو انتظار للأبد)
  final Dio plainDio;
  final void Function(String line)? log;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final tokens = readTokens();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.access}';
      log?.call('   🔑 Bearer ${_short(tokens.access)}');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final tokens = readTokens();
    // ليس 401 أو لا توجد جلسة ← لا شأن لنا، مرّر الخطأ كما هو
    if (err.response?.statusCode != 401 || tokens == null) {
      handler.next(err);
      return;
    }

    final options = err.requestOptions;
    final AuthTokens fresh;
    try {
      // هل جدّد طلب آخر التوكن بينما كان هذا الطلب ينتظر في الطابور؟
      final sent = options.headers['Authorization'];
      if (sent == 'Bearer ${tokens.access}') {
        log?.call('🔄 401 ← نجدّد التوكن عبر /auth/refresh');
        fresh = await _refresh(tokens.refresh);
        saveTokens(fresh);
      } else {
        log?.call('↻ التوكن جُدّد مسبقاً ← نعيد المحاولة مباشرة');
        fresh = tokens;
      }
    } on DioException {
      log?.call('⛔ فشل التجديد ← تسجيل خروج إجباري');
      saveTokens(null);
      handler.next(err);
      return;
    }

    // إعادة إرسال الطلب الأصلي نفسه بالتوكن الجديد
    options.headers['Authorization'] = 'Bearer ${fresh.access}';
    try {
      final response = await plainDio.fetch<dynamic>(options);
      handler.resolve(response); // الشاشة تستلم الرد وكأن شيئاً لم يحدث
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<AuthTokens> _refresh(String refreshToken) async {
    final response = await plainDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken, 'expiresInMins': 1},
    );
    final data = response.data!;
    return (
      access: data['accessToken'] as String,
      refresh: data['refreshToken'] as String,
    );
  }
}

String _short(String token) =>
    token.length > 12 ? '${token.substring(0, 12)}…' : token;

// ------------------------------------------------------------
// اثنان من Dio: "عادي" للدخول والتجديد، و"مُصادَق" لباقي الطلبات
// ------------------------------------------------------------
BaseOptions _baseOptions() => BaseOptions(
  baseUrl: 'https://dummyjson.com',
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 10),
);

final plainDioProvider = Provider<Dio>((ref) {
  final dio = Dio(_baseOptions());
  dio.interceptors.add(
    ConsoleLogInterceptor(ref.read(networkLogProvider.notifier).add),
  );
  ref.onDispose(dio.close);
  return dio;
});

final authDioProvider = Provider<Dio>((ref) {
  final log = ref.read(networkLogProvider.notifier).add;
  final dio = Dio(_baseOptions());
  dio.interceptors.addAll([
    ConsoleLogInterceptor(log), // أولاً: ليظهر الـ 401 في الكونسول قبل التجديد
    AuthInterceptor(
      readTokens: () => ref.read(tokenStoreProvider),
      saveTokens: ref.read(tokenStoreProvider.notifier).save,
      plainDio: ref.watch(plainDioProvider),
      log: log,
    ),
  ]);
  ref.onDispose(dio.close);
  return dio;
});

class AuthTokensScreen extends ConsumerStatefulWidget {
  const AuthTokensScreen({super.key});

  @override
  ConsumerState<AuthTokensScreen> createState() => _AuthTokensScreenState();
}

class _AuthTokensScreenState extends ConsumerState<AuthTokensScreen> {
  final _username = TextEditingController(text: 'emilys');
  final _password = TextEditingController(text: 'emilyspass');
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _log(String line) => ref.read(networkLogProvider.notifier).add(line);

  Future<void> _run(String title, Future<void> Function() action) async {
    ref.read(networkLogProvider.notifier).clear();
    _log('▶ $title');
    setState(() => _busy = true);
    try {
      await action();
    } on DioException catch (e) {
      // نفس التحويل من الدرس 7 ← رسالة مفهومة بدل نص تقني
      _log('❌ ${AppFailure.fromDio(e).message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // 1) الدخول: POST /auth/login ← نحفظ التوكنين
  Future<void> _login() async {
    final response = await ref
        .read(plainDioProvider)
        .post<Map<String, dynamic>>(
          '/auth/login',
          data: {
            'username': _username.text.trim(),
            'password': _password.text,
            'expiresInMins': 1, // دقيقة واحدة لنرى التجديد الحقيقي بسرعة
          },
        );
    final data = response.data!;
    ref
        .read(tokenStoreProvider.notifier)
        .save((
          access: data['accessToken'] as String,
          refresh: data['refreshToken'] as String,
        ));
    _log('✅ أهلاً ${data['firstName']} — التوكن صالح لدقيقة واحدة');
  }

  // 2) طلب محمي: الـ Interceptor يضيف التوكن تلقائياً
  Future<void> _me() async {
    final response = await ref
        .read(authDioProvider)
        .get<Map<String, dynamic>>('/auth/me');
    _log('👤 ${response.data?['firstName']} ${response.data?['lastName']}');
  }

  // 3) محاكاة انتهاء الصلاحية: نفسد access ونترك refresh سليماً
  void _expireAccess() {
    final tokens = ref.read(tokenStoreProvider);
    if (tokens == null) return;
    ref
        .read(tokenStoreProvider.notifier)
        .save((access: 'expired-token', refresh: tokens.refresh));
    ref.read(networkLogProvider.notifier).clear();
    _log('💣 أفسدنا access token ← الطلب القادم سيعود 401');
  }

  // 4) ثلاثة طلبات معاً بتوكن منتهٍ ← تجديد واحد فقط (QueuedInterceptor)
  Future<void> _parallel() async {
    final dio = ref.read(authDioProvider);
    await Future.wait([
      dio.get('/auth/me'),
      dio.get('/auth/me'),
      dio.get('/auth/me'),
    ]);
    _log('✅ نجحت الطلبات الثلاثة');
  }

  // 5) refresh منتهٍ أيضاً ← خروج إجباري
  void _expireBoth() {
    ref
        .read(tokenStoreProvider.notifier)
        .save((access: 'expired-token', refresh: 'expired-refresh'));
    ref.read(networkLogProvider.notifier).clear();
    _log('💣💣 أفسدنا التوكنين ← التجديد سيفشل');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ref.watch(tokenStoreProvider);
    final logs = ref.watch(networkLogProvider);
    final loggedIn = tokens != null;

    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 8: Access و Refresh tokens')),
      body: Column(
        children: [
          ListTile(
            leading: Icon(loggedIn ? Icons.verified_user : Icons.no_accounts),
            title: Text(loggedIn ? 'مسجّل الدخول' : 'غير مسجّل'),
            subtitle: loggedIn
                ? Text(
                    'access: ${_short(tokens.access)}\n'
                    'refresh: ${_short(tokens.refresh)}',
                    textDirection: TextDirection.ltr,
                  )
                : const Text('emilys / emilyspass'),
            trailing: loggedIn
                ? TextButton(
                    onPressed: () =>
                        ref.read(tokenStoreProvider.notifier).save(null),
                    child: const Text('خروج'),
                  )
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (!loggedIn) ...[
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: _username,
                      decoration: const InputDecoration(labelText: 'username'),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'password'),
                    ),
                  ),
                  FilledButton(
                    onPressed: _busy ? null : () => _run('1) الدخول', _login),
                    child: const Text('1) دخول'),
                  ),
                ] else ...[
                  FilledButton.tonal(
                    onPressed: _busy ? null : () => _run('2) GET /auth/me', _me),
                    child: const Text('2) /auth/me'),
                  ),
                  FilledButton.tonal(
                    onPressed: _busy ? null : _expireAccess,
                    child: const Text('3) أفسد access'),
                  ),
                  FilledButton.tonal(
                    onPressed: _busy
                        ? null
                        : () => _run('4) 3 طلبات معاً', _parallel),
                    child: const Text('4) 3 طلبات معاً'),
                  ),
                  OutlinedButton(
                    onPressed: _busy ? null : _expireBoth,
                    child: const Text('5) أفسد الاثنين'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
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
// 1) لا تُرسل التوكن لخوادم أخرى (CDN للصور، API خارجي): افحص الـ host أولاً:
//      if (options.uri.host == 'dummyjson.com') options.headers['Authorization'] = ...
//
// 2) اربط حارس go_router (الدرس 5) بمخزن التوكنات: عند الخروج الإجباري
//    تتغيّر الحالة ← refreshListenable ← redirect يحوّل لصفحة الدخول تلقائياً:
//      final loggedIn = ref.read(tokenStoreProvider) != null;
//
// 3) جدّد قبل الانتهاء بدل انتظار 401: الـ JWT يحمل حقل exp (وقت الانتهاء)،
//    فإذا بقي أقل من 30 ثانية جدّد في onRequest قبل إرسال الطلب.
//
// 4) طلب الـ refresh نفسه يجب ألا يمر بـ AuthInterceptor (لذلك plainDio)،
//    وإلا فإن 401 من /auth/refresh يُطلق تجديداً آخر ← حلقة لا تنتهي.
//
// 5) التوكنات في الذاكرة تضيع عند إغلاق التطبيق — في اليوم الثالث نحفظها
//    في flutter_secure_storage (Keychain / Keystore) وليس shared_preferences.
