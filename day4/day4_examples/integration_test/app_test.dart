// ============================================================
// الدرس 4 (Testing): Integration test — التطبيق الحقيقي كاملاً على جهاز
// التشغيل (يحتاج جهازاً: هاتف، محاكي، أو سطح المكتب):
//   flutter test integration_test            ← يختار الجهاز المتصل
//   flutter test integration_test -d linux   ← بدون هاتف
// ============================================================

import 'package:day4_examples/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  // ⚠️ السطر الأهم: يربط الاختبار بالجهاز الحقيقي
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // دالة مساعدة: افتح درساً من القائمة كما يفعل المستخدم
  Future<void> openLesson(WidgetTester tester, int n) async {
    final tile = find.textContaining('الدرس $n:');
    await tester.scrollUntilVisible(tile, 200);
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  testWidgets('تسجيل الدخول: بريد خاطئ ثم صحيح ← شاشة الترحيب', (tester) async {
    // التطبيق الحقيقي: نفس ما في main() بدون أي override
    await tester.pumpWidget(const ProviderScope(child: WorkshopApp()));
    await tester.pumpAndSettle();

    await openLesson(tester, 4);

    await tester.enterText(find.byKey(const Key('email')), 'ali@');
    await tester.enterText(find.byKey(const Key('password')), '123456');
    await tester.tap(find.byKey(const Key('login')));
    await tester.pumpAndSettle();
    expect(find.text('بريد غير صالح'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('email')), 'ali@mail.com');
    await tester.tap(find.byKey(const Key('login')));
    // وقت حقيقي: ننتظر حتى ينتهي "طلب الشبكة" (ثانية) والانتقال
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('welcome')), findsOneWidget);
    expect(find.text('أهلاً ali@mail.com 👋'), findsOneWidget);
  });

  testWidgets('المتجر: المنتجات من الـ API المحاكى ثم الإضافة للسلة', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: WorkshopApp()));
    await tester.pumpAndSettle();

    await openLesson(tester, 3);
    expect(find.text('لوحة مفاتيح'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-kb')));
    await tester.pump();

    final badge = tester.widget<Text>(find.byKey(const Key('cart-count')));
    expect(badge.data, '1');
  });
}
