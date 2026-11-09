// ============================================================
// الدرس 8: توليد الكود — freezed + json_serializable + build_runner
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
// الملفات المولَّدة:
//   user.freezed.dart ← copyWith و == و hashCode و toString
//   user.g.dart       ← fromJson و toJson
// ⚠️ لا تعدّل الملفات المولَّدة يدوياً أبداً

import 'package:freezed_annotation/freezed_annotation.dart';

// ربط هذا الملف بالملفات التي ستُولَّد
part 'user.freezed.dart';
part 'user.g.dart';

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
// 2) Union / Sealed مع freezed: حالات تسجيل الدخول
//    يجمع قوة sealed class (الدرس 5) مع التوليد التلقائي
// ------------------------------------------------------------
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated(User user) = Authenticated;
  const factory AuthState.error(String message) = AuthError;
}
