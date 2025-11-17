import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ⚠️ เอา token จาก LINE Notify มาใส่ตรงนี้ (อย่า push ขึ้น GitHub)
const _lineNotifyToken = 'YOUR_LINE_NOTIFY_TOKEN';

class LineNotify {
  static const _endpoint = 'https://notify-api.line.me/api/notify';

  static Future<void> send(String message) async {
    try {
      final res = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Bearer $_lineNotifyToken',
        },
        body: {
          'message': message,
        },
      );

      debugPrint('LINE Notify status: ${res.statusCode} ${res.body}');
    } catch (e) {
      debugPrint('LINE Notify error: $e');
    }
  }
}
