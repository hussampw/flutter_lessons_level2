// الدرس 4: نختبر كود القناة بدون جهاز — نرد بدلاً من Kotlin / Swift
import 'package:day5_examples/lessons/04_platform_channels.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(deviceChannel, null));

  test('getBatteryLevel تقرأ القيمة من القناة', () async {
    messenger.setMockMethodCallHandler(deviceChannel, (call) async {
      expect(call.method, 'getBatteryLevel');
      return 87;
    });
    expect(await getBatteryLevel(), 87);
  });

  test('بدون كود Native: MissingPluginException ورسالة عربية', () async {
    await expectLater(getBatteryLevel(), throwsA(isA<MissingPluginException>()));
    expect(nativeErrorMessage(MissingPluginException()), contains('Android'));
  });

  test('خطأ من المنصة يظهر مع الكود', () {
    final msg = nativeErrorMessage(
      PlatformException(code: 'UNAVAILABLE', message: 'غير متاح'),
    );
    expect(msg, contains('UNAVAILABLE'));
  });
}
