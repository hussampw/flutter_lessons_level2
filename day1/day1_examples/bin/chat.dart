//chat.dart
import 'dart:async';

class ChatService {
  final _controller = StreamController<String>.broadcast();

  Stream<String> get messages => _controller.stream;

  void send(String text) {
    _controller.add(text);
  }

  void fail() {
    _controller.addError(Exception("Cut Internet "));
  }

  Future<void> dispose() async {
    _controller.close();
  }
}

void main() async {
  ChatService chat = ChatService();
  var unread = 0;
  final sub1 = chat.messages.listen(
    (msg) => print('📩 شاشة الشات: $msg'),
    onError: (e) => print('❌ خطأ: $e'),
    onDone: () => print('✅ أُغلق الـ Stream'),
  );

  // المستمع الثاني (ممكن لأنه broadcast): يحسب الإشعارات
  final sub2 = chat.messages.listen((_) => unread++, onError: (_) {});
  sub1.pause(); // إيقاف مؤقت: الرسائل تُخزَّن (buffer) ولا تُعرض الآن
  chat.send('رسالة أثناء الإيقاف');
  sub1.resume(); // تصل الرسائل المخزّنة الآن دفعة واحدة
  await Future.delayed(Duration.zero);

  chat.fail(); // إرسال خطأ عبر الـ Stream
  await sub2.cancel();
  await chat.dispose(); // يستدعي onDone عند sub1
  await sub1.cancel(); //نعطي فرصة لوصول القيم
}
