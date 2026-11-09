// ============================================================
// الدرس 2 (Riverpod): الأساسيات — ProviderScope و ref (watch / read / listen)
// في التطبيق: القائمة ← الدرس 2  ·  في العرض: شرائح الدرس 2
// ============================================================
//
// الفكرة: الحالة (State) تعيش خارج الـ Widgets داخل "Providers".
// أي Widget يستطيع قراءة أي Provider بدون تمرير البيانات عبر الـ constructors.
//
// الخطوات:
//   1) نلف التطبيق بـ ProviderScope (انظر main.dart) ← هنا تُخزَّن كل الحالات
//   2) نعرّف Provider كمتغير global (آمن، لأنه مجرد "وصفة" وليس القيمة نفسها)
//   3) نستخدم ConsumerWidget بدل StatelessWidget لنحصل على ref

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ------------------------------------------------------------
// Provider بسيط: قيمة للقراءة فقط
// ------------------------------------------------------------
final greetingProvider = Provider<String>((ref) => 'أهلاً بك في Riverpod 👋');

// ------------------------------------------------------------
// Notifier: حالة قابلة للتغيير + الدوال التي تغيّرها
// ------------------------------------------------------------
class CounterNotifier extends Notifier<int> {
  // build() تعيد القيمة الابتدائية
  @override
  int build() => 0;

  // نغيّر الحالة بإسناد قيمة جديدة لـ state ← كل من يراقب يُعاد بناؤه
  void increment() => state++;
  void decrement() => state--;
  void reset() => state = 0;
}

final counterProvider = NotifierProvider<CounterNotifier, int>(
  CounterNotifier.new,
);

class BasicsScreen extends ConsumerWidget {
  const BasicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ------------------------------------------------------------
    // ref.watch: اقرأ القيمة + أعد بناء الـ Widget عند تغيّرها
    // ✅ استخدمه داخل build
    // ------------------------------------------------------------
    final greeting = ref.watch(greetingProvider);
    final count = ref.watch(counterProvider);

    // ------------------------------------------------------------
    // ref.listen: نفّذ "تأثيراً جانبياً" عند التغيّر (SnackBar، تنقّل، Dialog)
    // لا يعيد البناء — فقط يستدعي الدالة
    // ------------------------------------------------------------
    ref.listen<int>(counterProvider, (previous, next) {
      if (next == 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 وصلت إلى 10!')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 2: الأساسيات و ref')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Text(greeting, style: Theme.of(context).textTheme.titleLarge),
            Text('$count', style: Theme.of(context).textTheme.displayLarge),

            // ------------------------------------------------------------
            // Consumer: يعيد بناء جزء صغير فقط بدل الشاشة كاملة
            // select: نراقب جزءاً من القيمة (هنا: زوجي/فردي فقط)
            //         فلا يُعاد البناء إلا إذا تغيّر هذا الجزء
            // ------------------------------------------------------------
            Consumer(
              builder: (context, ref, _) {
                final isEven = ref.watch(
                  counterProvider.select((value) => value.isEven),
                );
                return Chip(label: Text(isEven ? 'زوجي' : 'فردي'));
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          // ------------------------------------------------------------
          // ref.read: اقرأ مرة واحدة بدون مراقبة
          // ✅ استخدمه داخل الأحداث (onPressed) — ❌ لا تستخدمه داخل build
          // .notifier تعطينا كائن الـ Notifier لنستدعي دواله
          // ------------------------------------------------------------
          FloatingActionButton(
            heroTag: 'dec',
            onPressed: () => ref.read(counterProvider.notifier).decrement(),
            child: const Icon(Icons.remove),
          ),
          FloatingActionButton(
            heroTag: 'reset',
            onPressed: () => ref.read(counterProvider.notifier).reset(),
            child: const Icon(Icons.refresh),
          ),
          FloatingActionButton(
            heroTag: 'inc',
            onPressed: () => ref.read(counterProvider.notifier).increment(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

// 📌 ملخص:
// watch  ← داخل build، للعرض وإعادة البناء
// read   ← داخل الأحداث، لاستدعاء الدوال
// listen ← للتأثيرات الجانبية (SnackBar / Navigation)
// 💡 للـ StatefulWidget نستخدم ConsumerStatefulWidget و ConsumerState

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) Consumer له باراميتر child: الجزء الثابت لا يُعاد بناؤه أبداً
//      Consumer(
//        builder: (context, ref, child) => Row(children: [Text('${ref.watch(counterProvider)}'), child!]),
//        child: const ExpensiveLogo(),   ← يُبنى مرة واحدة
//      )
//
// 2) ref.listen يقبل fireImmediately: true لتنفيذ الدالة فوراً بالقيمة الحالية.
//
// 3) اجعل state خاصاً بالـ Notifier: لا تعدّل ref.read(p.notifier).state = ... من الـ UI،
//    بل اكتب دالة واضحة (increment / reset) — أسهل في الاختبار والتتبع.
//
// 4) سمِّ كل provider باسم ينتهي بـ Provider (counterProvider) ليسهل البحث عنه.
//
// 5) لتتبع كل تغيّر في الحالات أثناء التطوير: ProviderScope(observers: [MyLogger()])
//    حيث MyLogger يرث من ProviderObserver ويطبع didUpdateProvider.
