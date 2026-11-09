// ============================================================
// الدرس 2 (Testing): Unit tests و mocktail
// في التطبيق: القائمة ← الدرس 2  ·  في العرض: شرائح الدرس 2
// ============================================================
//
// Unit test = نختبر "وحدة" صغيرة (دالة أو class) بدون شاشة وبدون شبكة.
// هو أسرع نوع اختبار (ميلي ثانية) لذلك نكتب منه أكثر عدد.
//
// في هذا الملف كود حقيقي نختبره:
//   - Cart: منطق سلة مشتريات immutable (إضافة، حذف، كوبون، المجموع)
//     ← test/02_cart_test.dart
//   - ProductRepository: يحوّل JSON من الـ API إلى Models ويخزّن كاش
//     ← test/02_product_repository_test.dart (نستبدل الـ API بـ Mock عبر mocktail)
//
// التشغيل:  flutter test test/02_cart_test.dart
//           flutter test            ← كل الاختبارات
//
// 💡 الشاشة تعرض السلة نفسها لتجربها بيدك، وتعرض قائمة الاختبارات المكتوبة لها.

import 'package:flutter/material.dart';

import '01_extension_methods.dart';

// ------------------------------------------------------------
// 1) Model بسيط
// ------------------------------------------------------------
class Product {
  const Product({required this.sku, required this.name, required this.price});

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    sku: json['sku'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
  );

  final String sku;
  final String name;
  final double price;
}

// ------------------------------------------------------------
// 2) منطق السلة: immutable ← كل عملية تعيد Cart جديدة
//    (سهل الاختبار، ومناسب لحالة Riverpod في الدرس 3)
// ------------------------------------------------------------
class Cart {
  const Cart({this.lines = const {}, this.coupon});

  // sku ← (المنتج، الكمية)
  final Map<String, (Product, int)> lines;
  final String? coupon;

  static const coupons = {'SAVE10': 0.10, 'VIP25': 0.25};

  Cart add(Product p) {
    final qty = (lines[p.sku]?.$2 ?? 0) + 1;
    return Cart(lines: {...lines, p.sku: (p, qty)}, coupon: coupon);
  }

  Cart remove(String sku) {
    final line = lines[sku];
    if (line == null) return this;
    final next = {...lines}..remove(sku);
    if (line.$2 > 1) next[sku] = (line.$1, line.$2 - 1);
    return Cart(lines: next, coupon: coupon);
  }

  // كوبون غير معروف ← نرمي خطأ واضح (والاختبار يتأكد من ذلك)
  Cart applyCoupon(String code) {
    final c = code.trim().toUpperCase();
    if (!coupons.containsKey(c)) throw ArgumentError.value(code, 'coupon');
    return Cart(lines: lines, coupon: c);
  }

  int get count => lines.values.fold(0, (sum, l) => sum + l.$2);
  double get subtotal =>
      lines.values.fold(0.0, (sum, l) => sum + l.$1.price * l.$2);
  double get discount => subtotal * (coupons[coupon] ?? 0);
  double get total => subtotal - discount;
}

// ------------------------------------------------------------
// 3) طبقة الـ API (في تطبيق حقيقي: Dio) — واجهة حتى نستطيع استبدالها
// ------------------------------------------------------------
abstract interface class ProductApi {
  Future<List<Map<String, dynamic>>> fetchProducts();
}

// تنفيذ محلي يحاكي الشبكة (بدون إنترنت) — يستخدمه التطبيق في الدرسين 2 و 3
class LocalProductApi implements ProductApi {
  const LocalProductApi({this.offline = false});
  final bool offline;

  @override
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    await Future.delayed(800.ms); // امتداد DurationX من الدرس 1
    if (offline) throw Exception('لا يوجد اتصال بالإنترنت');
    return [
      {'sku': 'kb', 'name': 'لوحة مفاتيح', 'price': 120},
      {'sku': 'ms', 'name': 'فأرة لاسلكية', 'price': 45.5},
      {'sku': 'hd', 'name': 'سماعة رأس', 'price': 210},
    ];
  }
}

class ProductsException implements Exception {
  const ProductsException(this.message);
  final String message;
  @override
  String toString() => message;
}

// ------------------------------------------------------------
// 4) Repository: يحوّل JSON إلى Models + كاش في الذاكرة + خطأ موحّد
//    الاعتمادية (ProductApi) تصل عبر الـ constructor ← نمرّر Mock في الاختبار
// ------------------------------------------------------------
class ProductRepository {
  ProductRepository(this._api);
  final ProductApi _api;
  List<Product>? _cache;

  Future<List<Product>> getProducts({bool refresh = false}) async {
    if (!refresh && _cache != null) return _cache!; // لا طلب ثانٍ
    try {
      final json = await _api.fetchProducts();
      return _cache = json.map(Product.fromJson).toList();
    } on Exception {
      throw const ProductsException('تعذّر تحميل المنتجات');
    }
  }
}

// ============================================================
// الشاشة: جرّب السلة بيدك + قائمة الاختبارات المكتوبة لها
// ============================================================
const _demoProducts = [
  Product(sku: 'kb', name: 'لوحة مفاتيح', price: 120),
  Product(sku: 'ms', name: 'فأرة لاسلكية', price: 45.5),
];

class UnitTestsScreen extends StatefulWidget {
  const UnitTestsScreen({super.key});

  @override
  State<UnitTestsScreen> createState() => _UnitTestsScreenState();
}

class _UnitTestsScreenState extends State<UnitTestsScreen> {
  var _cart = const Cart();
  final _coupon = TextEditingController();

  @override
  void dispose() {
    _coupon.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    try {
      setState(() => _cart = _cart.applyCoupon(_coupon.text));
      context.showSnack('تم تطبيق الكوبون ${_cart.coupon}');
    } on ArgumentError {
      context.showSnack('كوبون غير معروف — جرّب SAVE10', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 2: Unit tests و mocktail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'جرّب السلة (نفس الكود الذي نختبره)',
            style: context.textTheme.titleMedium,
          ),
          for (final p in _demoProducts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(p.name),
              subtitle: Text(
                '${p.price} ر.س · في السلة: '
                '${_cart.lines[p.sku]?.$2 ?? 0}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'حذف واحدة',
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () =>
                        setState(() => _cart = _cart.remove(p.sku)),
                  ),
                  IconButton(
                    tooltip: 'إضافة',
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(() => _cart = _cart.add(p)),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _coupon,
                  decoration: const InputDecoration(
                    labelText: 'كوبون (SAVE10 أو VIP25)',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(onPressed: _applyCoupon, child: const Text('تطبيق')),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'العدد: ${_cart.count} · المجموع: ${_cart.subtotal} · '
            'الخصم: ${_cart.discount.toStringAsFixed(2)} · '
            'الإجمالي: ${_cart.total.toStringAsFixed(2)} ر.س',
            style: context.textTheme.titleSmall,
          ),
          const Divider(height: 32),
          const _TestsCard(
            title: 'test/02_cart_test.dart — منطق خالص',
            command: 'flutter test test/02_cart_test.dart',
            cases: [
              'سلة جديدة فارغة: count = 0 و total = 0',
              'add نفس المنتج مرتين ← الكمية 2 والمجموع صحيح',
              'remove ينقص الكمية ثم يحذف السطر',
              'SAVE10 يخصم 10% (closeTo للأرقام العشرية)',
              'كوبون غير معروف ← throwsArgumentError',
              'Cart immutable: add لا يغيّر السلة القديمة',
            ],
          ),
          const _TestsCard(
            title: 'test/02_product_repository_test.dart — mocktail',
            command: 'flutter test test/02_product_repository_test.dart',
            cases: [
              'when(() => api.fetchProducts()).thenAnswer(...) ← JSON إلى Product',
              'الكاش: نداءان ← verify(...).called(1)',
              'refresh: true ← طلب جديد',
              'thenThrow(Exception()) ← ProductsException موحّد',
            ],
          ),
        ],
      ),
    );
  }
}

// بطاقة: ما الذي نختبره + أمر التشغيل
class _TestsCard extends StatelessWidget {
  const _TestsCard({
    required this.title,
    required this.command,
    required this.cases,
  });

  final String title;
  final String command;
  final List<String> cases;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(title, style: context.textTheme.titleSmall),
            for (final c in cases) Text('✅ $c'),
            SelectableText(
              command,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: 'monospace',
                color: context.colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) شغّل اختباراً واحداً بالاسم بدل الملف كله:
//      flutter test --plain-name 'SAVE10'
//
// 2) الأرقام العشرية: لا تقارن double بـ == بل بـ closeTo:
//      expect(cart.total, closeTo(148.95, 0.001));
//
// 3) mocktail: الدوال التي تأخذ باراميتر من نوع خاص مع any() تحتاج
//    registerFallbackValue(FakeProduct()) داخل setUpAll — وإلا يظهر خطأ واضح.
//
// 4) قاعدة AAA لكل اختبار: Arrange (جهّز) ← Act (نفّذ) ← Assert (تحقّق)
//    واختبار واحد = سلوك واحد، واسمه جملة تصف السلوك.
//
// 5) Fake أم Mock؟ Fake = تنفيذ بسيط حقيقي (FakeWeatherRepository في اليوم الأول)،
//    Mock = نتحكم بالرد ونتحقق من النداءات (verify). استخدم Mock عندما يهمّك "كم مرة نُودي".
