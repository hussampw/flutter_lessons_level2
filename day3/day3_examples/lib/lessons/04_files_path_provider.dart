// ============================================================
// الدرس 4: الملفات مع path_provider — أين أحفظ؟ وكيف أكتب وأقرأ؟
// في التطبيق: القائمة ← الدرس 4  ·  في العرض: شرائح الدرس 4
// ============================================================
//
// path_provider يعطينا "مسارات" فقط، والكتابة والقراءة تتم بـ dart:io (File / Directory).
// أهم 3 مجلدات:
//   • Documents  getApplicationDocumentsDirectory() ← بيانات المستخدم (تُنسخ احتياطياً في iOS)
//   • Support    getApplicationSupportDirectory()   ← ملفات التطبيق الداخلية (قواعد بيانات، إعدادات)
//   • Cache      getApplicationCacheDirectory()     ← يمكن للنظام حذفها عند امتلاء الذاكرة
//
// الشاشة: (1) مسارات هذه المنصة  (2) ملف JSON نكتبه ونقرأه  (3) كاش صور على القرص
// ⚠️ على الويب لا يوجد نظام ملفات ← نعرض شرحاً بدل الأمثلة.

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../shared/network.dart';

// ------------------------------------------------------------
// 1) المسارات حسب المنصة — كل استدعاء داخل try لأن بعضها غير مدعوم
// ------------------------------------------------------------
Future<String> _describe(Future<Directory?> Function() getDir) async {
  try {
    final dir = await getDir();
    return dir?.path ?? '— (null على هذه المنصة)';
  } on MissingPluginException {
    return '— لا يوجد Plugin هنا (مثلاً داخل flutter test)';
  } on UnsupportedError {
    return '— غير مدعوم على هذه المنصة';
  }
}

final directoriesProvider = FutureProvider<List<(String, String)>>((ref) async {
  return [
    ('Documents', await _describe(getApplicationDocumentsDirectory)),
    ('Support', await _describe(getApplicationSupportDirectory)),
    ('Cache', await _describe(getApplicationCacheDirectory)),
    ('Temporary', await _describe(getTemporaryDirectory)),
    ('Downloads', await _describe(getDownloadsDirectory)),
  ];
});

// ------------------------------------------------------------
// 2) ملف JSON: كتابة آمنة (ملف مؤقت ثم rename) وقراءة
// ------------------------------------------------------------
class JsonFileStore {
  JsonFileStore(this.file);
  final File file;

  Future<List<String>> read() async {
    if (!await file.exists()) return []; // أول تشغيل: لا يوجد ملف بعد
    final text = await file.readAsString();
    return (jsonDecode(text) as List).cast<String>();
  }

  Future<void> write(List<String> items) async {
    // نكتب في ملف مؤقت ثم نعيد تسميته: إذا انقطعت الكهرباء أثناء الكتابة
    // يبقى الملف القديم سليماً بدل ملف JSON نصفه مكتوب
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(items), flush: true);
    await tmp.rename(file.path);
  }
}

Future<JsonFileStore> openNotesFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return JsonFileStore(File(p.join(dir.path, 'day3_notes.json')));
}

// ------------------------------------------------------------
// 3) كاش صور على القرص: نحمّل مرة واحدة، والمرات التالية من الملف
// ------------------------------------------------------------
class ImageFileCache {
  ImageFileCache(this.dio);
  final Dio dio;

  Future<Directory> _dir() async {
    final cache = await getApplicationCacheDirectory();
    return Directory(p.join(cache.path, 'images')).create(recursive: true);
  }

  /// يعيد الملف + هل جاء من الكاش؟
  Future<(File, bool)> get(String url, String fileName) async {
    final file = File(p.join((await _dir()).path, fileName));
    if (await file.exists()) return (file, true); // ✅ بدون شبكة

    final res = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    await file.writeAsBytes(res.data!, flush: true);
    return (file, false);
  }

  Future<void> clear() async {
    final dir = await _dir();
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

// ------------------------------------------------------------
// 4) الشاشة
// ------------------------------------------------------------
class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 4: الملفات مع path_provider')),
      body: kIsWeb
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                '🌐 على الويب لا يوجد نظام ملفات للتطبيق، و path_provider غير مدعوم.\n'
                'البدائل: shared_preferences (الدرس 3) أو Drift على الويب (الدرس 5)، '
                'وللتنزيل: إنشاء رابط ملف في المتصفح.\n'
                'شغّل هذا الدرس على Android أو iOS أو Linux.',
                style: TextStyle(fontSize: 17, height: 1.6),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(12),
              children: const [
                _DirectoriesCard(),
                SizedBox(height: 12),
                _JsonFileCard(),
                SizedBox(height: 12),
                _ImageCacheCard(),
              ],
            ),
    );
  }
}

class _DirectoriesCard extends ConsumerWidget {
  const _DirectoriesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dirs = ref.watch(directoriesProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text('1) المجلدات على هذه المنصة',
                style: Theme.of(context).textTheme.titleMedium),
            ...switch (dirs) {
              AsyncData(:final value) => [
                  for (final (name, path) in value)
                    Text('$name: $path',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                ],
              AsyncError(:final error) => [Text('خطأ: $error')],
              _ => [const LinearProgressIndicator()],
            },
          ],
        ),
      ),
    );
  }
}

class _JsonFileCard extends StatefulWidget {
  const _JsonFileCard();

  @override
  State<_JsonFileCard> createState() => _JsonFileCardState();
}

class _JsonFileCardState extends State<_JsonFileCard> {
  List<String> _items = [];
  String _status = 'اضغط «قراءة» لفتح الملف';

  Future<void> _guard(Future<void> Function(JsonFileStore store) action) async {
    try {
      final store = await openNotesFile();
      await action(store);
    } on MissingPluginException {
      _setStatus('⚠️ path_provider غير متاح هنا (لا يوجد Plugin)');
    } on FileSystemException catch (e) {
      _setStatus('❌ خطأ في الملف: ${e.message}');
    }
  }

  void _setStatus(String s) {
    if (mounted) setState(() => _status = s);
  }

  Future<void> _read() => _guard((store) async {
        final items = await store.read();
        if (!mounted) return;
        setState(() {
          _items = items;
          _status = '📄 قرأنا ${items.length} عنصر من ${p.basename(store.file.path)}';
        });
      });

  Future<void> _add() => _guard((store) async {
        final items = [...await store.read(), 'ملاحظة ${DateTime.now().second}'];
        await store.write(items);
        final bytes = await store.file.length();
        if (!mounted) return;
        setState(() {
          _items = items;
          _status = '💾 كتبنا $bytes بايت';
        });
      });

  Future<void> _delete() => _guard((store) async {
        if (await store.file.exists()) await store.file.delete();
        if (!mounted) return;
        setState(() {
          _items = [];
          _status = '🗑️ حُذف الملف';
        });
      });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text('2) ملف JSON في Documents',
                style: Theme.of(context).textTheme.titleMedium),
            Wrap(spacing: 8, children: [
              FilledButton.tonal(onPressed: _read, child: const Text('قراءة')),
              FilledButton.tonal(onPressed: _add, child: const Text('إضافة + حفظ')),
              OutlinedButton(onPressed: _delete, child: const Text('حذف الملف')),
            ]),
            Text(_status),
            if (_items.isNotEmpty)
              Text(jsonEncode(_items),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ImageCacheCard extends ConsumerStatefulWidget {
  const _ImageCacheCard();

  @override
  ConsumerState<_ImageCacheCard> createState() => _ImageCacheCardState();
}

class _ImageCacheCardState extends ConsumerState<_ImageCacheCard> {
  static const _url = 'https://dummyjson.com/image/240x240/008080/ffffff?text=Day+3';
  File? _file;
  String _status = 'المرة الأولى من الشبكة، والمرات التالية من القرص';

  ImageFileCache get _cache => ImageFileCache(ref.read(dioProvider));

  Future<void> _load() async {
    final sw = Stopwatch()..start();
    try {
      final (file, fromCache) = await _cache.get(_url, 'day3_banner.png');
      final size = await file.length();
      if (!mounted) return;
      setState(() {
        _file = file;
        _status = '${fromCache ? '⚡ من الكاش' : '📡 من الشبكة'} · '
            '$size بايت · ${sw.elapsedMilliseconds}ms';
      });
    } on MissingPluginException {
      _setStatus('⚠️ path_provider غير متاح هنا');
    } on DioException catch (e) {
      _setStatus('❌ ${friendlyNetworkError(e)}');
    }
  }

  Future<void> _clear() async {
    try {
      await _cache.clear();
      if (!mounted) return;
      setState(() {
        _file = null;
        _status = '🗑️ مُسح مجلد images من الكاش';
      });
    } on MissingPluginException {
      _setStatus('⚠️ path_provider غير متاح هنا');
    }
  }

  void _setStatus(String s) {
    if (mounted) setState(() => _status = s);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text('3) كاش صور في Cache/images',
                style: Theme.of(context).textTheme.titleMedium),
            Wrap(spacing: 8, children: [
              FilledButton.tonal(onPressed: _load, child: const Text('تحميل الصورة')),
              OutlinedButton(onPressed: _clear, child: const Text('مسح الكاش')),
            ]),
            Text(_status),
            if (_file != null) Image.file(_file!, height: 120),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) ابنِ المسارات بـ package:path وليس بجمع النصوص — الفاصل يختلف بين الأنظمة:
//      p.join(dir.path, 'images', 'a.png')   ✅
//      '${dir.path}/images/a.png'            ❌ على Windows
//
// 2) الملفات الكبيرة: لا تقرأها كاملة في الذاكرة — اقرأ كـ Stream (الدرس 2):
//      await file.openRead().transform(utf8.decoder).transform(const LineSplitter()).forEach(print);
//
// 3) Cache قد يُحذف في أي وقت ← لا تضع فيه شيئاً لا يمكن تحميله من جديد.
//    وفي iOS: Documents تُنسخ إلى iCloud — الملفات الكبيرة المؤقتة مكانها Cache.
//
// 4) لاختبار كود الملفات بدون path_provider: مرّر Directory في الـ constructor
//    واستخدم Directory.systemTemp.createTemp() داخل الاختبار.
//
// 5) لكاش الصور من الشبكة في تطبيق حقيقي استخدم مكتبة جاهزة مثل cached_network_image
//    (نفس الفكرة: ملف على القرص + انتهاء صلاحية).
