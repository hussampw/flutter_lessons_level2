// ============================================================
// الدرس 3: shared_preferences و flutter_secure_storage — الإعدادات مقابل التوكن
// في التطبيق: القائمة ← الدرس 3  ·  في العرض: شرائح الدرس 3
// ============================================================
//
// سؤالان قبل أن تحفظ أي قيمة:
//   1) هل هي سرية؟  توكن، كلمة مرور، مفتاح API ← flutter_secure_storage
//      (Keychain في iOS · Keystore في Android · libsecret في Linux)
//   2) هل هي بسيطة وصغيرة؟ الوضع الليلي، اللغة، آخر تبويب ← shared_preferences
//      (ملف XML / NSUserDefaults / localStorage — نص عادي غير مشفّر!)
//   بيانات كثيرة أو لها علاقات ← قاعدة بيانات (الدرس 5)
//
// نمط Riverpod من اليوم الأول (الدرس 7): SharedPreferences تحتاج تهيئة async،
// فنهيئها مرة واحدة في main() ثم نعطيها للـ provider عبر override
// ← بعدها كل الـ providers تقرأ الإعدادات بشكل متزامن بدون await.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/network.dart';

// ------------------------------------------------------------
// 1) shared_preferences: التهيئة في main + provider بدون قيمة
// ------------------------------------------------------------
const _kDarkMode = 'dark_mode';
const _kFontScale = 'font_scale';
const _kLaunchCount = 'launch_count';

/// تُستدعى مرة واحدة في main() قبل runApp
Future<SharedPreferencesWithCache> initPreferences() async {
  final prefs = await SharedPreferencesWithCache.create(
    // allowList: المفاتيح المسموح بها فقط (يمنع الأخطاء الإملائية في المفاتيح)
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: {_kDarkMode, _kFontScale, _kLaunchCount},
    ),
  );
  await prefs.setInt(_kLaunchCount, (prefs.getInt(_kLaunchCount) ?? 0) + 1);
  return prefs;
}

// يجب أن يُعطى قيمة عبر override في main.dart، وإلا يرمي خطأ
final prefsProvider = Provider<SharedPreferencesWithCache>(
  (ref) => throw UnimplementedError('override في main.dart'),
);

// ------------------------------------------------------------
// 2) الإعدادات كحالة Riverpod — القراءة متزامنة من الكاش
// ------------------------------------------------------------
class AppSettings {
  const AppSettings({
    required this.darkMode,
    required this.fontScale,
    required this.launchCount,
  });

  final bool darkMode;
  final double fontScale;
  final int launchCount;

  AppSettings copyWith({bool? darkMode, double? fontScale}) => AppSettings(
        darkMode: darkMode ?? this.darkMode,
        fontScale: fontScale ?? this.fontScale,
        launchCount: launchCount,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.watch(prefsProvider);
    return AppSettings(
      darkMode: prefs.getBool(_kDarkMode) ?? false, // ?? قيمة افتراضية
      fontScale: prefs.getDouble(_kFontScale) ?? 1.0,
      launchCount: prefs.getInt(_kLaunchCount) ?? 1,
    );
  }

  Future<void> setDarkMode(bool value) async {
    state = state.copyWith(darkMode: value); // الواجهة تتغير فوراً
    await ref.read(prefsProvider).setBool(_kDarkMode, value); // ثم نحفظ
  }

  Future<void> setFontScale(double value) async {
    state = state.copyWith(fontScale: value);
    await ref.read(prefsProvider).setDouble(_kFontScale, value);
  }

  Future<void> reset() async {
    final prefs = ref.read(prefsProvider);
    await prefs.remove(_kDarkMode);
    await prefs.remove(_kFontScale);
    ref.invalidateSelf(); // نعيد build() فتُقرأ القيم الافتراضية
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// ------------------------------------------------------------
// 3) flutter_secure_storage: التوكن في مكان مشفّر
// ------------------------------------------------------------
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// حالة الجلسة كما نعرضها: هل التخزين الآمن متاح؟ وما التوكن الحالي؟
class SessionState {
  const SessionState({this.accessToken, this.problem});
  final String? accessToken;
  final String? problem; // سبب عدم توفر التخزين الآمن (منصة غير مدعومة…)

  bool get loggedIn => accessToken != null;
}

class SessionNotifier extends AsyncNotifier<SessionState> {
  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  FlutterSecureStorage get _storage => ref.read(secureStorageProvider);

  @override
  Future<SessionState> build() async {
    try {
      final token = await _storage.read(key: _kAccess);
      return SessionState(accessToken: token);
    } on MissingPluginException {
      // لا يوجد تنفيذ للمنصة (مثلاً داخل flutter test)
      return const SessionState(
        problem: 'التخزين الآمن غير متاح هنا (لا يوجد Plugin)',
      );
    } on PlatformException catch (e) {
      // مثلاً Linux بدون libsecret أو Keychain مقفل
      return SessionState(problem: 'تعذّر فتح التخزين الآمن: ${e.message}');
    }
  }

  /// تسجيل دخول حقيقي على dummyjson ثم حفظ التوكنين
  Future<void> login() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final res = await ref.read(dioProvider).post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': 'emilys', 'password': 'emilyspass', 'expiresInMins': 30},
      );
      final access = res.data!['accessToken'] as String;
      await _storage.write(key: _kAccess, value: access);
      await _storage.write(key: _kRefresh, value: res.data!['refreshToken'] as String);
      return SessionState(accessToken: access);
    });
  }

  Future<void> logout() async {
    // عند الخروج: احذف التوكنات — لا تكتفِ بإخفاء الشاشة
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    state = const AsyncData(SessionState());
  }
}

final sessionProvider =
    AsyncNotifierProvider<SessionNotifier, SessionState>(SessionNotifier.new);

// ------------------------------------------------------------
// 4) الشاشة
// ------------------------------------------------------------
class PrefsSecureStorageScreen extends ConsumerWidget {
  const PrefsSecureStorageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 3: الإعدادات والتخزين الآمن')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.tune),
                  title: Text('الإعدادات — shared_preferences'),
                  subtitle: Text('أغلق التطبيق وافتحه: القيم تبقى كما هي'),
                ),
                SwitchListTile(
                  title: const Text('الوضع الليلي (يغيّر ثيم التطبيق كله)'),
                  value: settings.darkMode,
                  onChanged: notifier.setDarkMode,
                ),
                ListTile(
                  title: Text('حجم الخط: ×${settings.fontScale.toStringAsFixed(1)}'),
                  subtitle: Slider(
                    min: 0.8,
                    max: 1.4,
                    divisions: 6,
                    value: settings.fontScale,
                    onChanged: notifier.setFontScale,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.rocket_launch),
                  title: Text('عدد مرات تشغيل التطبيق: ${settings.launchCount}'),
                  subtitle: const Text('يزيد في main() قبل runApp'),
                  trailing: TextButton(
                    onPressed: notifier.reset,
                    child: const Text('استعادة الافتراضي'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const _SessionCard(),
          const SizedBox(height: 12),
          const _WhereIsItStored(),
        ],
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  const _SessionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock),
              title: Text('التوكن — flutter_secure_storage'),
              subtitle: Text('dummyjson: emilys / emilyspass'),
            ),
            switch (session) {
              AsyncData(:final value) when value.problem != null =>
                Text('⚠️ ${value.problem}', style: const TextStyle(color: Colors.orange)),
              AsyncData(:final value) when value.loggedIn => Text(
                  '🔐 محفوظ: ${value.accessToken!.substring(0, 16)}…',
                  textDirection: TextDirection.ltr,
                ),
              AsyncData() => const Text('لا يوجد توكن محفوظ'),
              AsyncError(:final error) => Text(
                  '❌ ${error is DioException ? friendlyNetworkError(error) : '$error'}',
                  style: const TextStyle(color: Colors.red),
                ),
              _ => const LinearProgressIndicator(),
            },
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => ref.read(sessionProvider.notifier).login(),
                  icon: const Icon(Icons.login),
                  label: const Text('تسجيل الدخول'),
                ),
                OutlinedButton.icon(
                  onPressed: () => ref.read(sessionProvider.notifier).logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WhereIsItStored extends StatelessWidget {
  const _WhereIsItStored();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Android', 'ملف XML داخل التطبيق', 'Keystore + تشفير AES'),
      ('iOS', 'NSUserDefaults', 'Keychain'),
      ('Linux', 'ملف JSON', 'libsecret (Keyring)'),
      ('Web', 'localStorage', 'WebCrypto + localStorage'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Table(
          columnWidths: const {0: IntrinsicColumnWidth()},
          children: [
            const TableRow(children: [
              Text('المنصة', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('prefs (غير مشفّر)', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('secure storage', style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
            for (final (platform, prefs, secure) in rows)
              TableRow(children: [
                Padding(padding: const EdgeInsets.all(4), child: Text(platform)),
                Padding(padding: const EdgeInsets.all(4), child: Text(prefs)),
                Padding(padding: const EdgeInsets.all(4), child: Text(secure)),
              ]),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) SharedPreferences القديمة (getInstance) ما زالت تعمل، لكن الموصى به الآن:
//    SharedPreferencesWithCache (قراءة متزامنة من كاش) أو SharedPreferencesAsync
//    (كل قراءة await مباشرة من المنصة — أفضل إذا عدّلت القيم من Isolate آخر).
//
// 2) في الاختبارات استبدل المنصة بتخزين في الذاكرة (انظر test/):
//      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
//
// 3) ❌ لا تحفظ التوكن في shared_preferences: الملف نص عادي يمكن قراءته
//    من نسخة احتياطية أو جهاز مكسور الحماية (root / jailbreak).
//
// 4) iOS: Keychain يبقى بعد حذف التطبيق! لمسح التوكن القديم عند أول تشغيل
//    بعد إعادة التثبيت: علامة في prefs (تُحذف مع التطبيق) ثم deleteAll() للآمن.
//
// 5) لقراءة التوكن من كود يعمل في الخلفية (والجهاز مقفل) على iOS:
//      FlutterSecureStorage(
//        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
//      )
