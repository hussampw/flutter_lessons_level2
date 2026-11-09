// ============================================================
// الدرس 2 (Dart): توليد الكود — freezed + json_serializable (من JSON إلى Models)
// في التطبيق: القائمة ← الدرس 2  ·  في العرض: شرائح الدرس 2
// ============================================================
//
// المشكلة: كتابة model يدوياً تحتاج:
//   constructor + fromJson + toJson + copyWith + == + hashCode + toString
//   وهذا ممل وكثير الأخطاء (خصوصاً عند إضافة حقل جديد ونسيان تحديث ==).
//
// الحل: نكتب "الوصف" فقط، والأداة تولّد الباقي.
//
// أمر التوليد (من مجلد المشروع):
//   dart run build_runner build -d     ← مرة واحدة (-d = حذف الملفات المتعارضة)
//   dart run build_runner watch -d     ← يراقب التغييرات ويولّد تلقائياً
//
// الملفات المولَّدة بجانب هذا الملف:
//   02_freezed_json.freezed.dart ← copyWith و == و hashCode و toString
//   02_freezed_json.g.dart       ← fromJson و toJson
// ⚠️ لا تعدّل الملفات المولَّدة يدوياً أبداً
//
// 📌 Product و ProductsPage هنا هما نفس النماذج التي نستخدمها مع Dio
//    في الدرسين 7 و 9 (شكل JSON من https://dummyjson.com/products).

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '01_records_sealed.dart' show ConsoleView;

// ربط هذا الملف بالملفات التي ستُولَّد
part '02_freezed_json.freezed.dart';
part '02_freezed_json.g.dart';

// ------------------------------------------------------------
// 1) Model بيانات عادي
// ------------------------------------------------------------
@freezed
abstract class User with _$User {
  const factory User({
    required int id,
    required String name,
    required String email,
    // اسم الحقل في JSON مختلف عن اسمه في Dart
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    // قيمة افتراضية إذا لم يأتِ الحقل من الـ API
    @Default(false) bool isVerified,
    @Default(<String>[]) List<String> roles,
  }) = _User;

  // نحتاج هذا السطر ليولّد json_serializable دالة fromJson
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

// ------------------------------------------------------------
// 2) نماذج حقيقية من dummyjson — نستخدمها مع Dio في الدرسين 7 و 9
// ------------------------------------------------------------
@freezed
abstract class Product with _$Product {
  const factory Product({
    required int id,
    required String title,
    // price قد يصل int (مثل 10) أو double — المولَّد يستخدم (num).toDouble()
    required double price,
    @Default(0) double rating,
    @Default('') String category,
    @JsonKey(name: 'discountPercentage') @Default(0) double discount,
    String? thumbnail,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}

// صفحة من القائمة: { "products": [...], "total": 194, "skip": 0, "limit": 20 }
@freezed
abstract class ProductsPage with _$ProductsPage {
  // explicitToJson: toJson يحوّل القائمة المتداخلة إلى Map أيضاً
  // (التعليق التالي يُسكت تحذيراً معروفاً عند وضع @JsonSerializable على factory)
  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true)
  const factory ProductsPage({
    required List<Product> products, // قائمة متداخلة ← Product.fromJson تلقائياً
    required int total,
    required int skip,
    required int limit,
  }) = _ProductsPage;

  factory ProductsPage.fromJson(Map<String, dynamic> json) =>
      _$ProductsPageFromJson(json);
}

// ------------------------------------------------------------
// 3) Union / Sealed مع freezed: حالات تسجيل الدخول
//    يجمع قوة sealed class (الدرس 1) مع التوليد التلقائي
// ------------------------------------------------------------
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(User user) = Authenticated;
  const factory AuthState.error(String message) = AuthError;
}

// استجابة API كنص (في الدرس 7 تأتي من Dio مباشرة كـ Map)
const _userJson = '''
{
  "id": 1,
  "name": "ريم",
  "email": "reem@example.com",
  "avatar_url": "https://i.pravatar.cc/100"
}
''';

const _pageJson = '''
{
  "products": [
    {"id": 1, "title": "Essence Mascara", "price": 9.99, "rating": 2.56,
     "discountPercentage": 10.48, "category": "beauty", "stock": 99},
    {"id": 2, "title": "Eyeshadow Palette", "price": 20}
  ],
  "total": 194, "skip": 0, "limit": 2
}
''';

class FreezedJsonScreen extends StatefulWidget {
  const FreezedJsonScreen({super.key});

  @override
  State<FreezedJsonScreen> createState() => _FreezedJsonScreenState();
}

class _FreezedJsonScreenState extends State<FreezedJsonScreen> {
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

  User _parseUser() =>
      User.fromJson(jsonDecode(_userJson) as Map<String, dynamic>);

  // ------------------------------------------------------------
  // 1) fromJson و toJson
  // ------------------------------------------------------------
  void _fromToJson() {
    final user = _parseUser();
    _log('fromJson: $user'); // toString مولّد تلقائياً
    _log('isVerified الافتراضي = ${user.isVerified}'); // @Default(false)
    // لاحظ أن avatarUrl رجعت avatar_url بسبب @JsonKey
    _log('toJson: ${jsonEncode(user.toJson())}');
  }

  // ------------------------------------------------------------
  // 2) copyWith و المساواة بالقيمة
  // ------------------------------------------------------------
  void _copyWithEquality() {
    final user = _parseUser();
    // الكائن immutable، فننشئ نسخة معدّلة
    final verified = user.copyWith(isVerified: true, roles: ['admin']);
    _log('copyWith: $verified');
    _log('الأصل لم يتغير: isVerified = ${user.isVerified}');
    // == و hashCode مولّدة
    _log('user == نسخة أخرى من نفس JSON ؟ ${user == _parseUser()}'); // true
    _log('user == verified ؟ ${user == verified}'); // false
  }

  // ------------------------------------------------------------
  // 3) JSON متداخل: صفحة منتجات كما تعيدها dummyjson
  // ------------------------------------------------------------
  void _nestedJson() {
    final page = ProductsPage.fromJson(
      jsonDecode(_pageJson) as Map<String, dynamic>,
    );
    _log('صفحة: ${page.products.length} من ${page.total} منتج');
    for (final p in page.products) {
      // الحقول غير الموجودة في الـ Model (مثل stock) تُتجاهل بهدوء
      _log('#${p.id} ${p.title} — ${p.price}\$ · خصم ${p.discount}%');
    }
    // explicitToJson: المنتجات داخل toJson أصبحت Map وليست كائنات
    final first = (page.toJson()['products'] as List).first;
    _log('toJson المتداخل: $first');
  }

  // ------------------------------------------------------------
  // 4) JSON ناقص: ماذا يحدث إذا لم يرسل الخادم حقلاً مطلوباً؟
  // ------------------------------------------------------------
  void _brokenJson() {
    try {
      Product.fromJson({'id': 3, 'title': 'بدون سعر'});
    } catch (e) {
      // required + غير موجود ← خطأ نوع عند التحويل (لا قيمة null صامتة)
      _log('❌ ${e.runtimeType}: $e');
      _log('💡 الحل: اجعل الحقل nullable أو أعطه @Default(...)');
    }
  }

  // ------------------------------------------------------------
  // 5) Union: نستخدم switch الشامل كما في الدرس 1
  // ------------------------------------------------------------
  void _unionSwitch() {
    final user = _parseUser();
    final states = <AuthState>[
      const AuthState.initial(),
      const AuthState.loading(),
      AuthState.authenticated(user),
      const AuthState.error('كلمة المرور خاطئة'),
    ];
    for (final state in states) {
      final text = switch (state) {
        AuthInitial() => 'لم يسجّل الدخول بعد',
        AuthLoading() => 'جاري التحقق...',
        Authenticated(:final user) => 'أهلاً ${user.name} 👋',
        AuthError(:final message) => 'خطأ: $message',
      };
      _log(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final demos = <(String, void Function())>[
      ('1) fromJson / toJson', _fromToJson),
      ('2) copyWith و ==', _copyWithEquality),
      ('3) JSON متداخل', _nestedJson),
      ('4) JSON ناقص', _brokenJson),
      ('5) Union', _unionSwitch),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 2: freezed و JSON')),
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
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) شغّل build_runner بوضع watch في Terminal منفصل طوال الدرس:
//      dart run build_runner watch -d
//
// 2) لرسالة خطأ أوضح عند JSON ناقص (تذكر اسم الحقل) ضع فوق الـ factory:
//      @JsonSerializable(checked: true)
//    فيصبح الخطأ CheckedFromJsonException بدل TypeError عام.
//
// 3) أسماء الـ API بصيغة snake_case؟ بدل @JsonKey على كل حقل، ضع فوق الـ factory:
//      @JsonSerializable(fieldRename: FieldRename.snake)
//
// 4) أضف getter أو دالة للـ Model: نحتاج constructor خاص فارغ:
//      const Product._();
//      double get finalPrice => price * (1 - discount / 100);
//
// 5) تحويل JSON كبير جداً (آلاف العناصر) يجمّد الشاشة؟ انقله إلى Isolate:
//      final page = await Isolate.run(() => ProductsPage.fromJson(map));
