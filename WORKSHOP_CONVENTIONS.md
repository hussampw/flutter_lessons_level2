# Workshop conventions (Days 2–5 must match Day 1)

Root: `/mnt/hussam/flutter/lessones/level2` · SDK: Flutter 3.47.9 / Dart 3.13.7 (do NOT upgrade the SDK).
Reference implementation: `day1/` — read it before starting: `day1/day1_examples/lib/main.dart`, `day1/day1_examples/lib/lessons/01_futures_async.dart` (pattern for a Dart lesson as a Flutter screen with an on-screen console), any Riverpod lesson file, `day1/README.md`, `day1/presentation.html`.

## Audience & tone
Arab developers who already know basic Flutter. All code comments, UI text, README and slides in Arabic; keep technical terms in English (Future, Provider, Dio, Interceptor…). The user found 15 topics in one day too much: **7–9 lessons per day**, group curriculum topics into a lesson when they belong together. Each lesson should be teachable in ~25–40 minutes.

## Each day = its main module(s) + ONE small Dart part
The small Dart lesson(s) come first (lesson 1, or 1–2), like Day 1. Console versions of these Dart lessons already exist in `_later/dart_bin/` (read-only) — convert them to Flutter screens (no `dart run`, no `bin/`).

## Project layout (per day)
```
dayN/
  README.md                    # same format as day1/README.md: setup + lesson table (#, type, topic, file)
  PROGRESS.md                  # your checklist — create FIRST, tick after each lesson is verified
  presentation.html            # the deck
  dayN_examples/               # flutter create --org com.workshop --project-name dayN_examples --platforms android,ios,web,linux --empty
    lib/main.dart              # ProviderScope + RTL MaterialApp + lessons menu (copy Day 1's pattern: number badge, «الدرس N: title», kind · subtitle)
    lib/lessons/NN_name.dart   # one file (or a small folder lib/lessons/NN_name/) per lesson
    test/ …                    # tests where the topic needs them
```
- `analysis_options.yaml`: same as Day 1 (exclude platform dirs; `avoid_print: false`, `file_names: false`).
- State management in examples: Riverpod 3 (taught on Day 1). Add packages with `flutter pub add` (latest compatible).
- Every lesson file starts with the header:
  ```
  // ============================================================
  // الدرس N (Kind): title
  // في التطبيق: القائمة ← الدرس N  ·  في العرض: شرائح الدرس N
  // ============================================================
  ```
  and ends with a `// 💡 حيل الدرس` block of 3–5 practical, correct tips (with tiny snippets where useful). Verify every API you mention in a tip exists in the installed package version (grep `~/.pub-cache/hosted/pub.dev/<pkg>-<ver>/lib`).
- **Linking rule:** lesson number is identical in the deck («الدرس N»), in the app menu («الدرس N: …»), in the screen's AppBar title, and in the file prefix `NN_`.
- Screens must not crash anywhere `flutter test` can open them: code that calls plugins (camera, location, notifications, platform channels, secure storage…) must catch `MissingPluginException` / unsupported-platform errors and show an Arabic explanation instead of crashing. Network lessons use `https://dummyjson.com` (has `/auth/login`, `/auth/refresh`, `/auth/me`, `/products?limit=&skip=`; documented demo user `emilys` / `emilyspass`) and must show a friendly error when offline.

## Verification (code)
1. `dart run build_runner build -d` if codegen is used.
2. `flutter analyze` → **No issues found**.
3. Real tests you wrote → pass.
4. A temporary smoke widget test that opens every lesson from the menu (find the tile by `find.textContaining('الدرس N:')` + `scrollUntilVisible`), pumps ~4 s and asserts `tester.takeException()` is null — then delete it.

**Machine limits:** other day-builders run in parallel. Wrap every heavy command in a shared lock so only one runs at a time:
`flock /tmp/claude-1000/flutter-heavy.lock <command>` — for `flutter pub get/add`, `dart run build_runner …`, `flutter analyze`, `flutter test`, and headless Chrome screenshot batches. Never run `flutter upgrade`, never touch `~/development/flutter`.

## Deck (`dayN/presentation.html`)
- Start from a copy of `day1/presentation.html` and keep its engine unchanged: CSS tokens/identity, 16:9 stage scaling, transitions + stagger, inline Dart highlighter (with the bidi isolation of Arabic comments and the `// N)` handling), code auto-fit, run bars, `<bdi>` step labels, amber tips slides, chrome auto-hide, O overview, hash navigation, `?static` and `?check` audit (including the box-overflow and parenthesis checks). Replace only the slides and day-specific text.
- Fonts are local: keep `<link href="../assets/fonts/fonts.css" rel="stylesheet">` (no Google Fonts URLs).
- ≈30–36 slides: title (اليوم N), agenda (same numbers/titles as the app menu; mention `flutter run` once), per lesson: opener with «الدرس N · title · tag» → concept/code slides (excerpts 6–15 lines taken from the lesson files) → one «💡 حيل الدرس N» slide; run bar on the last content slide of each lesson: «▶ في التطبيق: الدرس N» + file chip. At least 2–3 animated diagrams that teach the day's key mechanisms. Recap, 4–5 exercises (each names its lesson), and a preview of the next day (Day 5: a workshop closing slide instead).
- Readability floor: ≥24px for anything the audience must read (code 24–27px via auto-fit is accepted).
- Verify: `?check` audit on all slides = 0 errors / 0 overflow of every kind / 0 parenthesis failures; an excerpt check (every code line on a slide exists in, or is a faithful trim of, its source file); screenshots with `?static` at 1920×1080 into the scratchpad folder you are given (title, agenda, two code slides, one diagram, one tips slide, closing). Do not critique screenshots yourself — the parent runs a separate image review.

## Don't
- Don't modify `day1/`, other days' folders, `_later/`, `assets/`, or this file.
- Don't create files outside your `dayN/` folder (except temp files in your scratchpad folder).
