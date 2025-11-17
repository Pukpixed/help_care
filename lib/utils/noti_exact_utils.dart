import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:timezone/data/latest.dart' as tzdata;

const _kBgPortName = 'noti_exact_bg_port';

class NotiUtils {
  static final fln.FlutterLocalNotificationsPlugin _plugin =
      fln.FlutterLocalNotificationsPlugin();

  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;

    tzdata.initializeTimeZones();

    const androidInit = fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = fln.InitializationSettings(android: androidInit);
    await _plugin.initialize(init);

    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<fln.AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    IsolateNameServer.removePortNameMapping(_kBgPortName);
    IsolateNameServer.registerPortWithName(ReceivePort().sendPort, _kBgPortName);

    _inited = true;
  }

  static DateTime _nextOccurrence(int hour, int minute) {
    final now = DateTime.now();
    var when = DateTime(now.year, now.month, now.day, hour, minute);
    if (!when.isAfter(now)) when = when.add(const Duration(days: 1));
    return when;
  }

  @pragma('vm:entry-point')
  static Future<void> _alarmCallback(
    int id,
    String title,
    String body,
    int hour,
    int minute,
  ) async {
    final local = fln.FlutterLocalNotificationsPlugin();
    const android = fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = fln.InitializationSettings(android: android);
    await local.initialize(init);

    const details = fln.NotificationDetails(
      android: fln.AndroidNotificationDetails(
        'care_channel',
        'การแจ้งเตือนกิจวัตร',
        importance: fln.Importance.max,
        priority: fln.Priority.high,
        playSound: true,
      ),
    );

    await local.show(id, title, body, details);

    final next = _nextOccurrence(hour, minute);
    await AndroidAlarmManager.oneShotAt(
      next,
      id,
      _alarmEntry,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: <String, dynamic>{
        'id': id,
        'title': title,
        'body': body,
        'hour': hour,
        'minute': minute,
      },
    );
  }

  @pragma('vm:entry-point')
  static void _alarmEntry(int id, Map<String, dynamic> params) {
    final title = params['title'] as String? ?? '';
    final body = params['body'] as String? ?? '';
    final hour = params['hour'] as int? ?? 8;
    final minute = params['minute'] as int? ?? 0;
    _alarmCallback(id, title, body, hour, minute);
  }

  static Future<int> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await init();
    final first = _nextOccurrence(hour, minute);
    await AndroidAlarmManager.oneShotAt(
      first,
      id,
      _alarmEntry,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: <String, dynamic>{
        'id': id,
        'title': title,
        'body': body,
        'hour': hour,
        'minute': minute,
      },
    );
    return id;
  }

  static Future<void> cancel(int id) async {
    await init();
    await AndroidAlarmManager.cancel(id);
  }

  static Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll(); // ล้างเฉพาะ noti ที่ตั้งไว้แล้ว
  }
}
