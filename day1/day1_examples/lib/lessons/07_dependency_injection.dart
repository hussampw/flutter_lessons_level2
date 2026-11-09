// ============================================================
// الدرس 7 (Riverpod): حقن الاعتماديات (Dependency Injection)
// في التطبيق: القائمة ← الدرس 7  ·  في العرض: شرائح الدرس 7
// ============================================================
//
// المشكلة: لو كتبنا داخل الشاشة  final repo = ApiWeatherRepository();
// صارت الشاشة مرتبطة بتنفيذ محدد ← صعب الاختبار وصعب التبديل.
//
// الحل مع Riverpod:
//   1) نعرّف واجهة (abstract interface)
//   2) نوفّر التنفيذ عبر Provider
//   3) كل من يحتاجه يقرأه بـ ref.watch
// النتيجة: Riverpod هو "حاوية الاعتماديات" — بدون get_it وبدون singletons.
// وفي الدرس 8 نبدّل التنفيذ بسطر واحد (override).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ------------------------------------------------------------
// الطبقة 1: الإعدادات
// ------------------------------------------------------------
class ApiConfig {
  const ApiConfig({required this.baseUrl, required this.apiKey});
  final String baseUrl;
  final String apiKey;
}

final apiConfigProvider = Provider<ApiConfig>(
  (ref) => const ApiConfig(
    baseUrl: 'https://api.weather.example',
    apiKey: 'demo-key',
  ),
);

// ------------------------------------------------------------
// الطبقة 2: الواجهة + التنفيذ الحقيقي
// ------------------------------------------------------------
abstract interface class WeatherRepository {
  Future<int> temperature(String city);
}

class ApiWeatherRepository implements WeatherRepository {
  // الاعتمادية تصل عبر الـ constructor (Constructor Injection)
  ApiWeatherRepository(this.config);
  final ApiConfig config;

  @override
  Future<int> temperature(String city) async {
    // في الواقع: dio.get('${config.baseUrl}/weather?city=$city')
    await Future.delayed(const Duration(milliseconds: 600));
    return 20 + city.length; // رقم وهمي
  }
}

// Provider للـ Repository: يقرأ الإعدادات من provider آخر
final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => ApiWeatherRepository(ref.watch(apiConfigProvider)),
);

// ------------------------------------------------------------
// الطبقة 3: المنطق — يعتمد على الواجهة فقط وليس التنفيذ
// ------------------------------------------------------------
final temperatureProvider = FutureProvider.family<int, String>(
  (ref, city) => ref.watch(weatherRepositoryProvider).temperature(city),
);

// ------------------------------------------------------------
// الطبقة 4: الواجهة — لا تعرف شيئاً عن API أو Dio
// ------------------------------------------------------------
const cities = ['الرياض', 'جدة', 'عمّان', 'القاهرة', 'دبي'];

class DependencyInjectionScreen extends StatelessWidget {
  const DependencyInjectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 7: Dependency Injection')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'ApiConfig ← WeatherRepository ← temperatureProvider ← الشاشة',
              textAlign: TextAlign.center,
            ),
          ),
          for (final city in cities) CityTemperatureTile(city: city),
        ],
      ),
    );
  }
}

class CityTemperatureTile extends ConsumerWidget {
  const CityTemperatureTile({super.key, required this.city});
  final String city;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temp = ref.watch(temperatureProvider(city));
    return ListTile(
      leading: const Icon(Icons.location_city),
      title: Text(city),
      trailing: switch (temp) {
        AsyncData(:final value) => Text('$value°'),
        AsyncError() => const Icon(Icons.error, color: Colors.red),
        _ => const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      },
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) كائنات تحتاج تهيئة async قبل تشغيل التطبيق (مثل SharedPreferences):
//      final prefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());
//      Future<void> main() async {
//        WidgetsFlutterBinding.ensureInitialized();
//        final prefs = await SharedPreferences.getInstance();
//        runApp(ProviderScope(
//          overrides: [prefsProvider.overrideWithValue(prefs)],
//          child: const App(),
//        ));
//      }
//    بعدها كل الـ providers تقرأ prefsProvider بشكل متزامن بدون await.
//
// 2) الشاشة تعتمد على الواجهة (WeatherRepository) وليس على التنفيذ
//    ← تبديل الـ API أو المكتبة لا يغيّر أي شاشة.
//
// 3) استخدم ref.watch (وليس ref.read) داخل provider لقراءة اعتمادياته،
//    فإذا تغيّرت الإعدادات يُعاد إنشاء الـ Repository تلقائياً.
