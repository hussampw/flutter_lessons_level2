// ============================================================
// مثال: Override في الاختبارات (سنتوسّع في الاختبارات في اليوم الرابع)
// التشغيل: flutter test test/overrides_test.dart
// ============================================================

import 'package:day1_examples/lessons/07_dependency_injection.dart';
import 'package:day1_examples/lessons/08_overrides.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('temperatureProvider يستخدم الـ Repository الوهمي', () async {
    // ProviderContainer = نفس ProviderScope لكن بدون Widgets
    // .test يتخلّص من الحاوية تلقائياً بعد انتهاء الاختبار
    final container = ProviderContainer.test(
      overrides: [
        weatherRepositoryProvider.overrideWithValue(FakeWeatherRepository()),
      ],
    );

    // .future ننتظر النتيجة النهائية للـ FutureProvider
    final temp = await container.read(temperatureProvider('الرياض').future);

    expect(temp, 99); // النتيجة من الـ Fake وليس من الـ API ✅
  });
}
