// ============================================================
// الدرس 9 (UI): اختبار الترجمة وإمكانية الوصول
// التشغيل: flutter test test/09_l10n_a11y_test.dart
// ============================================================

import 'package:day4_examples/l10n/app_localizations.dart';
import 'package:day4_examples/lessons/09_l10n_rtl_a11y.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // lookupAppLocalizations: الترجمة بدون Widgets (مفيد لاختبار plural)
  test('العربية: 6 صيغ للجمع', () {
    final ar = lookupAppLocalizations(const Locale('ar'));

    expect(ar.cartItems(0), 'السلة فارغة');
    expect(ar.cartItems(1), 'منتج واحد');
    expect(ar.cartItems(2), 'منتجان');
    expect(ar.cartItems(5), '5 منتجات'); // few: 3–10
    expect(ar.cartItems(11), '11 منتجاً'); // many: 11–99
    expect(ar.cartItems(100), '100 منتج'); // other
  });

  test('الإنجليزية: one / other و select', () {
    final en = lookupAppLocalizations(const Locale('en'));

    expect(en.cartItems(1), 'One item');
    expect(en.cartItems(7), '7 items');
    expect(en.welcomeBack('female'), 'Welcome back, madam');
  });

  // تطبيق صغير باللغة المطلوبة
  Widget app(Locale locale, Widget child) => MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );

  testWidgets('اللغة العربية تجعل الاتجاه RTL تلقائياً', (tester) async {
    late TextDirection dir;
    await tester.pumpWidget(
      app(
        const Locale('ar'),
        Builder(
          builder: (context) {
            dir = Directionality.of(context);
            return Text(context.l10n.hello('سارة'));
          },
        ),
      ),
    );

    expect(dir, TextDirection.rtl);
    expect(find.text('أهلاً سارة!'), findsOneWidget);
  });

  testWidgets('بطاقة المنتج تحقق إرشادات الوصول', (tester) async {
    // ensureSemantics: يبني شجرة Semantics كما يراها قارئ الشاشة
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        const Locale('ar'),
        const AccessibleProductTile(name: 'سماعة رأس', price: 210),
      ),
    );

    // الزر له وصف مترجم (tooltip) يقرؤه TalkBack / VoiceOver
    expect(find.byTooltip('أضف سماعة رأس إلى السلة'), findsOneWidget);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  test('contrastRatio: أسود على أبيض = 21', () {
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(contrastRatio(Colors.grey.shade400, Colors.white), lessThan(4.5));
  });
}
