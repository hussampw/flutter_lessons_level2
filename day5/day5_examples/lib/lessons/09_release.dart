// ============================================================
// الدرس 9 (Release): النشر على Google Play و App Store · CI/CD · تقارير الأعطال
// في التطبيق: القائمة ← الدرس 9  ·  في العرض: شرائح الدرس 9
// ============================================================
//
// رحلة النسخة: الكود ← CI (اختبار + بناء + توقيع) ← المتجر ← المستخدمون
//              ← تقارير الأعطال تعود إلينا ← إصلاح ← نسخة جديدة
//
// ملفات حقيقية في المشروع (جولة):
//   .github/workflows/flutter_ci.yml      ← CI/CD مع GitHub Actions
//   lib/lessons/09_crash_reporting.dart   ← Crashlytics (محمي بدون Firebase)
//   android/app/build.gradle.kts          ← flavors + signing (الدرس 8)
//
// الشاشة: قائمة تحقق قبل الرفع (Play / App Store) + تجربة تقارير الأعطال.

import 'dart:async';

import 'package:flutter/material.dart';

import '09_crash_reporting.dart';

// (المنصة، البند، شرح قصير)
const _checklist = <(String, String, String)>[
  ('Play', 'حساب Google Play Console', 'رسوم مرة واحدة 25\$'),
  ('Play', 'App Bundle موقّع (.aab)', 'flutter build appbundle --flavor prod'),
  ('Play', 'versionCode أكبر من السابق', 'version: 1.0.0+2 في pubspec.yaml'),
  ('Play', 'Play App Signing مفعّل', 'Google تحفظ مفتاح التوقيع النهائي'),
  ('Play', 'targetSdk حديث', 'Google تطلب آخر إصدار خلال سنة من صدوره'),
  ('Play', 'Data safety + سياسة الخصوصية', 'رابط سياسة خصوصية منشور'),
  ('Play', 'اختبار مغلق قبل الإنتاج', 'الحسابات الجديدة: 12 مختبِراً لمدة 14 يوماً'),
  ('Play', 'صور المتجر والوصف', 'أيقونة 512 · صورة مميزة 1024×500 · لقطات'),
  ('iOS', 'حساب Apple Developer', '99\$ سنوياً'),
  ('iOS', 'Bundle ID + App في App Store Connect', 'نفس PRODUCT_BUNDLE_IDENTIFIER'),
  ('iOS', 'بناء ورفع', 'flutter build ipa ثم Transporter أو Xcode'),
  ('iOS', 'TestFlight', 'اختبار داخلي فوري، خارجي بعد مراجعة قصيرة'),
  ('iOS', 'نصوص الصلاحيات واضحة', 'NSCameraUsageDescription... (الدرس 5)'),
  ('iOS', 'App Privacy + حساب تجريبي للمراجِع', 'إن كان التطبيق يتطلب تسجيل دخول'),
];

class ReleaseScreen extends StatefulWidget {
  const ReleaseScreen({super.key});

  @override
  State<ReleaseScreen> createState() => _ReleaseScreenState();
}

class _ReleaseScreenState extends State<ReleaseScreen> {
  final _done = <int>{};
  bool _handlersInstalled = false;
  String _crashStatus = 'اضغط "تهيئة" أولاً';

  @override
  void dispose() {
    // نعيد معالجات الأخطاء الأصلية عند الخروج من الدرس
    if (_handlersInstalled) CrashReporter.uninstallHandlers();
    super.dispose();
  }

  Future<void> _initCrashReporting() async {
    final error = await CrashReporter.init();
    if (!_handlersInstalled) {
      CrashReporter.installHandlers();
      _handlersInstalled = true;
    }
    await CrashReporter.setUser('student-42');
    if (!mounted) return;
    setState(() => _crashStatus = error ?? '✅ Crashlytics جاهز — الأعطال تُرسل إلى Firebase');
  }

  // 1) خطأ متوقع التقطناه بأنفسنا: نسجّله بدون إيقاف التطبيق
  Future<void> _nonFatal() async {
    try {
      throw const FormatException('رد غير متوقع من الخادم');
    } catch (e, stack) {
      await CrashReporter.log('المستخدم فتح شاشة الطلبات');
      await CrashReporter.record(e, stack, reason: 'تحليل رد /orders');
    }
  }

  // 2) خطأ داخل إطار Flutter ← يمر عبر FlutterError.onError
  void _flutterError() {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError('خطأ تجريبي في الواجهة'),
        stack: StackTrace.current,
        library: 'الدرس 9',
      ),
    );
  }

  // 3) خطأ async لم يلتقطه أحد ← يمر عبر PlatformDispatcher.onError
  void _uncaughtAsync() {
    unawaited(Future<void>.error(TimeoutException('طلب لم يكتمل')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 9: النشر و CI/CD والأعطال')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ---------------- قائمة التحقق ----------------
          Text(
            'قائمة التحقق قبل الرفع: ${_done.length} / ${_checklist.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          LinearProgressIndicator(value: _done.length / _checklist.length),
          for (final store in ['Play', 'iOS'])
            Card(
              child: ExpansionTile(
                initiallyExpanded: store == 'Play',
                leading: Icon(store == 'Play' ? Icons.shop : Icons.apple),
                title: Text(store == 'Play' ? 'Google Play' : 'App Store'),
                children: [
                  for (final (i, (s, item, hint)) in _checklist.indexed)
                    if (s == store)
                      CheckboxListTile(
                        dense: true,
                        value: _done.contains(i),
                        title: Text(item),
                        subtitle: Text(hint),
                        onChanged: (v) => setState(
                          () => v! ? _done.add(i) : _done.remove(i),
                        ),
                      ),
                ],
              ),
            ),

          // ---------------- CI/CD ----------------
          const Card(
            child: ListTile(
              leading: Icon(Icons.sync),
              title: Text('CI/CD: .github/workflows/flutter_ci.yml'),
              subtitle: Text(
                'كل push: analyze ← test ← build apk + appbundle (موقّع، مشوّش) '
                '← artifacts + symbols.\n'
                'Codemagic بديل جاهز لـ Flutter، ويسهّل توقيع iOS بدون Mac.',
              ),
            ),
          ),

          // ---------------- Crash reporting ----------------
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    'تقارير الأعطال (Crashlytics)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(_crashStatus),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton(
                        onPressed: _initCrashReporting,
                        child: const Text('تهيئة'),
                      ),
                      OutlinedButton(
                        onPressed: _handlersInstalled ? _nonFatal : null,
                        child: const Text('1) non-fatal'),
                      ),
                      OutlinedButton(
                        onPressed: _handlersInstalled ? _flutterError : null,
                        child: const Text('2) خطأ Flutter'),
                      ),
                      OutlinedButton(
                        onPressed: _handlersInstalled ? _uncaughtAsync : null,
                        child: const Text('3) async غير ملتقط'),
                      ),
                    ],
                  ),
                  // ما "كان سيُرسل" إلى Crashlytics
                  ValueListenableBuilder<List<String>>(
                    valueListenable: CrashReporter.localReports,
                    builder: (context, reports, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final r in reports.take(6))
                          Text(r, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
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
// 1) ابدأ النشر على مسار internal testing في Play Console: يصل للمختبرين
//    خلال دقائق وبدون مراجعة طويلة، ثم closed ← open ← production.
//
// 2) Staged rollout: انشر للإنتاج على 10% من المستخدمين أولاً، وراقب
//    Crashlytics يوماً أو يومين، ثم ارفع النسبة. يمكن إيقاف النشر إن ظهرت مشكلة.
//
// 3) لا ترفع رقم versionCode يدوياً في CI: مرّره من رقم التشغيل:
//      flutter build appbundle --build-number=${{ github.run_number }}
//
// 4) أضف سياقاً قبل الأعطال المهمة ليسهل تتبعها:
//      FirebaseCrashlytics.instance.setCustomKey('screen', 'checkout');
//
// 5) جرّب CI محلياً قبل كل push بنفس الأوامر:
//      flutter analyze && flutter test && flutter build apk --flavor prod
