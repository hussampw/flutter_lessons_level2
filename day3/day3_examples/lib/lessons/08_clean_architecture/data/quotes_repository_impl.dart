// ============================================================
// الدرس 8 (المعمارية): Clean Architecture — data/quotes_repository_impl.dart
// في التطبيق: القائمة ← الدرس 8  ·  في العرض: شرائح الدرس 8
// ============================================================
//
// طبقة data — تنفيذ الـ Repository: API + DB معاً
// الواجهة تقرأ من DB دائماً (الدرس 7)، والـ API يحدّث DB فقط

import 'package:dio/dio.dart';

import '../../../shared/network.dart';
import '../../../shared/result.dart';
import '../domain/quote.dart';
import '../domain/quotes_repository.dart';
import 'quotes_local_data_source.dart';
import 'quotes_remote_data_source.dart';

class QuotesRepositoryImpl implements QuotesRepository {
  QuotesRepositoryImpl({required this.remote, required this.local});

  final QuotesRemoteDataSource remote;
  final QuotesLocalDataSource local;

  @override
  Stream<List<Quote>> watchQuotes() => local.watchAll().map(
        (rows) => [for (final r in rows) r.toEntity()],
      );

  @override
  Future<Result<int>> refresh() async {
    try {
      final dtos = await remote.fetchQuotes();
      await local.upsertAll(dtos);
      return Success(dtos.length);
    } on DioException catch (e) {
      // خطأ تقني (Dio) يتحوّل هنا إلى رسالة — الطبقات العليا لا تعرف Dio
      return Failure(friendlyNetworkError(e), e);
    }
  }

  @override
  Future<void> toggleFavorite(int id) => local.toggleFavorite(id);
}

// التحويل من صف قاعدة البيانات إلى كيان الـ domain
extension on QuoteRow {
  Quote toEntity() => Quote(id: id, text: quote, author: author, isFavorite: isFavorite);
}
