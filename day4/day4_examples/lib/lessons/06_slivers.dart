// ============================================================
// الدرس 6 (UI): Slivers — CustomScrollView و SliverAppBar
// في التطبيق: القائمة ← الدرس 6  ·  في العرض: شرائح الدرس 6
// ============================================================
//
// Sliver = جزء من منطقة تمرير واحدة. ListView و GridView في الحقيقة
// sliver واحد داخل CustomScrollView. عندما نحتاج أكثر من نوع في نفس
// التمرير (رأس يتقلّص + شبكة + قائمة + رأس مثبّت) نكتبها كـ slivers.
//
// نموذج التمرير: الـ CustomScrollView يعطي كل sliver "كم تمرّر حتى الآن"
// (scrollOffset)، والـ sliver يقرّر كم يأخذ من الشاشة (paintExtent).
// SliverAppBar مثلاً: يبدأ بـ expandedHeight ويتقلّص حتى toolbarHeight.
//
// قاعدة: داخل CustomScrollView ← slivers فقط.
// Widget عادي؟ لفّه بـ SliverToBoxAdapter.

import 'package:flutter/material.dart';

import '01_extension_methods.dart';

class SliversScreen extends StatefulWidget {
  const SliversScreen({super.key});

  @override
  State<SliversScreen> createState() => _SliversScreenState();
}

class _SliversScreenState extends State<SliversScreen> {
  // نعرض قيمة التمرير الحالية لنرى نموذج الـ slivers وهو يعمل
  final _scroll = ScrollController();
  final _offset = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => _offset.value = _scroll.offset);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          // ------------------------------------------------------------
          // 1) SliverAppBar: يتقلّص من 220 إلى ارتفاع الـ toolbar
          //    pinned: يبقى ظاهراً · floating: يظهر مع أول سحب للأسفل
          // ------------------------------------------------------------
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 220,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('الدرس 6: Slivers'),
              background: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [colors.primary, colors.primaryContainer],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.storefront,
                    size: 96,
                    color: colors.onPrimary.withValues(alpha: .4),
                  ),
                ),
              ),
            ),
          ),

          // ------------------------------------------------------------
          // 2) SliverToBoxAdapter: أي Widget عادي داخل التمرير
          // ------------------------------------------------------------
          SliverToBoxAdapter(
            child: ValueListenableBuilder(
              valueListenable: _offset,
              builder: (context, offset, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'scrollOffset = ${offset.toStringAsFixed(0)} — '
                  'اسحب للأعلى وراقب تقلّص الـ SliverAppBar',
                ),
              ),
            ),
          ),

          // ------------------------------------------------------------
          // 3) رأس مثبّت (pinned) مخصّص: SliverPersistentHeader + delegate
          // ------------------------------------------------------------
          const SliverPersistentHeader(
            pinned: true,
            delegate: _SectionHeader('الأقسام'),
          ),

          // ------------------------------------------------------------
          // 4) SliverGrid: شبكة — عدد الأعمدة حسب العرض (maxCrossAxisExtent)
          // ------------------------------------------------------------
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, i) => Card(
                color: colors.secondaryContainer,
                child: Center(child: Text(_categories[i])),
              ),
            ),
          ),

          const SliverPersistentHeader(
            pinned: true,
            delegate: _SectionHeader('المنتجات'),
          ),

          // ------------------------------------------------------------
          // 5) SliverList.builder: كسول — يبني العناصر الظاهرة فقط
          // ------------------------------------------------------------
          SliverList.builder(
            itemCount: 30,
            itemBuilder: (context, i) => ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text('منتج رقم ${i + 1}'),
              subtitle: Text('${(i + 1) * 15} ر.س'),
            ),
          ),

          // 6) SliverFillRemaining: يملأ ما تبقى من الشاشة (تذييل)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('— نهاية القائمة —')),
            ),
          ),
        ],
      ),
    );
  }
}

const _categories = ['إلكترونيات', 'كتب', 'ملابس', 'رياضة', 'منزل', 'ألعاب'];

// ------------------------------------------------------------
// delegate الرأس المثبّت: يحدد أقصى وأدنى ارتفاع، ويُرسم حسب shrinkOffset
// ------------------------------------------------------------
class _SectionHeader extends SliverPersistentHeaderDelegate {
  const _SectionHeader(this.title);
  final String title;

  @override
  double get maxExtent => 56;
  @override
  double get minExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: context.colors.surfaceContainerHighest,
      // overlapsContent = true عندما يكون فوق المحتوى ← نضيف ظلاً
      elevation: overlapsContent || shrinkOffset > 0 ? 2 : 0,
      child: Container(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsetsDirectional.only(start: 16),
        child: Text(title, style: context.textTheme.titleMedium),
      ),
    );
  }

  // يعاد البناء فقط عندما يتغيّر العنوان
  @override
  bool shouldRebuild(_SectionHeader oldDelegate) => oldDelegate.title != title;
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) رؤوس مثبّتة بدون delegate (Flutter 3.24+):
//      PinnedHeaderSliver(child: Text('عنوان'))
//    و SliverFloatingHeader يختفي عند التمرير للأسفل ويظهر عند الرجوع.
//
// 2) قسم له رأس مثبّت خاص به فقط (يُدفع عند انتهاء القسم):
//      SliverMainAxisGroup(slivers: [PinnedHeaderSliver(...), SliverList(...)])
//
// 3) لا تضع ListView داخل SliverToBoxAdapter (shrinkWrap) — تفقد الكسل
//    وتبني كل العناصر مرة واحدة. استخدم SliverList.builder مباشرة.
//
// 4) SliverAppBar مع floating: true و snap: true ← يظهر كاملاً مع أول سحب للأسفل.
//
// 5) تريد سحب للتحديث؟ لفّ CustomScrollView بـ RefreshIndicator كأي قائمة.
