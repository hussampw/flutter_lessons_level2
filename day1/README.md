# اليوم الأول — Riverpod (+ درس Dart قصير: Futures و async/await)

- العرض التقديمي: `presentation.html` (افتحه في المتصفح، F للشاشة الكاملة، O لعرض كل الشرائح)
- الأمثلة: `day1_examples/` — تطبيق Flutter واحد (Flutter 3.47.9 / Dart 3.13.7)

**الربط:** رقم الدرس واحد في كل مكان: شرائح «الدرس 3» في العرض = «الدرس 3» في قائمة التطبيق = الملف `lib/lessons/03_provider_types.dart`.
كل ملف ينتهي بقسم **💡 حيل الدرس**.

## التجهيز (مرة واحدة)

```bash
cd day1_examples
flutter pub get
dart run build_runner build -d   # توليد ملفات @riverpod (الدرس 4)
flutter run                      # أو -d chrome / -d linux
```

## الدروس

| # | النوع | الموضوع | الملف |
|---|---|---|---|
| 1 | Dart | Futures و async/await + FutureBuilder | `lib/lessons/01_futures_async.dart` |
| 2 | Riverpod | الأساسيات: ProviderScope و ref (watch / read / listen) | `lib/lessons/02_riverpod_basics.dart` |
| 3 | Riverpod | أنواع الـ Providers | `lib/lessons/03_provider_types.dart` |
| 4 | Riverpod | توليد الكود `@riverpod` | `lib/lessons/04_riverpod_codegen.dart` |
| 5 | Riverpod | AsyncValue: loading / data / error | `lib/lessons/05_async_value.dart` |
| 6 | Riverpod | family و autoDispose | `lib/lessons/06_family_autodispose.dart` |
| 7 | Riverpod | حقن الاعتماديات | `lib/lessons/07_dependency_injection.dart` |
| 8 | Riverpod | Overrides — والاختبار: `flutter test` | `lib/lessons/08_overrides.dart` |
