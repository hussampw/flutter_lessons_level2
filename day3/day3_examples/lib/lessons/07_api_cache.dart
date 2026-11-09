// ============================================================
// الدرس 7: تخزين بيانات الـ API محلياً — stale-while-revalidate
// في التطبيق: القائمة ← الدرس 7  ·  في العرض: شرائح الدرس 7
// ============================================================
//
// المشكلة: كل فتح للشاشة = انتظار الشبكة + شاشة فارغة عند انقطاع الإنترنت.
// الحل: قاعدة البيانات هي «مصدر الحقيقة» للواجهة، والشبكة فقط تحدّثها.
//
// stale-while-revalidate (SWR):
//   1) اعرض الكاش فوراً (حتى لو قديماً = stale)
//   2) إذا انتهت صلاحيته (TTL) اطلب من الـ API في الخلفية (revalidate)
//   3) احفظ النتيجة في Drift ← watch() (الدرس 6) يحدّث الواجهة وحده
//   4) فشلت الشبكة؟ تبقى البيانات القديمة على الشاشة + رسالة ودّية
//
// جرّب: افتح الشاشة مرة ← اقلب «محاكاة عدم الاتصال» ← اخرج وادخل: القائمة ما زالت هنا.
// التوليد: dart run build_runner build -d   ← ينشئ 07_api_cache.g.dart

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift; // للـ Column فقط (Column بدون بادئة = Widget)
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart' hide Table;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/database_connection.dart';
import '../shared/network.dart';

part '07_api_cache.g.dart';

// ------------------------------------------------------------
// 1) جداول الكاش
// ------------------------------------------------------------
class CachedProducts extends Table {
  IntColumn get id => integer()(); // id من الـ API — وليس autoIncrement
  TextColumn get title => text()();
  RealColumn get price => real()();
  TextColumn get thumbnail => text()();

  @override
  Set<drift.Column> get primaryKey => {id};
}

// متى حدّثنا كل مفتاح آخر مرة؟ (نحتاجه لحساب انتهاء الصلاحية)
class CacheEntries extends Table {
  TextColumn get key => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<drift.Column> get primaryKey => {key};
}

@DriftDatabase(tables: [CachedProducts, CacheEntries])
class CacheDatabase extends _$CacheDatabase {
  CacheDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}

// ------------------------------------------------------------
// 2) ProductCache: يجمع الشبكة (Dio) والقرص (Drift) في مكان واحد
// ------------------------------------------------------------
class ProductCache {
  ProductCache(this.db, this.dio);
  final CacheDatabase db;
  final Dio dio;

  static const _key = 'products';
  static const ttl = Duration(seconds: 30); // قصيرة للعرض — في الواقع دقائق أو ساعات

  // الواجهة تقرأ من هنا فقط — من قاعدة البيانات وليس من الشبكة
  Stream<List<CachedProduct>> watchProducts() =>
      (db.select(db.cachedProducts)..orderBy([(p) => OrderingTerm.asc(p.id)])).watch();

  Future<DateTime?> lastFetch() async {
    final entry = await (db.select(db.cacheEntries)
          ..where((e) => e.key.equals(_key)))
        .getSingleOrNull();
    return entry?.fetchedAt;
  }

  Future<bool> isStale() async {
    final at = await lastFetch();
    return at == null || DateTime.now().difference(at) > ttl;
  }

  /// الطلب من الـ API ثم الحفظ (upsert) — يرمي DioException عند فشل الشبكة
  Future<int> refresh() async {
    final res = await dio.get<Map<String, dynamic>>(
      '/products',
      queryParameters: {'limit': 12, 'select': 'title,price,thumbnail'},
    );
    final rows = [
      for (final json in (res.data!['products'] as List).cast<Map<String, dynamic>>())
        CachedProductsCompanion.insert(
          id: Value(json['id'] as int),
          title: json['title'] as String,
          price: (json['price'] as num).toDouble(),
          thumbnail: json['thumbnail'] as String,
        ),
    ];
    // transaction: البيانات ووقت التحديث يُحفظان معاً أو لا شيء
    await db.transaction(() async {
      await db.batch((b) => b.insertAllOnConflictUpdate(db.cachedProducts, rows));
      await db.into(db.cacheEntries).insertOnConflictUpdate(
            CacheEntriesCompanion.insert(key: _key, fetchedAt: DateTime.now()),
          );
    });
    return rows.length;
  }

  Future<void> clear() => db.transaction(() async {
        await db.delete(db.cachedProducts).go();
        await db.delete(db.cacheEntries).go();
      });
}

// ------------------------------------------------------------
// 3) Providers
// ------------------------------------------------------------
final cacheDatabaseProvider = Provider<CacheDatabase>((ref) {
  final db = CacheDatabase(ref.watch(connectionProvider('api_cache')));
  ref.onDispose(db.close);
  return db;
});

final productCacheProvider = Provider<ProductCache>(
  (ref) => ProductCache(ref.watch(cacheDatabaseProvider), ref.watch(dioProvider)),
);

final cachedProductsProvider = StreamProvider<List<CachedProduct>>(
  (ref) => ref.watch(productCacheProvider).watchProducts(),
);

enum CachePhase { checking, fresh, refreshing, failed }

class CacheStatus {
  const CacheStatus(this.phase, {this.fetchedAt, this.error});
  final CachePhase phase;
  final DateTime? fetchedAt;
  final String? error;
}

// حالة «إعادة التحقق» منفصلة عن البيانات: البيانات من Drift، والحالة من هنا
class RevalidateNotifier extends Notifier<CacheStatus> {
  @override
  CacheStatus build() {
    Future.microtask(revalidate); // عند فتح الشاشة: تحقق من الصلاحية
    return const CacheStatus(CachePhase.checking);
  }

  Future<void> revalidate({bool force = false}) async {
    final cache = ref.read(productCacheProvider);
    // بعد كل await: ربما خرج المستخدم من الشاشة وتخلّص autoDispose من الـ Notifier
    void emit(CacheStatus s) {
      if (ref.mounted) state = s;
    }

    try {
      if (!force && !await cache.isStale()) {
        // ✅ الكاش ما زال صالحاً ← لا طلب شبكة إطلاقاً
        emit(CacheStatus(CachePhase.fresh, fetchedAt: await cache.lastFetch()));
        return;
      }
      emit(CacheStatus(CachePhase.refreshing, fetchedAt: await cache.lastFetch()));
      await cache.refresh();
      emit(CacheStatus(CachePhase.fresh, fetchedAt: await cache.lastFetch()));
    } on DioException catch (e) {
      // ❌ الشبكة فشلت — البيانات القديمة تبقى معروضة
      emit(CacheStatus(
        CachePhase.failed,
        fetchedAt: await cache.lastFetch(),
        error: friendlyNetworkError(e),
      ));
    } catch (e) {
      emit(CacheStatus(CachePhase.failed, error: 'تعذّر فتح قاعدة البيانات: $e'));
    }
  }

  Future<void> clearCache() async {
    await ref.read(productCacheProvider).clear();
    state = const CacheStatus(CachePhase.failed, error: 'مُسح الكاش — اسحب للتحديث');
  }
}

final revalidateProvider =
    NotifierProvider.autoDispose<RevalidateNotifier, CacheStatus>(RevalidateNotifier.new);

// ------------------------------------------------------------
// 4) الشاشة
// ------------------------------------------------------------
class ApiCacheScreen extends ConsumerWidget {
  const ApiCacheScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(revalidateProvider);
    final products = ref.watch(cachedProductsProvider);
    final offline = ref.watch(offlineModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدرس 7: كاش بيانات الـ API'),
        actions: [
          IconButton(
            tooltip: 'مسح الكاش',
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => ref.read(revalidateProvider.notifier).clearCache(),
          ),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            secondary: Icon(offline ? Icons.wifi_off : Icons.wifi),
            title: const Text('محاكاة عدم الاتصال'),
            value: offline,
            onChanged: (_) => ref.read(offlineModeProvider.notifier).toggle(),
          ),
          _StatusBanner(status: status),
          Expanded(
            child: RefreshIndicator(
              // السحب للأسفل = تحديث إجباري متجاهلاً الـ TTL
              onRefresh: () => ref.read(revalidateProvider.notifier).revalidate(force: true),
              child: switch (products) {
                AsyncData(:final value) when value.isEmpty => ListView(
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('الكاش فارغ — اتصل بالإنترنت واسحب للتحديث',
                            textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                AsyncData(:final value) => ListView(
                    children: [
                      for (final p in value)
                        ListTile(
                          leading: Image.network(
                            p.thumbnail,
                            width: 48,
                            errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
                          ),
                          title: Text(p.title, textDirection: TextDirection.ltr),
                          trailing: Text('\$${p.price}'),
                        ),
                    ],
                  ),
                AsyncError(:final error) => ListView(children: [Text('❌ $error')]),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final CacheStatus status;

  @override
  Widget build(BuildContext context) {
    final at = status.fetchedAt;
    final age = at == null ? 'لم نحمّل بعد' : 'آخر تحديث قبل ${DateTime.now().difference(at).inSeconds} ث';
    final (icon, color, text) = switch (status.phase) {
      CachePhase.checking => ('⏳', Colors.blueGrey, 'نتحقق من صلاحية الكاش…'),
      CachePhase.fresh => ('🟢', Colors.green, 'البيانات حديثة · $age'),
      CachePhase.refreshing => ('🔄', Colors.blue, 'نعرض الكاش ونحدّث في الخلفية… · $age'),
      CachePhase.failed => ('🟠', Colors.orange, '${status.error} · $age'),
    };
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$icon $text'),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) الواجهة تقرأ من قاعدة البيانات دائماً، والشبكة تكتب فيها فقط
//    ← مصدر حقيقة واحد (Single Source of Truth) = لا تضارب بين نسختين.
//
// 2) لا تمسح الجدول ثم تُدخل من جديد (ستومض القائمة فارغة) — استخدم upsert:
//      b.insertAllOnConflictUpdate(db.cachedProducts, rows)
//
// 3) خزّن وقت التحديث مع البيانات في نفس transaction، وإلا قد تحفظ
//    بيانات جديدة بوقت قديم إذا انقطع التطبيق بينهما.
//
// 4) TTL مختلف لكل نوع بيانات: الأسعار دقائق، التصنيفات ساعات، الصفحات الثابتة أيام.
//
// 5) للصفحات (pagination): خزّن مع كل صف رقم الصفحة أو ترتيبه (position)
//    حتى تعيد الترتيب نفسه من الكاش.
