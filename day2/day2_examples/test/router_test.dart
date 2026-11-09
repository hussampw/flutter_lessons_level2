// ============================================================
// اختبار الدرس 5: الحارس (redirect) و Deep links
// التشغيل: flutter test test/router_test.dart
// ============================================================

import 'package:day2_examples/lessons/05_guards_deep_links.dart';
import 'package:day2_examples/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// نرسل الرابط عبر نفس دالة الدرس (القناة flutter/navigation)
// runAsync: الرسالة تمر عبر حلقة الأحداث الحقيقية وليس الوقت الوهمي للاختبار
Future<void> openLink(WidgetTester tester, String link) async {
  await tester.runAsync(() async {
    simulateDeepLink(link);
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  await tester.pumpAndSettle();
}

void main() {
  // 1) الحارس دالة عادية ← اختبار بدون واجهة
  test('lesson5Guard: محمي ← الدخول، ثم العودة إلى الوجهة', () {
    expect(
      lesson5Guard(loggedIn: false, uri: Uri.parse('/l5/account/orders')),
      '/l5/login?from=%2Fl5%2Faccount%2Forders',
    );
    expect(
      lesson5Guard(
        loggedIn: true,
        uri: Uri.parse('/l5/login?from=%2Fl5%2Faccount%2Forders'),
      ),
      '/l5/account/orders',
    );
    // صفحة عامة ← لا تحويل، حتى مع مخطط Deep link
    expect(
      lesson5Guard(loggedIn: false, uri: Uri.parse('day2://open/l5/products/7')),
      isNull,
    );
  });

  // 2) Deep link حقيقي عبر قناة flutter/navigation (نفس ما يرسله Android/iOS)
  testWidgets('Deep link لصفحة محمية ← الدخول ← الصفحة المطلوبة', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WorkshopApp()));
    expect(find.text('اليوم الثاني: go_router و Dio'), findsOneWidget);

    await openLink(tester, 'day2://open/l5/account/orders');
    expect(find.text('الدرس 5: تسجيل الدخول'), findsOneWidget);

    // الدخول يغيّر الحالة فقط ← refreshListenable ← redirect يعيدنا للوجهة
    await tester.tap(find.text('دخول كـ سارة'));
    await tester.pumpAndSettle();
    expect(find.text('الدرس 5: طلباتي'), findsOneWidget);
  });

  testWidgets('Deep link لمنتج: الرجوع يعود إلى /l5 (مسارات متداخلة)', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WorkshopApp()));

    await openLink(tester, 'day2://open/l5/products/7?ref=sms');
    expect(find.text('الدرس 5: منتج 7'), findsOneWidget);
    expect(find.text('المصدر (?ref): sms'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('الدرس 5: redirect و Deep links'), findsOneWidget);
  });

  testWidgets('رابط غير معروف ← صفحة الخطأ (errorBuilder)', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: WorkshopApp()));

    await openLink(tester, 'day2://open/l5/oops');
    expect(find.text('الدرس 3: الصفحة غير موجودة'), findsOneWidget);
    expect(find.byIcon(Icons.link_off), findsOneWidget);
  });
}
