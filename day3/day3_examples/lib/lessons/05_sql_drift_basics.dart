// ============================================================
// الدرس 5: SQL و Drift — الجداول، CRUD، العلاقات و JOIN
// في التطبيق: القائمة ← الدرس 5  ·  في العرض: شرائح الدرس 5
// ============================================================
//
// SQLite = قاعدة بيانات كاملة داخل ملف واحد على الجهاز (بدون خادم).
// Drift = طبقة فوق SQLite: نكتب الجداول والاستعلامات بـ Dart،
//         والمولّد (build_runner) يكتب الـ SQL والـ classes نيابةً عنا،
//         والمترجم يكتشف أخطاء أسماء الأعمدة والأنواع قبل التشغيل.
//
// المثال: متجر صغير — جدول categories وجدول products
// والعلاقة: كل منتج ينتمي إلى تصنيف (category_id ← categories.id) = One-to-Many
//
// التوليد: dart run build_runner build -d   ← ينشئ 05_sql_drift_basics.g.dart
// 💡 كل زر يطبع الـ SQL أولاً ثم كود Drift المكافئ ونتيجته في "الكونسول".

import 'package:drift/drift.dart' hide Column; // Column هنا = Widget من Flutter
import 'package:flutter/material.dart' hide Table;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/console_view.dart';
import '../shared/database_connection.dart';

part '05_sql_drift_basics.g.dart';

// ------------------------------------------------------------
// 1) الجداول — كل class = جدول، وكل getter = عمود
// ------------------------------------------------------------
// CREATE TABLE categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE)
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40).unique()();
}

// CREATE TABLE products (..., category_id INTEGER NOT NULL
//   REFERENCES categories (id))
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get price => real()();
  // العلاقة: مفتاح أجنبي (Foreign Key) يشير إلى categories.id
  IntColumn get categoryId => integer().references(Categories, #id)();
}

// ------------------------------------------------------------
// 2) قاعدة البيانات — المولّد ينشئ: Category و Product (صفوف)
//    و CategoriesCompanion و ProductsCompanion (للإدخال والتعديل)
// ------------------------------------------------------------
@DriftDatabase(tables: [Categories, Products])
class ShopDatabase extends _$ShopDatabase {
  ShopDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll(); // CREATE TABLE لكل الجداول
          await seed();
        },
        // SQLite لا تفحص المفاتيح الأجنبية إلا إذا فعّلناها في كل اتصال
        beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
      );

  Future<void> seed() async {
    final phones = await into(categories).insert(CategoriesCompanion.insert(name: 'هواتف'));
    final books = await into(categories).insert(CategoriesCompanion.insert(name: 'كتب'));
    final extras = await into(categories).insert(CategoriesCompanion.insert(name: 'إكسسوارات'));
    await into(categories).insert(CategoriesCompanion.insert(name: 'ألعاب')); // بدون منتجات

    // batch: عدة عمليات في رحلة واحدة إلى قاعدة البيانات (أسرع بكثير)
    await batch((b) => b.insertAll(products, [
          ProductsCompanion.insert(name: 'Pixel 9', price: 3299, categoryId: phones),
          ProductsCompanion.insert(name: 'Galaxy S24', price: 3499, categoryId: phones),
          ProductsCompanion.insert(name: 'Clean Code', price: 120, categoryId: books),
          ProductsCompanion.insert(name: 'Flutter in Action', price: 95, categoryId: books),
          ProductsCompanion.insert(name: 'شاحن سريع', price: 79, categoryId: extras),
          ProductsCompanion.insert(name: 'سماعة لاسلكية', price: 249, categoryId: extras),
        ]));
  }

  // ----------------------------------------------------------
  // CRUD — فوق كل دالة: الـ SQL المكافئ
  // ----------------------------------------------------------

  // INSERT INTO products (name, price, category_id) VALUES (?, ?, ?)
  Future<int> addProduct(String name, double price, int categoryId) =>
      into(products).insert(
        ProductsCompanion.insert(name: name, price: price, categoryId: categoryId),
      );

  // SELECT * FROM products WHERE price > ? ORDER BY price DESC
  Future<List<Product>> productsAbove(double minPrice) =>
      (select(products)
            ..where((p) => p.price.isBiggerThanValue(minPrice))
            ..orderBy([(p) => OrderingTerm.desc(p.price)]))
          .get();

  // UPDATE products SET price = price * 0.9 WHERE category_id = ?
  Future<int> discountCategory(int categoryId) =>
      (update(products)..where((p) => p.categoryId.equals(categoryId))).write(
        ProductsCompanion.custom(price: products.price * const Constant(0.9)),
      );

  // DELETE FROM products WHERE price < ?
  Future<int> deleteCheaperThan(double price) =>
      (delete(products)..where((p) => p.price.isSmallerThanValue(price))).go();

  // ----------------------------------------------------------
  // JOIN — نقرأ من جدولين مرتبطين في استعلام واحد
  // ----------------------------------------------------------

  // SELECT * FROM products INNER JOIN categories
  //   ON categories.id = products.category_id
  Future<List<(Product, Category)>> productsWithCategory() async {
    final query = select(products).join([
      innerJoin(categories, categories.id.equalsExp(products.categoryId)),
    ]);
    final rows = await query.get();
    return [
      for (final row in rows) (row.readTable(products), row.readTable(categories)),
    ];
  }

  // SELECT categories.name, COUNT(products.id) FROM categories
  // LEFT OUTER JOIN products ON products.category_id = categories.id
  // GROUP BY categories.id
  Future<List<(String, int)>> countPerCategory() async {
    final count = products.id.count();
    final query = select(categories).join([
      leftOuterJoin(products, products.categoryId.equalsExp(categories.id)),
    ])
      ..addColumns([count])
      ..groupBy([categories.id]);
    final rows = await query.get();
    return [
      for (final row in rows) (row.readTable(categories).name, row.read(count)!),
    ];
  }

  // SQL مباشر عند الحاجة — مع readsFrom ليعرف Drift أي جداول نقرأ
  Future<List<String>> rawSql() async {
    final rows = await customSelect(
      'SELECT name, price FROM products WHERE price BETWEEN ? AND ? ORDER BY price',
      variables: [Variable.withReal(50), Variable.withReal(300)],
      readsFrom: {products},
    ).get();
    return [for (final r in rows) '${r.read<String>('name')} — ${r.read<double>('price')}'];
  }

  Future<void> resetData() => transaction(() async {
        await delete(products).go();
        await delete(categories).go();
        await seed();
      });
}

// قاعدة البيانات عبر Provider — تُغلق تلقائياً عند التخلص من الـ provider
final shopDatabaseProvider = Provider<ShopDatabase>((ref) {
  final db = ShopDatabase(ref.watch(connectionProvider('shop')));
  ref.onDispose(db.close);
  return db;
});

// ------------------------------------------------------------
// 3) الشاشة: SQL ← Drift ← النتيجة
// ------------------------------------------------------------
class SqlDriftScreen extends ConsumerStatefulWidget {
  const SqlDriftScreen({super.key});

  @override
  ConsumerState<SqlDriftScreen> createState() => _SqlDriftScreenState();
}

class _SqlDriftScreenState extends ConsumerState<SqlDriftScreen> {
  final _logs = <String>[];
  bool _busy = false;

  ShopDatabase get _db => ref.read(shopDatabaseProvider);

  void _log(String line) {
    if (!mounted) return;
    setState(() => _logs.add(line));
  }

  Future<void> _run(String title, Future<void> Function() demo) async {
    setState(() {
      _busy = true;
      _logs
        ..clear()
        ..add('▶ $title');
    });
    try {
      await demo();
    } on DriftWrappedException catch (e) {
      _log('❌ SQLite: ${e.cause}');
    } catch (e) {
      // مثلاً: لا توجد SQLite أصلية على هذه المنصة
      _log('❌ تعذّر فتح قاعدة البيانات: $e');
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _schema() async {
    _log("SQL: SELECT sql FROM sqlite_master WHERE type = 'table'");
    final rows = await _db
        .customSelect("SELECT sql FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'")
        .get();
    for (final r in rows) {
      _log(r.read<String>('sql'));
    }
    _log('↑ هذا الـ SQL كتبه Drift من classes الجداول');
  }

  Future<void> _insert() async {
    _log('SQL: INSERT INTO products (name, price, category_id) VALUES (?, ?, ?)');
    final id = await _db.addProduct('iPad mini', 2299, 1);
    _log('Drift: into(products).insert(...) → id = $id');
  }

  Future<void> _select() async {
    _log('SQL: SELECT * FROM products WHERE price > 100 ORDER BY price DESC');
    for (final p in await _db.productsAbove(100)) {
      _log('• ${p.name} — ${p.price}');
    }
  }

  Future<void> _update() async {
    _log('SQL: UPDATE products SET price = price * 0.9 WHERE category_id = 1');
    final n = await _db.discountCategory(1);
    _log('Drift: update(products)..where(...).write(...) → عُدّل $n صف');
  }

  Future<void> _delete() async {
    _log('SQL: DELETE FROM products WHERE price < 100');
    final n = await _db.deleteCheaperThan(100);
    _log('Drift: delete(products)..where(...).go() → حُذف $n صف');
  }

  Future<void> _join() async {
    _log('SQL: SELECT * FROM products INNER JOIN categories ON …');
    for (final (product, category) in await _db.productsWithCategory()) {
      _log('• ${product.name} ← ${category.name}');
    }
  }

  Future<void> _groupBy() async {
    _log('SQL: … LEFT OUTER JOIN … GROUP BY categories.id');
    for (final (name, count) in await _db.countPerCategory()) {
      _log('• $name: $count منتج');
    }
    _log('LEFT JOIN يُظهر «ألعاب» بـ 0 — و INNER JOIN كان سيخفيها');
  }

  Future<void> _foreignKey() async {
    _log('SQL: INSERT INTO products (..., category_id) VALUES (..., 999)');
    await _db.addProduct('منتج يتيم', 10, 999); // لا يوجد تصنيف 999
    _log('لن نصل هنا: المفتاح الأجنبي يمنع الإدخال');
  }

  Future<void> _raw() async {
    _log('SQL: SELECT name, price FROM products WHERE price BETWEEN ? AND ?');
    for (final line in await _db.rawSql()) {
      _log('• $line');
    }
  }

  Future<void> _reset() async {
    await _db.resetData();
    _log('أُعيدت البيانات الأولية داخل transaction واحدة');
  }

  @override
  Widget build(BuildContext context) {
    final demos = <(String, Future<void> Function())>[
      ('0) المخطط CREATE', _schema),
      ('1) INSERT', _insert),
      ('2) SELECT', _select),
      ('3) UPDATE', _update),
      ('4) DELETE', _delete),
      ('5) INNER JOIN', _join),
      ('6) LEFT JOIN + COUNT', _groupBy),
      ('7) مفتاح أجنبي خاطئ', _foreignKey),
      ('8) SQL مباشر', _raw),
      ('↺ إعادة البيانات', _reset),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 5: SQL و Drift')),
      body: Column(
        children: [
          DemoButtons(demos: demos, busy: _busy, onRun: _run),
          Expanded(child: ConsoleView(lines: _logs, busy: _busy)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) بعد أي تعديل على الجداول أعد التوليد، أو اتركه يراقب التغييرات:
//      dart run build_runner watch -d
//
// 2) لرؤية كل SQL ينفّذه Drift: في الاختبارات
//      NativeDatabase.memory(logStatements: true)
//    وفي التطبيق: class يرث QueryInterceptor ويطبع الاستعلامات، ثم:
//      openConnection('shop').interceptWith(SqlLogger())
//
// 3) عدة عمليات مرتبطة؟ ضعها في transaction: إما أن تنجح كلها أو لا شيء:
//      await db.transaction(() async { await a(); await b(); });
//
// 4) الإدخال الكثير: batch((b) => b.insertAll(...)) أسرع بعشرات المرات من حلقة insert.
//
// 5) insertOnConflictUpdate = «أدخل أو حدّث إن وُجد» (upsert) — نستخدمها للكاش في الدرس 7:
//      await into(products).insertOnConflictUpdate(row);
