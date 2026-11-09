# اليوم الرابع — الاختبارات + واجهات متقدمة (+ درس Dart قصير: Extension methods)

- العرض التقديمي: `presentation.html` (افتحه في المتصفح، F للشاشة الكاملة، O لعرض كل الشرائح)
- الأمثلة: `day4_examples/` — تطبيق Flutter واحد (Flutter 3.47.9 / Dart 3.13.7)

**الربط:** رقم الدرس واحد في كل مكان: شرائح «الدرس 6» في العرض = «الدرس 6» في قائمة التطبيق = الملف `lib/lessons/06_slivers.dart`.
كل ملف ينتهي بقسم **💡 حيل الدرس**.

## التجهيز (مرة واحدة)

```bash
cd day4_examples
flutter pub get                  # يولّد ملفات الترجمة lib/l10n/app_localizations*.dart (الدرس 9)
flutter run                      # أو -d chrome / -d linux
```

## الاختبارات

```bash
flutter test                                   # كل اختبارات test/ (unit + provider + widget)
flutter test test/02_cart_test.dart            # ملف واحد
flutter test --plain-name 'SAVE10'             # اختبار واحد بالاسم
flutter devices                                # الأجهزة المتصلة
flutter test integration_test                  # integration tests على الجهاز المتصل
flutter test integration_test -d linux         # بدون هاتف: تطبيق سطح المكتب
```

| الملف | النوع | الدرس |
|---|---|---|
| `test/02_cart_test.dart` | Unit — منطق السلة | 2 |
| `test/02_product_repository_test.dart` | Unit + mocktail | 2 |
| `test/03_providers_test.dart` | Riverpod — `ProviderContainer.test` | 3 |
| `test/03_shop_widget_test.dart` | Widget test | 3 |
| `integration_test/app_test.dart` | Integration — التطبيق كاملاً | 4 |
| `test/09_l10n_a11y_test.dart` | الترجمة + إرشادات الوصول | 9 |

## الدروس

| # | النوع | الموضوع | الملف |
|---|---|---|---|
| 1 | Dart | Extension methods و Extension types + امتدادات BuildContext | `lib/lessons/01_extension_methods.dart` |
| 2 | Testing | Unit tests و mocktail | `lib/lessons/02_unit_tests.dart` |
| 3 | Testing | اختبار Providers و Widgets | `lib/lessons/03_provider_widget_tests.dart` |
| 4 | Testing | Integration tests | `lib/lessons/04_integration_tests.dart` |
| 5 | UI | الأنيميشن: Implicit و AnimationController و Staggered | `lib/lessons/05_animations.dart` |
| 6 | UI | Slivers: CustomScrollView و SliverAppBar | `lib/lessons/06_slivers.dart` |
| 7 | UI | CustomPainter | `lib/lessons/07_custom_painter.dart` |
| 8 | UI | Responsive و Theming (فاتح / داكن) | `lib/lessons/08_responsive_theming.dart` |
| 9 | UI | الترجمة (intl و ARB) و RTL و إمكانية الوصول | `lib/lessons/09_l10n_rtl_a11y.dart` |

ملفات الترجمة: `l10n.yaml` و `lib/l10n/app_en.arb` و `lib/l10n/app_ar.arb`.
