# Day 3 — progress (Storage/DB + Architecture + Dart: Generics, Streams)

Rules: ../WORKSHOP_CONVENTIONS.md · heavy commands under `flock /tmp/claude-1000/flutter-heavy.lock`.
Tick a lesson only after its file is written AND `flutter analyze` is clean.

## Setup
(drift web files web/sqlite3.wasm + web/drift_worker.js downloaded from sqlite3-3.5.2 / drift-2.35.3 releases)
- [x] flutter create day3_examples (android,ios,web,linux, --empty) + analysis_options like Day 1
- [x] packages added (riverpod, shared_preferences, flutter_secure_storage, path_provider, drift, drift_flutter, dio; dev: build_runner, drift_dev)
- [x] main.dart (ProviderScope + prefs override after async init + RTL + lessons menu)

## Lessons
- [x] 1 (Dart) Generics — lib/lessons/01_generics.dart
- [x] 2 (Dart) Streams و StreamController — lib/lessons/02_streams.dart
- [x] 3 shared_preferences + flutter_secure_storage — lib/lessons/03_prefs_secure_storage.dart
- [x] 4 الملفات مع path_provider — lib/lessons/04_files_path_provider.dart
- [x] 5 SQL + Drift: الجداول والاستعلامات (CRUD, relation, JOIN) — lib/lessons/05_sql_drift_basics.dart
- [x] 6 Drift: migrations + watch() — lib/lessons/06_drift_migrations_watch.dart
- [x] 7 تخزين بيانات الـ API محلياً (stale-while-revalidate) — lib/lessons/07_api_cache.dart
- [x] 8 Clean Architecture + Repository + feature-first — lib/lessons/08_clean_architecture/
- [x] 9 Offline-first و المزامنة (outbox) — lib/lessons/09_offline_first_sync.dart

## Verification (code)
- [x] build_runner build
- [x] flutter analyze → No issues found
- [x] real tests pass (18 tests in 6 files)
- [x] smoke test (all lessons, 4 s, no exception) → passed (9/9, with content probes) and deleted
- [x] README.md

## Deck
- [x] copy engine from day1/presentation.html
- [x] slides: title, agenda, lessons 1–9 (opener, code, tips), diagrams (storage map, clean layers, sync flow)
- [x] recap, exercises, Day 4 preview
- [x] ?check audit = 0 errors / 0 overflow / 0 paren failures (36 slides, all code ≥24px)
- [x] excerpt check (36 blocks, 264 lines, 0 mismatches)
- [x] screenshots (?static 1920×1080): slides 1, 2, 11, 13, 14, 19, 28, 31, 36 in the scratchpad day3/ folder

Status: DONE — review round 1 fixed (font-size + bidi checks added to ?check: 0 hits); awaiting parent image review.
