// GENERATED CODE - DO NOT MODIFY BY HAND

part of '04_riverpod_codegen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appTitle)
final appTitleProvider = AppTitleProvider._();

final class AppTitleProvider extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  AppTitleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appTitleProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appTitleHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return appTitle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$appTitleHash() => r'9eb52f3e6263642e9b498b6885d66a8dd51b3933';

@ProviderFor(courses)
final coursesProvider = CoursesProvider._();

final class CoursesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  CoursesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coursesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coursesHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return courses(ref);
  }
}

String _$coursesHash() => r'06aa86013b3a40e0a8100b88e9bb3fef68638b79';

@ProviderFor(lessonCount)
final lessonCountProvider = LessonCountFamily._();

final class LessonCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  LessonCountProvider._({
    required LessonCountFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'lessonCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$lessonCountHash();

  @override
  String toString() {
    return r'lessonCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return lessonCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LessonCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$lessonCountHash() => r'66647842013eda2bbe95a6db948efbb620ff49b9';

final class LessonCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  LessonCountFamily._()
    : super(
        retry: null,
        name: r'lessonCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LessonCountProvider call(String course) =>
      LessonCountProvider._(argument: course, from: this);

  @override
  String toString() => r'lessonCountProvider';
}

@ProviderFor(Likes)
final likesProvider = LikesProvider._();

final class LikesProvider extends $NotifierProvider<Likes, int> {
  LikesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'likesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$likesHash();

  @$internal
  @override
  Likes create() => Likes();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$likesHash() => r'eb7b4886da74e952587a2c839db1c83fd66789f8';

abstract class _$Likes extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(DarkMode)
final darkModeProvider = DarkModeProvider._();

final class DarkModeProvider extends $NotifierProvider<DarkMode, bool> {
  DarkModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'darkModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$darkModeHash();

  @$internal
  @override
  DarkMode create() => DarkMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$darkModeHash() => r'cee8a809b8a1deee22a11a0f880767e1cc03d7ff';

abstract class _$DarkMode extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
