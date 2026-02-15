import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:typed_data';

typedef LocalNotifTap = void Function(Map<String, String> data);

class LocalNotifService {
  LocalNotifService._();
  static final instance = LocalNotifService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  LocalNotifTap? _onTap;

  /// ================= INIT =================
  Future<void> init({LocalNotifTap? onTap}) async {
    _onTap = onTap;

    // ✅ Timezone setup
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _createChannel();
    await _requestPermission();
  }

  /// ================= HANDLE TAP =================
  void _onNotificationResponse(NotificationResponse response) {
    if (response.actionId == 'TAKEN') return;

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    _onTap?.call(_decodePayload(payload));
  }

  /// ================= PERMISSION =================
  Future<void> _requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await android?.requestNotificationsPermission();
  }

  /// ================= CHANNEL =================
  Future<void> _createChannel() async {
    const channel = AndroidNotificationChannel(
      'med_reminder_channel',
      'Medication Reminders',
      description: 'แจ้งเตือนการให้ยา (สำคัญมาก)',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await android?.createNotificationChannel(channel);
  }

  /// ================= PAYLOAD =================
  String encodePayload(Map<String, String> data) =>
      data.entries.map((e) => '${e.key}=${e.value}').join('&');

  Map<String, String> _decodePayload(String payload) {
    final map = <String, String>{};

    for (final p in payload.split('&')) {
      final idx = p.indexOf('=');
      if (idx <= 0) continue;
      map[p.substring(0, idx)] = p.substring(idx + 1);
    }

    return map;
  }

  /// ================= BUILD ID =================
  int buildNotifId(String docId, TimeOfDay time) {
    final base = docId.hashCode;
    final timePart = time.hour * 100 + time.minute;
    return (base + timePart).abs();
  }

  /// ================= SHOW NOW =================
  Future<void> show({
    required String title,
    required String body,
    Map<String, String>? payloadData,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    const androidDetails = AndroidNotificationDetails(
      'med_reminder_channel',
      'Medication Reminders',
      channelDescription: 'แจ้งเตือนการให้ยา (สำคัญมาก)',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
      ongoing: true,
      autoCancel: false,
      actions: [
        AndroidNotificationAction(
          'TAKEN',
          '💊 กินยาแล้ว',
          cancelNotification: true,
        ),
      ],
    );

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: payloadData == null ? null : encodePayload(payloadData),
    );
  }

  /// ================= DAILY SCHEDULE =================
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

    final androidDetails = AndroidNotificationDetails(
      'med_reminder_channel',
      'Medication Reminders',
      channelDescription: 'แจ้งเตือนการให้ยา (สำคัญมาก)',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      ongoing: true,
      autoCancel: false,
      actions: [
        AndroidNotificationAction(
          'TAKEN',
          '💊 กินยาแล้ว',
          cancelNotification: true,
        ),
      ],
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payloadData == null ? null : encodePayload(payloadData),
    );
  }

  /// ================= CANCEL =================
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
