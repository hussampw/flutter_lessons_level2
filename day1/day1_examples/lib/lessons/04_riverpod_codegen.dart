// ============================================================
// الدرس 4 (Riverpod): توليد الكود باستخدام @riverpod
// في التطبيق: القائمة ← الدرس 4  ·  في العرض: شرائح الدرس 4
// التوليد: dart run build_runner watch -d
// ============================================================
//
// بدل أن نكتب النوع بأنفسنا (Provider / NotifierProvider / FutureProvider ...)
// نكتب دالة أو class عادية ونضع @riverpod فوقها،
// والمولّد يختار النوع المناسب ويُنشئ المتغير xxxProvider تلقائياً.
//
// المميزات:
//   ✅ autoDispose افتراضياً (توفير ذاكرة)
//   ✅ family عبر باراميترات عادية (حتى المسمّاة والاختيارية)
//   ✅ صياغة واحدة لكل الأنواع

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// اسم الملف المولَّد = اسم الملف + .g.dart
part '04_riverpod_codegen.g.dart';

// ------------------------------------------------------------
// 1) دالة تعيد قيمة ← يولّد Provider باسم appTitleProvider
// ------------------------------------------------------------
@riverpod
String appTitle(Ref ref) => 'ورشة Flutter المتقدمة';

// ------------------------------------------------------------
// 2) دالة تعيد Future ← يولّد FutureProvider باسم coursesProvider
// ------------------------------------------------------------
@riverpod
Future<List<String>> courses(Ref ref) async {
  await Future.delayed(const Duration(seconds: 1));
  return ['Dart المتقدم', 'Riverpod', 'go_router', 'Dio'];
}

// ------------------------------------------------------------
// 3) دالة بباراميتر ← family تلقائياً: lessonCountProvider('Riverpod')
// ------------------------------------------------------------
@riverpod
Future<int> lessonCount(Ref ref, String course) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return course.length; // رقم وهمي للتوضيح
}

// ------------------------------------------------------------
// 4) class ← يولّد NotifierProvider باسم likesProvider
//    نرث من _$Likes (مولّد) بدل Notifier<int>
// ------------------------------------------------------------
@riverpod
class Likes extends _$Likes {
  @override
  int build() => 0;

  void like() => state++;
}

// ------------------------------------------------------------
// 5) keepAlive: true ← لا يُحذف من الذاكرة حتى لو لم يستخدمه أحد
//    مناسب للإعدادات وبيانات المستخدم الحالي
// ------------------------------------------------------------
@Riverpod(keepAlive: true)
class DarkMode extends _$DarkMode {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

class CodegenScreen extends ConsumerWidget {
  const CodegenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // الاستخدام مطابق تماماً للـ providers اليدوية
    final title = ref.watch(appTitleProvider);
    final courses = ref.watch(coursesProvider);
    final likes = ref.watch(likesProvider);
    final dark = ref.watch(darkModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الدرس 4: @riverpod'),
        actions: [
          IconButton(
            icon: Icon(dark ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => ref.read(darkModeProvider.notifier).toggle(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          Text('الوضع الليلي (keepAlive): ${dark ? 'مفعّل' : 'متوقف'}'),
          const Divider(),
          ...switch (courses) {
            AsyncData(value: final list) => [
                for (final c in list)
                  ListTile(
                    title: Text(c),
                    // family: كل دورة لها provider مستقل بحسب الباراميتر
                    trailing: Consumer(
                      builder: (context, ref, _) {
                        final count = ref.watch(lessonCountProvider(c));
                        return Text(count.value?.toString() ?? '…');
                      },
                    ),
                  ),
              ],
            AsyncError(:final error) => [Text('خطأ: $error')],
            _ => [const Center(child: CircularProgressIndicator())],
          },
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ref.read(likesProvider.notifier).like(),
        icon: const Icon(Icons.favorite),
        label: Text('$likes'),
      ),
    );
  }
}

// 💡 جرّب: اخرج من الشاشة ثم ادخل مجدداً
//   likes يرجع 0 (autoDispose) أما الوضع الليلي فيبقى (keepAlive)

// ============================================================
// 💡 حيل الدرس
// ============================================================
// 1) شغّل dart run build_runner watch -d في Terminal منفصل طوال الدرس
//    فيُولَّد الكود تلقائياً مع كل حفظ.
//
// 2) خطأ "_$Likes isn't defined"؟ تأكد من:
//    سطر part 'اسم_الملف.g.dart'; مطابق تماماً لاسم الملف، ثم أعد التوليد.
//
// 3) في VS Code: إضافة "Flutter Riverpod Snippets" — اكتب riverpodClass أو
//    riverpodFuture فيُكتب القالب كاملاً.
//
// 4) أخفِ الملفات المولَّدة من شجرة الملفات في VS Code (settings.json):
//      "explorer.fileNesting.enabled": true,
//      "explorer.fileNesting.patterns": { "*.dart": "${capture}.g.dart, ${capture}.freezed.dart" }
//
// 5) استخدم @Riverpod(keepAlive: true) فقط لما يجب أن يعيش طوال التطبيق
//    (المستخدم الحالي، الإعدادات). الباقي اتركه autoDispose.
