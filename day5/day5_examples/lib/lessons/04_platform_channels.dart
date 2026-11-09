// ============================================================
// الدرس 4 (Native): Platform Channels و Pigeon
// في التطبيق: القائمة ← الدرس 4  ·  في العرض: شرائح الدرس 4
// ============================================================
//
// عندما تحتاج ميزة من النظام لا توجد لها مكتبة (أو تريد كودك الخاص):
//   Dart ──invokeMethod('getBatteryLevel')──► Channel ──► Kotlin / Swift
//   Dart ◄────────────── النتيجة (int) ◄──────────────── result.success(...)
//
// الملفات الأصلية (Native) في هذا الدرس:
//   android/app/src/main/kotlin/com/workshop/day5_examples/MainActivity.kt
//   ios/Runner/AppDelegate.swift
//
// طريقتان:
//   1) MethodChannel يدوي: أسماء الدوال نصوص، والأنواع dynamic ← أخطاء وقت التشغيل
//   2) Pigeon: نكتب الواجهة مرة واحدة في pigeons/device_api.dart
//      فيولّد كود Dart + Kotlin + Swift آمن الأنواع:
//        dart run pigeon --input pigeons/device_api.dart
//
// ⚠️ على Linux والويب والاختبارات لا يوجد كود Native ← نعرض رسالة بدل الانهيار.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '04_device_api.g.dart';

// ------------------------------------------------------------
// 1) MethodChannel: الاسم يجب أن يطابق Kotlin و Swift حرفياً
// ------------------------------------------------------------
const deviceChannel = MethodChannel('workshop/device');

Future<int> getBatteryLevel() async {
  // invokeMethod<int>: نحدد نوع النتيجة المتوقعة (التحقق في وقت التشغيل فقط)
  final level = await deviceChannel.invokeMethod<int>('getBatteryLevel');
  return level ?? -1;
}

// ------------------------------------------------------------
// 2) Pigeon: الـ API المولَّد عبر Provider (حقن الاعتماديات — اليوم الأول)
//    في الاختبارات نستبدله بـ Fake عبر overrideWithValue
// ------------------------------------------------------------
final deviceApiProvider = Provider<DeviceHostApi>((ref) => DeviceHostApi());

// رسالة موحّدة عندما لا يوجد كود Native لهذه المنصة
String nativeErrorMessage(Object e) => switch (e) {
      // MethodChannel بدون معالج على هذه المنصة
      MissingPluginException() =>
        'هذا يعمل على Android و iOS فقط (لا يوجد كود Native لهذه المنصة).',
      // Pigeon بدون معالج: channel-error
      PlatformException(code: 'channel-error') =>
        'هذا يعمل على Android و iOS فقط (Pigeon لم يجد الجهة الأخرى).',
      // خطأ أرسلته المنصة نفسها: result.error(...) / FlutterError(...)
      PlatformException(:final code, :final message) => 'خطأ من المنصة [$code]: $message',
      _ => 'خطأ: $e',
    };

class PlatformChannelsScreen extends ConsumerStatefulWidget {
  const PlatformChannelsScreen({super.key});

  @override
  ConsumerState<PlatformChannelsScreen> createState() =>
      _PlatformChannelsScreenState();
}

class _PlatformChannelsScreenState
    extends ConsumerState<PlatformChannelsScreen> {
  String _channelResult = 'اضغط الزر لقراءة البطارية عبر MethodChannel';
  String _pigeonResult = 'اضغط الزر لقراءة معلومات الجهاز عبر Pigeon';

  Future<void> _readBattery() async {
    try {
      final level = await getBatteryLevel();
      setState(() => _channelResult = '🔋 مستوى البطارية: $level%');
    } catch (e) {
      setState(() => _channelResult = '⚠️ ${nativeErrorMessage(e)}');
    }
  }

  Future<void> _readWithPigeon() async {
    final api = ref.read(deviceApiProvider);
    try {
      // أنواع حقيقية: DeviceInfo وليس Map<dynamic, dynamic>
      final DeviceInfo info = await api.getDeviceInfo();
      final greeting = await api.greet('طلاب الورشة');
      setState(() => _pigeonResult = '📱 ${info.model}\n'
          '${info.osVersion}\n'
          '🔋 ${info.batteryLevel}%\n'
          '$greeting');
    } catch (e) {
      setState(() => _pigeonResult = '⚠️ ${nativeErrorMessage(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 4: Platform Channels و Pigeon')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ------------------------------------------------------------
          // رحلة الرسالة: Dart ← Channel ← Kotlin/Swift ← النتيجة
          // ------------------------------------------------------------
          const _RoundTrip(),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('1) MethodChannel يدوي'),
              subtitle: Text(_channelResult),
              trailing: FilledButton.tonal(
                onPressed: _readBattery,
                child: const Text('البطارية'),
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_fix_high),
              title: const Text('2) Pigeon (كود مولَّد)'),
              subtitle: Text(_pigeonResult),
              trailing: FilledButton.tonal(
                onPressed: _readWithPigeon,
                child: const Text('معلومات الجهاز'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'MethodChannel مقابل Pigeon:\n'
            '• اسم دالة خاطئ في MethodChannel = notImplemented وقت التشغيل.\n'
            '• في Pigeon = خطأ ترجمة في Kotlin / Swift قبل التشغيل ✅\n'
            '• Pigeon يولّد الـ codec والتحويل بين الأنواع تلقائياً.',
          ),
        ],
      ),
    );
  }
}

class _RoundTrip extends StatelessWidget {
  const _RoundTrip();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget box(String text, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(text, textAlign: TextAlign.center),
          ),
        );
    // الرسم من اليسار لليمين مثل الكود: Dart ثم القناة ثم المنصة
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        spacing: 6,
        children: [
          box('Dart\ninvokeMethod', colors.primaryContainer),
          const Icon(Icons.arrow_forward),
          box('Channel\nworkshop/device', colors.secondaryContainer),
          const Icon(Icons.arrow_forward),
          box('Kotlin / Swift\nresult(level)', colors.tertiaryContainer),
        ],
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) لتجربة الشاشة في الاختبارات بدون جهاز: ردّ وهمي على القناة
//      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//          .setMockMethodCallHandler(deviceChannel, (call) async => 87);
//
// 2) القنوات تعمل على الـ main thread في Android/iOS: لا تنفّذ عملاً ثقيلاً
//    داخل المعالج مباشرة — انقله إلى thread خلفي ثم ارجع بـ result.
//
// 3) لاستقبال قيم مستمرة من المنصة (حساسات، حالة الشبكة) استخدم EventChannel
//    واقرأها كـ Stream في Dart: EventChannel('workshop/events').receiveBroadcastStream()
//
// 4) بعد تعديل pigeons/device_api.dart أعد التوليد دائماً، ولا تعدّل ملفات .g يدوياً:
//      dart run pigeon --input pigeons/device_api.dart
//
// 5) قبل كتابة كود Native ابحث في pub.dev: غالباً توجد مكتبة رسمية
//    (battery_plus, device_info_plus) — اكتب قناتك فقط لما هو خاص بتطبيقك.
