// ============================================================
// الدرس 3 (Testing): Widget test لشاشة المتجر
// التشغيل: flutter test test/03_shop_widget_test.dart
// ============================================================

import 'package:day4_examples/lessons/02_unit_tests.dart';
import 'package:day4_examples/lessons/03_provider_widget_tests.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductApi extends Mock implements ProductApi {}

void main() {
  late MockProductApi api;

  setUp(() => api = MockProductApi());

  // نلف الشاشة بـ ProviderScope (مع override) و MaterialApp
  Widget app() => ProviderScope(
    overrides: [productApiProvider.overrideWithValue(api)],
    child: const MaterialApp(home: ShopScreen()),
  );

  testWidgets('loading ثم القائمة، والضغط يزيد عدد السلة', (tester) async {
    when(() => api.fetchProducts()).thenAnswer(
      (_) async => [
        {'sku': 'kb', 'name': 'لوحة مفاتيح', 'price': 120},
        {'sku': 'ms', 'name': 'فأرة لاسلكية', 'price': 45.5},
      ],
    );

    await tester.pumpWidget(app());
    // الإطار الأول: ما زال يحمّل
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle(); // ننتظر حتى تكتمل الـ Future والأنيميشن
    expect(find.text('لوحة مفاتيح'), findsOneWidget);
    expect(find.byKey(const Key('cart-count')), findsNothing); // السلة فارغة

    await tester.tap(find.byKey(const Key('add-kb')));
    await tester.tap(find.byKey(const Key('add-kb')));
    await tester.pump();

    final badge = tester.widget<Text>(find.byKey(const Key('cart-count')));
    expect(badge.data, '2');
    expect(find.text('أُضيف لوحة مفاتيح'), findsOneWidget); // SnackBar
  });

  testWidgets('خطأ الشبكة يعرض رسالة وزر إعادة المحاولة', (tester) async {
    when(() => api.fetchProducts()).thenThrow(Exception('offline'));

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('⚠️ تعذّر تحميل المنتجات'), findsOneWidget);

    // نصلح الـ Mock ثم نضغط "إعادة المحاولة"
    when(() => api.fetchProducts()).thenAnswer((_) async => []);
    await tester.tap(find.byKey(const Key('retry')));
    await tester.pumpAndSettle();

    expect(find.text('⚠️ تعذّر تحميل المنتجات'), findsNothing);
    verify(() => api.fetchProducts()).called(2);
  });
}
