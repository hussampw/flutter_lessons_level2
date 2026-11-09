// ============================================================
// الدرس 9: اختبار الطابور (Outbox) والمزامنة وقاعدة التعارض
// التشغيل: flutter test test/offline_sync_test.dart
// ============================================================

import 'package:day3_examples/lessons/09_offline_first_sync.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SyncDatabase db;
  late FakeServer server;
  late SyncEngine engine;

  Task task(String id, String title, DateTime at, {bool done = false}) =>
      Task(id: id, title: title, done: done, updatedAt: at);

  setUp(() {
    db = SyncDatabase(NativeDatabase.memory());
    server = FakeServer(latency: Duration.zero);
    engine = SyncEngine(db, server);
  });
  tearDown(() async {
    await db.close();
    await server.dispose();
  });

  test('أوفلاين: التغيير يبقى في الطابور، وعند الاتصال يصل للخادم', () async {
    server.online = false;
    await db.saveTask(task('1', 'شراء حليب', nowMs()));

    expect(await engine.sync(), startsWith('📴'));
    expect(await db.watchOutbox().first, hasLength(1));
    expect(server.snapshot, isEmpty);

    server.online = true;
    await engine.sync();
    expect(await db.watchOutbox().first, isEmpty);
    expect(server.snapshot.single.title, 'شراء حليب');
  });

  test('تعارض: نسخة الخادم أحدث ← الخادم يفوز', () async {
    await db.saveTask(task('1', 'مهمة', DateTime(2026, 1, 1, 10)));
    await engine.sync();

    server.online = false;
    await db.saveTask(task('1', 'مهمة', DateTime(2026, 1, 1, 11), done: true)); // تعديلنا
    server.editFromAnotherDevice('1'); // جهاز آخر عدّل الآن = أحدث

    server.online = true;
    expect(await engine.sync(), contains('تعارض 1'));
    final local = (await db.watchTasks().first).single;
    expect(local.title, 'مهمة ✏️');
    expect(local.done, isFalse);
  });

  test('تعديلنا أحدث من الخادم ← تعديلنا يفوز', () async {
    await db.saveTask(task('1', 'مهمة', DateTime(2026, 1, 1, 10)));
    await engine.sync();
    server.editFromAnotherDevice('1');

    final later = nowMs().add(const Duration(minutes: 1));
    await db.saveTask(task('1', 'مهمة محلية', later));
    await engine.sync();

    expect(server.snapshot.single.title, 'مهمة محلية');
  });

  test('pull: مهمة من جهاز آخر تظهر محلياً، والمحذوفة على الخادم تختفي', () async {
    await server.push(ChangeOp.upsert, task('9', 'من الويب', nowMs()));
    await engine.sync();
    expect((await db.watchTasks().first).map((t) => t.id), ['9']);

    await server.push(ChangeOp.delete, task('9', 'من الويب', nowMs()));
    await engine.sync();
    expect(await db.watchTasks().first, isEmpty);
  });
}
