// ============================================================
// الدرس 4: Records (Dart 3)
// التشغيل: dart run bin/04_records.dart
// ============================================================
//
// الـ Record = مجموعة قيم مجمّعة بدون الحاجة لإنشاء class.
// - غير قابلة للتعديل (immutable)
// - المساواة بالقيمة (==) تلقائياً
// - الأنواع محفوظة لكل حقل

// ------------------------------------------------------------
// 1) إرجاع أكثر من قيمة من دالة — أشهر استخدام
// ------------------------------------------------------------
(double min, double max) minMax(List<double> values) {
  var min = values.first, max = values.first;
  for (final v in values) {
    if (v < min) min = v;
    if (v > max) max = v;
  }
  return (min, max);
}

// ------------------------------------------------------------
// 2) Record بحقول مسمّاة — أوضح عند القراءة
// ------------------------------------------------------------
({String name, int age, String? email}) parseUser(Map<String, dynamic> json) {
  return (
    name: json['name'] as String,
    age: json['age'] as int,
    email: json['email'] as String?,
  );
}

// ------------------------------------------------------------
// 3) typedef لإعطاء اسم للـ Record وإعادة استخدامه
// ------------------------------------------------------------
typedef Point = ({double x, double y});

double distanceSquared(Point p) => (p.x * p.x + p.y * p.y);

void main() {
  // --- Record موضعي (positional): نصل للحقول بـ $1 و $2 ---
  final pair = ('Flutter', 2026);
  print('${pair.$1} - ${pair.$2}');

  // --- التفكيك (Destructuring) مباشرة إلى متغيرات ---
  final (min, max) = minMax([4, 9, 1, 7]);
  print('الأصغر: $min ، الأكبر: $max');

  // --- حقول مسمّاة ---
  final user = parseUser({'name': 'سارة', 'age': 25});
  print('${user.name} عمرها ${user.age} — البريد: ${user.email ?? 'لا يوجد'}');

  // تفكيك الحقول المسمّاة: :name تعني name: name
  final (:name, :age, email: _) = user;
  print('بعد التفكيك: $name / $age');

  // --- مزيج موضعي ومسمّى ---
  final mixed = (200, 'OK', headers: {'content-type': 'json'});
  print('status=${mixed.$1} headers=${mixed.headers}');

  // --- المساواة بالقيمة (عكس الـ class العادي) ---
  const Point a = (x: 1, y: 2);
  const Point b = (x: 1, y: 2);
  print('a == b ؟ ${a == b}'); // true
  print('المسافة²: ${distanceSquared(a)}');

  // --- تبديل قيمتين في سطر واحد ---
  var first = 'أ', second = 'ب';
  (first, second) = (second, first);
  print('بعد التبديل: $first, $second');

  // --- مع الـ Map: التكرار على المفتاح والقيمة معاً ---
  final scores = {'علي': 90, 'منى': 85};
  for (final MapEntry(key: student, value: score) in scores.entries) {
    print('$student: $score');
  }

  // --- مع switch والأنماط (سنتوسع بالدرس القادم) ---
  final response = (200, 'تم');
  final text = switch (response) {
    (200, final msg) => 'نجاح: $msg',
    (404, _) => 'غير موجود',
    (>= 500, _) => 'خطأ في الخادم',
    _ => 'حالة أخرى',
  };
  print(text);

  // 📌 متى أستخدم Record ومتى class؟
  // Record: بيانات مؤقتة صغيرة (إرجاع قيمتين، مفتاح مركّب)
  // class : نموذج له سلوك، أو يُستخدم في أماكن كثيرة، أو يحتاج JSON
}
