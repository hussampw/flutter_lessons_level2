// ============================================================
// الدرس 2 (الأداء): Flutter DevTools وتقليل إعادة البناء
// في التطبيق: القائمة ← الدرس 2  ·  في العرض: شرائح الدرس 2
// ============================================================
//
// قبل أي تحسين: قِس! DevTools يخبرك أين المشكلة فعلاً.
//   flutter run --profile   ← القياس الصحيح يكون في profile (debug أبطأ بكثير)
//   ثم افتح DevTools من الرابط الذي يطبعه flutter run أو من VS Code / Android Studio
//
// أهم 3 تبويبات:
//   Performance ← الإطارات البطيئة (الأحمر) + "Track widget builds"
//   Flutter Inspector ← شجرة الـ Widgets + "Highlight repaints"
//   CPU Profiler / Memory ← الدوال الأثقل وتسرّب الذاكرة
//
// ثم 4 أدوات لتقليل إعادة البناء — كلها في هذه الشاشة مع عدّاد مرئي:
//   1) const   2) تقسيم الـ Widgets   3) select في Riverpod   4) RepaintBoundary

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ------------------------------------------------------------
// عدّاد إعادة البناء: يزيد في كل مرة تُستدعى فيها build()
// (نعدّل متغيراً داخل build للعرض فقط — لا تفعل هذا في كود حقيقي)
// ------------------------------------------------------------
class BuildCounter extends StatefulWidget {
  const BuildCounter(this.label, {super.key});

  final String label;

  @override
  State<BuildCounter> createState() => _BuildCounterState();
}

class _BuildCounterState extends State<BuildCounter> {
  int _builds = 0;

  @override
  Widget build(BuildContext context) {
    _builds++;
    return Chip(
      avatar: CircleAvatar(child: Text('$_builds')),
      label: Text(widget.label),
    );
  }
}

// ------------------------------------------------------------
// 3) Riverpod select: حالة فيها حقلان (اسم + إعجابات) كـ Record
// ------------------------------------------------------------
class ProfileNotifier extends Notifier<({String name, int likes})> {
  @override
  ({String name, int likes}) build() => (name: 'سارة', likes: 0);

  void like() => state = (name: state.name, likes: state.likes + 1);
  void rename(String name) => state = (name: name, likes: state.likes);
}

final profileProvider =
    NotifierProvider<ProfileNotifier, ({String name, int likes})>(
  ProfileNotifier.new,
);

class RebuildsScreen extends StatefulWidget {
  const RebuildsScreen({super.key});

  @override
  State<RebuildsScreen> createState() => _RebuildsScreenState();
}

class _RebuildsScreenState extends State<RebuildsScreen> {
  int _taps = 0;
  bool _rainbow = false;

  @override
  void dispose() {
    debugRepaintRainbowEnabled = false; // نعيد الأداة لوضعها الطبيعي
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 2: DevTools وإعادة البناء')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ------------------------------------------------------------
          // 1) const: نفس الـ instance ← Flutter يتخطى بناءه تماماً
          // ------------------------------------------------------------
          _Section(
            title: '1) const — اضغط الزر وراقب الأرقام',
            children: [
              Text('setState في الشاشة كلها: $_taps'),
              Wrap(
                spacing: 8,
                children: [
                  // ❌ بدون const: يُبنى من جديد مع كل setState في الأب
                  BuildCounter('بدون const'),
                  // ✅ مع const: يُبنى مرة واحدة فقط
                  const BuildCounter('مع const'),
                ],
              ),
              FilledButton.tonal(
                onPressed: () => setState(() => _taps++),
                child: const Text('setState() في الأب'),
              ),
            ],
          ),

          // ------------------------------------------------------------
          // 2) تقسيم الـ Widgets: الحالة المتغيرة في Widget صغير خاص بها
          // ------------------------------------------------------------
          const _Section(
            title: '2) تقسيم الـ Widgets — العدّاد داخل Widget مستقل',
            children: [
              // setState داخل _SmallCounter لا يعيد بناء الشاشة ولا الإخوة
              _SmallCounter(),
              BuildCounter('أخ ثابت بجانبه'),
            ],
          ),

          // ------------------------------------------------------------
          // 3) select: راقب جزءاً من الحالة فقط
          // ------------------------------------------------------------
          const _Section(
            title: '3) Riverpod select — إعجاب لا يغيّر الاسم',
            children: [_ProfileWatchers()],
          ),

          // ------------------------------------------------------------
          // 4) RepaintBoundary: عزل ما يتحرك عن ما هو ثابت
          // ------------------------------------------------------------
          const _Section(
            title: '4) RepaintBoundary — كم مرة يُرسم الرسم الثقيل؟',
            children: [_RepaintDemo()],
          ),

          // ------------------------------------------------------------
          // أداة DevTools داخل التطبيق: تلوين كل ما يُعاد رسمه (debug فقط)
          // ------------------------------------------------------------
          SwitchListTile(
            title: const Text('🌈 debugRepaintRainbowEnabled'),
            subtitle: const Text(
              'كل منطقة يُعاد رسمها تتغير ألوان إطارها — مثل "Highlight repaints" في DevTools',
            ),
            value: _rainbow,
            onChanged: (v) => setState(() {
              _rainbow = v;
              debugRepaintRainbowEnabled = v;
            }),
          ),
        ],
      ),
    );
  }
}

class _SmallCounter extends StatefulWidget {
  const _SmallCounter();

  @override
  State<_SmallCounter> createState() => _SmallCounterState();
}

class _SmallCounterState extends State<_SmallCounter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const BuildCounter('ابن const'),
        FilledButton.tonal(
          onPressed: () => setState(() => _count++),
          child: Text('عدّاد محلي: $_count'),
        ),
      ],
    );
  }
}

class _ProfileWatchers extends StatelessWidget {
  const _ProfileWatchers();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        const _WatchAll(),
        const _WatchNameOnly(),
        Consumer(
          builder: (context, ref, _) => Wrap(
            spacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () => ref.read(profileProvider.notifier).like(),
                child: const Text('❤️ إعجاب'),
              ),
              OutlinedButton(
                onPressed: () =>
                    ref.read(profileProvider.notifier).rename('سارة أحمد'),
                child: const Text('تغيير الاسم'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ❌ يراقب الحالة كاملة: يُعاد بناؤه مع كل إعجاب
class _WatchAll extends ConsumerStatefulWidget {
  const _WatchAll();

  @override
  ConsumerState<_WatchAll> createState() => _WatchAllState();
}

class _WatchAllState extends ConsumerState<_WatchAll> {
  int _builds = 0;

  @override
  Widget build(BuildContext context) {
    _builds++;
    final profile = ref.watch(profileProvider);
    return Text('❌ watch(profileProvider): ${profile.name} '
        '(${profile.likes} ❤️) — بُني $_builds مرة');
  }
}

// ✅ يراقب الاسم فقط: الإعجاب لا يعيد بناءه
class _WatchNameOnly extends ConsumerStatefulWidget {
  const _WatchNameOnly();

  @override
  ConsumerState<_WatchNameOnly> createState() => _WatchNameOnlyState();
}

class _WatchNameOnlyState extends ConsumerState<_WatchNameOnly> {
  int _builds = 0;

  @override
  Widget build(BuildContext context) {
    _builds++;
    final name = ref.watch(profileProvider.select((p) => p.name));
    return Text('✅ select((p) => p.name): $name — بُني $_builds مرة');
  }
}

// ------------------------------------------------------------
// RepaintBoundary: مؤشر يدور بجانب رسم ثقيل
// بدون حدود: كل إطار للمؤشر يعيد رسم الرسم الثقيل أيضاً (~60 مرة/ثانية)
// مع RepaintBoundary: المؤشر في طبقة (layer) خاصة والرسم الثقيل لا يُلمس
// ------------------------------------------------------------
class _HeavyPainter extends CustomPainter {
  static int paints = 0;

  @override
  void paint(Canvas canvas, Size size) {
    paints++;
    final random = Random(1); // نفس النقاط في كل مرة
    final paint = Paint()..color = Colors.indigo.withValues(alpha: 0.25);
    for (var i = 0; i < 1500; i++) {
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width,
            random.nextDouble() * size.height),
        3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HeavyPainter oldDelegate) => false;
}

class _RepaintDemo extends StatefulWidget {
  const _RepaintDemo();

  @override
  State<_RepaintDemo> createState() => _RepaintDemoState();
}

class _RepaintDemoState extends State<_RepaintDemo> {
  bool _isolated = false;
  final _perSecond = ValueNotifier<int>(0);
  late final Timer _timer;
  int _lastPaints = 0;

  @override
  void initState() {
    super.initState();
    // كل ثانية نحسب كم مرة رُسم الرسم الثقيل
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _perSecond.value = _HeavyPainter.paints - _lastPaints;
      _lastPaints = _HeavyPainter.paints;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _perSecond.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const spinner = SizedBox.square(
      dimension: 40,
      child: CircularProgressIndicator(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 16,
          children: [
            // ✅ نعزل الجزء المتحرك في طبقة خاصة
            _isolated ? const RepaintBoundary(child: spinner) : spinner,
            Expanded(
              child: SizedBox(
                height: 80,
                child: CustomPaint(painter: _HeavyPainter()),
              ),
            ),
          ],
        ),
        ValueListenableBuilder<int>(
          valueListenable: _perSecond,
          builder: (context, value, _) =>
              Text('الرسم الثقيل يُرسم $value مرة في الثانية'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('RepaintBoundary حول المؤشر'),
          value: _isolated,
          onChanged: (v) => setState(() => _isolated = v),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            ...children,
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) قِس دائماً في وضع profile على جهاز حقيقي: flutter run --profile
//    وضع debug أبطأ بكثير ولا يعكس الأداء الحقيقي.
//
// 2) أضف هذه القاعدة إلى analysis_options.yaml (ليست مفعّلة في flutter_lints)
//    ثم نفّذ dart fix --apply ليضيف const تلقائياً في كل المشروع:
//      linter:
//        rules:
//          prefer_const_constructors: true
//
// 3) لطباعة كل Widget يُعاد بناؤه في الـ Console (debug فقط):
//      debugPrintRebuildDirtyWidgets = true;   // من package:flutter/widgets.dart
//
// 4) Consumer و ValueListenableBuilder و AnimatedBuilder تقبل child:
//    ضع الجزء الثابت في child فلا يُعاد بناؤه مع كل تغيير.
//
// 5) لا تضع RepaintBoundary في كل مكان: كل طبقة تستهلك ذاكرة.
//    ضعه حول ما يتحرك باستمرار (مؤشر، فيديو، رسوم متحركة) بجانب محتوى ثابت ثقيل.
