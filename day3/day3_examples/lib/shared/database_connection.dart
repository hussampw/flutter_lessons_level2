// ============================================================
// فتح اتصال Drift — مكان واحد لكل قواعد بيانات اليوم (الدرس 5 يشرحه)
// ============================================================
//
// driftDatabase من drift_flutter هي الطريقة الموصى بها حالياً:
//   • Android / iOS / Linux / macOS / Windows: ملف SQLite في مجلد المستندات
//     (عبر path_provider) ويعمل في Isolate خلفي فلا تتجمد الواجهة.
//   • الويب: SQLite مترجمة إلى WebAssembly — تحتاج الملفين
//     web/sqlite3.wasm و web/drift_worker.js (موجودان في المشروع).
//
// في الاختبارات لا نفتح ملفاً حقيقياً: نستبدل connectionProvider
// بقاعدة في الذاكرة NativeDatabase.memory() — انظر test/

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

QueryExecutor openConnection(String name) {
  return driftDatabase(
    name: name, // اسم الملف: $name.sqlite
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}

/// اتصال لكل اسم قاعدة بيانات — نقطة override واحدة للاختبارات
final connectionProvider = Provider.family<QueryExecutor, String>(
  (ref, name) => openConnection(name),
);
