import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ timezone
  tz.initializeTimeZones();

  // ✅ Android init
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidSettings,
  );

  // ✅ initialize plugin
  await notifications.initialize(initializationSettings);

  // ✅ create channel (Android 8+)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'med_channel',
    'Medication Reminder',
    description: 'แจ้งเตือนกินยา',
    importance: Importance.max,
  );

  await notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
}
