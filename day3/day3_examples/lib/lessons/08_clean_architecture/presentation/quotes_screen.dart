// ============================================================
// الدرس 8 (المعمارية): Clean Architecture + Repository + feature-first
// في التطبيق: القائمة ← الدرس 8  ·  في العرض: شرائح الدرس 8
// ============================================================
//
// ميزة حقيقية صغيرة «الاقتباسات» مقسّمة إلى 3 طبقات داخل مجلد الميزة نفسها:
//
//   lib/lessons/08_clean_architecture/        ← في مشروع حقيقي: lib/features/quotes/
//     domain/        Quote · QuotesRepository (واجهة) · Use cases     ← Dart خالص
//     data/          QuoteDto · Remote (Dio) · Local (Drift) · RepositoryImpl
//     presentation/  quotes_providers.dart (الربط) · quotes_screen.dart (هذا الملف)
//
// اتجاه الاعتماد (مَن يستورد مَن):
//   presentation ──► domain ◄── data
//   الـ domain لا يستورد شيئاً من الطبقتين، والطبقتان تعتمدان عليه.
//   لذلك نستطيع تبديل Dio أو Drift دون لمس الشاشة أو قواعد العمل.
//
// Repository (API + DB): الشاشة تقرأ من Drift دائماً، والتحديث يجلب من الـ API ويحفظ.
// جرّب: «تحديث» ← ⭐ على اقتباس ← «تحديث» مرة أخرى: المفضّلة لم تُمسح.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network.dart';
import '../domain/quote.dart';
import 'quotes_providers.dart';

class CleanArchitectureScreen extends ConsumerWidget {
  const CleanArchitectureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes = ref.watch(quotesProvider);
    final message = ref.watch(refreshMessageProvider);
    final offline = ref.watch(offlineModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدرس 8: Clean Architecture'),
        actions: [
          IconButton(
            tooltip: offline ? 'محاكاة: بدون اتصال' : 'متصل',
            icon: Icon(offline ? Icons.wifi_off : Icons.wifi),
            onPressed: () => ref.read(offlineModeProvider.notifier).toggle(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ref.read(refreshMessageProvider.notifier).refresh(),
        icon: const Icon(Icons.sync),
        label: const Text('تحديث'),
      ),
      body: Column(
        children: [
          const _LayersStrip(),
          if (message != null)
            Padding(padding: const EdgeInsets.all(8), child: Text(message)),
          Expanded(
            child: switch (quotes) {
              AsyncData(:final value) when value.isEmpty => const Center(
                  child: Text('لا توجد بيانات محلية بعد — اضغط «تحديث»'),
                ),
              AsyncData(:final value) => ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: [for (final q in value) _QuoteTile(quote: q)],
                ),
              AsyncError(:final error) => Center(child: Text('❌ $error')),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
        ],
      ),
    );
  }
}

class _QuoteTile extends ConsumerWidget {
  const _QuoteTile({required this.quote});
  final Quote quote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(quote.text, textDirection: TextDirection.ltr),
      subtitle: Text('— ${quote.author}', textDirection: TextDirection.ltr),
      trailing: IconButton(
        icon: Icon(quote.isFavorite ? Icons.star : Icons.star_border,
            color: quote.isFavorite ? Colors.amber : null),
        // الشاشة تستدعي use case — لا تعرف Drift ولا Dio
        onPressed: () => ref.read(toggleFavoriteProvider)(quote.id),
      ),
    );
  }
}

class _LayersStrip extends StatelessWidget {
  const _LayersStrip();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget box(String title, String sub, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(sub, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        spacing: 4,
        children: [
          // Row في RTL: الأول على اليمين ← الأسهم كلها تشير إلى domain
          box('presentation', 'Screen · Providers', colors.primaryContainer),
          const Text('←'),
          box('domain', 'Quote · Repository · Use cases', colors.tertiaryContainer),
          const Text('→'),
          box('data', 'Dio · Drift · RepositoryImpl', colors.secondaryContainer),
        ],
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) feature-first: كل ما يخص الميزة في مجلدها (lib/features/quotes/…)،
//    فحذف ميزة = حذف مجلد، وفريقان يعملان على ميزتين بدون تعارض.
//    وما يُشارك بين الميزات فقط يذهب إلى lib/core/ أو lib/shared/.
//
// 2) Use cases ليست إجبارية: إذا كان الـ use case سطراً واحداً يمرّر للـ Repository
//    فلا بأس أن تستدعي الشاشة الـ Repository مباشرة. أضفه عندما توجد قاعدة عمل.
//
// 3) اختبر الطبقات منفصلة: الـ Repository مع Remote وهمي + Drift في الذاكرة
//    (test/quotes_repository_test.dart) — بدون شبكة وبدون Widgets.
//
// 4) لا تمرّر DTO أو صف Drift إلى الشاشة: حوّله إلى Entity في طبقة data،
//    فإذا تغيّر الـ API أو الجدول لا تتغير الشاشة.
//
// 5) قاعدة سريعة للمراجعة: افتح أي ملف في domain/ — إذا وجدت import لـ
//    flutter أو dio أو drift فهذه مخالفة لاتجاه الاعتماد.
