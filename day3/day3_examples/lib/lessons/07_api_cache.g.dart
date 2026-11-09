// GENERATED CODE - DO NOT MODIFY BY HAND

part of '07_api_cache.dart';

// ignore_for_file: type=lint
class $CachedProductsTable extends CachedProducts
    with drift.TableInfo<$CachedProductsTable, CachedProduct> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProductsTable(this.attachedDatabase, [this._alias]);
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
  static const drift.VerificationMeta _titleMeta = const drift.VerificationMeta(
    'title',
  );
  @override
  late final drift.GeneratedColumn<String> title =
      drift.GeneratedColumn<String>(
        'title',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const drift.VerificationMeta _priceMeta = const drift.VerificationMeta(
    'price',
  );
  @override
  late final drift.GeneratedColumn<double> price =
      drift.GeneratedColumn<double>(
        'price',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const drift.VerificationMeta _thumbnailMeta =
      const drift.VerificationMeta('thumbnail');
  @override
  late final drift.GeneratedColumn<String> thumbnail =
      drift.GeneratedColumn<String>(
        'thumbnail',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<drift.GeneratedColumn> get $columns => [id, title, price, thumbnail];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_products';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<CachedProduct> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('thumbnail')) {
      context.handle(
        _thumbnailMeta,
        thumbnail.isAcceptableOrUnknown(data['thumbnail']!, _thumbnailMeta),
      );
    } else if (isInserting) {
      context.missing(_thumbnailMeta);
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {id};
  @override
  CachedProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedProduct(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      thumbnail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail'],
      )!,
    );
  }

  @override
  $CachedProductsTable createAlias(String alias) {
    return $CachedProductsTable(attachedDatabase, alias);
  }
}

class CachedProduct extends drift.DataClass
    implements drift.Insertable<CachedProduct> {
  final int id;
  final String title;
  final double price;
  final String thumbnail;
  const CachedProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.thumbnail,
  });
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['id'] = drift.Variable<int>(id);
    map['title'] = drift.Variable<String>(title);
    map['price'] = drift.Variable<double>(price);
    map['thumbnail'] = drift.Variable<String>(thumbnail);
    return map;
  }

  CachedProductsCompanion toCompanion(bool nullToAbsent) {
    return CachedProductsCompanion(
      id: drift.Value(id),
      title: drift.Value(title),
      price: drift.Value(price),
      thumbnail: drift.Value(thumbnail),
    );
  }

  factory CachedProduct.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return CachedProduct(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      price: serializer.fromJson<double>(json['price']),
      thumbnail: serializer.fromJson<String>(json['thumbnail']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'price': serializer.toJson<double>(price),
      'thumbnail': serializer.toJson<String>(thumbnail),
    };
  }

  CachedProduct copyWith({
    int? id,
    String? title,
    double? price,
    String? thumbnail,
  }) => CachedProduct(
    id: id ?? this.id,
    title: title ?? this.title,
    price: price ?? this.price,
    thumbnail: thumbnail ?? this.thumbnail,
  );
  CachedProduct copyWithCompanion(CachedProductsCompanion data) {
    return CachedProduct(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      price: data.price.present ? data.price.value : this.price,
      thumbnail: data.thumbnail.present ? data.thumbnail.value : this.thumbnail,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedProduct(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('price: $price, ')
          ..write('thumbnail: $thumbnail')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, price, thumbnail);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedProduct &&
          other.id == this.id &&
          other.title == this.title &&
          other.price == this.price &&
          other.thumbnail == this.thumbnail);
}

class CachedProductsCompanion extends drift.UpdateCompanion<CachedProduct> {
  final drift.Value<int> id;
  final drift.Value<String> title;
  final drift.Value<double> price;
  final drift.Value<String> thumbnail;
  const CachedProductsCompanion({
    this.id = const drift.Value.absent(),
    this.title = const drift.Value.absent(),
    this.price = const drift.Value.absent(),
    this.thumbnail = const drift.Value.absent(),
  });
  CachedProductsCompanion.insert({
    this.id = const drift.Value.absent(),
    required String title,
    required double price,
    required String thumbnail,
  }) : title = drift.Value(title),
       price = drift.Value(price),
       thumbnail = drift.Value(thumbnail);
  static drift.Insertable<CachedProduct> custom({
    drift.Expression<int>? id,
    drift.Expression<String>? title,
    drift.Expression<double>? price,
    drift.Expression<String>? thumbnail,
  }) {
    return drift.RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (price != null) 'price': price,
      if (thumbnail != null) 'thumbnail': thumbnail,
    });
  }

  CachedProductsCompanion copyWith({
    drift.Value<int>? id,
    drift.Value<String>? title,
    drift.Value<double>? price,
    drift.Value<String>? thumbnail,
  }) {
    return CachedProductsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      thumbnail: thumbnail ?? this.thumbnail,
    );
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (id.present) {
      map['id'] = drift.Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = drift.Variable<String>(title.value);
    }
    if (price.present) {
      map['price'] = drift.Variable<double>(price.value);
    }
    if (thumbnail.present) {
      map['thumbnail'] = drift.Variable<String>(thumbnail.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedProductsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('price: $price, ')
          ..write('thumbnail: $thumbnail')
          ..write(')'))
        .toString();
  }
}

class $CacheEntriesTable extends CacheEntries
    with drift.TableInfo<$CacheEntriesTable, CacheEntry> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _keyMeta = const drift.VerificationMeta(
    'key',
  );
  @override
  late final drift.GeneratedColumn<String> key = drift.GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const drift.VerificationMeta _fetchedAtMeta =
      const drift.VerificationMeta('fetchedAt');
  @override
  late final drift.GeneratedColumn<DateTime> fetchedAt =
      drift.GeneratedColumn<DateTime>(
        'fetched_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<drift.GeneratedColumn> get $columns => [key, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_entries';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<CacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {key};
  @override
  CacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CacheEntriesTable createAlias(String alias) {
    return $CacheEntriesTable(attachedDatabase, alias);
  }
}

class CacheEntry extends drift.DataClass
    implements drift.Insertable<CacheEntry> {
  final String key;
  final DateTime fetchedAt;
  const CacheEntry({required this.key, required this.fetchedAt});
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['key'] = drift.Variable<String>(key);
    map['fetched_at'] = drift.Variable<DateTime>(fetchedAt);
    return map;
  }

  CacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return CacheEntriesCompanion(
      key: drift.Value(key),
      fetchedAt: drift.Value(fetchedAt),
    );
  }

  factory CacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return CacheEntry(
      key: serializer.fromJson<String>(json['key']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CacheEntry copyWith({String? key, DateTime? fetchedAt}) =>
      CacheEntry(key: key ?? this.key, fetchedAt: fetchedAt ?? this.fetchedAt);
  CacheEntry copyWithCompanion(CacheEntriesCompanion data) {
    return CacheEntry(
      key: data.key.present ? data.key.value : this.key,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheEntry(')
          ..write('key: $key, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheEntry &&
          other.key == this.key &&
          other.fetchedAt == this.fetchedAt);
}

class CacheEntriesCompanion extends drift.UpdateCompanion<CacheEntry> {
  final drift.Value<String> key;
  final drift.Value<DateTime> fetchedAt;
  final drift.Value<int> rowid;
  const CacheEntriesCompanion({
    this.key = const drift.Value.absent(),
    this.fetchedAt = const drift.Value.absent(),
    this.rowid = const drift.Value.absent(),
  });
  CacheEntriesCompanion.insert({
    required String key,
    required DateTime fetchedAt,
    this.rowid = const drift.Value.absent(),
  }) : key = drift.Value(key),
       fetchedAt = drift.Value(fetchedAt);
  static drift.Insertable<CacheEntry> custom({
    drift.Expression<String>? key,
    drift.Expression<DateTime>? fetchedAt,
    drift.Expression<int>? rowid,
  }) {
    return drift.RawValuesInsertable({
      if (key != null) 'key': key,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheEntriesCompanion copyWith({
    drift.Value<String>? key,
    drift.Value<DateTime>? fetchedAt,
    drift.Value<int>? rowid,
  }) {
    return CacheEntriesCompanion(
      key: key ?? this.key,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (key.present) {
      map['key'] = drift.Variable<String>(key.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = drift.Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = drift.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheEntriesCompanion(')
          ..write('key: $key, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CacheDatabase extends drift.GeneratedDatabase {
  _$CacheDatabase(QueryExecutor e) : super(e);
  $CacheDatabaseManager get managers => $CacheDatabaseManager(this);
  late final $CachedProductsTable cachedProducts = $CachedProductsTable(this);
  late final $CacheEntriesTable cacheEntries = $CacheEntriesTable(this);
  @override
  Iterable<drift.TableInfo<drift.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<drift.TableInfo<drift.Table, Object?>>();
  @override
  List<drift.DatabaseSchemaEntity> get allSchemaEntities => [
    cachedProducts,
    cacheEntries,
  ];
  @override
  drift.DriftDatabaseOptions get options =>
      const drift.DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$CachedProductsTableCreateCompanionBuilder =
    CachedProductsCompanion Function({
      drift.Value<int> id,
      required String title,
      required double price,
      required String thumbnail,
    });
typedef $$CachedProductsTableUpdateCompanionBuilder =
    CachedProductsCompanion Function({
      drift.Value<int> id,
      drift.Value<String> title,
      drift.Value<double> price,
      drift.Value<String> thumbnail,
    });

class $$CachedProductsTableFilterComposer
    extends drift.Composer<_$CacheDatabase, $CachedProductsTable> {
  $$CachedProductsTableFilterComposer({
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

  drift.ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<String> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => drift.ColumnFilters(column),
  );
}

class $$CachedProductsTableOrderingComposer
    extends drift.Composer<_$CacheDatabase, $CachedProductsTable> {
  $$CachedProductsTableOrderingComposer({
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

  drift.ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get thumbnail => $composableBuilder(
    column: $table.thumbnail,
    builder: (column) => drift.ColumnOrderings(column),
  );
}

class $$CachedProductsTableAnnotationComposer
    extends drift.Composer<_$CacheDatabase, $CachedProductsTable> {
  $$CachedProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  drift.GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  drift.GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  drift.GeneratedColumn<String> get thumbnail =>
      $composableBuilder(column: $table.thumbnail, builder: (column) => column);
}

class $$CachedProductsTableTableManager
    extends
        drift.RootTableManager<
          _$CacheDatabase,
          $CachedProductsTable,
          CachedProduct,
          $$CachedProductsTableFilterComposer,
          $$CachedProductsTableOrderingComposer,
          $$CachedProductsTableAnnotationComposer,
          $$CachedProductsTableCreateCompanionBuilder,
          $$CachedProductsTableUpdateCompanionBuilder,
          (
            CachedProduct,
            drift.BaseReferences<
              _$CacheDatabase,
              $CachedProductsTable,
              CachedProduct
            >,
          ),
          CachedProduct,
          drift.PrefetchHooks Function()
        > {
  $$CachedProductsTableTableManager(
    _$CacheDatabase db,
    $CachedProductsTable table,
  ) : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                drift.Value<int> id = const drift.Value.absent(),
                drift.Value<String> title = const drift.Value.absent(),
                drift.Value<double> price = const drift.Value.absent(),
                drift.Value<String> thumbnail = const drift.Value.absent(),
              }) => CachedProductsCompanion(
                id: id,
                title: title,
                price: price,
                thumbnail: thumbnail,
              ),
          createCompanionCallback:
              ({
                drift.Value<int> id = const drift.Value.absent(),
                required String title,
                required double price,
                required String thumbnail,
              }) => CachedProductsCompanion.insert(
                id: id,
                title: title,
                price: price,
                thumbnail: thumbnail,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedProductsTable, CachedProduct>(table),
                  drift.BaseReferences<
                    _$CacheDatabase,
                    $CachedProductsTable,
                    CachedProduct
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedProductsTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$CacheDatabase,
      $CachedProductsTable,
      CachedProduct,
      $$CachedProductsTableFilterComposer,
      $$CachedProductsTableOrderingComposer,
      $$CachedProductsTableAnnotationComposer,
      $$CachedProductsTableCreateCompanionBuilder,
      $$CachedProductsTableUpdateCompanionBuilder,
      (
        CachedProduct,
        drift.BaseReferences<
          _$CacheDatabase,
          $CachedProductsTable,
          CachedProduct
        >,
      ),
      CachedProduct,
      drift.PrefetchHooks Function()
    >;
typedef $$CacheEntriesTableCreateCompanionBuilder =
    CacheEntriesCompanion Function({
      required String key,
      required DateTime fetchedAt,
      drift.Value<int> rowid,
    });
typedef $$CacheEntriesTableUpdateCompanionBuilder =
    CacheEntriesCompanion Function({
      drift.Value<String> key,
      drift.Value<DateTime> fetchedAt,
      drift.Value<int> rowid,
    });

class $$CacheEntriesTableFilterComposer
    extends drift.Composer<_$CacheDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => drift.ColumnFilters(column),
  );
}

class $$CacheEntriesTableOrderingComposer
    extends drift.Composer<_$CacheDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => drift.ColumnOrderings(column),
  );
}

class $$CacheEntriesTableAnnotationComposer
    extends drift.Composer<_$CacheDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  drift.GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CacheEntriesTableTableManager
    extends
        drift.RootTableManager<
          _$CacheDatabase,
          $CacheEntriesTable,
          CacheEntry,
          $$CacheEntriesTableFilterComposer,
          $$CacheEntriesTableOrderingComposer,
          $$CacheEntriesTableAnnotationComposer,
          $$CacheEntriesTableCreateCompanionBuilder,
          $$CacheEntriesTableUpdateCompanionBuilder,
          (
            CacheEntry,
            drift.BaseReferences<
              _$CacheDatabase,
              $CacheEntriesTable,
              CacheEntry
            >,
          ),
          CacheEntry,
          drift.PrefetchHooks Function()
        > {
  $$CacheEntriesTableTableManager(_$CacheDatabase db, $CacheEntriesTable table)
    : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                drift.Value<String> key = const drift.Value.absent(),
                drift.Value<DateTime> fetchedAt = const drift.Value.absent(),
                drift.Value<int> rowid = const drift.Value.absent(),
              }) => CacheEntriesCompanion(
                key: key,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required DateTime fetchedAt,
                drift.Value<int> rowid = const drift.Value.absent(),
              }) => CacheEntriesCompanion.insert(
                key: key,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CacheEntriesTable, CacheEntry>(table),
                  drift.BaseReferences<
                    _$CacheDatabase,
                    $CacheEntriesTable,
                    CacheEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheEntriesTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$CacheDatabase,
      $CacheEntriesTable,
      CacheEntry,
      $$CacheEntriesTableFilterComposer,
      $$CacheEntriesTableOrderingComposer,
      $$CacheEntriesTableAnnotationComposer,
      $$CacheEntriesTableCreateCompanionBuilder,
      $$CacheEntriesTableUpdateCompanionBuilder,
      (
        CacheEntry,
        drift.BaseReferences<_$CacheDatabase, $CacheEntriesTable, CacheEntry>,
      ),
      CacheEntry,
      drift.PrefetchHooks Function()
    >;

class $CacheDatabaseManager {
  final _$CacheDatabase _db;
  $CacheDatabaseManager(this._db);
  $$CachedProductsTableTableManager get cachedProducts =>
      $$CachedProductsTableTableManager(_db, _db.cachedProducts);
  $$CacheEntriesTableTableManager get cacheEntries =>
      $$CacheEntriesTableTableManager(_db, _db.cacheEntries);
}
