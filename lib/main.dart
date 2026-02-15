import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'routes.dart';

// 🔔 Notification Services
import 'services/local_notif_service.dart';
import 'services/push_service.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// ✅ ซ่อน Error overlay / Red screen
  ErrorWidget.builder = (details) => const SizedBox.shrink();

  /// ✅ Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /// 🔔 Local Notification
  await LocalNotifService.instance.init(onTap: _handleLocalNotificationTap);

  /// 🔔 Push (FCM)
  await PushService.instance.init();
  await PushService.instance.saveTokenForCurrentUser();

  runApp(const MyApp());
}

/// =======================================================
/// 🔔 Local Notification Tap Handler
/// =======================================================
void _handleLocalNotificationTap(Map<String, String> data) {
  final collection = data['collection'] ?? '';

  WidgetsBinding.instance.addPostFrameCallback((_) {
    final state = navKey.currentState;
    if (state == null) return;

    if (collection == 'med_schedules') {
      state.pushNamed(AppRoutes.dailyCare);
    } else {
      state.pushNamed(AppRoutes.notifications);
    }
  });
}

/// =======================================================
/// APP
/// =======================================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    /// 👉 กดแจ้งเตือนตอนแอปเปิด
    PushService.instance.onNotificationTap(_routeFromNotificationData);

    /// 👉 เปิดแอปจาก terminated
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PushService.instance.handleInitialMessage(
        _routeFromNotificationData,
      );
    });
  }

  /// ===================================================
  /// Route จาก notification data (Push)
  /// ===================================================
  void _routeFromNotificationData(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = navKey.currentState;
      if (state == null) return;

      switch (type) {
        case 'sos':
          state.pushNamed(AppRoutes.sos);
          break;

        case 'careLog':
          final patientId = (data['patientId'] ?? '').toString();
          if (patientId.isEmpty) {
            state.pushNamed(AppRoutes.home);
          } else {
            state.pushNamed(
              AppRoutes.careLog,
              arguments: {'patientId': patientId},
            );
          }
          break;

        case 'dailyCare':
        case 'medSchedule':
          state.pushNamed(AppRoutes.dailyCare);
          break;

        case 'notification':
          final nid = (data['notificationId'] ?? '').toString();
          if (nid.isNotEmpty) {
            state.pushNamed(
              AppRoutes.notificationDetail,
              arguments: {'notificationId': nid},
            );
          } else {
            state.pushNamed(AppRoutes.notifications);
          }
          break;

        default:
          state.pushNamed(AppRoutes.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navKey,
      title: 'helpcare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.purple),
      initialRoute: AppRoutes.first,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
