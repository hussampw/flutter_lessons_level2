// ============================================================
// الدرس 4 (Native): ملف تعريف Pigeon — "العقد" بين Dart و Kotlin و Swift
// في التطبيق: القائمة ← الدرس 4  ·  في العرض: شرائح الدرس 4
// ============================================================
//
// هذا الملف لا يُستخدم في التطبيق مباشرة (ليس داخل lib/).
// نكتب فيه الواجهة مرة واحدة بلغة Dart، ثم نولّد الكود للمنصات:
//
//   dart run pigeon --input pigeons/device_api.dart
//
// الناتج (لا تعدّله يدوياً — أعد التوليد بعد أي تغيير هنا):
//   lib/lessons/04_device_api.g.dart                                   ← Dart
//   android/app/src/main/kotlin/com/workshop/day5_examples/DeviceApi.g.kt ← Kotlin
//   ios/Runner/DeviceApi.g.swift                                       ← Swift

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/lessons/04_device_api.g.dart',
    kotlinOut:
        'android/app/src/main/kotlin/com/workshop/day5_examples/DeviceApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.workshop.day5_examples'),
    swiftOut: 'ios/Runner/DeviceApi.g.swift',
    dartPackageName: 'day5_examples',
  ),
)
// ------------------------------------------------------------
// نموذج البيانات: يُولَّد كـ class في Dart و data class في Kotlin و struct في Swift
// ------------------------------------------------------------
class DeviceInfo {
  DeviceInfo({
    required this.model,
    required this.osVersion,
    required this.batteryLevel,
  });

  String model;
  String osVersion;
  int batteryLevel; // int في Dart = Long في Kotlin = Int64 في Swift
}

// ------------------------------------------------------------
// @HostApi: دوال تنفّذها المنصة (Kotlin / Swift) ويستدعيها Dart
// (والعكس @FlutterApi: دوال في Dart تستدعيها المنصة)
// ------------------------------------------------------------
@HostApi()
abstract class DeviceHostApi {
  // متزامنة في المنصة، لكنها في Dart تعيد Future<DeviceInfo>
  DeviceInfo getDeviceInfo();

  // @async: المنصة ترد لاحقاً (callback في Kotlin / completion في Swift)
  @async
  String greet(String name);
}
