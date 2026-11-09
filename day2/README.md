# اليوم الثاني — التنقّل مع go_router والشبكة مع Dio (+ درسا Dart قصيران: Records و Sealed classes، و freezed)

- العرض التقديمي: `presentation.html` (افتحه في المتصفح، F للشاشة الكاملة، O لعرض كل الشرائح)
- الأمثلة: `day2_examples/` — تطبيق Flutter واحد (Flutter 3.47.9 / Dart 3.13.7)

**الربط:** رقم الدرس واحد في كل مكان: شرائح «الدرس 3» في العرض = «الدرس 3» في قائمة التطبيق = الملف `lib/lessons/03_go_router_basics.dart`.
كل ملف ينتهي بقسم **💡 حيل الدرس**. قائمة الدروس نفسها تعمل بـ go_router: كل درس رابط (`/l1` … `/l9`).

## التجهيز (مرة واحدة)

```bash
cd day2_examples
flutter pub get
dart run build_runner build -d   # توليد ملفات freezed و json_serializable (الدرسان 2 و 9)
flutter run                      # أو -d chrome / -d linux
flutter test                     # اختبارات الدروس 2 و 5 و 7 و 8
```

دروس الشبكة (6–9) تستخدم `https://dummyjson.com` وتحتاج إنترنت؛ بدونه تظهر رسالة خطأ واضحة بالعربية.
حساب الدخول التجريبي (الدرس 8): `emilys` / `emilyspass`.

## الدروس

| # | النوع | الموضوع | الملف |
|---|---|---|---|
| 1 | Dart | Records و Sealed classes و Pattern matching | `lib/lessons/01_records_sealed.dart` |
| 2 | Dart | freezed + json_serializable: من JSON إلى Models | `lib/lessons/02_freezed_json.dart` |
| 3 | go_router | الإعداد + الباراميترات (path / query / extra) و go مقابل push | `lib/lessons/03_go_router_basics.dart` |
| 4 | go_router | المسارات المتداخلة و StatefulShellRoute (شريط سفلي يحفظ حالته) | `lib/lessons/04_shell_route.dart` |
| 5 | go_router | حماية المسارات (redirect) و Deep links | `lib/lessons/05_guards_deep_links.dart` |
| 6 | Dio | الإعداد و Interceptors (headers، تسجيل، CancelToken) | `lib/lessons/06_dio_interceptors.dart` |
| 7 | Dio | معالجة الأخطاء: DioException ← sealed AppFailure ← AsyncValue | `lib/lessons/07_error_handling.dart` |
| 8 | Dio | Access و Refresh tokens: ‏401 ← refresh ← إعادة الطلب | `lib/lessons/08_auth_tokens.dart` |
| 9 | Dio | Pagination: تمرير لا نهائي مع Riverpod | `lib/lessons/09_pagination.dart` |

إعداد الـ router (الدروس 3–5) موجود في `lib/main.dart` (`appRouterProvider`).

## تجربة Deep links (الدرس 5)

الإعداد مُضاف فعلاً: `android/app/src/main/AndroidManifest.xml` (intent-filter للمخطط `day2://open`) و `ios/Runner/Info.plist` (`CFBundleURLTypes`).

```bash
adb shell am start -a android.intent.action.VIEW -d "day2://open/l5/products/7?ref=sms"
xcrun simctl openurl booted "day2://open/l5/products/7?ref=sms"
```

وعلى Web افتح `http://localhost:PORT/#/l5/products/7` مباشرة. داخل التطبيق توجد أزرار «محاكاة Deep link» ترسل نفس رسالة النظام.

## الاختبارات

| الملف | الدرس | ماذا يختبر |
|---|---|---|
| `test/models_test.dart` | 2 | fromJson / toJson / == و JSON ناقص |
| `test/router_test.dart` | 5 | الحارس كدالة عادية + Deep link حقيقي عبر قناة flutter/navigation |
| `test/error_mapping_test.dart` | 7 | تحويل DioException إلى AppFailure |
| `test/auth_interceptor_test.dart` | 8 | ‏401 ← refresh ← retry بخادم وهمي، وتجديد واحد لثلاثة طلبات |
