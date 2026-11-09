# اليوم الثالث — التخزين المحلي وقواعد البيانات + المعمارية (+ درسا Dart قصيران: Generics و Streams)

- العرض التقديمي: `presentation.html` (افتحه في المتصفح، F للشاشة الكاملة، O لعرض كل الشرائح)
- الأمثلة: `day3_examples/` — تطبيق Flutter واحد (Flutter 3.47.9 / Dart 3.13.7)

**الربط:** رقم الدرس واحد في كل مكان: شرائح «الدرس 5» في العرض = «الدرس 5» في قائمة التطبيق = الملف `lib/lessons/05_sql_drift_basics.dart`.
كل ملف درس ينتهي بقسم **💡 حيل الدرس**.

## التجهيز (مرة واحدة)

```bash
cd day3_examples
flutter pub get
dart run build_runner build      # توليد ملفات Drift (*.g.dart) — الدروس 5 · 6 · 7 · 8 · 9
flutter run                      # أو -d chrome / -d linux
flutter test                     # اختبارات الدروس 2 · 3 · 5 · 6 · 8 · 9
```

ملاحظات المنصات:
- **SQLite (Drift):** الحزمة `sqlite3` تجهّز مكتبة SQLite تلقائياً أثناء البناء (build hooks) على Android / iOS / Linux — أول بناء يحتاج إنترنت.
- **الويب:** Drift يعمل بـ WebAssembly عبر الملفين `web/sqlite3.wasm` و `web/drift_worker.js` (موجودان في المشروع). الدرس 4 (الملفات) غير متاح على الويب ويعرض شرحاً بدلاً منه.
- **Linux:** `flutter_secure_storage` يحتاج libsecret: `sudo apt install libsecret-1-dev` (وللتشغيل: keyring مفتوح).
- الشبكة: الدروس 3 · 4 · 7 · 8 تستخدم `https://dummyjson.com` وتعرض رسالة ودّية بدون إنترنت، وفيها مفتاح «محاكاة عدم الاتصال».

## الدروس

| # | النوع | الموضوع | الملف |
|---|---|---|---|
| 1 | Dart | Generics: `Box<T>` · القيود `extends` · `Repository<T>` · `Result<T>` · Widget عام | `lib/lessons/01_generics.dart` (+ `lib/shared/result.dart`) |
| 2 | Dart | Streams و StreamController: async* · التحويلات · شات حي بمستمعَين · pause/resume · خطأ · close | `lib/lessons/02_streams.dart` |
| 3 | التخزين | الإعدادات والتخزين الآمن: shared_preferences + flutter_secure_storage (+ override في main) | `lib/lessons/03_prefs_secure_storage.dart` |
| 4 | التخزين | الملفات مع path_provider: المجلدات · ملف JSON · كاش صور | `lib/lessons/04_files_path_provider.dart` |
| 5 | قواعد البيانات | SQL و Drift: الجداول · CRUD · علاقة · JOIN (الـ SQL بجانب Drift) | `lib/lessons/05_sql_drift_basics.dart` (+ `lib/shared/database_connection.dart`) |
| 6 | قواعد البيانات | Drift: Migrations و `watch()` | `lib/lessons/06_drift_migrations_watch.dart` |
| 7 | قواعد البيانات | كاش بيانات الـ API: dummyjson ← Drift · stale-while-revalidate | `lib/lessons/07_api_cache.dart` |
| 8 | المعمارية | Clean Architecture + Repository (API + DB) + feature-first | `lib/lessons/08_clean_architecture/` (domain · data · presentation) |
| 9 | المعمارية | Offline-first والمزامنة: Outbox · sync · Last-Write-Wins | `lib/lessons/09_offline_first_sync.dart` |

## الاختبارات

| الملف | الدرس | ماذا يختبر |
|---|---|---|
| `test/streams_test.dart` | 2 | `emitsInOrder` · مستمعان · خطأ · إغلاق |
| `test/settings_test.dart` | 3 | shared_preferences في الذاكرة · الإعداد يبقى بعد «إعادة التشغيل» |
| `test/shop_database_test.dart` | 5 | CRUD · INNER/LEFT JOIN · المفتاح الأجنبي (`NativeDatabase.memory()`) |
| `test/notes_migration_test.dart` | 6 | ترحيل ملف بالإصدار 1 إلى 2 · `watch()` |
| `test/quotes_repository_test.dart` | 8 | Repository مع Remote وهمي + Drift في الذاكرة |
| `test/offline_sync_test.dart` | 9 | الطابور · المزامنة · قاعدة التعارض · pull |
