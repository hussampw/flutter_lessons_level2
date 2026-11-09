// ============================================================
// الدرس 3 (الأداء): القوائم الطويلة وتحسين الصور
// في التطبيق: القائمة ← الدرس 3  ·  في العرض: شرائح الدرس 3
// ============================================================
//
// القوائم:
//   ❌ ListView(children: [...10000 عنصر])  ← ينشئ كل الـ Widgets مقدّماً
//   ✅ ListView.builder ← ينشئ فقط ما يظهر على الشاشة (+ هامش صغير)
//   ✅ itemExtent / prototypeItem ← ارتفاع ثابت = لا حاجة لقياس كل عنصر،
//      والقفز إلى العنصر 9000 يصبح فورياً
//
// الصور:
//   حجم الملف ≠ حجم الذاكرة! صورة JPG حجمها 240KB بأبعاد 4000×3000
//   تُفك في الذاكرة إلى 4000 × 3000 × 4 بايت = 48MB.
//   ✅ cacheWidth / cacheHeight ← نفك الصورة بالحجم المعروض فقط
//   ✅ precacheImage ← نحمّل الصورة مسبقاً فتظهر فوراً في الشاشة التالية

import 'package:flutter/material.dart';

const _photo = AssetImage('assets/images/big_photo.jpg');
const _itemCount = 10000;
const _rowHeight = 64.0;

class ListsImagesScreen extends StatelessWidget {
  const ListsImagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الدرس 3: القوائم الطويلة والصور'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.list), text: 'القوائم'),
              Tab(icon: Icon(Icons.image), text: 'الصور'),
            ],
          ),
        ),
        body: const TabBarView(children: [_ListsTab(), _ImagesTab()]),
      ),
    );
  }
}

// ============================================================
// القوائم الطويلة
// ============================================================
class _ListsTab extends StatefulWidget {
  const _ListsTab();

  @override
  State<_ListsTab> createState() => _ListsTabState();
}

class _ListsTabState extends State<_ListsTab> {
  bool _useBuilder = true;
  bool _fixedExtent = true;
  int _created = 0; // كم Widget أنشأنا حتى الآن
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _row(int i) {
    _created++;
    return ListTile(
      leading: CircleAvatar(child: Text('${i % 100}')),
      title: Text('طلب رقم $i'),
      subtitle: Text('المبلغ: ${(i * 3.5).toStringAsFixed(1)} ر.س'),
    );
  }

  Widget _buildList() {
    if (!_useBuilder) {
      // ❌ كل الـ 10000 عنصر تُنشأ الآن، حتى لو لم يرها المستخدم أبداً
      return ListView(
        controller: _controller,
        children: List.generate(_itemCount, _row),
      );
    }
    // ✅ itemBuilder يُستدعى فقط للعناصر الظاهرة
    return ListView.builder(
      controller: _controller,
      itemCount: _itemCount,
      // ✅ ارتفاع ثابت: Flutter يحسب موضع أي عنصر بدون بنائه
      itemExtent: _fixedExtent ? _rowHeight : null,
      itemBuilder: (context, i) => _row(i),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _buildList(); // نبني القائمة أولاً ليظهر العدد الصحيح
    return Column(
      children: [
        SwitchListTile(
          title: Text(_useBuilder
              ? '✅ ListView.builder (كسول)'
              : '❌ ListView(children: ...)'),
          value: _useBuilder,
          onChanged: (v) => setState(() {
            _useBuilder = v;
            _created = 0;
          }),
        ),
        SwitchListTile(
          title: Text('itemExtent: ${_fixedExtent ? '$_rowHeight' : 'null'}'),
          value: _fixedExtent,
          onChanged: _useBuilder
              ? (v) => setState(() => _fixedExtent = v)
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Widgets أُنشئت: $_created من $_itemCount',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton(
                // مع itemExtent: الموضع = الرقم × الارتفاع، بدون قياس
                onPressed: () => _controller.jumpTo(9000 * _rowHeight),
                child: const Text('اقفز إلى 9000'),
              ),
              TextButton(
                onPressed: () => setState(() {}),
                child: const Text('تحديث العدد'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: list),
      ],
    );
  }
}

// ============================================================
// تحسين الصور
// ============================================================
class _ImagesTab extends StatefulWidget {
  const _ImagesTab();

  @override
  State<_ImagesTab> createState() => _ImagesTabState();
}

class _ImagesTabState extends State<_ImagesTab> {
  bool _resize = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ precacheImage: نفك الصورة الآن، فتظهر فوراً عند فتح التفاصيل
    // (didChangeDependencies وليس initState لأنها تحتاج context كاملاً)
    precacheImage(_photo, context);
  }

  @override
  Widget build(BuildContext context) {
    // نحوّل العرض المنطقي إلى بكسلات حقيقية حسب كثافة الشاشة
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (300 * dpr).round();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SwitchListTile(
          title: Text(_resize
              ? '✅ cacheWidth: $cacheWidth (عرض 300 × كثافة الشاشة)'
              : '❌ بدون cacheWidth (الصورة كاملة 4000×3000)'),
          value: _resize,
          onChanged: (v) => setState(() => _resize = v),
        ),
        Center(
          child: Image.asset(
            'assets/images/big_photo.jpg',
            width: 300,
            // cacheWidth: Flutter يفك الصورة بهذا العرض بدل 4000 بكسل
            cacheWidth: _resize ? cacheWidth : null,
          ),
        ),
        const SizedBox(height: 8),
        // نفس ما يفعله Image.asset داخلياً: cacheWidth = ResizeImage
        _DecodedSize(
          provider: ResizeImage.resizeIfNeeded(
            _resize ? cacheWidth : null,
            null,
            _photo,
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.flash_on),
          title: const Text('افتح التفاصيل (الصورة محمّلة مسبقاً)'),
          subtitle: const Text('precacheImage في didChangeDependencies'),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const _PhotoDetails()),
          ),
        ),
        const Divider(),
        // صورة من الشبكة: دائماً loadingBuilder + errorBuilder
        Image.network(
          'https://dummyjson.com/image/600x300',
          height: 150,
          cacheWidth: cacheWidth,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const Center(child: CircularProgressIndicator()),
          errorBuilder: (context, error, stack) => const ListTile(
            leading: Icon(Icons.wifi_off),
            title: Text('تعذّر تحميل الصورة — تحقّق من الاتصال بالإنترنت'),
          ),
        ),
      ],
    );
  }
}

// يعرض أبعاد الصورة بعد فكّها والذاكرة التي تستهلكها
class _DecodedSize extends StatefulWidget {
  const _DecodedSize({required this.provider});

  final ImageProvider provider;

  @override
  State<_DecodedSize> createState() => _DecodedSizeState();
}

class _DecodedSizeState extends State<_DecodedSize> {
  ImageStream? _stream;
  late final _listener = ImageStreamListener((info, _) {
    if (mounted) setState(() => _size = (info.image.width, info.image.height));
  });
  (int, int)? _size;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_DecodedSize oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider != widget.provider) _resolve();
  }

  void _resolve() {
    _stream?.removeListener(_listener);
    _stream = widget.provider.resolve(createLocalImageConfiguration(context))
      ..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = _size;
    if (size == null) return const Text('جاري فك الصورة...');
    final (w, h) = size;
    final mb = w * h * 4 / (1024 * 1024); // 4 بايت لكل بكسل (RGBA)
    return Text(
      'في الذاكرة: $w×$h بكسل ≈ ${mb.toStringAsFixed(1)} MB',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: mb > 10 ? Colors.red : Colors.green,
      ),
    );
  }
}

class _PhotoDetails extends StatelessWidget {
  const _PhotoDetails();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 3: صورة محمّلة مسبقاً')),
      // نفس الـ provider المحمّل مسبقاً ← يُقرأ من ImageCache فوراً
      body: const Center(child: Image(image: _photo)),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) عناصر القائمة بارتفاعات متغيرة لكن متشابهة؟ استخدم prototypeItem
//    بدل itemExtent: Flutter يقيس عنصراً نموذجياً واحداً فقط:
//      ListView.builder(prototypeItem: const ListTile(title: Text('x')), ...)
//
// 2) قائمة مع أقسام وعناوين؟ CustomScrollView + SliverList.builder
//    + SliverFixedExtentList بدل ListView داخل Column (يبني الكل!).
//
// 3) لا تستخدم shrinkWrap: true مع قائمة طويلة: يلغي الكسل ويبني كل العناصر
//    ليعرف الارتفاع. إن احتجت قائمة داخل قائمة فاستخدم Slivers.
//
// 4) ImageCache له حد افتراضي 100MB. لرؤية الصور الضخمة أثناء التطوير:
//      debugInvertOversizedImages = true;   // يقلب ألوان أي صورة أكبر من حجم عرضها
//
// 5) للصور من الشبكة في تطبيق حقيقي: ضع cacheWidth دائماً، واطلب من الخادم
//    حجماً مناسباً (thumbnail) بدل الصورة الأصلية.
