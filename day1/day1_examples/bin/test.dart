import 'dart:async';

Future<String> fetchOrdersCount() async {
  await Future.delayed(Duration(milliseconds: 700));
  print("Order Count is 11");
  return "";
}

void _log(String str) {
  print("*** $str");
}

void main() async {
  final fastest = await Future.any([fetchOrdersCount(), fetchUserName(5)]);
  _log(fastest);

  //var sw = Stopwatch()..start();
  //   // تسلسلي: الطلب الثاني لا يبدأ إلا بعد انتهاء الأول ≈ 1200ms
  //   final a = await fetchUserName(5);
  //   final b = await fetchOrdersCount();
  //   sw.stop();
  //   _log('تسلسلي: $a / $b طلب ← ${sw.elapsedMilliseconds}ms');
  //   sw.reset();
  //   sw.start();
  //   // متوازي باستخدام Future.wait: كل الطلبات تبدأ معاً ≈ 700ms
  //   final results = await Future.wait([fetchUserName(2), fetchOrdersCount()]);
  //   sw.stop();
  //   _log('Future.wait: $results ← ${sw.elapsedMilliseconds}ms');
  //   sw.reset();
  //   sw.start();
  //   // متوازي باستخدام Records (Dart 3): الأنواع محفوظة لكل عنصر ✅
  //   final (name, count) = await (fetchUserName(3), fetchOrdersCount()).wait;
  //   sw.stop();
  //   _log('Record.wait: $name / $count ← ${sw.elapsedMilliseconds}ms');
}

Future<String> fetchUserName(int id) async {
  await Future.delayed(const Duration(milliseconds: 500));
  if (id <= 0) {
    throw ArgumentError('رقم المستخدم غير صالح: $id');
  } else if (id == 1) {
    throw Exception("id equal 1");
  }

  return 'مستخدم رقم $id';
}
