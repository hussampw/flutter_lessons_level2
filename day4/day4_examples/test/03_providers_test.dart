// ============================================================
// الدرس 3 (Testing): اختبار الـ Providers بدون أي Widget
// التشغيل: flutter test test/03_providers_test.dart
// ============================================================

import 'package:day4_examples/lessons/02_unit_tests.dart';
import 'package:day4_examples/lessons/03_provider_widget_tests.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductApi extends Mock implements ProductApi {}

const keyboard = Product(sku: 'kb', name: 'لوحة مفاتيح', price: 120);

void main() {
  late MockProductApi api;

  setUp(() => api = MockProductApi());

  // دالة مساعدة: حاوية فيها الـ API مستبدل بالـ Mock
  ProviderContainer makeContainer() => ProviderContainer.test(
    overrides: [productApiProvider.overrideWithValue(api)],
  );

  test('productsProvider يقرأ من الـ Mock عبر الـ Repository', () async {
    when(() => api.fetchProducts()).thenAnswer(
      (_) async => [
        {'sku': 'kb', 'name': 'لوحة مفاتيح', 'price': 120},
      ],
    );
    final container = makeContainer();

    // .future ننتظر النتيجة النهائية
    final products = await container.read(productsProvider.future);

    expect(products.single.sku, 'kb');
  });

  test('الحالات بالترتيب: loading ثم error', () async {
    when(() => api.fetchProducts()).thenThrow(Exception('offline'));
    final container = makeContainer();

    // listen يسجّل كل حالة جديدة (fireImmediately = سجّل الحالية أيضاً)
    final states = <AsyncValue<List<Product>>>[];
    container.listen(
      productsProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );

    await expectLater(
      container.read(productsProvider.future),
      throwsA(isA<ProductsException>()),
    );

    expect(states.first, isA<AsyncLoading<List<Product>>>());
    expect(states.last, isA<AsyncError<List<Product>>>());
  });

  test('CartNotifier: add و applyCoupon و المشتق cartCountProvider', () {
    final container = makeContainer();
    final cart = container.read(cartProvider.notifier);

    cart.add(keyboard);
    cart.add(keyboard);

    expect(container.read(cartCountProvider), 2);
    expect(cart.applyCoupon('FREE'), isFalse); // لا يرمي خطأ للـ UI
    expect(cart.applyCoupon('VIP25'), isTrue);
    expect(container.read(cartProvider).total, 180);
  });

  test('offlineProvider يعيد إنشاء الـ API الحقيقي (بدون Mock)', () {
    // بدون overrides: نختبر سلسلة الاعتماديات نفسها
    final container = ProviderContainer.test();

    final before = container.read(productApiProvider);
    container.read(offlineProvider.notifier).toggle();
    final after = container.read(productApiProvider);

    expect(identical(before, after), isFalse);
    expect((after as LocalProductApi).offline, isTrue);
  });
}
