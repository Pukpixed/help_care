import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'local_notif_service.dart';
import 'user_service.dart';

class PushService {
  PushService._();
  static final instance = PushService._();

  final _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Foreground -> ให้เด้ง local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage m) async {
      final title =
          m.notification?.title ?? (m.data['title']?.toString() ?? 'แจ้งเตือน');
      final body = m.notification?.body ?? (m.data['body']?.toString() ?? '');
      await LocalNotifService.instance.show(title: title, body: body);
    });
  }

  Future<void> saveTokenForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await UserService.instance.ensureUserDoc();

    final token = await _messaging.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
          'token': token,
          'platform': Platform.isAndroid ? 'android' : 'other',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    _messaging.onTokenRefresh.listen((newToken) async {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .collection('fcmTokens')
          .doc(newToken)
          .set({
            'token': newToken,
            'platform': Platform.isAndroid ? 'android' : 'other',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    });
  }

  void onNotificationTap(void Function(Map<String, dynamic> data) callback) {
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      callback(Map<String, dynamic>.from(m.data));
    });
  }

  Future<void> handleInitialMessage(
    void Function(Map<String, dynamic> data) callback,
  ) async {
    final m = await _messaging.getInitialMessage();
    if (m == null) return;
    callback(Map<String, dynamic>.from(m.data));
  }
}
