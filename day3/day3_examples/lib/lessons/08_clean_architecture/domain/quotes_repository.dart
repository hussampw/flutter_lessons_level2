// ============================================================
// الدرس 8 (المعمارية): Clean Architecture — domain/quotes_repository.dart
// في التطبيق: القائمة ← الدرس 8  ·  في العرض: شرائح الدرس 8
// ============================================================
//
// طبقة domain — عقد الـ Repository (واجهة فقط)
// الـ domain يقول «ماذا أحتاج»، وطبقة data تقرر «كيف» (API؟ قاعدة بيانات؟ كلاهما)

import '../../../shared/result.dart';
import 'quote.dart';

abstract interface class QuotesRepository {
  /// الاقتباسات من المصدر المحلي — تتحدث تلقائياً (Stream)
  Stream<List<Quote>> watchQuotes();

  /// جلب الجديد من الشبكة وحفظه محلياً — لا يرمي استثناء، بل يعيد Result
  Future<Result<int>> refresh();

  Future<void> toggleFavorite(int id);
}
