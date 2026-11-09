// ============================================================
// الدرس 8 (المعمارية): Clean Architecture — domain/quote.dart
// في التطبيق: القائمة ← الدرس 8  ·  في العرض: شرائح الدرس 8
// ============================================================
//
// طبقة domain — الكيان (Entity)
// Dart خالص: لا Flutter ولا Dio ولا Drift ← يمكن اختباره ونقله لأي مشروع

class Quote {
  const Quote({
    required this.id,
    required this.text,
    required this.author,
    required this.isFavorite,
  });

  final int id;
  final String text;
  final String author;
  final bool isFavorite;
}
