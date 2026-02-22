import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

typedef LocalNotifTap = void Function(Map<String, String> data);

class LocalNotifService {
  LocalNotifService._();
  static final instance = LocalNotifService._();

  static const String channelId = 'med_reminder_channel';
  static const String channelName = 'Medication Reminders';
  static const String channelDesc = 'แจ้งเตือนการให้ยา (สำคัญมาก)';

  /// ถ้ามีไฟล์ android/app/src/main/res/raw/alarm.mp3
  static const String androidRawSoundName = 'alarm';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  LocalNotifTap? _onTap;
  bool _tzReady = false;
  bool _inited = false;

  /// เรียกใช้ก่อน schedule/cancel/show ได้เลย (ซ้ำได้)
  Future<void> ensureInit({LocalNotifTap? onTap}) async {
    await init(onTap: onTap);
  }

  /// ================= INIT =================
  Future<void> init({LocalNotifTap? onTap}) async {
    if (onTap != null) _onTap = onTap;
    if (_inited) return;

    // Timezone
    if (!_tzReady) {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));
      _tzReady = true;
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    // ✅ v19.5.0: initialize ใช้ positional ตัวแรก
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _createChannel();
    await _requestNotificationPermission();
    await _requestExactAlarmPermissionIfNeeded();

    _inited = true;
  }

  /// ================= TAP =================
  void _onNotificationResponse(NotificationResponse response) {
    if (response.actionId == 'TAKEN') return;

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    final data = decodePayloadSafe(payload);
    if (data.isNotEmpty) _onTap?.call(data);
  }

  /// ================= PERMISSIONS =================
  Future<void> _requestNotificationPermission() async {
    // Android 13+ ต้องขอ permission
    await _android?.requestNotificationsPermission();
  }

  Future<void> _requestExactAlarmPermissionIfNeeded() async {
    final canExact = await _android?.canScheduleExactNotifications();
    if (canExact == false) {
      await _android?.requestExactAlarmsPermission();
    }
  }

  /// ================= CHANNEL =================
  Future<void> _createChannel() async {
    final channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: const RawResourceAndroidNotificationSound(androidRawSoundName),
    );
    await _android?.createNotificationChannel(channel);
  }

  /// ================= PAYLOAD =================
  String encodePayload(Map<String, String> data) =>
      Uri(queryParameters: data).query;

  Map<String, String> decodePayloadSafe(String payload) {
    try {
      return Uri.splitQueryString(payload);
    } catch (_) {
      return <String, String>{};
    }
  }

  /// ================= STABLE ID =================
  int buildNotifIdKey(String docId, String key, TimeOfDay time) {
    return _fnv1a31('$docId|$key|${time.hour}:${time.minute}');
  }

  int _fnv1a31(String input) {
    const int fnvPrime = 0x01000193;
    int hash = 0x811C9DC5;
    for (final c in input.codeUnits) {
      hash ^= c;
      hash = (hash * fnvPrime) & 0x7fffffff; // 31-bit positive
    }
    return hash == 0 ? 1 : hash;
  }

  /// ================= DETAILS =================
  AndroidNotificationDetails androidDetails({required bool alarmStyle}) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound(androidRawSoundName),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 900, 300, 900]),
      visibility: NotificationVisibility.public,
      actions: const [
        AndroidNotificationAction(
          'TAKEN',
          '💊 กินยาแล้ว',
          cancelNotification: true,
        ),
      ],
      category: alarmStyle ? AndroidNotificationCategory.alarm : null,
      fullScreenIntent: alarmStyle,
      ongoing: alarmStyle,
      autoCancel: !alarmStyle,
    );
  }

  Future<AndroidScheduleMode> _preferredScheduleMode() async {
    final canExact = await _android?.canScheduleExactNotifications();
    return (canExact == true)
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// ================= SHOW NOW =================
  Future<void> showNow({
    required String title,
    required String body,
    Map<String, String>? payloadData,
    bool alarmStyle = false,
  }) async {
    await ensureInit();

    final id = (DateTime.now().microsecondsSinceEpoch & 0x7fffffff);
    final details = NotificationDetails(
      android: androidDetails(alarmStyle: alarmStyle),
    );

    await _plugin.show(
      id,
      title,
      body,
      details,
      payload: payloadData == null ? null : encodePayload(payloadData),
    );
  }

  /// ✅ Alias กันชน: ให้ไฟล์อื่นเรียก show(...) ได้
  Future<void> show({
    required String title,
    required String body,
    Map<String, String>? payloadData,
    bool alarmStyle = false,
  }) {
    return showNow(
      title: title,
      body: body,
      payloadData: payloadData,
      alarmStyle: alarmStyle,
    );
  }

  /// ================= DAILY SCHEDULE =================
  Future<void> scheduleDailyAt({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    Map<String, String>? payloadData,
    bool alarmStyle = false,
  }) async {
    await ensureInit();

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

    final details = NotificationDetails(
      android: androidDetails(alarmStyle: alarmStyle),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: await _preferredScheduleMode(),
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payloadData == null ? null : encodePayload(payloadData),
    );
  }

  /// ================= WEEKLY SCHEDULE =================
  /// weekday: 1=Mon ... 7=Sun
  Future<void> scheduleWeeklyAt({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required TimeOfDay time,
    Map<String, String>? payloadData,
    bool alarmStyle = false,
  }) async {
    await ensureInit();

    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final details = NotificationDetails(
      android: androidDetails(alarmStyle: alarmStyle),
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: await _preferredScheduleMode(),
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payloadData == null ? null : encodePayload(payloadData),
    );
  }

  /// ================= CANCEL =================
  Future<void> cancel(int id) async {
    await ensureInit();
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await ensureInit();
    await _plugin.cancelAll();
  }
}
