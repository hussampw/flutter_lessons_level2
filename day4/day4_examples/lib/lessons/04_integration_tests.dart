// ============================================================
// الدرس 4 (Testing): Integration tests — التطبيق كاملاً على جهاز حقيقي
// في التطبيق: القائمة ← الدرس 4  ·  في العرض: شرائح الدرس 4
// ============================================================
//
// Integration test = نفس كتابة Widget test (find / tap / expect)
// لكنه يشغّل التطبيق الحقيقي على جهاز أو محاكي: محرك الرسم الحقيقي،
// الـ plugins الحقيقية، والوقت الحقيقي. أبطأ نوع، لكنه الأعلى ثقة.
//
// الملف: integration_test/app_test.dart  (مجلد منفصل عن test/)
// الحزمة: integration_test من الـ SDK (dev_dependencies في pubspec.yaml)
//
// التشغيل:
//   flutter devices                              ← اعرض الأجهزة المتصلة
//   flutter test integration_test                ← يختار الجهاز المتصل
//   flutter test integration_test -d linux       ← تطبيق سطح المكتب
//   flutter test integration_test -d emulator-5554  ← محاكي Android
//
// 💡 هذه الشاشة فيها "تدفق تسجيل دخول" صغير، والاختبار يفتح التطبيق من القائمة،
//    يدخل هنا، يكتب البريد وكلمة المرور، ويتأكد من ظهور شاشة الترحيب.

import 'package:flutter/material.dart';

import '01_extension_methods.dart';

class IntegrationScreen extends StatelessWidget {
  const IntegrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 4: Integration tests')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _LoginForm(),
          const SizedBox(height: 16),
          const _InfoCard(
            title: 'ماذا يختبر integration_test/app_test.dart؟',
            lines: [
              '1) يشغّل WorkshopApp الحقيقي (ProviderScope + الثيم + اللغة)',
              '2) يفتح «الدرس 4» من القائمة كما يفعل المستخدم',
              '3) بريد خاطئ ← رسالة تحقق · بريد صحيح ← شاشة الترحيب',
              '4) يفتح «الدرس 3» ويضيف منتجاً من الـ API المحاكى (وقت حقيقي)',
            ],
          ),
          const _InfoCard(
            title: 'كيف أشغّله على جهاز؟',
            lines: [
              'شغّل محاكي Android أو وصّل هاتفاً (USB debugging)',
              'flutter devices',
              'flutter test integration_test -d <device-id>',
              'سطح المكتب بدون هاتف: flutter test integration_test -d linux',
            ],
          ),
          const _InfoCard(
            title: 'الفرق عن Widget test',
            lines: [
              'Widget test: بيئة وهمية، وقت مزيّف، ميلي ثوانٍ ← flutter test',
              'Integration test: جهاز حقيقي، وقت حقيقي، ثوانٍ إلى دقائق',
              'نفس الـ API: find · tap · enterText · pumpAndSettle · expect',
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// تدفق تسجيل الدخول: Form + validator ← تحميل ← شاشة ترحيب
// الـ Keys تجعل الاختبار مستقراً حتى لو تغيّرت النصوص أو اللغة
// ------------------------------------------------------------
class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(1.seconds); // يحاكي طلب الشبكة (امتداد الدرس 1)
    if (!mounted) return;
    setState(() => _loading = false);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _WelcomePage(email: _email.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            spacing: 12,
            children: [
              Text('تدفق تسجيل الدخول', style: context.textTheme.titleMedium),
              TextFormField(
                key: const Key('email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'البريد'),
                validator: (v) =>
                    (v ?? '').trim().isValidEmail ? null : 'بريد غير صالح',
              ),
              TextFormField(
                key: const Key('password'),
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
                validator: (v) =>
                    (v ?? '').length >= 6 ? null : '6 أحرف على الأقل',
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('login'),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('دخول'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 4: مرحباً')),
      body: Center(
        child: Text(
          'أهلاً $email 👋',
          key: const Key('welcome'),
          style: context.textTheme.headlineSmall,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.lines});
  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(title, style: context.textTheme.titleSmall),
            for (final l in lines) Text('• $l'),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) لا تنسَ السطر الأول في كل ملف integration test — بدونه يعمل كـ widget test عادي:
//      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
//
// 2) صورة من الجهاز أثناء الاختبار (للتقارير أو مقارنة التصميم):
//      final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
//      await binding.takeScreenshot('login');   // على Android: convertFlutterSurfaceToImage() أولاً
//
// 3) على الويب نحتاج flutter drive مع chromedriver وملف test_driver/integration_test.dart:
//      flutter drive --driver=test_driver/integration_test.dart \
//        --target=integration_test/app_test.dart -d chrome
//
// 4) اختبار الأداء على الجهاز (اليوم الخامس): binding.traceAction(() async {...})
//    يسجّل Timeline لأزمنة رسم الإطارات أثناء التمرير.
//
// 5) اجعل integration tests قليلة وتغطي "الرحلات المهمة" فقط (تسجيل دخول، شراء)،
//    والباقي unit و widget tests — هرم الاختبارات.
