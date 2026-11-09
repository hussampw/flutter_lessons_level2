// ============================================================
// الدرس 8 (المعمارية): Clean Architecture — data/quotes_local_data_source.dart
// في التطبيق: القائمة ← الدرس 8  ·  في العرض: شرائح الدرس 8
// ============================================================
//
// طبقة data — المصدر المحلي (Drift)

import 'package:drift/drift.dart' as drift; // للـ Column فقط (Column بدون بادئة = Widget)
import 'package:drift/drift.dart' hide Column;

import 'quote_dto.dart';

part 'quotes_local_data_source.g.dart';

class QuoteRows extends Table {
  IntColumn get id => integer()();
  TextColumn get quote => text()();
  TextColumn get author => text()();
  // حقل محلي فقط — لا يأتي من الخادم، ولا يجب أن يمسحه التحديث
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  @override
  Set<drift.Column> get primaryKey => {id};
}

@DriftDatabase(tables: [QuoteRows])
class QuotesDatabase extends _$QuotesDatabase {
  QuotesDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}

class QuotesLocalDataSource {
  QuotesLocalDataSource(this._db);
  final QuotesDatabase _db;

  Stream<List<QuoteRow>> watchAll() => _db.select(_db.quoteRows).watch();

  // upsert بدون isFavorite ← عند التعارض تُحدَّث الأعمدة المرسلة فقط
  Future<void> upsertAll(List<QuoteDto> dtos) => _db.batch(
        (b) => b.insertAllOnConflictUpdate(_db.quoteRows, [
          for (final d in dtos)
            QuoteRowsCompanion.insert(id: Value(d.id), quote: d.quote, author: d.author),
        ]),
      );

  // UPDATE quote_rows SET is_favorite = NOT is_favorite WHERE id = ?
  Future<void> toggleFavorite(int id) =>
      (_db.update(_db.quoteRows)..where((q) => q.id.equals(id))).write(
        QuoteRowsCompanion.custom(isFavorite: _db.quoteRows.isFavorite.not()),
      );
}
