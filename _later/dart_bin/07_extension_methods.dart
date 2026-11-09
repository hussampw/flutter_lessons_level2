// ============================================================
// الدرس 7: Extension Methods و Extension Types
// التشغيل: dart run bin/07_extension_methods.dart
// ============================================================
//
// الـ Extension تضيف دوال جديدة لأنواع موجودة (حتى لو لم نكتبها نحن)
// مثل String أو int أو BuildContext — بدون وراثة وبدون تعديل الأصل.

// ------------------------------------------------------------
// 1) Extension على String
// ------------------------------------------------------------
extension StringX on String {
  // تحقق بسيط من البريد الإلكتروني
  bool get isValidEmail => RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch(this);

  // أول حرف كبير
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  // تقصير النص الطويل مع ...
  String truncate(int max) => length <= max ? this : '${substring(0, max)}…';
}

// ------------------------------------------------------------
// 2) Extension على int لكتابة مدة زمنية بشكل مقروء
//    await Future.delayed(2.seconds) بدل Duration(seconds: 2)
// ------------------------------------------------------------
extension DurationX on int {
  Duration get seconds => Duration(seconds: this);
  Duration get ms => Duration(milliseconds: this);
}

// ------------------------------------------------------------
// 3) Extension عامة (Generic) على List<T>
// ------------------------------------------------------------
extension ListX<T> on List<T> {
  // نسخة آمنة من first لا ترمي خطأ في القائمة الفارغة
  T? get firstOrNull => isEmpty ? null : first;

  // تجميع العناصر حسب مفتاح
  Map<K, List<T>> groupBy<K>(K Function(T item) keyOf) {
    final map = <K, List<T>>{};
    for (final item in this) {
      map.putIfAbsent(keyOf(item), () => []).add(item);
    }
    return map;
  }
}

// ------------------------------------------------------------
// 4) Extension على نوع nullable
// ------------------------------------------------------------
extension NullableStringX on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  String orDefault([String fallback = '-']) => isNullOrEmpty ? fallback : this!;
}

// ------------------------------------------------------------
// 5) Extension على DateTime: صياغة "منذ ..." بالعربي
// ------------------------------------------------------------
extension DateTimeX on DateTime {
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}

// 💡 في Flutter نستخدمها كثيراً على BuildContext:
// extension ContextX on BuildContext {
//   ThemeData get theme => Theme.of(this);
//   Size get screenSize => MediaQuery.sizeOf(this);
//   void showSnack(String msg) =>
//       ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(msg)));
// }
// ثم: context.theme  و  context.showSnack('تم الحفظ')

// ------------------------------------------------------------
// 6) Extension Types (Dart 3.3+): نوع جديد "مجاني" فوق نوع موجود
//    لا يُنشئ كائن إضافي وقت التشغيل (zero-cost)
//    يمنع الخلط بين UserId و ProductId رغم أن كلاهما int
// ------------------------------------------------------------
extension type UserId(int value) {
  // يمكن إضافة تحقق في constructor مسمّى
  UserId.parse(String raw) : value = int.parse(raw);
  bool get isGuest => value == 0;
}

extension type ProductId(int value) {}

String loadUser(UserId id) => 'تحميل المستخدم ${id.value}';

void main() {
  print('--- 1) String ---');
  print('ali@mail.com'.isValidEmail); // true
  print('not-an-email'.isValidEmail); // false
  print('flutter'.capitalized);
  print('هذا نص طويل جداً يحتاج إلى تقصير'.truncate(12));

  print('\n--- 2) int → Duration ---');
  print(2.seconds);
  print(300.ms);

  print('\n--- 3) List<T> ---');
  print(<int>[].firstOrNull); // null بدل crash
  final words = ['تفاحة', 'توت', 'موز', 'مانجو', 'تين'];
  print(words.groupBy((w) => w[0]));

  print('\n--- 4) nullable ---');
  String? nickname;
  print(nickname.isNullOrEmpty);
  print(nickname.orDefault('بدون لقب'));

  print('\n--- 5) DateTime ---');
  print(DateTime.now().subtract(const Duration(minutes: 5)).timeAgo);
  print(DateTime.now().subtract(const Duration(days: 3)).timeAgo);

  print('\n--- 6) Extension Types ---');
  final userId = UserId(7);
  final productId = ProductId(7);
  print(loadUser(userId));
  // loadUser(productId); ← خطأ ترجمة! رغم أن الاثنين int ✅
  // loadUser(7);         ← خطأ ترجمة أيضاً
  print('productId = ${productId.value}');
  print('UserId.parse: ${UserId.parse('0').isGuest}');

  // 📌 تنبيه: الـ extensions تعتمد على النوع الثابت (static type)
  // لذلك لا تعمل مع متغير dynamic:  dynamic x = 'a'; x.capitalized ← خطأ وقت التشغيل
}
