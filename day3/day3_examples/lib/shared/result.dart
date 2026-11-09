// ============================================================
// Result<T> — نتيجة عملية: نجاح بقيمة من النوع T، أو فشل برسالة
// يُشرح في الدرس 1 (Generics) ويُستخدم في الدرسين 8 و 9
// ملف Dart خالص (بدون Flutter) لأن طبقة domain في الدرس 8 تستورده
// ============================================================

sealed class Result<T> {
  const Result();

  /// تحويل القيمة عند النجاح فقط — والفشل يمر كما هو
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success(:final value) => Success(transform(value)),
        Failure(:final message, :final error) => Failure(message, error),
      };
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;

  @override
  String toString() => 'Success<$T>($value)';
}

final class Failure<T> extends Result<T> {
  const Failure(this.message, [this.error]);
  final String message;
  final Object? error;

  @override
  String toString() => 'Failure<$T>($message)';
}

/// يشغّل عملية async ويحوّل أي استثناء إلى Failure بدل رميه
Future<Result<T>> runCatching<T>(
  Future<T> Function() body, {
  String Function(Object error)? describe,
}) async {
  try {
    return Success(await body());
  } catch (e) {
    return Failure(describe?.call(e) ?? '$e', e);
  }
}
