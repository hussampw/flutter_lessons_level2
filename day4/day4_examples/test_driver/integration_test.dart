// ============================================================
// الدرس 4 (Testing): مشغّل integration tests على الويب فقط (flutter drive)
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/app_test.dart -d chrome
// (يحتاج chromedriver يعمل على المنفذ 4444)
// ============================================================

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
