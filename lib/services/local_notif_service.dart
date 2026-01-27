import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

typedef LocalNotifTap = void Function(Map<String, String> data);

class LocalNotifService {
  LocalNotifService._();
  static final instance = LocalNotifService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  LocalNotifTap? _onTap;

  /// ✅ init + handle tap (payload -> Map)
  Future<void> init({LocalNotifTap? onTap}) async {
    _onTap = onTap;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse resp) {
        final payload = resp.payload;
        if (payload == null || payload.isEmpty) return;
        _onTap?.call(_parsePayload(payload));
      },
    );
  }

  /// ✅ Android 13+ ขอสิทธิ์แจ้งเตือน
  Future<void> requestAndroid13PermissionIfNeeded() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
  }

  /// ✅ แปลง Map -> payload string
  String encodePayload(Map<String, String> data) =>
      data.entries.map((e) => '${e.key}=${e.value}').join('&');

  /// ✅ แปลง payload string -> Map
  Map<String, String> _parsePayload(String payload) {
    final map = <String, String>{};
    for (final p in payload.split('&')) {
      final idx = p.indexOf('=');
      if (idx <= 0) continue;
      map[p.substring(0, idx)] = p.substring(idx + 1);
    }
    return map;
  }

  /// ✅ สร้าง notificationId แบบคงที่จาก docId + time เพื่อ cancel/replace ได้
  int buildNotifId(String docId, String hhmm) {
    final s = '$docId|$hhmm';
    var hash = 0;
    for (final code in s.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return 100000 + (hash % 800000);
  }

  /// ✅ เด้งแจ้งเตือนทันที (ใช้ใน AppNotifyService)
  Future<void> show({
    required String title,
    required String body,
    Map<String, String>? payloadData,
  }) async {
    const android = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'General notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: android),
      payload: payloadData == null ? null : encodePayload(payloadData),
    );
  }

  /// ✅ Schedule แจ้งเตือน “ทุกวัน” ตามเวลาเดียว (ซ้ำรายวัน)
  Future<void> scheduleDailyAt({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    Map<String, String>? payloadData,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const android = AndroidNotificationDetails(
      'med_reminder_channel',
      'Medication Reminders',
      channelDescription: 'Reminders for medication schedule',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(android: android),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          DateTimeComponents.time, // ✅ ซ้ำทุกวันตามเวลาเดิม
      payload: payloadData == null ? null : encodePayload(payloadData),
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id);

  Future<void> cancelMany(List<int> ids) async {
    for (final id in ids) {
      await _plugin.cancel(id);
    }
  }
}
