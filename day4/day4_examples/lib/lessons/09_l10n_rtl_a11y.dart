// ============================================================
// الدرس 9 (UI): الترجمة (intl و ARB) + RTL + إمكانية الوصول
// في التطبيق: القائمة ← الدرس 9  ·  في العرض: شرائح الدرس 9
// ============================================================
//
// 1) Localization — gen-l10n الرسمي (بدون حزم خارجية للتوليد):
//    pubspec.yaml: flutter_localizations + intl + (flutter: generate: true)
//    l10n.yaml:    arb-dir: lib/l10n · template-arb-file: app_en.arb
//    lib/l10n/app_en.arb و app_ar.arb ← نصوص + plural + select + تواريخ وعملات
//    flutter gen-l10n (أو تلقائياً مع flutter run) ← AppLocalizations
//    main.dart: localizationsDelegates + supportedLocales + locale
//
// 2) RTL: اللغة العربية تجعل Directionality = rtl تلقائياً.
//    استخدم EdgeInsetsDirectional و AlignmentDirectional (start / end)
//    بدل left / right، فيعمل التصميم في الاتجاهين بدون تعديل.
//
// 3) Accessibility (إمكانية الوصول):
//    Semantics ← ماذا يقرأ قارئ الشاشة (TalkBack / VoiceOver)
//    حجم الخط ← المستخدم يكبّر النص من إعدادات الجهاز (TextScaler)
//    التباين ← نسبة 4.5:1 على الأقل للنص العادي (WCAG AA)

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '01_extension_methods.dart';

// امتداد (الدرس 1): context.l10n بدل AppLocalizations.of(context)
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class L10nRtlA11yScreen extends StatelessWidget {
  const L10nRtlA11yScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 9: الترجمة و RTL و الوصول')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Title('1) الترجمة: ARB + plural + select + تاريخ وعملة'),
          _L10nDemo(),
          _Title('2) RTL: left/right مقابل start/end'),
          _RtlDemo(),
          _Title('3) الوصول: Semantics + حجم الخط + التباين'),
          _A11yDemo(),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// 1) الترجمة — Localizations.override يغيّر اللغة لهذا الجزء فقط
//    (في تطبيق حقيقي: locale في MaterialApp من provider)
// ------------------------------------------------------------
class _L10nDemo extends StatefulWidget {
  const _L10nDemo();

  @override
  State<_L10nDemo> createState() => _L10nDemoState();
}

class _L10nDemoState extends State<_L10nDemo> {
  String _lang = 'ar';
  int _count = 3;
  String _gender = 'female';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ar', label: Text('العربية')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {_lang},
              onSelectionChanged: (s) => setState(() => _lang = s.first),
            ),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'male', label: Text('ذكر')),
                ButtonSegment(value: 'female', label: Text('أنثى')),
              ],
              selected: {_gender},
              onSelectionChanged: (s) => setState(() => _gender = s.first),
            ),
          ],
        ),
        Row(
          children: [
            const Text('count:'),
            Expanded(
              child: Slider(
                value: _count.toDouble(),
                max: 120,
                divisions: 120,
                label: '$_count',
                onChanged: (v) => setState(() => _count = v.round()),
              ),
            ),
          ],
        ),
        Localizations.override(
          context: context,
          locale: Locale(_lang),
          // Builder: نحتاج context جديد "تحت" الـ override لنقرأ اللغة الجديدة
          child: Builder(
            builder: (context) {
              final t = context.l10n;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        t.hello('Sara'),
                        style: context.textTheme.titleMedium,
                      ),
                      Text(t.welcomeBack(_gender)),
                      Text(t.cartItems(_count)),
                      Text(t.total(_count * 19.5)),
                      Text(t.today(DateTime.now())),
                      Text(
                        'Directionality = ${Directionality.of(context).name}',
                        style: TextStyle(color: context.colors.primary),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// 2) RTL — نفس الكود في الاتجاهين
// ------------------------------------------------------------
class _RtlDemo extends StatelessWidget {
  const _RtlDemo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final dir in TextDirection.values)
          Directionality(
            textDirection: dir,
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '  TextDirection.${dir.name}',
                    style: context.textTheme.labelLarge,
                  ),
                  // ❌ left: ثابت في اليسار مهما كانت اللغة
                  _bar(
                    context,
                    const EdgeInsets.only(left: 48),
                    'left: 48',
                    context.colors.errorContainer,
                  ),
                  // ✅ start: يمين في العربية، يسار في الإنجليزية
                  _bar(
                    context,
                    const EdgeInsetsDirectional.only(start: 48),
                    'start: 48',
                    context.colors.primaryContainer,
                  ),
                  const ListTile(
                    dense: true,
                    leading: Icon(Icons.inbox),
                    title: Text('leading / trailing يتبعان الاتجاه'),
                    // arrow_forward ينعكس تلقائياً مع rtl (matchTextDirection)
                    trailing: Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _bar(
    BuildContext context,
    EdgeInsetsGeometry padding,
    String label,
    Color color,
  ) {
    return Padding(
      padding: padding,
      child: Container(
        height: 32,
        margin: const EdgeInsets.symmetric(vertical: 4),
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsetsDirectional.only(start: 8),
        color: color,
        child: Text(label),
      ),
    );
  }
}

// ------------------------------------------------------------
// 3) الوصول — بطاقة منتج يقرؤها قارئ الشاشة جملة واحدة واضحة
// ------------------------------------------------------------
class AccessibleProductTile extends StatelessWidget {
  const AccessibleProductTile({
    super.key,
    required this.name,
    required this.price,
  });
  final String name;
  final double price;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          spacing: 12,
          children: [
            // أيقونة زخرفية فقط ← لا داعي لقراءتها
            const ExcludeSemantics(child: Icon(Icons.headphones, size: 40)),
            Expanded(
              // MergeSemantics: الاسم والسعر يُقرآن كعنصر واحد
              child: MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: context.textTheme.titleMedium),
                    Text('$price ر.س'),
                  ],
                ),
              ),
            ),
            // IconButton بدون نص ← tooltip يصبح الوصف المقروء (وأيضاً عند الضغط المطوّل)
            IconButton.filled(
              tooltip: context.l10n.addToCart(name),
              icon: const Icon(Icons.add_shopping_cart),
              onPressed: () => context.showSnack('أُضيف $name'),
            ),
          ],
        ),
      ),
    );
  }
}

// نسبة التباين بين لونين (WCAG): 1 (لا تباين) ← 21 (أسود على أبيض)
double contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance(), l2 = b.computeLuminance();
  final (hi, lo) = l1 > l2 ? (l1, l2) : (l2, l1);
  return (hi + 0.05) / (lo + 0.05);
}

class _A11yDemo extends StatefulWidget {
  const _A11yDemo();

  @override
  State<_A11yDemo> createState() => _A11yDemoState();
}

class _A11yDemoState extends State<_A11yDemo> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pairs = [
      ('onPrimary / primary', colors.onPrimary, colors.primary),
      ('onSurface / surface', colors.onSurface, colors.surface),
      ('grey.shade400 / white', Colors.grey.shade400, Colors.white),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('حجم الخط ×${_scale.toStringAsFixed(1)}'),
            Expanded(
              child: Slider(
                value: _scale,
                min: 1,
                max: 2,
                divisions: 4,
                onChanged: (v) => setState(() => _scale = v),
              ),
            ),
          ],
        ),
        // نحاكي اختيار المستخدم لحجم خط أكبر من إعدادات الجهاز
        MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(_scale)),
          child: const AccessibleProductTile(name: 'سماعة رأس', price: 210),
        ),
        const SizedBox(height: 8),
        for (final (label, fg, bg) in pairs)
          _ContrastRow(label: label, fg: fg, bg: bg),
      ],
    );
  }
}

class _ContrastRow extends StatelessWidget {
  const _ContrastRow({required this.label, required this.fg, required this.bg});
  final String label;
  final Color fg, bg;

  @override
  Widget build(BuildContext context) {
    final ratio = contrastRatio(fg, bg);
    final ok = ratio >= 4.5;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(10),
      color: bg,
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: fg)),
          ),
          // النتيجة بلون مقروء دائماً (أسود/أبيض حسب الخلفية)
          Text(
            '${ratio.toStringAsFixed(1)}:1 ${ok ? '✅ AA' : '❌'}',
            style: TextStyle(
              color: bg.computeLuminance() > 0.4 ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(text, style: context.textTheme.titleMedium),
  );
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) لا تجمع النصوص بنفسك: 'لديك ' + n + ' منتج' ❌ — العربية فيها 6 صيغ جمع
//    (zero, one, two, few, many, other) ← اكتب plural في ملف ARB ✅
//
// 2) اختبر الوصول آلياً في widget test (انظر test/09_l10n_a11y_test.dart):
//      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
//      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
//      await expectLater(tester, meetsGuideline(textContrastGuideline));
//
// 3) أيقونات تشير لاتجاه (سهم، إرسال) ← Icons.arrow_forward تنعكس تلقائياً.
//    أيقونة أو صورة مخصّصة؟ Transform.flip(flipX: Directionality.of(context) == TextDirection.rtl, ...)
//
// 4) نص بالإنجليزية داخل جملة عربية (رقم طلب، بريد) ← اعزله باتجاهه:
//      Text('رقم الطلب: \u2066#A-1024\u2069')   // LRI ... PDI
//
// 5) لا تمنع تكبير الخط في التطبيق كله؛ إن انكسر تصميم ما ضع حداً معقولاً:
//      MediaQuery.withClampedTextScaling(maxScaleFactor: 1.6, child: ...)
