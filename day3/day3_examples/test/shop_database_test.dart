// ============================================================
// الدرس 5: اختبار قاعدة بيانات Drift في الذاكرة (بدون ملف وبدون جهاز)
// التشغيل: flutter test test/shop_database_test.dart
// ============================================================

import 'package:day3_examples/lessons/05_sql_drift_basics.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ShopDatabase db;

  setUp(() {
    // قاعدة جديدة فارغة لكل اختبار ← onCreate يضيف البيانات الأولية
    db = ShopDatabase(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  test('SELECT مع where و orderBy', () async {
    final expensive = await db.productsAbove(1000);
    expect(expensive.map((p) => p.name), ['Galaxy S24', 'Pixel 9']);
  });

  test('INSERT ثم UPDATE ثم DELETE', () async {
    final id = await db.addProduct('iPad mini', 2000, 1);
    expect(id, greaterThan(0));

    expect(await db.discountCategory(1), 3); // 3 هواتف بعد الإضافة
    final ipad = (await db.productsAbove(0)).firstWhere((p) => p.id == id);
    expect(ipad.price, closeTo(1800, 0.001));

    expect(await db.deleteCheaperThan(100), 2); // Flutter in Action + الشاحن
  });

  test('INNER JOIN يعيد المنتج مع تصنيفه', () async {
    final rows = await db.productsWithCategory();
    expect(rows, hasLength(6));
    final (product, category) = rows.firstWhere((r) => r.$1.name == 'Clean Code');
    expect(product.categoryId, category.id);
    expect(category.name, 'كتب');
  });

  test('LEFT JOIN + COUNT يُظهر التصنيف الفارغ بصفر', () async {
    final counts = Map.fromEntries(
      (await db.countPerCategory()).map((r) => MapEntry(r.$1, r.$2)),
    );
    expect(counts, {'هواتف': 2, 'كتب': 2, 'إكسسوارات': 2, 'ألعاب': 0});
  });

  test('المفتاح الأجنبي يمنع منتجاً بتصنيف غير موجود', () async {
    expect(
      () => db.addProduct('منتج يتيم', 10, 999),
      throwsA(isA<SqliteException>()),
    );
  });
}
