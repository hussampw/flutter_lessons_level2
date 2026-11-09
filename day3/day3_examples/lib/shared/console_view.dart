// ============================================================
// أداة مشتركة: «الكونسول» داخل الشاشة
// تستخدمها الدروس 1 و 2 و 5 و 6 لعرض نتائج الأمثلة بدل print
// (نفس فكرة كونسول الدرس 1 في اليوم الأول)
// ============================================================

import 'package:flutter/material.dart';

class ConsoleView extends StatelessWidget {
  const ConsoleView({super.key, required this.lines, this.busy = false});

  final List<String> lines;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        children: [
          if (lines.isEmpty)
            const Text(
              'اضغط زراً لتشغيل مثال…',
              style: TextStyle(color: Color(0xFF7F95AB), fontSize: 15),
            ),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                line,
                style: const TextStyle(
                  color: Color(0xFFB8F5C8),
                  fontFamily: 'monospace',
                  fontSize: 15,
                ),
              ),
            ),
          if (busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}

/// صف أزرار الأمثلة: (العنوان، الدالة)
class DemoButtons extends StatelessWidget {
  const DemoButtons({super.key, required this.demos, required this.onRun, this.busy = false});

  final List<(String, Future<void> Function())> demos;
  final void Function(String label, Future<void> Function() demo) onRun;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (label, demo) in demos)
            FilledButton.tonal(
              onPressed: busy ? null : () => onRun(label, demo),
              child: Text(label),
            ),
        ],
      ),
    );
  }
}
