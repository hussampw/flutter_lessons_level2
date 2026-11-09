// ============================================================
// الدرس 6: Drift — الترحيل (Migrations) والاستعلامات التفاعلية watch()
// في التطبيق: القائمة ← الدرس 6  ·  في العرض: شرائح الدرس 6
// ============================================================
//
// الترحيل: التطبيق المنشور عند المستخدمين لديه ملف قاعدة بيانات بالإصدار القديم.
// إذا أضفنا عموداً في التحديث الجديد يجب أن نخبر Drift كيف يحوّل الملف القديم:
//   schemaVersion  ← رقم الإصدار الحالي للمخطط (نزيده مع كل تغيير)
//   onCreate       ← مستخدم جديد: أنشئ كل الجداول
//   onUpgrade      ← مستخدم قديم: from = إصداره، to = الإصدار الجديد
//
// watch(): نفس الاستعلام لكن يعيد Stream<List<T>> (الدرس 2!)
// يرسل قائمة جديدة تلقائياً بعد كل insert / update / delete على الجدول
// ← الواجهة تتحدث وحدها، بدون setState وبدون «تحديث» يدوي.
//
// التوليد: dart run build_runner build -d   ← ينشئ 06_drift_migrations_watch.g.dart

import 'package:drift/drift.dart' hide Column; // Column هنا = Widget من Flutter
import 'package:flutter/material.dart' hide Table;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/database_connection.dart';

part '06_drift_migrations_watch.g.dart';

// ------------------------------------------------------------
// 1) الجدول — الإصدار 1 كان: id, title, created_at
//    الإصدار 2 أضاف: pinned
// ------------------------------------------------------------
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  // 🆕 الإصدار 2 — قيمة افتراضية حتى تحصل الصفوف القديمة على false
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Notes])
class NotesDatabase extends _$NotesDatabase {
  NotesDatabase(super.executor);

  /// سجل ما حدث عند فتح الملف — نعرضه في الشاشة
  final migrationLog = <String>[];

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          migrationLog.add('onCreate: ملف جديد ← createAll() بالإصدار $schemaVersion');
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          migrationLog.add('onUpgrade: من $from إلى $to');
          // خطوة لكل إصدار — مستخدم على الإصدار 1 ينفّذ كل الخطوات بعده بالترتيب
          if (from < 2) {
            await m.addColumn(notes, notes.pinned);
            migrationLog.add('  ALTER TABLE notes ADD COLUMN pinned');
          }
          // if (from < 3) { await m.createTable(tags); }  ← التحديث القادم
        },
        beforeOpen: (details) async {
          migrationLog.add('beforeOpen: قبل=${details.versionBefore} الآن=${details.versionNow}');
        },
      );

  // ----------------------------------------------------------
  // 2) استعلامات تفاعلية: watch() بدل get()
  // ----------------------------------------------------------

  // المثبّتة أولاً، ثم الأحدث
  Stream<List<Note>> watchNotes() => (select(notes)
        ..orderBy([
          (n) => OrderingTerm.desc(n.pinned),
          (n) => OrderingTerm.desc(n.createdAt),
        ]))
      .watch();

  // SELECT COUNT(*) FROM notes — قيمة واحدة تتحدث أيضاً
  Stream<int> watchCount() {
    final count = notes.id.count();
    return (selectOnly(notes)..addColumns([count]))
        .map((row) => row.read(count)!)
        .watchSingle();
  }

  Future<int> addNote(String title) =>
      into(notes).insert(NotesCompanion.insert(title: title));

  Future<void> togglePin(Note note) =>
      (update(notes)..where((n) => n.id.equals(note.id)))
          .write(NotesCompanion(pinned: Value(!note.pinned)));

  Future<void> deleteNote(int id) =>
      (delete(notes)..where((n) => n.id.equals(id))).go();

  /// للعرض فقط: نعيد الملف إلى شكل الإصدار 1 كأنه هاتف لم يُحدَّث بعد
  Future<void> rollBackToV1ForDemo() async {
    await customStatement('ALTER TABLE notes DROP COLUMN pinned');
    await customStatement('PRAGMA user_version = 1');
  }
}

// ------------------------------------------------------------
// 3) Providers: StreamProvider يشترك في watch() ويلغي الاشتراك تلقائياً
// ------------------------------------------------------------
final notesDatabaseProvider = Provider<NotesDatabase>((ref) {
  final db = NotesDatabase(ref.watch(connectionProvider('notes')));
  ref.onDispose(db.close);
  return db;
});

final notesProvider = StreamProvider<List<Note>>(
  (ref) => ref.watch(notesDatabaseProvider).watchNotes(),
);

final notesCountProvider = StreamProvider<int>(
  (ref) => ref.watch(notesDatabaseProvider).watchCount(),
);

/// (إصدار الملف، أعمدة الجدول، سجل الترحيل)
final schemaInfoProvider = FutureProvider<(int, List<String>, List<String>)>((ref) async {
  final db = ref.watch(notesDatabaseProvider);
  final version = await db
      .customSelect('PRAGMA user_version')
      .map((r) => r.read<int>('user_version'))
      .getSingle();
  final columns = await db
      .customSelect('PRAGMA table_info(notes)')
      .map((r) => r.read<String>('name'))
      .get();
  return (version, columns, List.of(db.migrationLog));
});

// ------------------------------------------------------------
// 4) الشاشة
// ------------------------------------------------------------
class DriftMigrationsWatchScreen extends StatelessWidget {
  const DriftMigrationsWatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 6: Migrations و watch()')),
      body: const Column(
        children: [
          _SchemaCard(),
          Expanded(child: _NotesCard()),
        ],
      ),
    );
  }
}

class _SchemaCard extends ConsumerWidget {
  const _SchemaCard();

  Future<void> _simulateOldUser(WidgetRef ref) async {
    await ref.read(notesDatabaseProvider).rollBackToV1ForDemo();
    // نغلق الاتصال ونفتحه من جديد ← Drift يرى user_version = 1 فيستدعي onUpgrade
    ref.invalidate(connectionProvider('notes'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(schemaInfoProvider);
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text('1) المخطط والترحيل', style: Theme.of(context).textTheme.titleMedium),
            switch (info) {
              AsyncData(value: (final version, final columns, final log)) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('user_version = $version · الأعمدة: ${columns.join(', ')}'),
                    for (final line in log)
                      Text(line, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                  ],
                ),
              AsyncError(:final error) => Text('❌ تعذّر فتح قاعدة البيانات: $error'),
              _ => const LinearProgressIndicator(),
            },
            OutlinedButton.icon(
              onPressed: () => _simulateOldUser(ref),
              icon: const Icon(Icons.history),
              label: const Text('محاكاة: هاتف عليه الإصدار 1 ثم حدّث التطبيق'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends ConsumerStatefulWidget {
  const _NotesCard();

  @override
  ConsumerState<_NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends ConsumerState<_NotesCard> {
  final _controller = TextEditingController();
  int _emissions = 0; // كم مرة أرسل الـ Stream قائمة جديدة

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final text = _controller.text.trim();
    // لاحظ: لا setState للقائمة — watch() سيرسل القائمة الجديدة وحده
    await ref.read(notesDatabaseProvider).addNote(text.isEmpty ? 'ملاحظة جديدة' : text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(notesProvider, (_, next) {
      if (next.hasValue) setState(() => _emissions++);
    });
    final notes = ref.watch(notesProvider);
    final count = ref.watch(notesCountProvider).value ?? 0;
    final db = ref.read(notesDatabaseProvider);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text('2) watch(): $count ملاحظة · أرسل الـ Stream $_emissions مرة',
                style: Theme.of(context).textTheme.titleMedium),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'عنوان الملاحظة'),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                FilledButton(onPressed: _add, child: const Text('إضافة')),
              ],
            ),
            Expanded(
              child: switch (notes) {
                AsyncData(:final value) when value.isEmpty =>
                  const Center(child: Text('لا توجد ملاحظات — أضف واحدة')),
                AsyncData(:final value) => ListView(
                    children: [
                      for (final note in value)
                        ListTile(
                          dense: true,
                          leading: IconButton(
                            icon: Icon(note.pinned ? Icons.push_pin : Icons.push_pin_outlined),
                            onPressed: () => db.togglePin(note),
                          ),
                          title: Text(note.title),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => db.deleteNote(note.id),
                          ),
                        ),
                    ],
                  ),
                AsyncError(:final error) => Text('❌ $error'),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) لا تعدّل migration قديمة نُشرت للمستخدمين — أضف خطوة جديدة (from < 3) دائماً.
//
// 2) احفظ نسخة من المخطط مع كل إصدار، واجعل Drift يولّد خطوات واختبارات الترحيل:
//      dart run drift_dev make-migrations
//    (يحتاج إعداد databases في build.yaml — راجع توثيق Drift)
//
// 3) اختبر الترحيل: افتح قاعدة في الذاكرة بشكل الإصدار القديم ثم افتحها بـ Drift
//    (انظر test/notes_migration_test.dart — نستخدم setup في NativeDatabase.memory).
//
// 4) watch() يراقب الجداول وليس الصفوف: أي تغيير في notes يعيد تنفيذ الاستعلام.
//    لقائمة كبيرة جداً استخدم limit أو Stream لعنصر واحد: watchSingleOrNull().
//
// 5) SQL مباشر يتحدث تلقائياً أيضاً إذا ذكرت الجداول:
//      customSelect('SELECT ...', readsFrom: {notes}).watch()
