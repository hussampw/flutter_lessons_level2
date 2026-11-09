// ============================================================
// الدرس 5: Sealed Classes و Pattern Matching
// التشغيل: dart run bin/05_sealed_pattern_matching.dart
// ============================================================
//
// sealed class = class "مغلقة": كل الأنواع الفرعية معروفة في نفس الملف.
// الفائدة: المترجم (compiler) يتأكد أنك غطّيت كل الحالات في switch.
// إذا أضفت حالة جديدة ونسيت معالجتها ← خطأ وقت الترجمة وليس crash للمستخدم!

// ------------------------------------------------------------
// 1) مثال كلاسيكي: الأشكال الهندسية
// ------------------------------------------------------------
sealed class Shape {}

class Circle extends Shape {
  Circle(this.radius);
  final double radius;
}

class Square extends Shape {
  Square(this.side);
  final double side;
}

class Rectangle extends Shape {
  Rectangle(this.width, this.height);
  final double width, height;
}

// switch expression: لا نحتاج default لأن الـ sealed تضمن التغطية الكاملة
// جرّب حذف أي سطر ← سيظهر خطأ: The type 'Shape' is not exhaustively matched
double area(Shape shape) => switch (shape) {
      Circle(:final radius) => 3.14 * radius * radius,
      Square(:final side) => side * side,
      Rectangle(:final width, :final height) => width * height,
    };

// ------------------------------------------------------------
// 2) مثال عملي جداً: نتيجة طلب شبكة Result
//    (سنستخدم نفس الفكرة مع Riverpod و Networking لاحقاً)
// ------------------------------------------------------------
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

class Failure<T> extends Result<T> {
  const Failure(this.message, {this.code});
  final String message;
  final int? code;
}

class Loading<T> extends Result<T> {
  const Loading();
}

String render(Result<List<String>> result) => switch (result) {
      Loading() => '⏳ جاري التحميل...',
      // guard باستخدام when: شرط إضافي على النمط
      Success(data: final items) when items.isEmpty => '📭 لا توجد بيانات',
      Success(data: final items) => '✅ ${items.length} عناصر: $items',
      Failure(code: 401) => '🔒 يجب تسجيل الدخول',
      Failure(:final message) => '❌ $message',
    };

void main() {
  print('--- 1) Sealed + switch ---');
  final shapes = <Shape>[Circle(2), Square(3), Rectangle(2, 5)];
  for (final s in shapes) {
    print('${s.runtimeType}: ${area(s)}');
  }

  print('\n--- 2) Result ---');
  final states = <Result<List<String>>>[
    const Loading(),
    const Success([]),
    const Success(['أحمد', 'ليلى']),
    const Failure('انتهت الجلسة', code: 401),
    const Failure('لا يوجد إنترنت'),
  ];
  states.map(render).forEach(print);

  // ------------------------------------------------------------
  // 3) أنواع الأنماط (Patterns) الأخرى
  // ------------------------------------------------------------
  print('\n--- 3) أنواع الأنماط ---');

  // نمط القائمة (List pattern) مع ...rest
  final numbers = [1, 2, 3, 4, 5];
  if (numbers case [final first, final second, ...final rest]) {
    print('الأول=$first الثاني=$second الباقي=$rest');
  }

  // نمط الـ Map: مفيد جداً للتحقق من JSON
  final json = <String, dynamic>{
    'user': {'name': 'خالد', 'age': 30},
  };
  if (json case {'user': {'name': String name, 'age': int age}}) {
    print('JSON صالح: $name ($age)');
  } else {
    print('JSON غير صالح');
  }

  // الأنماط المنطقية والعلائقية: || و && و > و <
  String classify(int score) => switch (score) {
        >= 90 && <= 100 => 'ممتاز',
        >= 75 && < 90 => 'جيد جداً',
        >= 50 && < 75 => 'مقبول',
        < 0 || > 100 => 'درجة غير صالحة',
        _ => 'راسب',
      };
  for (final s in [95, 80, 60, 30, 150]) {
    print('$s ← ${classify(s)}');
  }

  // نمط النوع مع null-check (مفيد مع قيم dynamic القادمة من JSON)
  String describe(Object? value) => switch (value) {
        null => 'فارغ',
        String s when s.length > 3 => 'نص طويل: $s',
        String s => 'نص قصير: $s',
        int() || double() => 'رقم',
        _ => 'نوع آخر',
      };
  for (final v in <Object?>['مرحبا', 'هلا', 42, null, true]) {
    print(describe(v));
  }

  // 📌 كلمات Dart 3 المفيدة مع الـ classes:
  // sealed    ← حالات مغلقة + switch شامل
  // final     ← لا يمكن الوراثة منها خارج المكتبة
  // base      ← وراثة فقط (لا implements) خارج المكتبة
  // interface ← implements فقط (لا extends) خارج المكتبة
}
