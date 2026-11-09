// ============================================================
// الدرس 8 (المعمارية): Clean Architecture — data/quotes_remote_data_source.dart
// في التطبيق: القائمة ← الدرس 8  ·  في العرض: شرائح الدرس 8
// ============================================================
//
// طبقة data — المصدر البعيد (API عبر Dio)

import 'package:dio/dio.dart';

import 'quote_dto.dart';

abstract interface class QuotesRemoteDataSource {
  Future<List<QuoteDto>> fetchQuotes();
}

class DioQuotesRemoteDataSource implements QuotesRemoteDataSource {
  DioQuotesRemoteDataSource(this._dio);
  final Dio _dio;

  @override
  Future<List<QuoteDto>> fetchQuotes() async {
    // GET https://dummyjson.com/quotes?limit=10
    final res = await _dio.get<Map<String, dynamic>>(
      '/quotes',
      queryParameters: {'limit': 10},
    );
    return [
      for (final json in (res.data!['quotes'] as List).cast<Map<String, dynamic>>())
        QuoteDto.fromJson(json),
    ];
  }
}
