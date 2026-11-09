// ============================================================
// الدرس 8: استخدام الكود المولَّد (freezed + json_serializable)
// قبل التشغيل نولّد الكود:
//   dart run build_runner build -d
// التشغيل:
//   dart run bin/08_codegen.dart
// الـ Model نفسه موجود في: lib/models/user.dart
// ============================================================

import 'dart:convert';

import 'package:day1_examples/models/user.dart';

void main() {
  // ------------------------------------------------------------
  // 1) fromJson: من استجابة API إلى كائن Dart
  // ------------------------------------------------------------
  const apiResponse = '''
  {
    "id": 1,
    "name": "ريم",
    "email": "reem@example.com",
    "avatar_url": "https://i.pravatar.cc/100"
  }
  ''';
  final user = User.fromJson(jsonDecode(apiResponse) as Map<String, dynamic>);
  print('1) fromJson:\n   $user'); // toString مولّد تلقائياً
  print('   isVerified الافتراضي = ${user.isVerified}'); // @Default(false)

  // ------------------------------------------------------------
  // 2) toJson: من كائن إلى JSON (لإرساله للـ API)
  // ------------------------------------------------------------
  print('\n2) toJson:\n   ${jsonEncode(user.toJson())}');
  // لاحظ أن avatarUrl رجعت avatar_url بسبب @JsonKey

  // ------------------------------------------------------------
  // 3) copyWith: الكائن immutable، فننشئ نسخة معدّلة
  // ------------------------------------------------------------
  final verified = user.copyWith(isVerified: true, roles: ['admin']);
  print('\n3) copyWith:\n   $verified');
  print('   الأصل لم يتغير: isVerified = ${user.isVerified}');

  // ------------------------------------------------------------
  // 4) المساواة بالقيمة: == و hashCode مولّدة
  // ------------------------------------------------------------
  final same = User.fromJson(jsonDecode(apiResponse) as Map<String, dynamic>);
  print('\n4) المساواة:');
  print('   user == same ؟ ${user == same}'); // true (بدون freezed = false)
  print('   user == verified ؟ ${user == verified}'); // false

  // ------------------------------------------------------------
  // 5) Union: نستخدم switch الشامل كما في الدرس 5
  // ------------------------------------------------------------
  print('\n5) AuthState:');
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
    print('   $text');
  }
}
