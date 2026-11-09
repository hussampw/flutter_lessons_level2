// ============================================================
// الدرس 8: اختبار الـ Repository (API + DB) بدون شبكة وبدون Widgets
// Remote وهمي + Drift في الذاكرة
// التشغيل: flutter test test/quotes_repository_test.dart
// ============================================================

import 'package:day3_examples/lessons/08_clean_architecture/data/quote_dto.dart';
import 'package:day3_examples/lessons/08_clean_architecture/data/quotes_local_data_source.dart';
import 'package:day3_examples/lessons/08_clean_architecture/data/quotes_remote_data_source.dart';
import 'package:day3_examples/lessons/08_clean_architecture/data/quotes_repository_impl.dart';
import 'package:day3_examples/lessons/08_clean_architecture/domain/quote_use_cases.dart';
import 'package:day3_examples/shared/result.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRemote implements QuotesRemoteDataSource {
  bool offline = false;
  List<QuoteDto> quotes = const [
    QuoteDto(id: 1, quote: 'Stay hungry', author: 'Jobs'),
    QuoteDto(id: 2, quote: 'Keep it simple', author: 'KISS'),
  ];

  @override
  Future<List<QuoteDto>> fetchQuotes() async {
    if (offline) {
      throw DioException(
        requestOptions: RequestOptions(path: '/quotes'),
        type: DioExceptionType.connectionError,
      );
    }
    return quotes;
  }
}

void main() {
  late QuotesDatabase db;
  late FakeRemote remote;
  late QuotesRepositoryImpl repository;

  setUp(() {
    db = QuotesDatabase(NativeDatabase.memory());
    remote = FakeRemote();
    repository = QuotesRepositoryImpl(remote: remote, local: QuotesLocalDataSource(db));
  });
  tearDown(() => db.close());

  test('refresh يجلب من الـ API ويحفظ في DB، و watch يقرأ من DB', () async {
    expect(await repository.refresh(), isA<Success<int>>());
    final quotes = await repository.watchQuotes().first;
    expect(quotes.map((q) => q.author), ['Jobs', 'KISS']);
  });

  test('بدون اتصال: Failure برسالة، والبيانات المحفوظة تبقى', () async {
    await repository.refresh();
    remote.offline = true;

    final result = await repository.refresh();
    expect(result, isA<Failure<int>>());
    expect((await repository.watchQuotes().first), hasLength(2));
  });

  test('التحديث لا يمسح المفضّلة، و WatchQuotes يضعها أولاً', () async {
    await repository.refresh();
    await repository.toggleFavorite(2);
    remote.quotes = [
      ...remote.quotes,
      const QuoteDto(id: 3, quote: 'New one', author: 'API'),
    ];
    await repository.refresh();

    final quotes = await WatchQuotes(repository)().first;
    expect(quotes.first.id, 2); // المفضّلة أولاً (قاعدة عمل في domain)
    expect(quotes.first.isFavorite, isTrue); // upsert لم يمسحها
    expect(quotes, hasLength(3));
  });
}
