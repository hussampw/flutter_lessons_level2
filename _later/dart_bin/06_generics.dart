// ============================================================
// الدرس 6: Generics — كتابة كود واحد يعمل مع أنواع متعددة
// التشغيل: dart run bin/06_generics.dart
// ============================================================
//
// بدل كتابة UserRepository و ProductRepository و OrderRepository
// بنفس المنطق تقريباً، نكتب Repository<T> واحد.
// الـ Generics تعطينا: إعادة استخدام + أمان الأنواع (Type Safety).

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
// 4) Repository عام — نمط سنستخدمه كثيراً في المشاريع الحقيقية
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
typedef Mapper<A, B> = B Function(A input);
typedef JsonFactory<T> = T Function(Map<String, dynamic> json);

// دالة تحوّل قائمة JSON إلى قائمة نماذج من أي نوع
List<T> parseList<T>(List<Map<String, dynamic>> raw, JsonFactory<T> fromJson) =>
    raw.map(fromJson).toList();

Future<void> main() async {
  print('--- 1) Box<T> ---');
  final intBox = Box(42); // Dart يستنتج النوع: Box<int>
  final textBox = intBox.map((v) => 'القيمة $v'); // Box<String>
  print('$intBox → $textBox');

  print('\n--- 2) دالة عامة ---');
  print(firstOrDefault(<String>[], 'افتراضي'));
  print(firstOrDefault([10, 20], 0));

  print('\n--- 3) القيود ---');
  print('أكبر int: ${maxOf([3, 9, 2])}');
  print('أكبر double: ${maxOf([1.5, 0.2, 7.8])}');
  // maxOf(['a', 'b']); ← خطأ ترجمة: String ليس num ✅

  print('\n--- 4) Repository<T> ---');
  final users = InMemoryRepository<User>();
  final products = InMemoryRepository<Product>();
  await users.save(User('u1', 'نورة'));
  await products.save(Product('p1', 'لابتوب', 3500));
  print(await users.getAll());
  print(await products.getById('p1'));
  // users.save(Product(...)); ← خطأ ترجمة: النوع محمي ✅

  print('\n--- 5) JsonFactory<T> ---');
  final parsed = parseList(
    [
      {'id': '1', 'name': 'سامي'},
      {'id': '2', 'name': 'هدى'},
    ],
    (json) => User(json['id'] as String, json['name'] as String),
  );
  print(parsed);

  // 📌 لماذا لا نستخدم dynamic بدل الـ Generics؟
  // dynamic يلغي فحص الأنواع ← الأخطاء تظهر وقت التشغيل (crash)
  // Generics تكتشف الأخطاء وقت الكتابة + الإكمال التلقائي يعمل
}
