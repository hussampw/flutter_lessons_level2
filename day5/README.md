# اليوم الخامس — الأداء · التكامل مع المنصة · الأمان · النشر (+ درس Dart قصير: Isolates)

- العرض التقديمي: `presentation.html` (افتحه في المتصفح، F للشاشة الكاملة، O لعرض كل الشرائح)
- الأمثلة: `day5_examples/` — تطبيق Flutter واحد (Flutter 3.47.9 / Dart 3.13.7)

**الربط:** رقم الدرس واحد في كل مكان: شرائح «الدرس 4» في العرض = «الدرس 4» في قائمة التطبيق = الملف `lib/lessons/04_platform_channels.dart`.
كل ملف درس ينتهي بقسم **💡 حيل الدرس**.

## التجهيز (مرة واحدة)

```bash
cd day5_examples
flutter pub get
flutter run                                   # Android: flavor dev افتراضياً (default-flavor في pubspec.yaml)
flutter run -d linux                          # أو -d chrome
flutter run --dart-define-from-file=config/dev.json   # الدرس 7: المفاتيح وقت البناء
flutter test                                  # اختبارات الدروس 1 و 4 و 8
dart run pigeon --input pigeons/device_api.dart        # الدرس 4: إعادة توليد كود Pigeon
```

## الدروس

| # | النوع | الموضوع | الملف |
|---|---|---|---|
| 1 | Dart | Isolates: Isolate.run · compute · spawn · JSON ضخم | `lib/lessons/01_isolates.dart` |
| 2 | Performance | DevTools وإعادة البناء: const · تقسيم · select · RepaintBoundary | `lib/lessons/02_rebuilds_devtools.dart` |
| 3 | Performance | القوائم الطويلة والصور: builder · itemExtent · cacheWidth · precacheImage | `lib/lessons/03_lists_images.dart` |
| 4 | Native | Platform Channels و Pigeon (Kotlin + Swift) | `lib/lessons/04_platform_channels.dart` |
| 5 | Native | الصلاحيات والكاميرا والموقع | `lib/lessons/05_permissions_camera_location.dart` |
| 6 | Native | الإشعارات: محلية + FCM (محمي) | `lib/lessons/06_notifications.dart` + `06_fcm_service.dart` |
| 7 | Security | الأمان: SSL Pinning · Obfuscation · الأسرار · Root · التخزين الآمن | `lib/lessons/07_security.dart` + `07_ssl_pinning.dart` |
| 8 | Release | Flavors (dev / prod) والتوقيع | `lib/lessons/08_flavors_signing.dart` |
| 9 | Release | النشر و CI/CD وتقارير الأعطال | `lib/lessons/09_release.dart` + `09_crash_reporting.dart` |

## ملفات المنصة والإعداد (جولة الدروس 4–9)

| الملف | الدرس | ماذا فيه |
|---|---|---|
| `android/app/src/main/kotlin/com/workshop/day5_examples/MainActivity.kt` | 4، 7 | MethodChannel (البطارية + فحص Root) + تنفيذ Pigeon |
| `ios/Runner/AppDelegate.swift` | 4، 7 | نفس القناة في Swift + فحص Jailbreak + تنفيذ Pigeon |
| `pigeons/device_api.dart` ← `*.g.dart` / `DeviceApi.g.kt` / `DeviceApi.g.swift` | 4 | تعريف Pigeon والكود المولَّد |
| `android/app/src/main/AndroidManifest.xml` · `ios/Runner/Info.plist` | 5، 6 | الصلاحيات ونصوصها + receivers الإشعارات المجدولة |
| `config/dev.json` · `config/prod.example.json` | 7 | قيم `--dart-define-from-file` (prod.json في .gitignore) |
| `android/app/build.gradle.kts` · `android/key.properties.example` | 8 | productFlavors + signingConfigs (بدون مفاتيح حقيقية) |
| `ios/Runner.xcodeproj/xcshareddata/xcschemes/dev.xcscheme` و `prod.xcscheme` | 8 | Schemes لـ `--flavor` على iOS |
| `.github/workflows/flutter_ci.yml` | 9 | analyze + test + build apk/appbundle موقّع ومشوّش + artifacts |

## ملاحظات

- **Firebase (الدرسان 6 و 9):** المشروع بلا ملفات Firebase عمداً. الشاشات تعمل وتعرض رسالة عربية؛ بعد `flutterfire configure` يعمل نفس الكود (الخطوات في أعلى `06_fcm_service.dart` و `09_crash_reporting.dart`).
- **Android:** `compileSdk = 37` (تتطلبه flutter_local_notifications 23 و permission_handler_android 14) + desugaring.
- **على Linux / الويب:** الميزات الخاصة بالجوال (القنوات، الكاميرا، الموقع، Root) تعرض «هذا يعمل على Android و iOS» بدل الانهيار. الإشعارات المحلية تعمل على Linux.
