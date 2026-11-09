// ============================================================
// الدرس 6: اختبار الترحيل من الإصدار 1 إلى 2 + watch()
// التشغيل: flutter test test/notes_migration_test.dart
// ============================================================

import 'package:day3_examples/lessons/06_drift_migrations_watch.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ملف بالإصدار 1 يُرحَّل إلى 2 والبيانات القديمة تبقى', () async {
    // setup يعمل على SQLite مباشرة قبل Drift ← نصنع ملفاً «قديماً»
    final db = NotesDatabase(NativeDatabase.memory(setup: (raw) {
      raw.execute('CREATE TABLE notes (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          'title TEXT NOT NULL, created_at TEXT NOT NULL)');
      raw.execute("INSERT INTO notes (title, created_at) VALUES ('ملاحظة قديمة', '2025-01-01T10:00:00.000')");
      raw.userVersion = 1;
    }));
    addTearDown(db.close);

    final notes = await db.watchNotes().first;
    expect(notes.single.title, 'ملاحظة قديمة');
    expect(notes.single.pinned, isFalse); // العمود الجديد أخذ القيمة الافتراضية
    expect(db.migrationLog, contains('onUpgrade: من 1 إلى 2'));
  });

  test('watch() يرسل قيمة جديدة بعد كل تغيير', () async {
    final db = NotesDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final counts = <int>[];
    final sub = db.watchCount().listen(counts.add);
    addTearDown(sub.cancel);

    await pumpEventQueue(); // أول قيمة عند الاشتراك
    final id = await db.addNote('أ');
    await pumpEventQueue();
    await db.addNote('ب');
    await pumpEventQueue();
    await db.deleteNote(id);
    await pumpEventQueue();

    expect(counts, [0, 1, 2, 1]); // لم نستدعِ get() مرة واحدة
  });
}
