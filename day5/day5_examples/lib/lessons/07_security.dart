// ============================================================
// الدرس 7 (Security): SSL Pinning · التشويش · المفاتيح والأسرار · Root/Jailbreak · مراجعة التخزين الآمن
// في التطبيق: القائمة ← الدرس 7  ·  في العرض: شرائح الدرس 7
// ============================================================
//
// القاعدة الأولى في أمان تطبيقات الجوال:
//   التطبيق موجود على جهاز المهاجم ← كل ما بداخله يمكن قراءته في النهاية.
//   الحماية في التطبيق "تصعّب" الهجوم فقط، والحماية الحقيقية في الخادم.
//
// في هذه الشاشة 5 أقسام:
//   1) SSL Pinning (Dio) ← lib/lessons/07_ssl_pinning.dart
//   2) Obfuscation: flutter build apk --obfuscate --split-debug-info=build/symbols
//   3) المفاتيح: --dart-define و --dart-define-from-file=config/dev.json
//   4) Root / Jailbreak: عبر قناة الدرس 4 (MainActivity.kt و AppDelegate.swift)
//   5) مراجعة التخزين الآمن (اليوم الثالث): ماذا نحفظ وأين

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '04_platform_channels.dart';
import '07_ssl_pinning.dart';

// ------------------------------------------------------------
// 3) المفاتيح والإعدادات وقت البناء (compile-time constants)
//    flutter run --dart-define-from-file=config/dev.json
//    flutter run --dart-define=API_KEY=xyz
// ------------------------------------------------------------
const apiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: 'https://dummyjson.com');
const apiKey = String.fromEnvironment('API_KEY'); // '' إذا لم يُمرَّر
const enableLogs = bool.fromEnvironment('ENABLE_LOGS');

// نعرض أول 4 أحرف فقط — لا تطبع المفاتيح كاملة في السجلات
String mask(String value) => value.isEmpty
    ? '(لم يُمرَّر — شغّل مع --dart-define-from-file=config/dev.json)'
    : '${value.substring(0, value.length.clamp(0, 4))}••••';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  String? _seenFingerprint; // البصمة الحقيقية التي رآها التطبيق
  String _pinResult = 'اختر تجربة';
  String _rootResult = 'لم يُفحص بعد';

  // بعد أي await قد يكون المستخدم خرج من الشاشة ← نتحقق من mounted
  void _show(String pin) {
    if (mounted) setState(() => _pinResult = pin);
  }

  // ------------------------------------------------------------
  // 1) SSL Pinning: ثلاث تجارب على نفس الخادم
  // ------------------------------------------------------------
  Future<void> _tryPinning(Set<String> pins, String title) async {
    if (kIsWeb) {
      setState(() => _pinResult = '🌐 على الويب المتصفح يتحكم بـ TLS — '
          'لا يمكن الوصول إلى الشهادة. جرّب على Android / iOS / Linux.');
      return;
    }
    setState(() => _pinResult = '⏳ $title ...');
    final dio = createPinnedDio(
      allowedFingerprints: pins,
      onCertificate: (fp) => _seenFingerprint = fp,
    );
    try {
      final res = await dio.get<Map<String, dynamic>>('/products/1');
      _show('✅ $title: الشهادة مطابقة — '
          'وصل المنتج «${res.data?['title']}»');
    } on DioException catch (e) {
      _show(switch (e.type) {
            // تجربة أ: القائمة فارغة عمداً، هدفنا قراءة البصمة فقط
            DioExceptionType.badCertificate when pins.isEmpty =>
              '🔍 سجّلنا بصمة الخادم الحقيقية (بالأسفل) — الآن جرّب ج)',
            // validateCertificate أعادت false ← رفض الاتصال قبل إرسال أي بيانات
            DioExceptionType.badCertificate =>
              '🛑 $title: البصمة غير مطابقة — رُفض الاتصال (هذا ما نريده ضد MITM)',
            DioExceptionType.connectionError ||
            DioExceptionType.connectionTimeout =>
              '📡 لا يوجد اتصال بالإنترنت — تحقّق من الشبكة وأعد المحاولة',
            _ => '⚠️ $title: ${e.message}',
          });
    } finally {
      dio.close();
    }
  }

  // ------------------------------------------------------------
  // 4) Root / Jailbreak: نسأل الكود الأصلي عبر MethodChannel (الدرس 4)
  // ------------------------------------------------------------
  Future<void> _checkRoot() async {
    try {
      final result = await deviceChannel
          .invokeMapMethod<String, dynamic>('isDeviceCompromised');
      final compromised = result?['compromised'] == true;
      final reasons = (result?['reasons'] as List?)?.join('، ') ?? '';
      if (!mounted) return;
      setState(() => _rootResult = compromised
          ? '⚠️ الجهاز معدّل (Root/Jailbreak): $reasons'
          : '✅ لا توجد علامات Root/Jailbreak ${reasons.isEmpty ? '' : '($reasons)'}');
    } catch (e) {
      if (mounted) setState(() => _rootResult = '⚠️ ${nativeErrorMessage(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final seen = _seenFingerprint;
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 7: الأمان')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ---------------- 1) SSL Pinning ----------------
          _Section(
            icon: Icons.lock,
            title: '1) SSL Pinning مع Dio',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    // نسجّل البصمة الحقيقية (للتعلّم فقط — في الإنتاج تُكتب مسبقاً)
                    onPressed: () => _tryPinning({}, 'أ) اكتشاف البصمة'),
                    child: const Text('أ) اكتشف البصمة'),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _tryPinning({'00' * 32}, 'ب) بصمة خاطئة'),
                    child: const Text('ب) بصمة خاطئة'),
                  ),
                  FilledButton(
                    onPressed: seen == null
                        ? null
                        : () => _tryPinning({seen}, 'ج) البصمة الصحيحة'),
                    child: const Text('ج) البصمة الصحيحة'),
                  ),
                ],
              ),
              Text(_pinResult),
              if (seen != null)
                SelectableText(
                  'SHA-256: $seen',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
            ],
          ),

          // ---------------- 2) Obfuscation ----------------
          _Section(
            icon: Icons.blur_on,
            title: '2) تشويش الكود (Obfuscation)',
            children: [
              const _Command(
                'flutter build apk --obfuscate --split-debug-info=build/symbols',
              ),
              // في نسخة مشوّشة يصبح هذا الاسم حروفاً عشوائية
              Text('اسم هذا الـ class الآن: $runtimeType\n'
                  'في نسخة --obfuscate يصبح اسماً قصيراً بلا معنى.'),
              const Text('لقراءة stack trace من نسخة مشوّشة:'),
              const _Command(
                'flutter symbolize -i stack.txt -d build/symbols/app.android-arm64.symbols',
              ),
            ],
          ),

          // ---------------- 3) Keys & secrets ----------------
          _Section(
            icon: Icons.key,
            title: '3) المفاتيح والأسرار (--dart-define)',
            children: [
              Text('API_BASE_URL = $apiBaseUrl'),
              Text('API_KEY = ${mask(apiKey)}'),
              Text('ENABLE_LOGS = $enableLogs'),
              const _Command('flutter run --dart-define-from-file=config/dev.json'),
              const Text(
                '⚠️ أي قيمة داخل التطبيق يمكن استخراجها (strings على ملف libapp.so).\n'
                '✅ المفاتيح العامة (Google Maps مقيّد بالـ package) في التطبيق مقبولة.\n'
                '❌ الأسرار الحقيقية (Stripe secret، مفتاح OpenAI) تبقى في الخادم فقط،\n'
                '   والتطبيق يطلب من خادمك، وخادمك يطلب من الخدمة.',
              ),
            ],
          ),

          // ---------------- 4) Root / Jailbreak ----------------
          _Section(
            icon: Icons.phonelink_lock,
            title: '4) كشف Root / Jailbreak',
            children: [
              Text(_rootResult),
              FilledButton.tonal(
                onPressed: _checkRoot,
                child: const Text('افحص الجهاز'),
              ),
              const Text(
                'علامات بسيطة في Kotlin / Swift (ملفات su و Cydia...). '
                'للإنتاج: freeRASP أو Play Integrity (Android) و App Attest (iOS) '
                '— والقرار النهائي في الخادم.',
              ),
            ],
          ),

          // ---------------- 5) Secure storage review ----------------
          const _Section(
            icon: Icons.inventory_2,
            title: '5) مراجعة التخزين الآمن (اليوم الثالث)',
            children: [
              _StorageRow('Access / Refresh token', 'flutter_secure_storage', true),
              _StorageRow('الثيم، اللغة، آخر شاشة', 'shared_preferences', true),
              _StorageRow('بيانات كثيرة (طلبات، رسائل)', 'قاعدة بيانات محلية', true),
              _StorageRow('كلمة المرور نفسها', 'لا تُحفظ أبداً — احفظ token', false),
              _StorageRow('API secret / مفتاح دفع', 'الخادم فقط', false),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Row(
              spacing: 8,
              children: [
                Icon(icon),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

// أمر طرفية قابل للنسخ
class _Command extends StatelessWidget {
  const _Command(this.command);

  final String command;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: SelectableText(
                command,
                style: const TextStyle(
                  color: Color(0xFFB8F5C8),
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white70, size: 18),
              tooltip: 'نسخ',
              onPressed: () => Clipboard.setData(ClipboardData(text: command)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageRow extends StatelessWidget {
  const _StorageRow(this.what, this.where, this.ok);

  final String what;
  final String where;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        ok ? Icons.check_circle : Icons.cancel,
        color: ok ? Colors.green : Colors.red,
      ),
      title: Text(what),
      trailing: Text(where),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) badCertificateCallback = (cert, host, port) => true  لتجاوز خطأ أثناء التطوير
//    هو أخطر سطر في التطبيق: ينسى الكثيرون حذفه فيصل إلى الإنتاج. لا تكتبه أبداً.
//
// 2) احفظ ملفات build/symbols من كل نسخة release (في CI كـ artifact):
//    بدونها لا يمكن قراءة أي stack trace من المستخدمين بعد التشويش.
//
// 3) القيم من --dart-define ثوابت const ← يحذف المترجم الكود غير المستخدم:
//      if (enableLogs) print(...);   // يختفي تماماً من نسخة ENABLE_LOGS=false
//
// 4) لا تمنع الأجهزة المعدّلة (Root) من كل شيء: كثير من المستخدمين الحقيقيين لديهم Root.
//    اعرض تحذيراً، وامنع فقط العمليات الحساسة (الدفع)، وأرسل النتيجة للخادم.
//
// 5) iOS Keychain لا يُحذف عند حذف التطبيق! عند أول تشغيل بعد إعادة التثبيت
//    امسح الـ tokens القديمة (اعرف أول تشغيل عبر علامة في shared_preferences).
