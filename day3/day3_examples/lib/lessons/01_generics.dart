// ============================================================
// الدرس 1 (Dart): Generics — كود واحد يعمل مع أنواع متعددة
// في التطبيق: القائمة ← الدرس 1  ·  في العرض: شرائح الدرس 1
// ============================================================
//
// بدل كتابة UserRepository و ProductRepository و OrderRepository
// بنفس المنطق تقريباً، نكتب Repository<T> واحداً.
// الـ Generics تعطينا: إعادة استخدام + أمان الأنواع (Type Safety).
//
// لماذا اليوم؟ كل ما سنراه لاحقاً مبني عليها:
//   Future<T> · Stream<T> (الدرس 2) · Provider<T> · Drift: Stream<List<Note>> (الدرس 6)
//   Result<T> (الدروس 8 و 9) · Repository<T> (الدرس 8)
//
// 💡 كل زر في الشاشة ينفّذ مثالاً ويكتب النتيجة في "الكونسول".

import 'package:flutter/material.dart';

import '../shared/console_view.dart';
import '../shared/result.dart';

// ------------------------------------------------------------
// 1) Class عام بسيط
// ------------------------------------------------------------
class Box<T> {
  Box(this.value);
  final T value;

  // دالة عامة داخل class عام: نحوّل Box<T> إلى Box<R>
  Box<R> map<R>(R Function(T value) transform) => Box(transform(value));

  @override
  String toString() => 'Box<$T>($value)';
}

// ------------------------------------------------------------
// 2) دالة عامة (Generic function)
// ------------------------------------------------------------
T firstOrDefault<T>(List<T> items, T defaultValue) =>
    items.isEmpty ? defaultValue : items.first;

// ------------------------------------------------------------
// 3) القيود (Bounded generics): T extends num
//    T يجب أن يكون رقماً، لذلك نستطيع استخدام + و >
// ------------------------------------------------------------
T maxOf<T extends num>(List<T> values) =>
    values.reduce((a, b) => a > b ? a : b);

// قيد بواجهة: كل نموذج يجب أن يملك id
abstract interface class Entity {
  String get id;
}

class User implements Entity {
  User(this.id, this.name);
  @override
  final String id;
  final String name;
  @override
  String toString() => 'User($name)';
}

class Product implements Entity {
  Product(this.id, this.title, this.price);
  @override
  final String id;
  final String title;
  final double price;
  @override
  String toString() => 'Product($title, $price)';
}

// ------------------------------------------------------------
// 4) Repository عام — نمط سنستخدمه في الدرس 8 (Clean Architecture)
// ------------------------------------------------------------
abstract class Repository<T extends Entity> {
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<void> save(T item);
}

// تنفيذ في الذاكرة يعمل مع أي Entity
class InMemoryRepository<T extends Entity> implements Repository<T> {
  final _store = <String, T>{};

  @override
  Future<List<T>> getAll() async => _store.values.toList();

  @override
  Future<T?> getById(String id) async => _store[id];

  @override
  Future<void> save(T item) async => _store[item.id] = item;
}

// ------------------------------------------------------------
// 5) Typedef عام لدوال الـ callback
// ------------------------------------------------------------
typedef JsonFactory<T> = T Function(Map<String, dynamic> json);

// دالة تحوّل قائمة JSON إلى قائمة نماذج من أي نوع
List<T> parseList<T>(List<Map<String, dynamic>> raw, JsonFactory<T> fromJson) =>
    raw.map(fromJson).toList();

// ------------------------------------------------------------
// 6) Result<T> — في lib/shared/result.dart:
//    sealed class Result<T> → Success<T>(value) أو Failure<T>(message)
//    الدالة لا ترمي استثناء، بل تعيد النتيجة كقيمة يجب التعامل معها
// ------------------------------------------------------------
Future<Result<Product>> findProduct(Repository<Product> repo, String id) async {
  final product = await repo.getById(id);
  if (product == null) return Failure('لا يوجد منتج بالرقم $id');
  return Success(product);
}

class GenericsScreen extends StatefulWidget {
  const GenericsScreen({super.key});

  @override
  State<GenericsScreen> createState() => _GenericsScreenState();
}

class _GenericsScreenState extends State<GenericsScreen> {
  final _logs = <String>[];
  bool _busy = false;

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
    await demo();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _boxDemo() async {
    final intBox = Box(42); // Dart يستنتج النوع: Box<int>
    final textBox = intBox.map((v) => 'القيمة $v'); // Box<String>
    _log('$intBox → $textBox');
    _log('firstOrDefault: ${firstOrDefault(<String>[], 'افتراضي')}');
    _log('firstOrDefault: ${firstOrDefault([10, 20], 0)}');
  }

  Future<void> _boundsDemo() async {
    _log('أكبر int: ${maxOf([3, 9, 2])}');
    _log('أكبر double: ${maxOf([1.5, 0.2, 7.8])}');
    // maxOf(['a', 'b']); ← خطأ ترجمة: String ليس num ✅
    _log("maxOf(['a', 'b']) ← لا يُترجم أصلاً: String ليس num");
  }

  Future<void> _repositoryDemo() async {
    final users = InMemoryRepository<User>();
    final products = InMemoryRepository<Product>();
    await users.save(User('u1', 'نورة'));
    await products.save(Product('p1', 'لابتوب', 3500));
    _log('users: ${await users.getAll()}');
    _log('products.getById: ${await products.getById('p1')}');
    // users.save(Product(...)); ← خطأ ترجمة: النوع محمي ✅
    _log('users.save(Product(...)) ← خطأ ترجمة: النوع محمي');
  }

  Future<void> _jsonDemo() async {
    final parsed = parseList(
      [
        {'id': '1', 'name': 'سامي'},
        {'id': '2', 'name': 'هدى'},
      ],
      (json) => User(json['id'] as String, json['name'] as String),
    );
    _log('parseList<User>: $parsed');
    // 📌 لماذا لا نستخدم dynamic بدل الـ Generics؟
    // dynamic يلغي فحص الأنواع ← الأخطاء تظهر وقت التشغيل (crash)
    _log('النوع المستنتج: ${parsed.runtimeType}');
  }

  Future<void> _resultDemo() async {
    final repo = InMemoryRepository<Product>();
    await repo.save(Product('p1', 'سماعة', 199));

    for (final id in ['p1', 'p9']) {
      final result = await findProduct(repo, id);
      // switch على sealed class: المترجم يجبرنا على تغطية الحالتين
      final text = switch (result) {
        Success(:final value) => '✅ ${value.title} بسعر ${value.price}',
        Failure(:final message) => '❌ $message',
      };
      _log('findProduct($id) → $text');
    }

    // map<R>: نحوّل Result<Product> إلى Result<double> بدون فك يدوي
    final price = (await findProduct(repo, 'p1')).map((p) => p.price * 1.15);
    _log('السعر مع الضريبة: $price');
  }

  @override
  Widget build(BuildContext context) {
    final demos = <(String, Future<void> Function())>[
      ('1) Box<T> و دالة عامة', _boxDemo),
      ('2) القيود extends', _boundsDemo),
      ('3) Repository<T>', _repositoryDemo),
      ('4) JsonFactory<T>', _jsonDemo),
      ('5) Result<T>', _resultDemo),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 1: Generics')),
      body: Column(
        children: [
          DemoButtons(demos: demos, busy: _busy, onRun: _run),
          Expanded(child: ConsoleView(lines: _logs, busy: _busy)),
          const _GenericWidgetDemo(),
        ],
      ),
    );
  }
}

// ============================================================
// 6) Widget عام: ChoiceRow<T> يعمل مع أي نوع (enum، int، String…)
// ============================================================
// نفس الفكرة في Flutter نفسه: DropdownButton<T> · FutureBuilder<T> · ValueListenableBuilder<T>

class ChoiceRow<T> extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.options,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> options;
  final T selected;
  final String Function(T option) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(label(option)),
            selected: option == selected,
            onSelected: (_) => onSelected(option),
          ),
      ],
    );
  }
}

enum SortOrder { newest, cheapest, popular }

class _GenericWidgetDemo extends StatefulWidget {
  const _GenericWidgetDemo();

  @override
  State<_GenericWidgetDemo> createState() => _GenericWidgetDemoState();
}

class _GenericWidgetDemoState extends State<_GenericWidgetDemo> {
  SortOrder _order = SortOrder.newest;
  int _pageSize = 20;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              '6) Widget عام: ChoiceRow<T>',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            // T = SortOrder (يُستنتج تلقائياً من options)
            ChoiceRow(
              options: SortOrder.values,
              selected: _order,
              label: (o) => switch (o) {
                SortOrder.newest => 'الأحدث',
                SortOrder.cheapest => 'الأرخص',
                SortOrder.popular => 'الأكثر طلباً',
              },
              onSelected: (o) => setState(() => _order = o),
            ),
            // T = int — نفس الـ Widget بدون أي تعديل
            ChoiceRow(
              options: const [10, 20, 50],
              selected: _pageSize,
              label: (n) => '$n عنصر',
              onSelected: (n) => setState(() => _pageSize = n),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) حدّد النوع عند إنشاء مجموعة فارغة، وإلا تصبح List<dynamic>:
//      final ids = <int>[];          ✅
//      final ids = [];               ❌ List<dynamic>
//
// 2) فعّل في analysis_options.yaml الفحص الصارم ليمنع dynamic الضمني:
//      analyzer:
//        language:
//          strict-raw-types: true
//          strict-inference: true
//
// 3) عند استدعاء دالة عامة والمترجم لا يستطيع الاستنتاج، مرّر النوع صراحة:
//      final user = await cache.read<User>('me');
//
// 4) whereType<T>() تفلتر وتحوّل النوع في خطوة واحدة:
//      final products = items.whereType<Product>().toList(); // List<Product>
//
// 5) لا تبالغ: إذا كان الـ class يُستخدم مع نوع واحد فقط فلا تجعله عاماً.
