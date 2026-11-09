// ============================================================
// الدرس 7 (UI): CustomPainter — نرسم بأنفسنا على Canvas
// في التطبيق: القائمة ← الدرس 7  ·  في العرض: شرائح الدرس 7
// ============================================================
//
// عندما لا يوجد Widget جاهز (حلقة تقدّم، رسم بياني، توقيع، موجة...)
// نرسم مباشرة: CustomPaint(painter: MyPainter(...))
//
// الـ CustomPainter فيه دالتان:
//   paint(canvas, size)   ← أوامر الرسم: drawArc · drawRect · drawPath · TextPainter
//   shouldRepaint(old)    ← هل تغيّرت البيانات؟ false = لا تُعِد الرسم (أداء)
//
// ثلاثة أمثلة:
//   1) ProgressRingPainter  ← حلقة تقدّم + shouldRepaint يقارن الحقول
//   2) BarChartPainter      ← رسم بياني + نصوص بـ TextPainter
//   3) WavePainter          ← super(repaint: animation): يعيد الرسم بدون build

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '01_extension_methods.dart';

// ------------------------------------------------------------
// 1) حلقة التقدّم
// ------------------------------------------------------------
class ProgressRingPainter extends CustomPainter {
  ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress; // من 0 إلى 1
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // المسار الخلفي: دائرة كاملة
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);

    // القوس: يبدأ من الأعلى (-90°) ويمتد بنسبة progress من 360°
    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  // نعيد الرسم فقط إذا تغيّرت قيمة تؤثر على الشكل
  @override
  bool shouldRepaint(ProgressRingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor;
}

// ------------------------------------------------------------
// 2) رسم بياني بالأعمدة + نصوص
// ------------------------------------------------------------
class BarChartPainter extends CustomPainter {
  BarChartPainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.textColor,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    const labelHeight = 22.0;
    final maxValue = values.reduce(math.max);
    final slot = size.width / values.length;
    final chartHeight = size.height - labelHeight;
    final bar = Paint()..color = color;

    for (var i = 0; i < values.length; i++) {
      final h = chartHeight * values[i] / maxValue;
      final rect = Rect.fromLTWH(
        i * slot + slot * 0.2,
        chartHeight - h,
        slot * 0.6,
        h,
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        bar,
      );

      // النص على Canvas: TextPainter ← layout ← paint
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(color: textColor, fontSize: 12),
        ),
        textDirection: TextDirection.rtl,
      )..layout(maxWidth: slot);
      tp.paint(
        canvas,
        Offset(i * slot + (slot - tp.width) / 2, chartHeight + 4),
      );
      tp.dispose();
    }
  }

  // listEquals: مقارنة محتوى القائمتين وليس المرجع
  @override
  bool shouldRepaint(BarChartPainter old) =>
      !listEquals(old.values, values) ||
      !listEquals(old.labels, labels) ||
      old.color != color ||
      old.textColor != textColor;
}

// ------------------------------------------------------------
// 3) موجة متحركة: repaint يربط الرسم بالأنيميشن مباشرة
//    كل إطار ← paint() فقط، بدون build() للشجرة (أسرع)
// ------------------------------------------------------------
class WavePainter extends CustomPainter {
  WavePainter({required this.animation, required this.color})
    : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = animation.value * 2 * math.pi;
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x <= size.width; x += 4) {
      final y =
          size.height / 2 +
          math.sin(x / size.width * 4 * math.pi + phase) * size.height / 4;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(WavePainter old) => old.color != color;
}

// ============================================================
// الشاشة
// ============================================================
class CustomPainterScreen extends StatefulWidget {
  const CustomPainterScreen({super.key});

  @override
  State<CustomPainterScreen> createState() => _CustomPainterScreenState();
}

class _CustomPainterScreenState extends State<CustomPainterScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.65;
  var _sales = [12.0, 18.0, 9.0, 22.0, 15.0];
  static const _days = ['سبت', 'أحد', 'اثنين', 'ثلاثاء', 'أربعاء'];

  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 7: CustomPainter')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('1) حلقة التقدّم', style: context.textTheme.titleMedium),
          Center(
            child: SizedBox.square(
              dimension: 180,
              // TweenAnimationBuilder (الدرس 5) يحرّك الحلقة عند تغيّر القيمة
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: _progress),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) => CustomPaint(
                  painter: ProgressRingPainter(
                    progress: value,
                    color: colors.primary,
                    trackColor: colors.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: Text(
                      '${(value * 100).round()}%',
                      style: context.textTheme.headlineMedium,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Slider(
            value: _progress,
            onChanged: (v) => setState(() => _progress = v),
          ),
          const SizedBox(height: 16),
          Text(
            '2) رسم بياني (TextPainter للنصوص)',
            style: context.textTheme.titleMedium,
          ),
          SizedBox(
            height: 180,
            // RepaintBoundary: يعزل الرسم في طبقة خاصة — لا يُعاد رسمه
            // عندما يتحرك شيء آخر في الشاشة (مثل الموجة بالأسفل)
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: BarChartPainter(
                  values: _sales,
                  labels: _days,
                  color: colors.tertiary,
                  textColor: colors.onSurface,
                ),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(
              () => _sales = [
                for (final v in _sales) (v * 0.6 + math.Random().nextInt(15)),
              ],
            ),
            icon: const Icon(Icons.shuffle),
            label: const Text('بيانات جديدة'),
          ),
          const SizedBox(height: 16),
          Text(
            '3) موجة: super(repaint: animation)',
            style: context.textTheme.titleMedium,
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 100,
              child: CustomPaint(
                size: Size.infinite,
                painter: WavePainter(
                  animation: _wave,
                  color: colors.primary.withValues(alpha: .5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) لا تنشئ Paint أو Path ثابتة داخل paint() في كل إطار إن أمكن —
//    واجعل shouldRepaint دقيقاً: return true دائماً = رسم مع كل build.
//
// 2) CustomPaint بدون child وبدون size حجمه صفر ← لا يظهر شيء!
//    أعطه size: Size.infinite داخل SizedBox، أو child يحدد الحجم.
//
// 3) لمعرفة أي جزء يُعاد رسمه: فعّل Highlight repaints في Flutter DevTools
//    أو في الكود: debugRepaintRainbowEnabled = true (من rendering.dart).
//
// 4) foregroundPainter يرسم فوق الـ child و painter تحته:
//      CustomPaint(painter: Grid(), foregroundPainter: Highlight(), child: ...)
//
// 5) لاختبار الرسم: matchesGoldenFile('ring.png') في widget test
//    يقارن صورة الـ Widget بصورة محفوظة (flutter test --update-goldens لإنشائها).
