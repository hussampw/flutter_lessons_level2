// الدرس 8: إعدادات كل flavor
import 'package:day5_examples/lessons/08_flavors_signing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prod يستخدم خادم الإنتاج بدون سجلات', () {
    final config = AppConfig.fromFlavor('prod');
    expect(config.flavor, Flavor.prod);
    expect(config.showLogs, isFalse);
  });

  test('أي قيمة أخرى (أو null) = dev', () {
    expect(AppConfig.fromFlavor('dev').flavor, Flavor.dev);
    expect(AppConfig.fromFlavor(null).flavor, Flavor.dev);
  });
}
