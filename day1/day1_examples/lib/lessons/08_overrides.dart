// ============================================================
// الدرس 8 (Riverpod): تبديل الـ Providers (Overrides)
// في التطبيق: القائمة ← الدرس 8  ·  في العرض: شرائح الدرس 8
// ============================================================
//
// override = "استبدل هذا الـ provider بقيمة أو تنفيذ آخر داخل هذا النطاق"
//
// الاستخدامات الثلاثة الأشهر:
//   1) الاختبارات: نستبدل الـ Repository الحقيقي بـ Fake (انظر test/overrides_test.dart)
//   2) البيئات: تنفيذ مختلف للتطوير والإنتاج (انظر تعليق main.dart)
//   3) النطاق المحلي: ProviderScope متداخل يعطي قيمة مختلفة لجزء من الشجرة
//
// أنواع الـ override:
//   provider.overrideWithValue(قيمة)   ← قيمة جاهزة
//   provider.overrideWith((ref) => ...) ← دالة إنشاء جديدة

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '07_dependency_injection.dart';

// ------------------------------------------------------------
// تنفيذ وهمي (Fake) للـ Repository — نفس الواجهة، نتيجة ثابتة وفورية
// ------------------------------------------------------------
class FakeWeatherRepository implements WeatherRepository {
  @override
  Future<int> temperature(String city) async => 99;
}

// ------------------------------------------------------------
// Provider "بدون قيمة": يجب أن يُعطى قيمة عبر override وإلا يرمي خطأ
// نمط مشهور لتمرير بيانات العنصر الحالي داخل قائمة بدون constructors
// ------------------------------------------------------------
final currentCityProvider = Provider<String>(
  (ref) => throw UnimplementedError('يجب عمل override لـ currentCityProvider'),
);

class OverridesScreen extends StatelessWidget {
  const OverridesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 8: Overrides')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ------------------------------------------------------------
          // 1) بدون override: البيانات من ApiWeatherRepository (تأخير 600ms)
          // ------------------------------------------------------------
          const _Title('بدون override ← الـ API الحقيقي'),
          const CityTemperatureTile(city: 'الرياض'),

          // ------------------------------------------------------------
          // 2) ProviderScope متداخل: نستبدل الـ Repository لهذا الجزء فقط
          //    نعمل override أيضاً لـ temperatureProvider لأنه يقرأ الـ Repository
          //    فيُنشأ من جديد داخل هذا النطاق ويرى الـ Fake
          // ------------------------------------------------------------
          const _Title('مع override ← FakeWeatherRepository (دائماً 99°)'),
          ProviderScope(
            overrides: [
              weatherRepositoryProvider.overrideWithValue(
                FakeWeatherRepository(),
              ),
              temperatureProvider.overrideWith(
                (ref, city) =>
                    ref.watch(weatherRepositoryProvider).temperature(city),
              ),
            ],
            child: const CityTemperatureTile(city: 'الرياض'),
          ),

          // ------------------------------------------------------------
          // 3) قيمة مختلفة لكل عنصر في القائمة عبر currentCityProvider
          // ------------------------------------------------------------
          const _Title('override لكل عنصر ← currentCityProvider'),
          for (final city in cities)
            ProviderScope(
              overrides: [currentCityProvider.overrideWithValue(city)],
              child: const _CityChip(), // لاحظ: لا نمرّر city للـ constructor
            ),
        ],
      ),
    );
  }
}

class _CityChip extends ConsumerWidget {
  const _CityChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(currentCityProvider);
    return ListTile(dense: true, leading: const Icon(Icons.place), title: Text(city));
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) لاستبدال Notifier في اختبار أو عرض تجريبي:
//      counterProvider.overrideWith(() => FakeCounterNotifier())
//    حيث FakeCounterNotifier يرث من CounterNotifier ويغيّر build().
//
// 2) وضع "العرض التجريبي" (Demo mode) للمبيعات أو لمراجعة المتجر:
//    نفس التطبيق + override لكل الـ repositories ببيانات وهمية ← بدون خادم.
//
// 3) ProviderContainer.test() في الاختبارات يتخلّص من الحاوية تلقائياً
//    فلا تحتاج addTearDown(container.dispose).
//
// 4) نمط currentXProvider (في هذا الملف) يوفّر تمرير نفس الباراميتر
//    عبر 4–5 Widgets متداخلة — مفيد جداً في عناصر القوائم المعقدة.
