// ============================================================
// الدرس 5 (Native): الصلاحيات والكاميرا والموقع
// في التطبيق: القائمة ← الدرس 5  ·  في العرض: شرائح الدرس 5
// ============================================================
//
// كل صلاحية "خطيرة" تمر بخطوتين:
//   1) نعلن عنها في ملفات المنصة (مرة واحدة):
//        android/app/src/main/AndroidManifest.xml ← <uses-permission .../>
//        ios/Runner/Info.plist                    ← NSCameraUsageDescription + نص للمستخدم
//   2) نطلبها وقت التشغيل، في اللحظة التي يحتاجها المستخدم (وليس عند فتح التطبيق)
//
// الحالات: granted ✅ · denied (يمكن السؤال مجدداً) · permanentlyDenied (الإعدادات فقط)
//          restricted (iOS: رقابة أبوية) · limited (iOS: بعض الصور فقط)
//
// المكتبات: permission_handler (الصلاحيات) · image_picker (الكاميرا والمعرض)
//           geolocator (الموقع، وله نظام صلاحيات خاص به)
//
// ⚠️ على Linux والاختبارات بعض هذه المكتبات غير موجودة ← رسالة بدل الانهيار.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// الكاميرا والموقع الحقيقيان: Android و iOS (والويب جزئياً)
bool get isMobile =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

const onlyOnMobile = '📱 هذا يعمل على Android و iOS — '
    'على هذه المنصة لا توجد صلاحيات تشغيل (Runtime permissions).';

// ------------------------------------------------------------
// النمط الكامل لطلب صلاحية: افحص ← اطلب ← وإن رُفضت نهائياً افتح الإعدادات
// ------------------------------------------------------------
Future<bool> ensurePermission(
  BuildContext context,
  Permission permission,
  String why,
) async {
  var status = await permission.status;
  if (status.isGranted || status.isLimited) return true;

  // رُفضت نهائياً: النظام لن يعرض نافذة الطلب مرة أخرى
  if (status.isPermanentlyDenied) {
    if (!context.mounted) return false;
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الصلاحية مرفوضة'),
        content: Text('$why\nفعّلها من إعدادات التطبيق.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لاحقاً'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('فتح الإعدادات'),
          ),
        ],
      ),
    );
    if (open ?? false) await openAppSettings();
    return false;
  }

  // denied: نطلبها (تظهر نافذة النظام)
  status = await permission.request();
  return status.isGranted || status.isLimited;
}

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final _picker = ImagePicker();
  Uint8List? _photo;
  String _statuses = 'اضغط "فحص الحالات"';
  String _location = 'لم يُحدَّد الموقع بعد';
  String? _error;

  // يلتقط أخطاء المكتبات على المنصات غير المدعومة
  Future<void> _guard(Future<void> Function() action) async {
    setState(() => _error = null);
    try {
      await action();
    } on MissingPluginException {
      setState(() => _error = onlyOnMobile);
    } on UnimplementedError {
      setState(() => _error = onlyOnMobile);
    } catch (e) {
      setState(() => _error = '⚠️ $e');
    }
  }

  // ------------------------------------------------------------
  // 1) فحص الحالة بدون طلب (لا تظهر أي نافذة للمستخدم)
  // ------------------------------------------------------------
  Future<void> _checkStatuses() => _guard(() async {
        final camera = await Permission.camera.status;
        final location = await Permission.locationWhenInUse.status;
        final notification = await Permission.notification.status;
        setState(() => _statuses = 'الكاميرا: ${camera.name}\n'
            'الموقع: ${location.name}\n'
            'الإشعارات: ${notification.name}');
      });

  // ------------------------------------------------------------
  // 2) الكاميرا: الصلاحية أولاً ثم image_picker
  // ------------------------------------------------------------
  Future<void> _takePhoto() => _guard(() async {
        if (!isMobile) throw MissingPluginException();
        final ok = await ensurePermission(
          context,
          Permission.camera,
          'نحتاج الكاميرا لالتقاط صورة الملف الشخصي.',
        );
        if (!ok) return;
        // maxWidth + imageQuality: نصغّر الصورة قبل أن تصل إلى Dart (الدرس 3)
        final file = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1024,
          imageQuality: 80,
        );
        if (file == null) return; // المستخدم ألغى
        final bytes = await file.readAsBytes();
        setState(() => _photo = bytes);
      });

  // المعرض: على Android 13+ و iOS 14+ لا يحتاج صلاحية (Photo Picker من النظام)
  // ويعمل أيضاً على Linux (نافذة اختيار ملف)
  Future<void> _pickFromGallery() => _guard(() async {
        final file = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
        );
        if (file == null) return;
        final bytes = await file.readAsBytes();
        setState(() => _photo = bytes);
      });

  // ------------------------------------------------------------
  // 3) الموقع: geolocator له فحص خدمة + صلاحيات خاصة به
  // ------------------------------------------------------------
  Future<void> _getLocation() => _guard(() async {
        if (!isMobile && !kIsWeb) throw MissingPluginException();
        // هل خدمة الموقع (GPS) مفعّلة في الجهاز أصلاً؟
        if (!await Geolocator.isLocationServiceEnabled()) {
          setState(() => _location = '📍 خدمة الموقع مغلقة — فعّلها من الإعدادات');
          await Geolocator.openLocationSettings();
          return;
        }
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever) {
          setState(() => _location = '📍 مرفوضة نهائياً — من الإعدادات فقط');
          await Geolocator.openAppSettings();
          return;
        }
        if (permission == LocationPermission.denied) {
          setState(() => _location = '📍 رفض المستخدم الصلاحية');
          return;
        }
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15), // لا ننتظر للأبد
          ),
        );
        setState(() => _location = '📍 ${position.latitude.toStringAsFixed(5)}, '
            '${position.longitude.toStringAsFixed(5)} '
            '(±${position.accuracy.round()}m)');
      });

  @override
  Widget build(BuildContext context) {
    final photo = _photo;
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 5: الصلاحيات والكاميرا والموقع')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!isMobile)
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text(onlyOnMobile),
                subtitle: Text('اختيار صورة من المعرض يعمل هنا أيضاً.'),
              ),
            ),
          if (_error case final error?)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(title: Text(error)),
            ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('1) حالة الصلاحيات'),
            subtitle: Text(_statuses),
            trailing: OutlinedButton(
              onPressed: _checkStatuses,
              child: const Text('فحص الحالات'),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('2) الكاميرا والمعرض'),
            subtitle: const Text('image_picker + permission_handler'),
          ),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('التقط صورة'),
              ),
              OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('من المعرض'),
              ),
            ],
          ),
          if (photo != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(photo, height: 220, cacheWidth: 600),
              ),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('3) الموقع الحالي (geolocator)'),
            subtitle: Text(_location),
            trailing: FilledButton.tonal(
              onPressed: _getLocation,
              child: const Text('أين أنا؟'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) اطلب الصلاحية في سياقها: عند ضغط "التقط صورة" وليس عند فتح التطبيق.
//    اشرح السبب قبل نافذة النظام (Android يساعدك):
//      if (await Permission.camera.shouldShowRequestRationale) { /* اعرض شرحاً */ }
//
// 2) iOS: بدون مفتاح NSCameraUsageDescription في Info.plist يُغلق التطبيق فوراً
//    عند طلب الكاميرا، و Apple ترفض التطبيق إذا كان النص غامضاً ("نحتاج الكاميرا").
//
// 3) لا تطلب ACCESS_BACKGROUND_LOCATION (الموقع الدائم) إلا لو كانت الميزة
//    الأساسية تحتاجه — Google Play يطلب نموذج تبرير ومراجعة خاصة.
//
// 4) لتتبع الموقع باستمرار (تطبيق توصيل مثلاً) استخدم Stream بدل getCurrentPosition:
//      Geolocator.getPositionStream(
//        locationSettings: const LocationSettings(distanceFilter: 20),
//      ).listen((p) => ...);
//
// 5) عاد المستخدم من الإعدادات؟ أعد فحص الحالة عند رجوع التطبيق للواجهة:
//    AppLifecycleListener(onResume: _checkStatuses)
