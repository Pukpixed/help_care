import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app_notify_service.dart';
import 'local_notif_service.dart';
import 'user_service.dart';

class PushService {
  PushService._();
  static final instance = PushService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamSubscription<RemoteMessage>? _subOnMessage;
  StreamSubscription<RemoteMessage>? _subOnOpen;
  StreamSubscription<String>? _subTokenRefresh;

  bool _inited = false;

  /// เปิด/ปิด: จะให้ “ข้อความตอน foreground” ถูกเก็บเข้า inbox ด้วยไหม
  bool saveForegroundToInbox = true;

  void Function(Map<String, dynamic> data)? _tapCallback;

  Future<void> init() async {
    if (_inited) return;
    _inited = true;

    await LocalNotifService.instance.ensureInit();

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // iOS: กันเด้งซ้ำตอน foreground (เราจะเด้ง Local เอง)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    // Foreground -> เด้ง local “ครั้งเดียว”
    _subOnMessage?.cancel();
    _subOnMessage = FirebaseMessaging.onMessage.listen((RemoteMessage m) async {
      final title =
          m.notification?.title ?? (m.data['title']?.toString() ?? 'แจ้งเตือน');
      final body = m.notification?.body ?? (m.data['body']?.toString() ?? '');

      final dataMap = Map<String, dynamic>.from(m.data);

      // 1) (ทางเลือก) เก็บเข้า inbox แต่ห้ามเด้ง local ซ้ำ
      if (saveForegroundToInbox) {
        await AppNotifyService.instance.notifyOnSave(
          title: title,
          body: body,
          type: 'push',
          data: dataMap,
          showLocal: false, // ✅ กันเด้งซ้ำ
        );
      }

      // 2) เด้ง local ที่เครื่อง (1 ครั้ง)
      await LocalNotifService.instance.show(
        title: title,
        body: body,
        payloadData: <String, String>{
          'type': 'push',
          ...m.data.map((k, v) => MapEntry(k, v.toString())),
        },
      );
    });

    // Tap notification (เปิดจาก background)
    _subOnOpen?.cancel();
    _subOnOpen = FirebaseMessaging.onMessageOpenedApp.listen((m) {
      _tapCallback?.call(Map<String, dynamic>.from(m.data));
    });
  }

  /// เรียกใน UI เพื่อรับ event ตอนผู้ใช้กดแจ้งเตือน
  void onNotificationTap(void Function(Map<String, dynamic> data) callback) {
    _tapCallback = callback;
  }

  /// ต้องเรียกตอนเปิดแอปครั้งแรก เพื่อรับ “ข้อความแรก” ที่ทำให้แอปถูกเปิด
  Future<void> handleInitialMessage(
    void Function(Map<String, dynamic> data) callback,
  ) async {
    final m = await _messaging.getInitialMessage();
    if (m == null) return;
    callback(Map<String, dynamic>.from(m.data));
  }

  /// ---------------- Token ----------------
  Future<void> saveTokenForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await UserService.instance.ensureUserDoc();

    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(user.uid, token);
    }

    _subTokenRefresh?.cancel();
    _subTokenRefresh = _messaging.onTokenRefresh.listen((newToken) async {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null) return;
      await _saveToken(u.uid, newToken);
    });
  }

  Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(token)
        .set({
          'token': token,
          'platform': Platform.isAndroid ? 'android' : 'other',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> dispose() async {
    await _subOnMessage?.cancel();
    await _subOnOpen?.cancel();
    await _subTokenRefresh?.cancel();
    _subOnMessage = null;
    _subOnOpen = null;
    _subTokenRefresh = null;
    _inited = false;
  }
}
