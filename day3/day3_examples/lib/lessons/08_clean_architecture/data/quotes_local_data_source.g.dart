// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quotes_local_data_source.dart';

// ignore_for_file: type=lint
class $QuoteRowsTable extends QuoteRows
    with drift.TableInfo<$QuoteRowsTable, QuoteRow> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuoteRowsTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _idMeta = const drift.VerificationMeta(
    'id',
  );
  @override
  late final drift.GeneratedColumn<int> id = drift.GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const drift.VerificationMeta _quoteMeta = const drift.VerificationMeta(
    'quote',
  );
  @override
  late final drift.GeneratedColumn<String> quote =
      drift.GeneratedColumn<String>(
        'quote',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const drift.VerificationMeta _authorMeta =
      const drift.VerificationMeta('author');
  @override
  late final drift.GeneratedColumn<String> author =
      drift.GeneratedColumn<String>(
        'author',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const drift.VerificationMeta _isFavoriteMeta =
      const drift.VerificationMeta('isFavorite');
  @override
  late final drift.GeneratedColumn<bool> isFavorite =
      drift.GeneratedColumn<bool>(
        'is_favorite',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_favorite" IN (0, 1))',
        ),
        defaultValue: const drift.Constant(false),
      );
  @override
  List<drift.GeneratedColumn> get $columns => [id, quote, author, isFavorite];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quote_rows';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<QuoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('quote')) {
      context.handle(
        _quoteMeta,
        quote.isAcceptableOrUnknown(data['quote']!, _quoteMeta),
      );
    } else if (isInserting) {
      context.missing(_quoteMeta);
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    } else if (isInserting) {
      context.missing(_authorMeta);
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {id};
  @override
  QuoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      quote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quote'],
      )!,
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
    );
  }

  @override
  $QuoteRowsTable createAlias(String alias) {
    return $QuoteRowsTable(attachedDatabase, alias);
  }
}

class QuoteRow extends drift.DataClass implements drift.Insertable<QuoteRow> {
  final int id;
  final String quote;
  final String author;
  final bool isFavorite;
  const QuoteRow({
    required this.id,
    required this.quote,
    required this.author,
    required this.isFavorite,
  });
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['id'] = drift.Variable<int>(id);
    map['quote'] = drift.Variable<String>(quote);
    map['author'] = drift.Variable<String>(author);
    map['is_favorite'] = drift.Variable<bool>(isFavorite);
    return map;
  }

  QuoteRowsCompanion toCompanion(bool nullToAbsent) {
    return QuoteRowsCompanion(
      id: drift.Value(id),
      quote: drift.Value(quote),
      author: drift.Value(author),
      isFavorite: drift.Value(isFavorite),
    );
  }

  factory QuoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return QuoteRow(
      id: serializer.fromJson<int>(json['id']),
      quote: serializer.fromJson<String>(json['quote']),
      author: serializer.fromJson<String>(json['author']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'quote': serializer.toJson<String>(quote),
      'author': serializer.toJson<String>(author),
      'isFavorite': serializer.toJson<bool>(isFavorite),
    };
  }

  QuoteRow copyWith({
    int? id,
    String? quote,
    String? author,
    bool? isFavorite,
  }) => QuoteRow(
    id: id ?? this.id,
    quote: quote ?? this.quote,
    author: author ?? this.author,
    isFavorite: isFavorite ?? this.isFavorite,
  );
  QuoteRow copyWithCompanion(QuoteRowsCompanion data) {
    return QuoteRow(
      id: data.id.present ? data.id.value : this.id,
      quote: data.quote.present ? data.quote.value : this.quote,
      author: data.author.present ? data.author.value : this.author,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuoteRow(')
          ..write('id: $id, ')
          ..write('quote: $quote, ')
          ..write('author: $author, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, quote, author, isFavorite);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuoteRow &&
          other.id == this.id &&
          other.quote == this.quote &&
          other.author == this.author &&
          other.isFavorite == this.isFavorite);
}

class QuoteRowsCompanion extends drift.UpdateCompanion<QuoteRow> {
  final drift.Value<int> id;
  final drift.Value<String> quote;
  final drift.Value<String> author;
  final drift.Value<bool> isFavorite;
  const QuoteRowsCompanion({
    this.id = const drift.Value.absent(),
    this.quote = const drift.Value.absent(),
    this.author = const drift.Value.absent(),
    this.isFavorite = const drift.Value.absent(),
  });
  QuoteRowsCompanion.insert({
    this.id = const drift.Value.absent(),
    required String quote,
    required String author,
    this.isFavorite = const drift.Value.absent(),
  }) : quote = drift.Value(quote),
       author = drift.Value(author);
  static drift.Insertable<QuoteRow> custom({
    drift.Expression<int>? id,
    drift.Expression<String>? quote,
    drift.Expression<String>? author,
    drift.Expression<bool>? isFavorite,
  }) {
    return drift.RawValuesInsertable({
      if (id != null) 'id': id,
      if (quote != null) 'quote': quote,
      if (author != null) 'author': author,
      if (isFavorite != null) 'is_favorite': isFavorite,
    });
  }

  QuoteRowsCompanion copyWith({
    drift.Value<int>? id,
    drift.Value<String>? quote,
    drift.Value<String>? author,
    drift.Value<bool>? isFavorite,
  }) {
    return QuoteRowsCompanion(
      id: id ?? this.id,
      quote: quote ?? this.quote,
      author: author ?? this.author,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (id.present) {
      map['id'] = drift.Variable<int>(id.value);
    }
    if (quote.present) {
      map['quote'] = drift.Variable<String>(quote.value);
    }
    if (author.present) {
      map['author'] = drift.Variable<String>(author.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = drift.Variable<bool>(isFavorite.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuoteRowsCompanion(')
          ..write('id: $id, ')
          ..write('quote: $quote, ')
          ..write('author: $author, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }
}

abstract class _$QuotesDatabase extends drift.GeneratedDatabase {
  _$QuotesDatabase(QueryExecutor e) : super(e);
  $QuotesDatabaseManager get managers => $QuotesDatabaseManager(this);
  late final $QuoteRowsTable quoteRows = $QuoteRowsTable(this);
  @override
  Iterable<drift.TableInfo<drift.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<drift.TableInfo<drift.Table, Object?>>();
  @override
  List<drift.DatabaseSchemaEntity> get allSchemaEntities => [quoteRows];
  @override
  drift.DriftDatabaseOptions get options =>
      const drift.DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$QuoteRowsTableCreateCompanionBuilder = QuoteRowsCompanion Function({
  drift.Value<int> id,
  required String quote,
  required String author,
  drift.Value<bool> isFavorite,
});
typedef $$QuoteRowsTableUpdateCompanionBuilder = QuoteRowsCompanion Function({
  drift.Value<int> id,
  drift.Value<String> quote,
  drift.Value<String> author,
  drift.Value<bool> isFavorite,
});

class $$QuoteRowsTableFilterComposer
    extends drift.Composer<_$QuotesDatabase, $QuoteRowsTable> {
  $$QuoteRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<String> get quote => $composableBuilder(
    column: $table.quote,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => drift.ColumnFilters(column),
  );
}

class $$QuoteRowsTableOrderingComposer
    extends drift.Composer<_$QuotesDatabase, $QuoteRowsTable> {
  $$QuoteRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get quote => $composableBuilder(
    column: $table.quote,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get author => $composableBuilder(
    column: $table.author,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => drift.ColumnOrderings(column),
  );
}

class $$QuoteRowsTableAnnotationComposer
    extends drift.Composer<_$QuotesDatabase, $QuoteRowsTable> {
  $$QuoteRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  drift.GeneratedColumn<String> get quote =>
      $composableBuilder(column: $table.quote, builder: (column) => column);

  drift.GeneratedColumn<String> get author =>
      $composableBuilder(column: $table.author, builder: (column) => column);

  drift.GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );
}

class $$QuoteRowsTableTableManager
    extends
        drift.RootTableManager<
          _$QuotesDatabase,
          $QuoteRowsTable,
          QuoteRow,
          $$QuoteRowsTableFilterComposer,
          $$QuoteRowsTableOrderingComposer,
          $$QuoteRowsTableAnnotationComposer,
          $$QuoteRowsTableCreateCompanionBuilder,
          $$QuoteRowsTableUpdateCompanionBuilder,
          (
            QuoteRow,
            drift.BaseReferences<_$QuotesDatabase, $QuoteRowsTable, QuoteRow>,
          ),
          QuoteRow,
          drift.PrefetchHooks Function()
        > {
  $$QuoteRowsTableTableManager(_$QuotesDatabase db, $QuoteRowsTable table)
    : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuoteRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuoteRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuoteRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                drift.Value<int> id = const drift.Value.absent(),
                drift.Value<String> quote = const drift.Value.absent(),
                drift.Value<String> author = const drift.Value.absent(),
                drift.Value<bool> isFavorite = const drift.Value.absent(),
              }) => QuoteRowsCompanion(
                id: id,
                quote: quote,
                author: author,
                isFavorite: isFavorite,
              ),
          createCompanionCallback:
              ({
                drift.Value<int> id = const drift.Value.absent(),
                required String quote,
                required String author,
                drift.Value<bool> isFavorite = const drift.Value.absent(),
              }) => QuoteRowsCompanion.insert(
                id: id,
                quote: quote,
                author: author,
                isFavorite: isFavorite,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$QuoteRowsTable, QuoteRow>(table),
                  drift.BaseReferences<
                    _$QuotesDatabase,
                    $QuoteRowsTable,
                    QuoteRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$QuoteRowsTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$QuotesDatabase,
      $QuoteRowsTable,
      QuoteRow,
      $$QuoteRowsTableFilterComposer,
      $$QuoteRowsTableOrderingComposer,
      $$QuoteRowsTableAnnotationComposer,
      $$QuoteRowsTableCreateCompanionBuilder,
      $$QuoteRowsTableUpdateCompanionBuilder,
      (
        QuoteRow,
        drift.BaseReferences<_$QuotesDatabase, $QuoteRowsTable, QuoteRow>,
      ),
      QuoteRow,
      drift.PrefetchHooks Function()
    >;

class $QuotesDatabaseManager {
  final _$QuotesDatabase _db;
  $QuotesDatabaseManager(this._db);
  $$QuoteRowsTableTableManager get quoteRows =>
      $$QuoteRowsTableTableManager(_db, _db.quoteRows);
}
