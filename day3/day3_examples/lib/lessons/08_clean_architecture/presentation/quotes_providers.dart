// ============================================================
// الدرس 8 (المعمارية): Clean Architecture — presentation/quotes_providers.dart
// في التطبيق: القائمة ← الدرس 8  ·  في العرض: شرائح الدرس 8
// ============================================================
//
// طبقة presentation — ربط الطبقات بـ Riverpod (حقن الاعتماديات)
// هذا الملف الوحيد الذي يعرف كل الطبقات؛ الشاشة تعرف domain فقط

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/database_connection.dart';
import '../../../shared/network.dart';
import '../../../shared/result.dart';
import '../data/quotes_local_data_source.dart';
import '../data/quotes_remote_data_source.dart';
import '../data/quotes_repository_impl.dart';
import '../domain/quote.dart';
import '../domain/quote_use_cases.dart';
import '../domain/quotes_repository.dart';

// --- data ---
final quotesDatabaseProvider = Provider<QuotesDatabase>((ref) {
  final db = QuotesDatabase(ref.watch(connectionProvider('quotes')));
  ref.onDispose(db.close);
  return db;
});

final quotesRemoteProvider = Provider<QuotesRemoteDataSource>(
  (ref) => DioQuotesRemoteDataSource(ref.watch(dioProvider)),
);

final quotesLocalProvider = Provider<QuotesLocalDataSource>(
  (ref) => QuotesLocalDataSource(ref.watch(quotesDatabaseProvider)),
);

// النوع المُعلن = الواجهة من domain، وليس QuotesRepositoryImpl
final quotesRepositoryProvider = Provider<QuotesRepository>(
  (ref) => QuotesRepositoryImpl(
    remote: ref.watch(quotesRemoteProvider),
    local: ref.watch(quotesLocalProvider),
  ),
);

// --- domain (use cases) ---
final watchQuotesProvider = Provider((ref) => WatchQuotes(ref.watch(quotesRepositoryProvider)));
final refreshQuotesProvider = Provider((ref) => RefreshQuotes(ref.watch(quotesRepositoryProvider)));
final toggleFavoriteProvider = Provider((ref) => ToggleFavorite(ref.watch(quotesRepositoryProvider)));

// --- presentation (state) ---
final quotesProvider = StreamProvider<List<Quote>>(
  (ref) => ref.watch(watchQuotesProvider)(),
);

/// رسالة آخر تحديث (null = لا شيء بعد)
class RefreshMessage extends Notifier<String?> {
  @override
  String? build() => null;

  Future<void> refresh() async {
    final result = await ref.read(refreshQuotesProvider)();
    if (!ref.mounted) return;
    state = switch (result) {
      Success(:final value) => '✅ وصل $value اقتباس وحُفظ محلياً',
      Failure(:final message) => '🟠 $message',
    };
  }
}

final refreshMessageProvider =
    NotifierProvider.autoDispose<RefreshMessage, String?>(RefreshMessage.new);
