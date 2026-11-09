// ============================================================
// الدرس 2 (Testing): mocktail — نستبدل الـ API بـ Mock ونتحكم بالرد
// التشغيل: flutter test test/02_product_repository_test.dart
// ============================================================

import 'package:day4_examples/lessons/02_unit_tests.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// Mock = class فارغة ترث من Mock وتطبّق الواجهة — بدون توليد كود
class MockProductApi extends Mock implements ProductApi {}

void main() {
  late MockProductApi api;
  late ProductRepository repo;

  setUp(() {
    api = MockProductApi();
    repo = ProductRepository(api); // نحقن الـ Mock عبر الـ constructor
  });

  test('يحوّل JSON إلى قائمة Product', () async {
    // Arrange: when(...).thenAnswer للدوال التي تعيد Future
    when(() => api.fetchProducts()).thenAnswer(
      (_) async => [
        {'sku': 'kb', 'name': 'لوحة مفاتيح', 'price': 120},
      ],
    );

    // Act
    final products = await repo.getProducts();

    // Assert
    expect(products, hasLength(1));
    expect(products.first.name, 'لوحة مفاتيح');
    expect(products.first.price, isA<double>());
  });

  test('الكاش: نداءان للـ Repository = طلب واحد للـ API', () async {
    when(() => api.fetchProducts()).thenAnswer((_) async => []);

    await repo.getProducts();
    await repo.getProducts();

    // verify: نتحقق كم مرة نُوديت الدالة
    verify(() => api.fetchProducts()).called(1);
  });

  test('refresh: true يتجاوز الكاش', () async {
    when(() => api.fetchProducts()).thenAnswer((_) async => []);

    await repo.getProducts();
    await repo.getProducts(refresh: true);

    verify(() => api.fetchProducts()).called(2);
  });

  test('خطأ الشبكة يتحوّل إلى ProductsException', () async {
    when(() => api.fetchProducts()).thenThrow(Exception('timeout'));

    // مع Future نستخدم expectLater + throwsA
    await expectLater(repo.getProducts(), throwsA(isA<ProductsException>()));
  });

  test('لا طلب للشبكة قبل أن نطلب المنتجات', () {
    verifyNever(() => api.fetchProducts());
  });
}
