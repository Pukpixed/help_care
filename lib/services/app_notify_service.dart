import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'local_notif_service.dart';

class AppNotifyService {
  AppNotifyService._();
  static final instance = AppNotifyService._();

  /// เด้งบนเครื่อง + เพิ่มเข้า inbox (notifications)
  Future<String?> notifyOnSave({
    required String title,
    required String body,
    String type = 'notification',
    Map<String, dynamic>? data,
  }) async {
    // 1) เด้งบนเครื่องนี้
    await LocalNotifService.instance.show(title: title, body: body);

    // 2) เข้ากล่องแจ้งเตือนในแอป
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final ref = await FirebaseFirestore.instance
        .collection('notifications')
        .add({
          'targetUid': uid,
          'title': title,
          'body': body,
          'status': 'saved', // ฟรี: ยังไม่ใช้ functions ก็ใช้ saved ได้เลย
          'createdAt': FieldValue.serverTimestamp(),
          'data': {'type': type, ...(data ?? {})},
        });

    return ref.id;
  }
}
