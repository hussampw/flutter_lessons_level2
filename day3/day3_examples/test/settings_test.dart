// ============================================================
// الدرس 3: اختبار الإعدادات مع shared_preferences في الذاكرة
// التشغيل: flutter test test/settings_test.dart
// ============================================================

import 'package:day3_examples/lessons/03_prefs_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    // بدل المنصة الحقيقية: تخزين في الذاكرة يبدأ فارغاً في كل اختبار
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  test('initPreferences يزيد عدد مرات التشغيل', () async {
    expect((await initPreferences()).getInt('launch_count'), 1);
    expect((await initPreferences()).getInt('launch_count'), 2);
  });

  test('الوضع الليلي يُحفظ ويبقى بعد «إعادة تشغيل» التطبيق', () async {
    final first = ProviderContainer.test(
      overrides: [prefsProvider.overrideWithValue(await initPreferences())],
    );
    expect(first.read(settingsProvider).darkMode, isFalse);
    await first.read(settingsProvider.notifier).setDarkMode(true);

    // حاوية جديدة + prefs جديدة من نفس التخزين = تشغيل جديد للتطبيق
    final second = ProviderContainer.test(
      overrides: [prefsProvider.overrideWithValue(await initPreferences())],
    );
    expect(second.read(settingsProvider).darkMode, isTrue);
    expect(second.read(settingsProvider).launchCount, 2);
  });
}
