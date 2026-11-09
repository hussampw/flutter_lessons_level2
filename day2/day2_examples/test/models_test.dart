// ============================================================
// اختبار الدرس 2: نماذج freezed + json_serializable
// التشغيل: flutter test test/models_test.dart
// ============================================================

import 'package:day2_examples/lessons/02_freezed_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Product.fromJson: int ← double و @JsonKey و @Default', () {
    final p = Product.fromJson({
      'id': 2,
      'title': 'Eyeshadow Palette',
      'price': 20, // int في JSON
      'discountPercentage': 5.5,
    });

    expect(p.price, 20.0);
    expect(p.discount, 5.5); // @JsonKey(name: 'discountPercentage')
    expect(p.rating, 0); // @Default(0)
    expect(p, Product.fromJson(p.toJson())); // == مولّدة + رحلة ذهاب وعودة
  });

  test('ProductsPage: قائمة متداخلة و explicitToJson', () {
    final page = ProductsPage.fromJson({
      'products': [
        {'id': 1, 'title': 'A', 'price': 1.5},
      ],
      'total': 194,
      'skip': 0,
      'limit': 1,
    });

    expect(page.products.single.title, 'A');
    expect(page.toJson()['products'], isA<List<Map<String, dynamic>>>());
  });

  test('حقل مطلوب ناقص ← خطأ وليس null صامتاً', () {
    expect(() => Product.fromJson({'id': 3, 'title': 'بدون سعر'}),
        throwsA(isA<TypeError>()));
  });
}
