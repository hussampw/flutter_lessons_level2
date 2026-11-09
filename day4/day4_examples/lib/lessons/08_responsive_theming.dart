// ============================================================
// الدرس 8 (UI): التصميم المتجاوب والثيمات (فاتح / داكن)
// في التطبيق: القائمة ← الدرس 8  ·  في العرض: شرائح الدرس 8
// ============================================================
//
// الجزء الأول — Theming:
//   ThemeData + ColorScheme.fromSeed ← لون واحد يولّد كل ألوان Material 3
//   theme / darkTheme / themeMode في MaterialApp (انظر main.dart)
//   ThemeExtension ← ألوان خاصة بتطبيقنا (success / warning) تتغيّر مع الثيم
//   themeSettingsProvider ← المستخدم يغيّر الثيم واللون للتطبيق كله
//
// الجزء الثاني — Responsive:
//   LayoutBuilder ← المساحة المتاحة لهذا الـ Widget (constraints)
//   MediaQuery.sizeOf ← حجم الشاشة كلها (context.screenSize من الدرس 1)
//   نقاط التوقف (Material 3): compact < 600 ≤ medium < 840 ≤ expanded
//   compact: NavigationBar بالأسفل · medium: NavigationRail · expanded: Rail ممتد + لوحة تفاصيل

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '01_extension_methods.dart';

// ------------------------------------------------------------
// 1) ThemeExtension: ألواننا الخاصة كجزء من الثيم
// ------------------------------------------------------------
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.success, required this.warning});

  final Color success;
  final Color warning;

  static const light = AppColors(
    success: Color(0xFF1B873F),
    warning: Color(0xFF9A6700),
  );
  static const dark = AppColors(
    success: Color(0xFF6FDD8B),
    warning: Color(0xFFF2CC60),
  );

  @override
  AppColors copyWith({Color? success, Color? warning}) => AppColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
  );

  // lerp: انتقال ناعم بين الثيمين (MaterialApp يحرّك الثيم عند التبديل)
  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

// ------------------------------------------------------------
// 2) بناء الثيم من لون واحد (seed) — نفس الدالة للفاتح والداكن
// ------------------------------------------------------------
ThemeData buildTheme(Color seed, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    extensions: [
      brightness == Brightness.dark ? AppColors.dark : AppColors.light,
    ],
    cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(vertical: 6)),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

// امتدادات (الدرس 1) للوصول السريع
extension ThemeX on BuildContext {
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
  WindowSize get windowSize => WindowSize.of(MediaQuery.sizeOf(this).width);
}

// ------------------------------------------------------------
// 3) إعدادات الثيم كحالة Riverpod — main.dart يراقبها
// ------------------------------------------------------------
typedef ThemeSettings = ({ThemeMode mode, Color seed});

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
      ThemeSettingsNotifier.new,
    );

class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() => (mode: ThemeMode.system, seed: Colors.indigo);

  void setMode(ThemeMode mode) => state = (mode: mode, seed: state.seed);
  void setSeed(Color seed) => state = (mode: state.mode, seed: seed);
}

// ------------------------------------------------------------
// 4) نقاط التوقف (Breakpoints)
// ------------------------------------------------------------
enum WindowSize {
  compact,
  medium,
  expanded;

  static WindowSize of(double width) => switch (width) {
    < 600 => compact,
    < 840 => medium,
    _ => expanded,
  };
}

// ============================================================
// الشاشة
// ============================================================
class ResponsiveThemingScreen extends StatefulWidget {
  const ResponsiveThemingScreen({super.key});

  @override
  State<ResponsiveThemingScreen> createState() =>
      _ResponsiveThemingScreenState();
}

class _ResponsiveThemingScreenState extends State<ResponsiveThemingScreen> {
  int _tab = 0;

  static const _destinations = [
    (Icons.palette_outlined, 'الثيم'),
    (Icons.grid_view, 'الشبكة'),
    (Icons.info_outline, 'المقاس'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدرس 8: Responsive و Theming')),
      // LayoutBuilder: نقرّر الشكل حسب العرض المتاح فعلاً
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = WindowSize.of(constraints.maxWidth);
          final content = _Content(
            tab: _tab,
            size: size,
            width: constraints.maxWidth,
          );

          if (size == WindowSize.compact) {
            return Column(
              children: [
                Expanded(child: content),
                NavigationBar(
                  selectedIndex: _tab,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  destinations: [
                    for (final (icon, label) in _destinations)
                      NavigationDestination(icon: Icon(icon), label: label),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              NavigationRail(
                extended: size == WindowSize.expanded,
                labelType: size == WindowSize.expanded
                    ? NavigationRailLabelType.none
                    : NavigationRailLabelType.all,
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                destinations: [
                  for (final (icon, label) in _destinations)
                    NavigationRailDestination(
                      icon: Icon(icon),
                      label: Text(label),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: content),
              // expanded فقط: لوحة جانبية إضافية
              if (size == WindowSize.expanded)
                const SizedBox(width: 280, child: _SidePanel()),
            ],
          );
        },
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.tab, required this.size, required this.width});
  final int tab;
  final WindowSize size;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    final notifier = ref.read(themeSettingsProvider.notifier);
    final app = context.appColors;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'WindowSize.${size.name} · العرض المتاح ${width.round()}px · '
          'الشاشة ${context.screenSize.width.round()}px',
        ),
        const SizedBox(height: 12),
        if (tab == 0) ...[
          Text('وضع الثيم (للتطبيق كله)', style: context.textTheme.titleMedium),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('النظام')),
              ButtonSegment(value: ThemeMode.light, label: Text('فاتح')),
              ButtonSegment(value: ThemeMode.dark, label: Text('داكن')),
            ],
            selected: {settings.mode},
            onSelectionChanged: (s) => notifier.setMode(s.first),
          ),
          const SizedBox(height: 12),
          Text('لون البذرة (seed)', style: context.textTheme.titleMedium),
          Wrap(
            spacing: 8,
            children: [
              for (final c in [
                Colors.indigo,
                Colors.teal,
                Colors.deepOrange,
                Colors.pink,
              ])
                ChoiceChip(
                  avatar: CircleAvatar(backgroundColor: c),
                  label: Text(c == settings.seed ? 'مختار' : 'لون'),
                  selected: c == settings.seed,
                  onSelected: (_) => notifier.setSeed(c),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: app.success),
              title: const Text('AppColors.success من ThemeExtension'),
              subtitle: Text('الوضع الآن: ${context.isDark ? 'داكن' : 'فاتح'}'),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.warning_amber, color: app.warning),
              title: const Text('AppColors.warning'),
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Filled')),
              OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
              const Chip(label: Text('Chip')),
            ],
          ),
        ],
        if (tab == 1)
          // عدد الأعمدة يتبع المقاس
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: switch (size) {
              WindowSize.compact => 2,
              WindowSize.medium => 3,
              WindowSize.expanded => 4,
            },
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (var i = 1; i <= 8; i++)
                Card(
                  color: context.colors.primaryContainer,
                  child: Center(child: Text('عنصر $i')),
                ),
            ],
          ),
        if (tab == 2)
          const Text(
            'غيّر حجم النافذة (flutter run -d linux أو chrome) وراقب:\n'
            '• أقل من 600 ← NavigationBar بالأسفل\n'
            '• 600 – 840 ← NavigationRail\n'
            '• 840 فأكثر ← Rail ممتد + لوحة جانبية',
          ),
      ],
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.surfaceContainerLow,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('لوحة التفاصيل — تظهر فقط في المقاس expanded'),
      ),
    );
  }
}

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) LayoutBuilder أم MediaQuery؟ LayoutBuilder يعطي مساحة الـ Widget نفسه
//    (صحيح داخل لوحة جانبية أو Dialog)، و MediaQuery.sizeOf حجم الشاشة كلها.
//
// 2) لا تكتب ألواناً ثابتة داخل الشاشات: Colors.blue ❌ ← context.colors.primary ✅
//    هكذا يعمل الوضع الداكن وتغيير اللون تلقائياً.
//
// 3) لون نص مناسب فوق أي خلفية: استخدم الأزواج on*:
//      primary ← onPrimary · primaryContainer ← onPrimaryContainer
//
// 4) نصوص التطبيق كلها من textTheme (titleMedium, bodyLarge...) وليس fontSize ثابت،
//    فتتغيّر مع الثيم ومع حجم الخط الذي يختاره المستخدم (الدرس 9).
//
// 5) لحفظ اختيار الثيم بين التشغيلات: خزّن mode و seed في SharedPreferences
//    (اليوم الثالث) واقرأها في build() الخاص بـ ThemeSettingsNotifier.
