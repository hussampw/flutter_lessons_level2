Future<int> _countedFetch() async {
  await Future.delayed(Duration(seconds: 3));
  print("o");
  return 700;
}

Future<int> _countedFetch2() async {
  await Future.delayed(Duration(seconds: 5));
  print("d");
  return 700;
}

Future<int> _countedFetch3() async {
  Future.delayed(Duration(seconds: 1));
  throw Exception("DD");
}

void main() {
  Future.wait([
    _countedFetch3(),
    _countedFetch2(),
    _countedFetch(),
  ], eagerError: true);
}
