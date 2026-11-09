// ============================================================
// الدرس 2: اختبار Streams بدون listen يدوي — emitsInOrder
// التشغيل: flutter test test/streams_test.dart
// ============================================================

import 'package:day3_examples/lessons/02_streams.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('countdown يرسل القيم بالترتيب ثم يُغلق', () {
    expect(countdown(2), emitsInOrder([2, 1, 0, emitsDone]));
  });

  test('ChatService: مستمعان + خطأ + إغلاق', () async {
    final chat = ChatService();

    // broadcast: مستمعان على نفس الـ Stream
    final screen = expectLater(
      chat.messages,
      emitsInOrder(['مرحباً', emitsError(isA<Exception>()), emitsDone]),
    );
    final badge = expectLater(
      chat.messages.handleError((_) {}), // المستمع الثاني يتجاهل الأخطاء
      emitsInOrder(['مرحباً', emitsDone]),
    );

    chat.send('مرحباً');
    chat.fail();
    await chat.dispose();
    chat.send('بعد الإغلاق'); // لا يُرسل شيئاً ولا يرمي خطأ

    await Future.wait([screen, badge]);
  });
}
