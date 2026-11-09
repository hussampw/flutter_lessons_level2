// الدرس 1: الدوال التي نرسلها إلى Isolate دوال عادية ← تُختبر مباشرة
import 'dart:isolate';

import 'package:day5_examples/lessons/01_isolates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('countPrimes يعدّ الأعداد الأولية بشكل صحيح', () {
    expect(countPrimes(10), 4); // 2, 3, 5, 7
    expect(countPrimes(100), 25);
  });

  test('Isolate.run تعيد نفس نتيجة الاستدعاء المباشر', () async {
    final result = await Isolate.run(() => countPrimes(10000));
    expect(result, countPrimes(10000));
  });

  test('parseProducts يحوّل JSON إلى قائمة منتجات', () {
    final products = parseProducts(buildBigJson(3));
    expect(products, hasLength(3));
    expect(products.last.id, 2);
    expect(products.last.title, 'منتج رقم 2');
    expect(products.last.price, 3.0);
  });
}
