// GENERATED CODE - DO NOT MODIFY BY HAND

part of '09_offline_first_sync.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with drift.TableInfo<$TasksTable, Task> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _idMeta = const drift.VerificationMeta(
    'id',
  );
  @override
  late final drift.GeneratedColumn<String> id = drift.GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const drift.VerificationMeta _doneMeta = const drift.VerificationMeta(
    'done',
  );
  @override
  late final drift.GeneratedColumn<bool> done = drift.GeneratedColumn<bool>(
    'done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("done" IN (0, 1))',
    ),
    defaultValue: const drift.Constant(false),
  );
  static const drift.VerificationMeta _updatedAtMeta =
      const drift.VerificationMeta('updatedAt');
  @override
  late final drift.GeneratedColumn<DateTime> updatedAt =
      drift.GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<drift.GeneratedColumn> get $columns => [id, title, done, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('done')) {
      context.handle(
        _doneMeta,
        done.isAcceptableOrUnknown(data['done']!, _doneMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      done: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}done'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends drift.DataClass implements drift.Insertable<Task> {
  final String id;
  final String title;
  final bool done;
  final DateTime updatedAt;
  const Task({
    required this.id,
    required this.title,
    required this.done,
    required this.updatedAt,
  });
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['id'] = drift.Variable<String>(id);
    map['title'] = drift.Variable<String>(title);
    map['done'] = drift.Variable<bool>(done);
    map['updated_at'] = drift.Variable<DateTime>(updatedAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: drift.Value(id),
      title: drift.Value(title),
      done: drift.Value(done),
      updatedAt: drift.Value(updatedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      done: serializer.fromJson<bool>(json['done']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'done': serializer.toJson<bool>(done),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Task copyWith({String? id, String? title, bool? done, DateTime? updatedAt}) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        done: done ?? this.done,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      done: data.done.present ? data.done.value : this.done,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('done: $done, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, done, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.done == this.done &&
          other.updatedAt == this.updatedAt);
}

class TasksCompanion extends drift.UpdateCompanion<Task> {
  final drift.Value<String> id;
  final drift.Value<String> title;
  final drift.Value<bool> done;
  final drift.Value<DateTime> updatedAt;
  final drift.Value<int> rowid;
  const TasksCompanion({
    this.id = const drift.Value.absent(),
    this.title = const drift.Value.absent(),
    this.done = const drift.Value.absent(),
    this.updatedAt = const drift.Value.absent(),
    this.rowid = const drift.Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    this.done = const drift.Value.absent(),
    required DateTime updatedAt,
    this.rowid = const drift.Value.absent(),
  }) : id = drift.Value(id),
       title = drift.Value(title),
       updatedAt = drift.Value(updatedAt);
  static drift.Insertable<Task> custom({
    drift.Expression<String>? id,
    drift.Expression<String>? title,
    drift.Expression<bool>? done,
    drift.Expression<DateTime>? updatedAt,
    drift.Expression<int>? rowid,
  }) {
    return drift.RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (done != null) 'done': done,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    drift.Value<String>? id,
    drift.Value<String>? title,
    drift.Value<bool>? done,
    drift.Value<DateTime>? updatedAt,
    drift.Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (id.present) {
      map['id'] = drift.Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = drift.Variable<String>(title.value);
    }
    if (done.present) {
      map['done'] = drift.Variable<bool>(done.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = drift.Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = drift.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('done: $done, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingChangesTable extends PendingChanges
    with drift.TableInfo<$PendingChangesTable, PendingChange> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingChangesTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _idMeta = const drift.VerificationMeta(
    'id',
  );
  @override
  late final drift.GeneratedColumn<int> id = drift.GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const drift.VerificationMeta _taskIdMeta =
      const drift.VerificationMeta('taskId');
  @override
  late final drift.GeneratedColumn<String> taskId =
      drift.GeneratedColumn<String>(
        'task_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  late final drift.GeneratedColumnWithTypeConverter<ChangeOp, String> op =
      drift.GeneratedColumn<String>(
        'op',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ChangeOp>($PendingChangesTable.$converterop);
  static const drift.VerificationMeta _payloadMeta =
      const drift.VerificationMeta('payload');
  @override
  late final drift.GeneratedColumn<String> payload =
      drift.GeneratedColumn<String>(
        'payload',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<drift.GeneratedColumn> get $columns => [id, taskId, op, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_changes';
  @override
  drift.VerificationContext validateIntegrity(
    drift.Insertable<PendingChange> instance, {
    bool isInserting = false,
  }) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {id};
  @override
  PendingChange map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingChange(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      op: $PendingChangesTable.$converterop.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}op'],
        )!,
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $PendingChangesTable createAlias(String alias) {
    return $PendingChangesTable(attachedDatabase, alias);
  }

  static drift.JsonTypeConverter2<ChangeOp, String, String> $converterop =
      const drift.EnumNameConverter<ChangeOp>(ChangeOp.values);
}

class PendingChange extends drift.DataClass
    implements drift.Insertable<PendingChange> {
  final int id;
  final String taskId;
  final ChangeOp op;
  final String payload;
  const PendingChange({
    required this.id,
    required this.taskId,
    required this.op,
    required this.payload,
  });
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['id'] = drift.Variable<int>(id);
    map['task_id'] = drift.Variable<String>(taskId);
    {
      map['op'] = drift.Variable<String>(
        $PendingChangesTable.$converterop.toSql(op),
      );
    }
    map['payload'] = drift.Variable<String>(payload);
    return map;
  }

  PendingChangesCompanion toCompanion(bool nullToAbsent) {
    return PendingChangesCompanion(
      id: drift.Value(id),
      taskId: drift.Value(taskId),
      op: drift.Value(op),
      payload: drift.Value(payload),
    );
  }

  factory PendingChange.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return PendingChange(
      id: serializer.fromJson<int>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      op: $PendingChangesTable.$converterop.fromJson(
        serializer.fromJson<String>(json['op']),
      ),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'taskId': serializer.toJson<String>(taskId),
      'op': serializer.toJson<String>(
        $PendingChangesTable.$converterop.toJson(op),
      ),
      'payload': serializer.toJson<String>(payload),
    };
  }

  PendingChange copyWith({
    int? id,
    String? taskId,
    ChangeOp? op,
    String? payload,
  }) => PendingChange(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    op: op ?? this.op,
    payload: payload ?? this.payload,
  );
  PendingChange copyWithCompanion(PendingChangesCompanion data) {
    return PendingChange(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      op: data.op.present ? data.op.value : this.op,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingChange(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('op: $op, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, taskId, op, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingChange &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.op == this.op &&
          other.payload == this.payload);
}

class PendingChangesCompanion extends drift.UpdateCompanion<PendingChange> {
  final drift.Value<int> id;
  final drift.Value<String> taskId;
  final drift.Value<ChangeOp> op;
  final drift.Value<String> payload;
  const PendingChangesCompanion({
    this.id = const drift.Value.absent(),
    this.taskId = const drift.Value.absent(),
    this.op = const drift.Value.absent(),
    this.payload = const drift.Value.absent(),
  });
  PendingChangesCompanion.insert({
    this.id = const drift.Value.absent(),
    required String taskId,
    required ChangeOp op,
    required String payload,
  }) : taskId = drift.Value(taskId),
       op = drift.Value(op),
       payload = drift.Value(payload);
  static drift.Insertable<PendingChange> custom({
    drift.Expression<int>? id,
    drift.Expression<String>? taskId,
    drift.Expression<String>? op,
    drift.Expression<String>? payload,
  }) {
    return drift.RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (op != null) 'op': op,
      if (payload != null) 'payload': payload,
    });
  }

  PendingChangesCompanion copyWith({
    drift.Value<int>? id,
    drift.Value<String>? taskId,
    drift.Value<ChangeOp>? op,
    drift.Value<String>? payload,
  }) {
    return PendingChangesCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      op: op ?? this.op,
      payload: payload ?? this.payload,
    );
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (id.present) {
      map['id'] = drift.Variable<int>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = drift.Variable<String>(taskId.value);
    }
    if (op.present) {
      map['op'] = drift.Variable<String>(
        $PendingChangesTable.$converterop.toSql(op.value),
      );
    }
    if (payload.present) {
      map['payload'] = drift.Variable<String>(payload.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingChangesCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('op: $op, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }
}

abstract class _$SyncDatabase extends drift.GeneratedDatabase {
  _$SyncDatabase(QueryExecutor e) : super(e);
  $SyncDatabaseManager get managers => $SyncDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $PendingChangesTable pendingChanges = $PendingChangesTable(this);
  @override
  Iterable<drift.TableInfo<drift.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<drift.TableInfo<drift.Table, Object?>>();
  @override
  List<drift.DatabaseSchemaEntity> get allSchemaEntities => [
    tasks,
    pendingChanges,
  ];
  @override
  drift.DriftDatabaseOptions get options =>
      const drift.DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String title,
  drift.Value<bool> done,
  required DateTime updatedAt,
  drift.Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  drift.Value<String> id,
  drift.Value<String> title,
  drift.Value<bool> done,
  drift.Value<DateTime> updatedAt,
  drift.Value<int> rowid,
});

class $$TasksTableFilterComposer
    extends drift.Composer<_$SyncDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => drift.ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends drift.Composer<_$SyncDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<bool> get done => $composableBuilder(
    column: $table.done,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => drift.ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends drift.Composer<_$SyncDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  drift.GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  drift.GeneratedColumn<bool> get done =>
      $composableBuilder(column: $table.done, builder: (column) => column);

  drift.GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TasksTableTableManager
    extends
        drift.RootTableManager<
          _$SyncDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, drift.BaseReferences<_$SyncDatabase, $TasksTable, Task>),
          Task,
          drift.PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$SyncDatabase db, $TasksTable table)
    : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                drift.Value<String> id = const drift.Value.absent(),
                drift.Value<String> title = const drift.Value.absent(),
                drift.Value<bool> done = const drift.Value.absent(),
                drift.Value<DateTime> updatedAt = const drift.Value.absent(),
                drift.Value<int> rowid = const drift.Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                done: done,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                drift.Value<bool> done = const drift.Value.absent(),
                required DateTime updatedAt,
                drift.Value<int> rowid = const drift.Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                done: done,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, Task>(table),
                  drift.BaseReferences<_$SyncDatabase, $TasksTable, Task>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$SyncDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, drift.BaseReferences<_$SyncDatabase, $TasksTable, Task>),
      Task,
      drift.PrefetchHooks Function()
    >;
typedef $$PendingChangesTableCreateCompanionBuilder =
    PendingChangesCompanion Function({
      drift.Value<int> id,
      required String taskId,
      required ChangeOp op,
      required String payload,
    });
typedef $$PendingChangesTableUpdateCompanionBuilder =
    PendingChangesCompanion Function({
      drift.Value<int> id,
      drift.Value<String> taskId,
      drift.Value<ChangeOp> op,
      drift.Value<String> payload,
    });

class $$PendingChangesTableFilterComposer
    extends drift.Composer<_$SyncDatabase, $PendingChangesTable> {
  $$PendingChangesTableFilterComposer({
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

  drift.ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => drift.ColumnFilters(column),
  );

  drift.ColumnWithTypeConverterFilters<ChangeOp, ChangeOp, String> get op =>
      $composableBuilder(
        column: $table.op,
        builder: (column) => drift.ColumnWithTypeConverterFilters(column),
      );

  drift.ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => drift.ColumnFilters(column),
  );
}

class $$PendingChangesTableOrderingComposer
    extends drift.Composer<_$SyncDatabase, $PendingChangesTable> {
  $$PendingChangesTableOrderingComposer({
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

  drift.ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => drift.ColumnOrderings(column),
  );

  drift.ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => drift.ColumnOrderings(column),
  );
}

class $$PendingChangesTableAnnotationComposer
    extends drift.Composer<_$SyncDatabase, $PendingChangesTable> {
  $$PendingChangesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  drift.GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  drift.GeneratedColumnWithTypeConverter<ChangeOp, String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  drift.GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$PendingChangesTableTableManager
    extends
        drift.RootTableManager<
          _$SyncDatabase,
          $PendingChangesTable,
          PendingChange,
          $$PendingChangesTableFilterComposer,
          $$PendingChangesTableOrderingComposer,
          $$PendingChangesTableAnnotationComposer,
          $$PendingChangesTableCreateCompanionBuilder,
          $$PendingChangesTableUpdateCompanionBuilder,
          (
            PendingChange,
            drift.BaseReferences<
              _$SyncDatabase,
              $PendingChangesTable,
              PendingChange
            >,
          ),
          PendingChange,
          drift.PrefetchHooks Function()
        > {
  $$PendingChangesTableTableManager(
    _$SyncDatabase db,
    $PendingChangesTable table,
  ) : super(
        drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingChangesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingChangesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingChangesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                drift.Value<int> id = const drift.Value.absent(),
                drift.Value<String> taskId = const drift.Value.absent(),
                drift.Value<ChangeOp> op = const drift.Value.absent(),
                drift.Value<String> payload = const drift.Value.absent(),
              }) => PendingChangesCompanion(
                id: id,
                taskId: taskId,
                op: op,
                payload: payload,
              ),
          createCompanionCallback:
              ({
                drift.Value<int> id = const drift.Value.absent(),
                required String taskId,
                required ChangeOp op,
                required String payload,
              }) => PendingChangesCompanion.insert(
                id: id,
                taskId: taskId,
                op: op,
                payload: payload,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingChangesTable, PendingChange>(table),
                  drift.BaseReferences<
                    _$SyncDatabase,
                    $PendingChangesTable,
                    PendingChange
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingChangesTableProcessedTableManager =
    drift.ProcessedTableManager<
      _$SyncDatabase,
      $PendingChangesTable,
      PendingChange,
      $$PendingChangesTableFilterComposer,
      $$PendingChangesTableOrderingComposer,
      $$PendingChangesTableAnnotationComposer,
      $$PendingChangesTableCreateCompanionBuilder,
      $$PendingChangesTableUpdateCompanionBuilder,
      (
        PendingChange,
        drift.BaseReferences<
          _$SyncDatabase,
          $PendingChangesTable,
          PendingChange
        >,
      ),
      PendingChange,
      drift.PrefetchHooks Function()
    >;

class $SyncDatabaseManager {
  final _$SyncDatabase _db;
  $SyncDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$PendingChangesTableTableManager get pendingChanges =>
      $$PendingChangesTableTableManager(_db, _db.pendingChanges);
}
