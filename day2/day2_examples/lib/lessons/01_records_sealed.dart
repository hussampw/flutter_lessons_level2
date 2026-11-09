// ============================================================
// الدرس 1 (Dart): Records و Sealed classes و Pattern matching
// في التطبيق: القائمة ← الدرس 1  ·  في العرض: شرائح الدرس 1
// ============================================================
//
// ثلاث ميزات من Dart 3 سنستخدمها طوال اليوم:
//   Record        ← مجموعة قيم بدون class: إرجاع أكثر من قيمة، مفتاح مركّب
//   sealed class  ← كل الحالات معروفة، والمترجم يجبرك على تغطيتها في switch
//   Patterns      ← تفكيك القيم وفحصها في سطر واحد (switch / if-case)
//
// اليوم: AppFailure في الدرس 7 sealed class، و extra في الدرس 3 Record،
// و AsyncValue من اليوم الأول هو أيضاً sealed class.
//
// 💡 كل زر في الشاشة ينفّذ مثالاً ويكتب النتيجة في "الكونسول".

import 'package:flutter/material.dart';

// ============================================================
// الجزء الأول: Records
// ============================================================

// 1) إرجاع أكثر من قيمة من دالة — أشهر استخدام
(double min, double max) minMax(List<double> values) {
  var min = values.first, max = values.first;
  for (final v in values) {
    if (v < min) min = v;
    if (v > max) max = v;
  }
  return (min, max);
}

// 2) Record بحقول مسمّاة — أوضح عند القراءة
({String name, int age, String? email}) parseUser(Map<String, dynamic> json) {
  return (
    name: json['name'] as String,
    age: json['age'] as int,
    email: json['email'] as String?,
  );
}

// 3) typedef لإعطاء اسم للـ Record وإعادة استخدامه
typedef Point = ({double x, double y});

double distanceSquared(Point p) => p.x * p.x + p.y * p.y;

// ============================================================
// الجزء الثاني: Sealed classes
// ============================================================
//
// sealed class = class "مغلقة": كل الأنواع الفرعية معروفة في نفس الملف.
// إذا أضفت حالة جديدة ونسيت معالجتها ← خطأ وقت الترجمة وليس crash للمستخدم!

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
// جرّب حذف أي سطر ← خطأ: The type 'Shape' is not exhaustively matched
double area(Shape shape) => switch (shape) {
  Circle(:final radius) => 3.14 * radius * radius,
  Square(:final side) => side * side,
  Rectangle(:final width, :final height) => width * height,
};

// مثال عملي: نتيجة طلب شبكة (نفس الفكرة في الدرس 7 مع Dio)
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

// الأنماط المنطقية والعلائقية: && و || و >= و <
String classify(int score) => switch (score) {
  >= 90 && <= 100 => 'ممتاز',
  >= 75 && < 90 => 'جيد جداً',
  >= 50 && < 75 => 'مقبول',
  < 0 || > 100 => 'درجة غير صالحة',
  _ => 'راسب',
};

// نمط النوع مع null-check (مفيد مع قيم dynamic القادمة من JSON)
String describe(Object? value) => switch (value) {
  null => 'فارغ',
  String s when s.length > 3 => 'نص طويل: $s',
  String s => 'نص قصير: $s',
  int() || double() => 'رقم',
  _ => 'نوع آخر',
};

class RecordsSealedScreen extends StatefulWidget {
  const RecordsSealedScreen({super.key});

  @override
  State<RecordsSealedScreen> createState() => _RecordsSealedScreenState();
}

class _RecordsSealedScreenState extends State<RecordsSealedScreen> {
  final _logs = <String>[];

  void _log(String line) => _logs.add(line);

  void _run(String title, void Function() demo) {
    setState(() {
      _logs
        ..clear()
        ..add('▶ $title');
      demo();
    });
  }

  // ------------------------------------------------------------
  // 1) Records: موضعي، مسمّى، تفكيك، مساواة، تبديل
  // ------------------------------------------------------------
  void _recordsBasics() {
    // Record موضعي (positional): نصل للحقول بـ $1 و $2
    final pair = ('Flutter', 2026);
    _log('${pair.$1} - ${pair.$2}');

    // التفكيك (Destructuring) مباشرة إلى متغيرات
    final (min, max) = minMax([4, 9, 1, 7]);
    _log('الأصغر: $min ، الأكبر: $max');

    // حقول مسمّاة + تفكيكها: :name تعني name: name
    final user = parseUser({'name': 'سارة', 'age': 25});
    final (:name, :age, email: _) = user;
    _log('$name عمرها $age — البريد: ${user.email ?? 'لا يوجد'}');

    // المساواة بالقيمة (عكس الـ class العادي)
    const Point a = (x: 1, y: 2);
    const Point b = (x: 1, y: 2);
    _log('a == b ؟ ${a == b}  ·  المسافة²: ${distanceSquared(a)}');

    // تبديل قيمتين في سطر واحد
    var first = 'أ', second = 'ب';
    (first, second) = (second, first);
    _log('بعد التبديل: $first, $second');
  }

  // ------------------------------------------------------------
  // 2) Records مع switch و for — نمط الـ Record ونمط الكائن
  // ------------------------------------------------------------
  void _recordsPatterns() {
    for (final response in [(200, 'تم'), (404, ''), (503, '')]) {
      final text = switch (response) {
        (200, final msg) => 'نجاح: $msg',
        (404, _) => 'غير موجود',
        (>= 500, _) => 'خطأ في الخادم',
        _ => 'حالة أخرى',
      };
      _log('${response.$1} ← $text');
    }

    // التكرار على المفتاح والقيمة معاً (نمط كائن MapEntry)
    final scores = {'علي': 90, 'منى': 85};
    for (final MapEntry(key: student, value: score) in scores.entries) {
      _log('$student: $score ← ${classify(score)}');
    }
  }

  // ------------------------------------------------------------
  // 3) Sealed: switch شامل بدون default
  // ------------------------------------------------------------
  void _sealedShapes() {
    final shapes = <Shape>[Circle(2), Square(3), Rectangle(2, 5)];
    for (final s in shapes) {
      _log('${s.runtimeType}: ${area(s)}');
    }
    final states = <Result<List<String>>>[
      const Loading(),
      const Success([]),
      const Success(['أحمد', 'ليلى']),
      const Failure('انتهت الجلسة', code: 401),
      const Failure('لا يوجد إنترنت'),
    ];
    states.map(render).forEach(_log);
  }

  // ------------------------------------------------------------
  // 4) أنماط أخرى: List و Map (التحقق من JSON) والأنواع
  // ------------------------------------------------------------
  void _otherPatterns() {
    // نمط القائمة مع ...rest
    final numbers = [1, 2, 3, 4, 5];
    if (numbers case [final first, final second, ...final rest]) {
      _log('الأول=$first الثاني=$second الباقي=$rest');
    }

    // نمط الـ Map: يتحقق من الشكل والأنواع معاً
    final json = <String, dynamic>{
      'user': {'name': 'خالد', 'age': 30},
    };
    if (json case {'user': {'name': String name, 'age': int age}}) {
      _log('JSON صالح: $name ($age)');
    } else {
      _log('JSON غير صالح');
    }

    for (final v in <Object?>['مرحبا', 'هلا', 42, null, true]) {
      _log(describe(v));
    }
  }

  @override
  Widget build(BuildContext context) {
    final demos = <(String, void Function())>[
      ('1) Records', _recordsBasics),
      ('2) Records + switch', _recordsPatterns),
      ('3) Sealed', _sealedShapes),
      ('4) List/Map patterns', _otherPatterns),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 1: Records و Sealed classes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, demo) in demos)
                  FilledButton.tonal(
                    onPressed: () => _run(label, demo),
                    child: Text(label),
                  ),
              ],
            ),
          ),
          Expanded(child: ConsoleView(lines: _logs)),
          const _SealedInUiDemo(),
        ],
      ),
    );
  }
}

// ============================================================
// 5) sealed داخل الـ UI: switch يعيد Widget لكل حالة
// ============================================================
// نفس الأسلوب الذي استخدمناه مع AsyncValue في اليوم الأول (الدرس 5).

class _SealedInUiDemo extends StatefulWidget {
  const _SealedInUiDemo();

  @override
  State<_SealedInUiDemo> createState() => _SealedInUiDemoState();
}

class _SealedInUiDemoState extends State<_SealedInUiDemo> {
  static const _states = <(String, Result<List<String>>)>[
    ('تحميل', Loading()),
    ('فارغ', Success([])),
    ('بيانات', Success(['أحمد', 'ليلى'])),
    ('401', Failure('انتهت الجلسة', code: 401)),
    ('خطأ', Failure('لا يوجد إنترنت')),
  ];
  int _selected = 2;

  @override
  Widget build(BuildContext context) {
    final result = _states[_selected].$2;
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 8,
          children: [
            Text(
              '5) sealed في الـ UI: اختر حالة',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              spacing: 6,
              children: [
                for (final (i, (label, _)) in _states.indexed)
                  ChoiceChip(
                    label: Text(label),
                    selected: i == _selected,
                    onSelected: (_) => setState(() => _selected = i),
                  ),
              ],
            ),
            SizedBox(
              height: 56,
              child: Center(
                // switch شامل: كل حالة لها Widget — لا ننسى أي حالة
                child: switch (result) {
                  Loading() => const CircularProgressIndicator(),
                  Success(data: final items) when items.isEmpty =>
                    const Text('📭 لا توجد بيانات'),
                  Success(data: final items) => Text('✅ ${items.join('، ')}'),
                  Failure(code: 401) => FilledButton(
                    onPressed: () {},
                    child: const Text('🔒 سجّل الدخول'),
                  ),
                  Failure(:final message) => Text(
                    '❌ $message',
                    style: const TextStyle(color: Colors.red),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// الكونسول: نعرض فيه نتائج الأمثلة بدل print
// (نعيد استخدامه في الدروس 2 و 6 و 8)
// ============================================================
class ConsoleView extends StatelessWidget {
  const ConsoleView({super.key, required this.lines, this.busy = false});

  final List<String> lines;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        children: [
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                line,
                style: const TextStyle(
                  color: Color(0xFFB8F5C8),
                  fontFamily: 'monospace',
                  fontSize: 15,
                ),
              ),
            ),
          if (busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) Record مع حقل واحد يحتاج فاصلة: ('وحيد',) — بدونها هي مجرد أقواس.
//
// 2) Record كباراميتر family في Riverpod (المساواة بالقيمة تضمن نفس الحالة):
//      ref.watch(searchProvider((page: 1, query: 'لابتوب')));
//
// 3) استخدم if-case للتحقق من JSON بدل سلسلة من is و as:
//      if (json case {'id': int id, 'title': String title}) { ... }
//
// 4) final class / base / interface (Dart 3) تتحكم بمن يرث أو يطبّق الـ class
//    خارج المكتبة، أما sealed فتضيف عليها: switch شامل بدون default.
//
// 5) Record أم class؟ Record للبيانات المؤقتة الصغيرة (إرجاع قيمتين، مفتاح مركّب)،
//    و class (مع freezed — الدرس 2) لنموذج له سلوك أو JSON أو يُستخدم في أماكن كثيرة.
