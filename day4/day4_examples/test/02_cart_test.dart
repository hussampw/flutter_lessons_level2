// ============================================================
// الدرس 2 (Testing): Unit tests لمنطق السلة — بدون شاشة وبدون شبكة
// التشغيل: flutter test test/02_cart_test.dart
// ============================================================

import 'package:day4_examples/lessons/02_unit_tests.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const keyboard = Product(sku: 'kb', name: 'لوحة مفاتيح', price: 120);
  const mouse = Product(sku: 'ms', name: 'فأرة لاسلكية', price: 45.5);

  // group: يجمع اختبارات نفس الوحدة تحت اسم واحد في التقرير
  group('Cart', () {
    late Cart cart;

    // setUp: يعمل قبل كل test ← كل اختبار يبدأ من حالة نظيفة
    setUp(() => cart = const Cart());

    test('سلة جديدة فارغة', () {
      expect(cart.count, 0);
      expect(cart.total, 0);
    });

    test('إضافة نفس المنتج مرتين تزيد الكمية', () {
      // Arrange + Act
      cart = cart.add(keyboard).add(keyboard).add(mouse);

      // Assert
      expect(cart.count, 3);
      expect(cart.lines['kb']?.$2, 2);
      expect(cart.subtotal, 285.5);
    });

    test('remove ينقص الكمية ثم يحذف السطر', () {
      cart = cart.add(keyboard).add(keyboard);

      cart = cart.remove('kb');
      expect(cart.lines['kb']?.$2, 1);

      cart = cart.remove('kb');
      expect(cart.lines.containsKey('kb'), isFalse);
      expect(cart.remove('غير موجود'), same(cart)); // لا تغيير
    });

    test('SAVE10 يخصم 10%', () {
      cart = cart.add(keyboard).add(mouse).applyCoupon(' save10 ');

      expect(cart.coupon, 'SAVE10');
      // closeTo بدل == لأن الأرقام العشرية غير دقيقة
      expect(cart.discount, closeTo(16.55, 0.001));
      expect(cart.total, closeTo(148.95, 0.001));
    });

    test('كوبون غير معروف يرمي ArgumentError', () {
      // نمرّر دالة (وليس النتيجة) حتى يلتقط expect الخطأ
      expect(() => cart.applyCoupon('FREE'), throwsArgumentError);
    });

    test('Cart immutable: add لا يغيّر السلة القديمة', () {
      final before = cart;
      final after = before.add(mouse);

      expect(before.count, 0);
      expect(after.count, 1);
    });
  });
}
