// ============================================================
// الدرس 1 (Dart): Extension methods و Extension types
// في التطبيق: القائمة ← الدرس 1  ·  في العرض: شرائح الدرس 1
// ============================================================
//
// الـ Extension تضيف دوال جديدة لأنواع موجودة (حتى لو لم نكتبها نحن)
// مثل String أو int أو BuildContext — بدون وراثة وبدون تعديل الأصل.
//
// الـ Extension type (Dart 3.3+) نوع جديد "مجاني" فوق نوع موجود:
// لا يُنشئ كائناً إضافياً وقت التشغيل، ويمنع الخلط بين UserId و ProductId.
//
// 💡 امتدادات BuildContext في آخر الملف (ContextX) نستخدمها في دروس الـ UI
//    التالية (5 – 9): context.colors · context.screenSize · context.showSnack
//
// 💡 كل زر في الشاشة ينفّذ مثالاً ويكتب النتيجة في "الكونسول" أسفل الشاشة.

import 'package:flutter/material.dart';

// ------------------------------------------------------------
// 1) Extension على String
// ------------------------------------------------------------
extension StringX on String {
  // تحقق بسيط من البريد الإلكتروني (نستخدمه في نموذج الدرس 4)
  bool get isValidEmail => RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]+$').hasMatch(this);

  // أول حرف كبير
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  // تقصير النص الطويل مع …
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
  // نسخة آمنة من list[i] لا ترمي RangeError
  T? getOrNull(int index) => index >= 0 && index < length ? this[index] : null;

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

// ------------------------------------------------------------
// 6) Extension Types (Dart 3.3+): نوع جديد "مجاني" فوق نوع موجود
//    لا يُنشئ كائن إضافي وقت التشغيل (zero-cost)
//    يمنع الخلط بين UserId و ProductId رغم أن كلاهما int
// ------------------------------------------------------------
extension type UserId(int value) {
  // constructor مسمّى يحوّل النص إلى رقم
  UserId.parse(String raw) : value = int.parse(raw);
  bool get isGuest => value == 0;
}

extension type ProductId(int value) {}

String loadUser(UserId id) => 'تحميل المستخدم ${id.value}';

// Extension type مع تحقق: لا يمكن إنشاء Email إلا من نص صحيح
// implements String ← كل دوال String متاحة عليه (length, contains...)
extension type Email._(String value) implements String {
  factory Email(String raw) {
    final v = raw.trim().toLowerCase();
    if (!v.isValidEmail) throw FormatException('بريد غير صالح', raw);
    return Email._(v);
  }
  String get domain => value.split('@').last;
}

// ------------------------------------------------------------
// 7) Extension على BuildContext — الأكثر استخداماً في Flutter
//    بدل Theme.of(context).colorScheme ← context.colors
// ------------------------------------------------------------
extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // sizeOf بدل of(this).size: يُعاد البناء عند تغيّر الحجم فقط
  Size get screenSize => MediaQuery.sizeOf(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  void showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? colors.error : null,
        ),
      );
  }
}

class ExtensionsScreen extends StatefulWidget {
  const ExtensionsScreen({super.key});

  @override
  State<ExtensionsScreen> createState() => _ExtensionsScreenState();
}

class _ExtensionsScreenState extends State<ExtensionsScreen> {
  final _logs = <String>[];

  void _log(String line) => setState(() => _logs.add(line));

  void _run(String title, void Function() demo) {
    setState(
      () => _logs
        ..clear()
        ..add('▶ $title'),
    );
    demo();
  }

  void _stringDemo() {
    _log("'ali@mail.com'.isValidEmail ← ${'ali@mail.com'.isValidEmail}");
    _log("'not-an-email'.isValidEmail ← ${'not-an-email'.isValidEmail}");
    _log("'flutter'.capitalized ← ${'flutter'.capitalized}");
    _log('truncate(12) ← ${'هذا نص طويل جداً يحتاج إلى تقصير'.truncate(12)}');
  }

  void _intDemo() {
    _log('2.seconds ← ${2.seconds}');
    _log('300.ms ← ${300.ms}');
  }

  void _listDemo() {
    final words = ['تفاحة', 'توت', 'موز', 'مانجو', 'تين'];
    _log('words.getOrNull(10) ← ${words.getOrNull(10)}'); // null بدل crash
    _log('groupBy(أول حرف) ← ${words.groupBy((w) => w[0])}');
  }

  void _nullableDemo() {
    String? nickname;
    _log('nickname.isNullOrEmpty ← ${nickname.isNullOrEmpty}');
    _log("orDefault('بدون لقب') ← ${nickname.orDefault('بدون لقب')}");
  }

  void _dateDemo() {
    final now = DateTime.now();
    _log('قبل 5 دقائق ← ${now.subtract(const Duration(minutes: 5)).timeAgo}');
    _log('قبل 3 أيام ← ${now.subtract(const Duration(days: 3)).timeAgo}');
  }

  void _extensionTypeDemo() {
    final userId = UserId(7);
    final productId = ProductId(7);
    _log(loadUser(userId));
    // loadUser(productId); ← خطأ ترجمة! رغم أن الاثنين int ✅
    // loadUser(7);         ← خطأ ترجمة أيضاً
    _log('productId = ${productId.value}');
    _log("UserId.parse('0').isGuest ← ${UserId.parse('0').isGuest}");

    final email = Email('  Ali@Mail.COM ');
    _log('Email ← $email · domain: ${email.domain} · length: ${email.length}');
    try {
      Email('ali@');
    } on FormatException catch (e) {
      _log('Email(\'ali@\') ← ${e.message}');
    }
  }

  void _contextDemo() {
    // نفس الامتدادات التي سنستخدمها في دروس الـ UI
    final size = context.screenSize;
    _log('context.screenSize ← ${size.width.round()} × ${size.height.round()}');
    _log('context.isDark ← ${context.isDark}');
    _log('context.colors.primary ← ${context.colors.primary}');
    context.showSnack('تم! هذه SnackBar من context.showSnack');
  }

  @override
  Widget build(BuildContext context) {
    final demos = <(String, void Function())>[
      ('1) String', _stringDemo),
      ('2) int → Duration', _intDemo),
      ('3) List<T>', _listDemo),
      ('4) nullable', _nullableDemo),
      ('5) DateTime', _dateDemo),
      ('6) Extension types', _extensionTypeDemo),
      ('7) BuildContext', _contextDemo),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 1: Extension methods')),
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
          // الكونسول: نعرض فيه نتائج الأمثلة بدل print
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView(
                children: [
                  for (final line in _logs)
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) Dart 3 فيها امتدادات جاهزة في dart:core — لا تكتبها من جديد:
//      list.firstOrNull · list.lastOrNull · list.elementAtOrNull(5)
//      list.indexed  ← for (final (i, item) in list.indexed)
//
// 2) الـ extensions تعتمد على النوع الثابت (static type)
//    لذلك لا تعمل مع متغير dynamic:
//      dynamic x = 'a';  x.capitalized  ← خطأ وقت التشغيل NoSuchMethodError
//
// 3) تعارض اسمين من مكتبتين؟ استدعِ الـ extension باسمها صراحةً:
//      StringX('flutter').capitalized
//    أو أخفِ واحدة عند الاستيراد: import 'utils.dart' hide StringX;
//
// 4) الـ Extension type يختفي وقت التشغيل: (userId is int) ← true
//    هو حماية وقت الترجمة فقط، وليس class حقيقية — لا تعتمد عليه في is/as.
//
// 5) ضع امتدادات BuildContext في ملف واحد (مثلاً lib/core/context_x.dart)
//    واستوردها في كل الشاشات — كما تستورد الدروس 5–9 هذا الملف.
