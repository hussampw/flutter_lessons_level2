// ============================================================
// الدرس 8 (المعمارية): Clean Architecture — domain/quote_use_cases.dart
// في التطبيق: القائمة ← الدرس 8  ·  في العرض: شرائح الدرس 8
// ============================================================
//
// طبقة domain — حالات الاستخدام (Use cases)
// كل class = فعل واحد يقوم به المستخدم + قواعد العمل (Business rules)

import '../../../shared/result.dart';
import 'quote.dart';
import 'quotes_repository.dart';

/// قاعدة عمل: المفضّلة أولاً، ثم حسب الرقم
class WatchQuotes {
  const WatchQuotes(this._repository);
  final QuotesRepository _repository;

  Stream<List<Quote>> call() => _repository.watchQuotes().map(
        (quotes) => [...quotes]..sort((a, b) {
            if (a.isFavorite != b.isFavorite) return a.isFavorite ? -1 : 1;
            return a.id.compareTo(b.id);
          }),
      );
}

class RefreshQuotes {
  const RefreshQuotes(this._repository);
  final QuotesRepository _repository;

  Future<Result<int>> call() => _repository.refresh();
}

class ToggleFavorite {
  const ToggleFavorite(this._repository);
  final QuotesRepository _repository;

  Future<void> call(int id) => _repository.toggleFavorite(id);
}
