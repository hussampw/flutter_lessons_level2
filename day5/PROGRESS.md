# Day 5 — PROGRESS (Performance + Native + Security + Release + Dart: Isolates)

Rules: ../WORKSHOP_CONVENTIONS.md · project: day5_examples · tick a lesson only after its file is written AND `flutter analyze` is clean.

## Setup
- [x] flutter create day5_examples (android, ios, web, linux, --empty)
- [x] analysis_options.yaml like Day 1
- [x] packages added (flutter_riverpod 3.5.0, dio 5.11.1, crypto 3.0.8, permission_handler 13.0.2, image_picker 1.2.4, geolocator 14.1.2, flutter_local_notifications 23.0.0, firebase_core 5.1.0, firebase_messaging 17.0.1, firebase_crashlytics 6.0.1; dev: pigeon 29.1.1)
- [x] main.dart menu (ProviderScope + RTL + 9 lessons)

## Lessons
- [x] 1 (Dart) Isolates — Isolate.run / compute / spawn + big JSON — lib/lessons/01_isolates.dart
- [x] 2 DevTools + reducing rebuilds — lib/lessons/02_rebuilds_devtools.dart
- [x] 3 Long lists + images — lib/lessons/03_lists_images.dart
- [x] 4 Platform Channels + Pigeon — lib/lessons/04_platform_channels.dart (+ MainActivity.kt, AppDelegate.swift, pigeons/device_api.dart → 04_device_api.g.dart / DeviceApi.g.kt / DeviceApi.g.swift, pbxproj entry)
- [x] 5 Permissions + camera & location — lib/lessons/05_permissions_camera_location.dart (+ manifest / Info.plist)
- [x] 6 Notifications (local + FCM guarded) — lib/lessons/06_notifications.dart + 06_fcm_service.dart (+ manifest receivers, desugaring)
- [x] 7 Security — lib/lessons/07_security.dart + 07_ssl_pinning.dart (+ config/dev.json, config/prod.example.json)
- [x] 8 Flavors + signing — lib/lessons/08_flavors_signing.dart (+ build.gradle.kts flavors/signing, key.properties.example, iOS dev/prod schemes, default-flavor)
- [x] 9 Publishing + CI/CD + crash reporting — lib/lessons/09_release.dart + 09_crash_reporting.dart (+ .github/workflows/flutter_ci.yml)

## Verification (code)
- [x] flutter analyze clean
- [x] real tests pass (8 tests: isolates, platform channel, flavor config)
- [x] smoke test (all 9 lessons open, 4 s, no exception, at 432dp and 360dp width) — then deleted
- [x] linux / web build (linux debug built with default flavor dev + all 9 screens opened in the real Linux app, 0 errors; web release built)
- [x] android debug apk --flavor dev built (assembleDevDebug, compileSdk 37, 442 s)

## Deck
- [x] presentation.html copied from day1 (engine unchanged; added tag + diagram CSS), 36 slides — generator in scratchpad deckgen/
- [x] animated diagrams: isolate frames (s5) · channel round trip (s13) · release pipeline (s30)
- [x] ?check audit: 0 errors / 0 overflow / 0 boxOverflow / 0 colOverflow / 0 paren fail (8 checked); all code ≥24px
- [x] excerpt check: every code line found in its source file
- [x] screenshots (?static 1920×1080): scratchpad/day5/slide_{01,02,05,06,13,14,28,30,36}_*.png
- [x] README.md

## Review round 1 (Haiku, 7/9 approved → fixes)
- [x] s28 title: whole Latin phrase in one `<bdi dir="ltr">`; Latin+":"+isolate patterns rewritten (s2 key, s7, s27 mini, s31, s34)
- [x] code-window file labels: 24px, cut from the start with "…" so they never reach the window dots
- [x] 24px floor: new smallText check in ?check (own text + ::before/::after) → 0 hits; slide-1 pills/hint, agenda cards (title+file stacked), s13 edge labels, s30 sublabels, s36 day cards raised
- [x] s1 subtitle bracket group kept together (nowrap); s2 card 5 title on one line
- [x] audit 0/0/0/0 + paren 0 + smallText 0; excerpt check clean; screenshots 1,2,13,14,28,30,36 re-shot
