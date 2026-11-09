// ============================================================
// الدرس 5 (UI): الأنيميشن الضمني والصريح (Implicit / Explicit)
// في التطبيق: القائمة ← الدرس 5  ·  في العرض: شرائح الدرس 5
// ============================================================
//
// نوعان من الأنيميشن في Flutter:
//
// 1) Implicit (ضمني): تغيّر قيمة ← Flutter يحرّك من القديم إلى الجديد وحده
//    AnimatedContainer · AnimatedOpacity · AnimatedSwitcher · TweenAnimationBuilder
//    ✅ أسهل — استخدمه أولاً كلما كفى.
//
// 2) Explicit (صريح): نحن نتحكم بالزمن عبر AnimationController
//    forward · reverse · repeat · stop — ونربطه بـ Tween و Curve.
//    ✅ عند الحاجة لتكرار، أو تحكم يدوي، أو عدة حركات متتالية (Staggered).
//
// السلسلة: vsync (Ticker كل إطار) ← controller.value من 0 إلى 1
//          ← CurvedAnimation (منحنى) ← Tween (قيم حقيقية) ← Widget

import 'package:flutter/material.dart';

import '01_extension_methods.dart';

class AnimationsScreen extends StatelessWidget {
  const AnimationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 5: الأنيميشن')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Section('1) Implicit: AnimatedContainer', _ImplicitBox()),
          _Section('2) TweenAnimationBuilder + AnimatedSwitcher', _TweenDemo()),
          _Section('3) Explicit: AnimationController', _ExplicitDemo()),
          _Section(
            '4) Staggered: controller واحد و Intervals',
            _StaggeredDemo(),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// 1) Implicit: نغيّر القيم في setState فقط — والحركة تلقائية
// ------------------------------------------------------------
class _ImplicitBox extends StatefulWidget {
  const _ImplicitBox();

  @override
  State<_ImplicitBox> createState() => _ImplicitBoxState();
}

class _ImplicitBoxState extends State<_ImplicitBox> {
  bool _big = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors; // امتداد الدرس 1
    return GestureDetector(
      onTap: () => setState(() => _big = !_big),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutBack,
          width: _big ? 260 : 120,
          height: _big ? 140 : 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _big ? colors.primary : colors.tertiaryContainer,
            borderRadius: BorderRadius.circular(_big ? 32 : 12),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: _big ? 1 : 0.6,
            child: Text(
              _big ? 'اضغط للتصغير' : 'اضغط',
              style: TextStyle(
                color: _big ? colors.onPrimary : colors.onTertiaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// 2) TweenAnimationBuilder: أنيميشن لأي قيمة (رقم، لون...) بدون controller
//    AnimatedSwitcher: انتقال بين Widget قديم وجديد (يحتاج key مختلف)
// ------------------------------------------------------------
class _TweenDemo extends StatefulWidget {
  const _TweenDemo();

  @override
  State<_TweenDemo> createState() => _TweenDemoState();
}

class _TweenDemoState extends State<_TweenDemo> {
  double _target = 0.3;
  int _likes = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // كلما تغيّر end يتحرك من القيمة الحالية إلى الجديدة
        TweenAnimationBuilder<double>(
          tween: Tween(end: _target),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          builder: (context, value, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${(value * 100).round()}%',
                style: context.textTheme.headlineSmall,
              ),
              LinearProgressIndicator(value: value),
            ],
          ),
        ),
        Row(
          children: [
            TextButton(
              onPressed: () => setState(() => _target = 0.25),
              child: const Text('25%'),
            ),
            TextButton(
              onPressed: () => setState(() => _target = 0.9),
              child: const Text('90%'),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'إعجاب',
              icon: const Icon(Icons.favorite, color: Colors.pink),
              onPressed: () => setState(() => _likes++),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              // key مختلف ← AnimatedSwitcher يعرف أن الـ Widget تغيّر
              child: Text(
                '$_likes',
                key: ValueKey(_likes),
                style: context.textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// 3) Explicit: AnimationController + CurvedAnimation + Tween
// ------------------------------------------------------------
class _ExplicitDemo extends StatefulWidget {
  const _ExplicitDemo();

  @override
  State<_ExplicitDemo> createState() => _ExplicitDemoState();
}

// SingleTickerProviderStateMixin يعطينا vsync: نبضة مع كل إطار شاشة
// (وتتوقف تلقائياً عندما تكون الشاشة غير ظاهرة ← توفير بطارية)
class _ExplicitDemoState extends State<_ExplicitDemo>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  // المنحنى يغيّر "سرعة" التقدّم، والقيمة تبقى من 0 إلى 1
  late final _curved = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack, // يتجاوز 1 قليلاً ثم يرجع
    reverseCurve: Curves.easeIn,
  );

  // Tween: من 0.0 إلى 1.0 ← قيم حقيقية: زاوية الدوران ثم الحجم
  late final _turns = Tween(begin: 0.0, end: 1.0).animate(_curved);
  late final _scale = Tween(begin: 0.6, end: 1.2).animate(_curved);

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        context.showSnack('AnimationStatus.completed ✅');
      }
    });
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose(); // ⚠️ إلزامي: وإلا يبقى الـ Ticker يعمل (تسريب)
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // *Transition جاهزة: تعيد الرسم فقط بدون إعادة build للشجرة
            RotationTransition(
              turns: _turns,
              child: ScaleTransition(
                scale: _scale,
                child: Icon(
                  Icons.flutter_dash,
                  size: 72,
                  color: context.colors.primary,
                ),
              ),
            ),
            const SizedBox(width: 24),
            // AnimatedBuilder: لأي Widget — نعرض قيمة الـ controller مباشرة
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'controller.value = '
                      '${_controller.value.toStringAsFixed(2)}',
                    ),
                    Text('curved.value = ${_curved.value.toStringAsFixed(2)}'),
                    Text('status = ${_controller.status.name}'),
                  ],
                ),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.tonal(
              onPressed: () => _controller.forward(from: 0),
              child: const Text('forward'),
            ),
            FilledButton.tonal(
              onPressed: _controller.reverse,
              child: const Text('reverse'),
            ),
            FilledButton.tonal(
              onPressed: () => _controller.repeat(reverse: true),
              child: const Text('repeat'),
            ),
            FilledButton.tonal(
              onPressed: _controller.stop,
              child: const Text('stop'),
            ),
          ],
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// 4) Staggered: controller واحد، وكل عنصر يتحرك في جزء من الزمن (Interval)
// ------------------------------------------------------------
class _StaggeredDemo extends StatefulWidget {
  const _StaggeredDemo();

  @override
  State<_StaggeredDemo> createState() => _StaggeredDemoState();
}

class _StaggeredDemoState extends State<_StaggeredDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  static const _items = ['الطلب استُلم', 'قيد التجهيز', 'خرج للتوصيل'];

  // العنصر i يبدأ عند i*0.25 وينتهي عند i*0.25 + 0.5 من زمن الـ controller
  late final _anims = [
    for (var i = 0; i < _items.length; i++)
      CurvedAnimation(
        parent: _controller,
        curve: Interval(i * 0.25, i * 0.25 + 0.5, curve: Curves.easeOut),
      ),
  ];

  @override
  void dispose() {
    for (final a in _anims) {
      a.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _items.length; i++)
          _StaggerItem(animation: _anims[i], text: _items[i]),
        TextButton.icon(
          onPressed: () => _controller.forward(from: 0),
          icon: const Icon(Icons.replay),
          label: const Text('أعد التشغيل'),
        ),
      ],
    );
  }
}

class _StaggerItem extends StatelessWidget {
  const _StaggerItem({required this.animation, required this.text});
  final Animation<double> animation;
  final String text;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        // من اليسار قليلاً إلى مكانه (Offset بنسبة من حجم العنصر)
        position: Tween(
          begin: const Offset(-0.3, 0),
          end: Offset.zero,
        ).animate(animation),
        child: Card(
          child: ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(text),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.child);
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(title, style: context.textTheme.titleMedium),
          child,
        ],
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) لأكثر من AnimationController في نفس الـ State استخدم
//    TickerProviderStateMixin (بدون Single) — وإلا يظهر خطأ وقت التشغيل.
//
// 2) مرّر الجزء الثابت كـ child لـ AnimatedBuilder فلا يُعاد بناؤه كل إطار:
//      AnimatedBuilder(animation: c, child: const Logo(),
//        builder: (context, child) => Transform.rotate(angle: c.value * 6.3, child: child))
//
// 3) احترم إعداد "تقليل الحركة" في الجهاز:
//      if (MediaQuery.disableAnimationsOf(context)) { /* بدون أنيميشن أو مدة أقصر */ }
//
// 4) AnimatedSwitcher لا يحرّك شيئاً إذا بقي نفس النوع ونفس الـ key —
//    أعطِ الـ child مفتاحاً يتغيّر مع القيمة: ValueKey(count).
//
// 5) في widget test: tester.pump(const Duration(milliseconds: 300)) يقدّم الأنيميشن
//    إلى منتصفها لتتحقق من قيمة وسطية — بدون انتظار حقيقي.
