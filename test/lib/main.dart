import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const _FutureBuilderDemo(),
    );
  }
}

class _FutureBuilderDemo extends StatefulWidget {
  const _FutureBuilderDemo();

  @override
  State<_FutureBuilderDemo> createState() => _FutureBuilderDemoState();
}

class _FutureBuilderDemoState extends State<_FutureBuilderDemo> {
  int _fetchCalls = 0;

  Future<int> _countedFetch() async {
    _fetchCalls++; // نعدّ كم مرة أُرسل "طلب الشبكة"
    Future.delayed(Duration(seconds: 5));
    return 700;
  }

  // ✅ الـ Future يُنشأ مرة واحدة فقط
  late final Future<int> _ordersFuture = _countedFetch();
  bool _wrongWay = false;

  @override
  Widget build(BuildContext context) {
    // ❌ في الوضع الخاطئ ننشئ Future جديداً في كل build = طلب شبكة جديد
    // ✅ في الوضع الصحيح نستخدم نفس الـ Future المحفوظ
    final future = _wrongWay ? _countedFetch() : _ordersFuture;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              '7) FutureBuilder — عدد طلبات الشبكة: $_fetchCalls',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _wrongWay
                    ? '❌ Future داخل build (طلب جديد مع كل إعادة بناء)'
                    : '✅ Future محفوظ في initState (طلب واحد فقط)',
              ),
              value: _wrongWay,
              onChanged: (v) => setState(() => _wrongWay = v),
            ),
            FutureBuilder<int>(
              future: future,
              builder: (context, snapshot) {
                // ConnectionState + hasError + hasData = نفس فكرة AsyncValue
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('خطأ: ${snapshot.error}');
                }
                return Text('عدد الطلبات من الـ API: ${snapshot.data}');
              },
            ),
            TextButton(
              child: Text("إعادة البناء"),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}
