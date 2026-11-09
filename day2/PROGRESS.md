# Day 2 — progress checklist

Topic: go_router + Dio (+ Dart: Records, Sealed, freezed). Rules: ../WORKSHOP_CONVENTIONS.md
Project: day2_examples (package day2_examples). Resume: find the first unticked box.

## Setup
- [x] flutter create + analysis_options + packages (go_router, dio, freezed, json_serializable, build_runner, flutter_riverpod)
- [x] main.dart (RTL MaterialApp.router + go_router-driven lessons menu) (router: appRouterProvider in main.dart)

## Lessons (tick = file written AND `flutter analyze` clean)
- [x] 1 (Dart) Records + Sealed classes & pattern matching — lib/lessons/01_records_sealed.dart
- [x] 2 (Dart) freezed + json_serializable: JSON → models — lib/lessons/02_freezed_json.dart
- [x] 3 (go_router) setup + passing parameters (path/query/extra) — lib/lessons/03_go_router_basics.dart
- [x] 4 (go_router) nested routes + StatefulShellRoute — lib/lessons/04_shell_route.dart
- [x] 5 (go_router) redirect guards + deep links — lib/lessons/05_guards_deep_links.dart (+ AndroidManifest / Info.plist)
- [x] 6 (Dio) setup + interceptors — lib/lessons/06_dio_interceptors.dart
- [x] 7 (Dio) error handling: DioException → sealed AppFailure + AsyncValue — lib/lessons/07_error_handling.dart
- [x] 8 (Dio) access + refresh tokens (dummyjson) — lib/lessons/08_auth_tokens.dart
- [x] 9 (Dio) pagination / infinite scroll — lib/lessons/09_pagination.dart

## Verification (code)
- [x] build_runner build -d
- [x] flutter analyze → No issues found
- [x] real tests pass (test/)
- [x] temporary smoke test (all lessons from the menu) passed, then deleted
- [x] README.md

## Deck
- [x] presentation.html copied from day1, slides replaced (title, agenda, lessons 1–9, recap, exercises, Day 3 preview)
- [x] animated diagrams: nav stack vs ShellRoute branches, interceptor chain, 401 → refresh → retry
- [x] ?check audit = 0 errors / 0 overflow / 0 paren failures
- [x] excerpt check (every code line exists in its source file)
- [x] screenshots (?static, 1920×1080) in scratchpad/day2/

## Notes
- Packages: go_router 18.1.3, dio 5.11.1, flutter_riverpod 3.5.0, freezed 4.0.3 / freezed_annotation 3.1.0, json_serializable 6.15.2 / json_annotation 4.12.0, build_runner 2.17.1
- Router lives in main.dart (appRouterProvider); lessons 3/4/5 export their routes. Menu uses context.go('/lN').
- Tests: models_test (L2), error_mapping_test (L7), auth_interceptor_test (L8, fake adapter), router_test (L5 guard + deep links). 21/21 incl. smoke.
- Live check vs dummyjson (temporary test, deleted): all 6 error scenarios map correctly, pagination 20→40 of 194, 3 parallel 401 → 1 refresh, broken refresh → logout.
- Deep links: intent-filter (day2://open) in AndroidManifest + CFBundleURLTypes in Info.plist; not tested on a real device/emulator.
- Smoke test file test/smoke_test.dart is kept until the final re-run, then deleted.
- Deck: 36 slides; ?check = 0 errors / 0 overflow / 0 colOverflow / 0 boxOverflow / 0 paren failures (21 checked, 12 skipped pairs); all code ≥24px.
- Excerpt check: 363 code lines, 0 not found (script: scratchpad/day2/excerpts.py).
- Final: analyze clean; 12 real tests pass; smoke (9 lessons) passed then deleted.
- Review round 1 (Haiku): fixed bidi (SVG next(), bdi on code tokens), slide 28 bullet + saveTokens pill, kicker 28px / footer 26px, ?check font-size floor (0 hits), slide 29 chip, slide 10 tip arrow, slide 8 title.
- Review round 2: slide 15 inactive text no longer uses opacity (#9FB3C8 on card 6.1:1, tabs #C9D6E3 11.1:1, lost card #FFC2CC 8.7:1); audit still all-0.
