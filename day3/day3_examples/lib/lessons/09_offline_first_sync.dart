// ============================================================
// الدرس 9: Offline-first والمزامنة — طابور التغييرات (Outbox)
// في التطبيق: القائمة ← الدرس 9  ·  في العرض: شرائح الدرس 9
// ============================================================
//
// Offline-first = التطبيق يعمل كاملاً بدون إنترنت، والمزامنة تحدث لاحقاً.
// المسار دائماً واحد:
//   UI ──► Drift (الجدول tasks)      ← الكتابة محلياً فوراً، الواجهة تتحدث بـ watch()
//      └─► Outbox (pending_changes)  ← في نفس transaction: «هذا تغيير لم يصل للخادم»
//   عند الاتصال: SyncEngine يرسل الطابور بالترتيب (push) ثم يجلب الجديد (pull)
//
// قاعدة التعارض (Conflict): «آخر كتابة تفوز» Last-Write-Wins حسب updatedAt
//   إذا كانت نسخة الخادم أحدث من تغييرنا ← يرفضه الخادم ونأخذ نسخته.
//
// الخادم هنا وهمي (في الذاكرة) حتى نتحكم بالاتصال ونصنع تعارضاً من «جهاز آخر».
// جرّب: افصل ← أضف وعدّل (الطابور يكبر) ← «تعديل من جهاز آخر» ← اتصل ← راقب السجل.
//
// التوليد: dart run build_runner build -d   ← ينشئ 09_offline_first_sync.g.dart

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' as drift; // للـ Column فقط (Column بدون بادئة = Widget)
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart' hide Table;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/database_connection.dart';

part '09_offline_first_sync.g.dart';

// ------------------------------------------------------------
// 1) الجداول: البيانات + طابور التغييرات
// ------------------------------------------------------------
class Tasks extends Table {
  TextColumn get id => text()(); // يُنشأ على الجهاز — لا ننتظر الخادم ليعطينا id
  TextColumn get title => text()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()(); // أساس قاعدة التعارض

  @override
  Set<drift.Column> get primaryKey => {id};
}

enum ChangeOp { upsert, delete }

class PendingChanges extends Table {
  IntColumn get id => integer().autoIncrement()(); // الترتيب = ترتيب الإرسال
  TextColumn get taskId => text()();
  TextColumn get op => textEnum<ChangeOp>()();
  TextColumn get payload => text()(); // نسخة JSON من المهمة لحظة التغيير
}

@DriftDatabase(tables: [Tasks, PendingChanges])
class SyncDatabase extends _$SyncDatabase {
  SyncDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  Stream<List<Task>> watchTasks() =>
      (select(tasks)..orderBy([(t) => OrderingTerm.asc(t.title)])).watch();

  Stream<List<PendingChange>> watchOutbox() =>
      (select(pendingChanges)..orderBy([(c) => OrderingTerm.asc(c.id)])).watch();

  // كل كتابة = تغيير البيانات + سطر في الطابور، داخل transaction واحدة
  Future<void> saveTask(Task task) => transaction(() async {
        await into(tasks).insertOnConflictUpdate(task);
        await into(pendingChanges).insert(PendingChangesCompanion.insert(
          taskId: task.id,
          op: ChangeOp.upsert,
          payload: jsonEncode(task.toJson()),
        ));
      });

  Future<void> deleteTask(Task task) => transaction(() async {
        await (delete(tasks)..where((t) => t.id.equals(task.id))).go();
        await into(pendingChanges).insert(PendingChangesCompanion.insert(
          taskId: task.id,
          op: ChangeOp.delete,
          payload: jsonEncode(task.toJson()),
        ));
      });
}

// ------------------------------------------------------------
// 2) خادم وهمي: online / offline + «جهاز آخر» يعدّل البيانات
// ------------------------------------------------------------
/// الوقت بدقة الملي ثانية (نفس دقة toJson) حتى تكون المقارنة عادلة بين الجهاز والخادم
DateTime nowMs() => DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch);

class OfflineException implements Exception {
  const OfflineException();
}

class FakeServer {
  FakeServer({this.latency = const Duration(milliseconds: 350)});
  final Duration latency;

  final _tasks = <String, Task>{};
  final _changes = StreamController<List<Task>>.broadcast(); // الدرس 2
  bool online = true;

  List<Task> get snapshot => _tasks.values.toList()..sort((a, b) => a.title.compareTo(b.title));
  Stream<List<Task>> get changes => _changes.stream;

  Future<void> _network() async {
    await Future.delayed(latency);
    if (!online) throw const OfflineException();
  }

  /// يعيد null إذا قُبل التغيير، أو نسخة الخادم الأحدث عند التعارض
  Future<Task?> push(ChangeOp op, Task task) async {
    await _network();
    final current = _tasks[task.id];
    // ⚖️ Last-Write-Wins: نسخة الخادم أحدث؟ نرفض التغيير ونعيدها
    if (current != null && current.updatedAt.isAfter(task.updatedAt)) return current;
    switch (op) {
      case ChangeOp.upsert:
        _tasks[task.id] = task;
      case ChangeOp.delete:
        _tasks.remove(task.id);
    }
    _changes.add(snapshot);
    return null;
  }

  Future<List<Task>> fetchAll() async {
    await _network();
    return snapshot;
  }

  /// مستخدم آخر يعدّل المهمة من جهازه (بدون المرور بجهازنا)
  void editFromAnotherDevice(String id) {
    final task = _tasks[id];
    if (task == null) return;
    _tasks[id] = task.copyWith(
      title: '${task.title.replaceAll(' ✏️', '')} ✏️',
      updatedAt: nowMs(),
    );
    _changes.add(snapshot);
  }

  Future<void> dispose() => _changes.close();
}

// ------------------------------------------------------------
// 3) محرّك المزامنة: push للطابور بالترتيب ← ثم pull
// ------------------------------------------------------------
class SyncEngine {
  SyncEngine(this.db, this.server);
  final SyncDatabase db;
  final FakeServer server;

  Future<String> sync() async {
    var pushed = 0, conflicts = 0, pulled = 0;
    try {
      // --- PUSH: أقدم تغيير أولاً ---
      final pending = await (db.select(db.pendingChanges)
            ..orderBy([(c) => OrderingTerm.asc(c.id)]))
          .get();
      for (final change in pending) {
        final task = Task.fromJson(jsonDecode(change.payload) as Map<String, dynamic>);
        final newer = await server.push(change.op, task);
        await db.transaction(() async {
          if (newer != null) {
            conflicts++; // الخادم فاز ← نكتب نسخته محلياً
            await db.into(db.tasks).insertOnConflictUpdate(newer);
          }
          // نحذف التغيير من الطابور فقط بعد أن رد الخادم
          await (db.delete(db.pendingChanges)..where((c) => c.id.equals(change.id))).go();
        });
        pushed++;
      }

      // --- PULL: ما تغيّر على الخادم من أجهزة أخرى ---
      final remote = await server.fetchAll();
      final remoteIds = {for (final t in remote) t.id};
      await db.transaction(() async {
        // تغيير أضافه المستخدم أثناء المزامنة ولم يُرسل بعد ← لا نلمسه
        final stillPending = {
          for (final c in await db.select(db.pendingChanges).get()) c.taskId,
        };
        for (final r in remote) {
          if (stillPending.contains(r.id)) continue;
          final local = await (db.select(db.tasks)..where((t) => t.id.equals(r.id)))
              .getSingleOrNull();
          if (local == null || r.updatedAt.isAfter(local.updatedAt)) {
            await db.into(db.tasks).insertOnConflictUpdate(r);
            pulled++;
          }
        }
        // حُذفت على الخادم من جهاز آخر ← نحذفها محلياً
        await (db.delete(db.tasks)
              ..where((t) => t.id.isNotIn({...remoteIds, ...stillPending})))
            .go();
      });
      return '✅ أُرسل $pushed · تعارض $conflicts (فاز الخادم) · وصل $pulled';
    } on OfflineException {
      return '📴 لا يوجد اتصال — بقيت التغييرات في الطابور (أُرسل $pushed)';
    }
  }
}

// ------------------------------------------------------------
// 4) Providers
// ------------------------------------------------------------
final syncDatabaseProvider = Provider<SyncDatabase>((ref) {
  final db = SyncDatabase(ref.watch(connectionProvider('offline_first')));
  ref.onDispose(db.close);
  return db;
});

final fakeServerProvider = Provider<FakeServer>((ref) {
  final server = FakeServer();
  ref.onDispose(server.dispose);
  return server;
});

final tasksProvider = StreamProvider<List<Task>>(
  (ref) => ref.watch(syncDatabaseProvider).watchTasks(),
);

final outboxProvider = StreamProvider<List<PendingChange>>(
  (ref) => ref.watch(syncDatabaseProvider).watchOutbox(),
);

final serverTasksProvider = StreamProvider<List<Task>>((ref) async* {
  final server = ref.watch(fakeServerProvider);
  yield server.snapshot; // القيمة الحالية أولاً ثم كل تغيير
  yield* server.changes;
});

class SyncState {
  const SyncState({required this.online, this.syncing = false, this.log = const []});
  final bool online;
  final bool syncing;
  final List<String> log;

  SyncState copyWith({bool? online, bool? syncing, String? addLog}) => SyncState(
        online: online ?? this.online,
        syncing: syncing ?? this.syncing,
        log: addLog == null ? log : [addLog, ...log].take(6).toList(),
      );
}

class SyncController extends Notifier<SyncState> {
  bool _again = false;

  SyncDatabase get _db => ref.read(syncDatabaseProvider);

  @override
  SyncState build() {
    Future.microtask(sync); // مزامنة عند فتح الشاشة
    return const SyncState(online: true);
  }

  void setOnline(bool online) {
    ref.read(fakeServerProvider).online = online;
    state = state.copyWith(online: online, addLog: online ? '📶 عاد الاتصال' : '📴 انقطع الاتصال');
    if (online) sync(); // عاد الاتصال ← أفرغ الطابور
  }

  Future<void> sync() async {
    if (state.syncing) {
      _again = true; // مزامنة جارية؟ نعيدها بعد انتهائها بدل تشغيل اثنتين معاً
      return;
    }
    state = state.copyWith(syncing: true);
    try {
      final report = await SyncEngine(_db, ref.read(fakeServerProvider)).sync();
      if (!ref.mounted) return;
      state = state.copyWith(syncing: false, addLog: report);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(syncing: false, addLog: '❌ تعذّر فتح قاعدة البيانات: $e');
      return;
    }
    if (_again) {
      _again = false;
      await sync();
    }
  }

  // الكتابة محلياً أولاً (فورية) ← ثم مزامنة في الخلفية بدون انتظار
  Future<void> add(String title) async {
    await _db.saveTask(Task(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      done: false,
      updatedAt: nowMs(),
    ));
    unawaited(sync());
  }

  Future<void> toggle(Task task) async {
    await _db.saveTask(task.copyWith(done: !task.done, updatedAt: nowMs()));
    unawaited(sync());
  }

  Future<void> remove(Task task) async {
    await _db.deleteTask(task);
    unawaited(sync());
  }
}

final syncControllerProvider =
    NotifierProvider<SyncController, SyncState>(SyncController.new);

// ------------------------------------------------------------
// 5) الشاشة: الجهاز · الطابور · الخادم
// ------------------------------------------------------------
class OfflineFirstScreen extends ConsumerStatefulWidget {
  const OfflineFirstScreen({super.key});

  @override
  ConsumerState<OfflineFirstScreen> createState() => _OfflineFirstScreenState();
}

class _OfflineFirstScreenState extends ConsumerState<OfflineFirstScreen> {
  final _controller = TextEditingController();
  var _counter = 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    ref.read(syncControllerProvider.notifier).add(text.isEmpty ? 'مهمة ${_counter++}' : text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(syncControllerProvider);
    final controller = ref.read(syncControllerProvider.notifier);
    final tasks = ref.watch(tasksProvider).value ?? const [];
    final outbox = ref.watch(outboxProvider).value ?? const [];
    final server = ref.watch(serverTasksProvider).value ?? const [];
    final pendingIds = {for (final c in outbox) c.taskId};
    final title = Theme.of(context).textTheme.titleSmall;

    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 9: Offline-first والمزامنة')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SwitchListTile(
            secondary: Icon(sync.online ? Icons.wifi : Icons.wifi_off),
            title: Text(sync.online ? 'متصل' : 'غير متصل (محاكاة)'),
            subtitle: sync.syncing ? const LinearProgressIndicator() : null,
            value: sync.online,
            onChanged: controller.setOnline,
          ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'مهمة جديدة'),
                  onSubmitted: (_) => _add(),
                ),
              ),
              FilledButton(onPressed: _add, child: const Text('إضافة')),
            ],
          ),
          const SizedBox(height: 12),
          Text('📱 الجهاز — Drift (${tasks.length})', style: title),
          for (final t in tasks)
            CheckboxListTile(
              dense: true,
              value: t.done,
              onChanged: (_) => controller.toggle(t),
              title: Text(t.title),
              secondary: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(pendingIds.contains(t.id) ? Icons.schedule : Icons.cloud_done,
                      size: 18,
                      color: pendingIds.contains(t.id) ? Colors.orange : Colors.green),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => controller.remove(t),
                  ),
                ],
              ),
            ),
          const Divider(),
          Text('📤 الطابور Outbox (${outbox.length})', style: title),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (outbox.isEmpty) const Text('فارغ — كل شيء وصل للخادم ✅'),
              for (final c in outbox) Chip(label: Text('#${c.id} ${c.op.name}')),
            ],
          ),
          const Divider(),
          Text('☁️ الخادم (${server.length})', style: title),
          for (final t in server)
            ListTile(
              dense: true,
              leading: Icon(t.done ? Icons.check_box : Icons.check_box_outline_blank),
              title: Text(t.title),
              trailing: TextButton(
                onPressed: () => ref.read(fakeServerProvider).editFromAnotherDevice(t.id),
                child: const Text('تعديل من جهاز آخر'),
              ),
            ),
          const Divider(),
          Text('📝 سجل المزامنة', style: title),
          for (final line in sync.log) Text(line),
        ],
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) لمعرفة حالة الشبكة الحقيقية: connectivity_plus يعطي Stream للتغيّرات:
//      Connectivity().onConnectivityChanged.listen((results) { ... });
//    لكنه يعرف «هل توجد شبكة» وليس «هل الخادم يرد» — الحكم النهائي لنجاح الطلب.
//
// 2) اجعل كل عملية على الخادم idempotent: إرسال نفس التغيير مرتين لا يضر
//    (مهم لأن التطبيق قد يُغلق بعد أن يرد الخادم وقبل حذف السطر من الطابور).
//
// 3) ادمج التغييرات المتتالية لنفس العنصر قبل الإرسال (coalescing):
//    10 تعديلات على مهمة واحدة أثناء الانقطاع = طلب واحد بآخر نسخة.
//
// 4) المعرّفات تُنشأ على الجهاز (UUID) — لا تنتظر الخادم ليعطيك id وإلا لن تعمل أوفلاين.
//
// 5) للمزامنة في الخلفية والتطبيق مغلق: workmanager على Android و
//    BGTaskScheduler على iOS — نفس SyncEngine، فقط من يستدعيه يختلف.
