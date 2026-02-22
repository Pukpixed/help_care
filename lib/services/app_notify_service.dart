import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'local_notif_service.dart';

class AppNotifyService {
  AppNotifyService._();
  static final instance = AppNotifyService._();

  /// เด้งบนเครื่อง + เพิ่มเข้า inbox (notifications)
  /// - showLocal=true  : ใช้เวลาคุณอยากเด้งเอง (เช่น บันทึกสำเร็จ)
  /// - showLocal=false : ใช้เมื่อ PushService เด้ง local ให้แล้ว (กันเด้งซ้ำ)
  Future<String?> notifyOnSave({
    required String title,
    required String body,
    String type = 'notification',
    Map<String, dynamic>? data,
    bool showLocal = true,
  }) async {
    // 1) เด้งบนเครื่อง (เลือกได้)
    if (showLocal) {
      await LocalNotifService.instance.show(
        title: title,
        body: body,
        payloadData: {'type': type},
      );
    }

    // 2) เข้ากล่องแจ้งเตือนในแอป
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final ref = await FirebaseFirestore.instance
        .collection('notifications')
        .add({
          'targetUid': uid,
          'title': title,
          'body': body,
          'status': 'saved',
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
          'data': <String, dynamic>{
            'type': type,
            ...(data ?? <String, dynamic>{}),
          },
        });

    return ref.id;
  }
}
