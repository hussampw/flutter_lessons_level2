// ============================================================
// الدرس 8 (المعمارية): Clean Architecture — data/quote_dto.dart
// في التطبيق: القائمة ← الدرس 8  ·  في العرض: شرائح الدرس 8
// ============================================================
//
// طبقة data — DTO: شكل البيانات كما تصل من الـ API
// منفصل عن الكيان Quote: إذا غيّر الخادم اسم حقل نعدّل هنا فقط

class QuoteDto {
  const QuoteDto({required this.id, required this.quote, required this.author});

  factory QuoteDto.fromJson(Map<String, dynamic> json) => QuoteDto(
        id: json['id'] as int,
        quote: json['quote'] as String,
        author: json['author'] as String,
      );

  final int id;
  final String quote; // اسم الحقل في الـ API هو quote وليس text
  final String author;
}
