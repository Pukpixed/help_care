import 'dart:async';
import 'package:flutter/foundation.dart';
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

  // ✅ ซ่อน error เฉพาะตอน release (ตอน debug ต้องเห็น error)
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const SizedBox.shrink();
  }

  // ✅ Firebase (จำเป็นก่อนใช้ messaging/firestore)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ แสดง UI ก่อน (กันค้างสแปลช)
  runApp(const MyApp());

  // ✅ ค่อย init services หลังวาดเฟรมแรก
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _initServices();
  });
}

Future<void> _initServices() async {
  try {
    // 🔔 Local Notification
    await LocalNotifService.instance.ensureInit(
      onTap: _handleLocalNotificationTap,
    );

    // 🔔 Push (FCM)
    await PushService.instance.init();

    // ✅ token ควรทำหลัง login แต่เรียกไว้ก็ไม่พัง (ถ้าไม่มี user มัน return)
    await PushService.instance.saveTokenForCurrentUser();
  } catch (e, st) {
    // ✅ อย่าปล่อยเงียบตอน debug จะได้รู้ว่าค้างเพราะอะไร
    debugPrint('Init services failed: $e');
    debugPrint('$st');
  }
}

/// =======================================================
/// 🔔 Local Notification Tap Handler
/// =======================================================
void _handleLocalNotificationTap(Map<String, String> data) {
  // รองรับทั้ง key แบบเก่า (collection) และแบบใหม่ (type)
  final collection = (data['collection'] ?? '').trim();
  final type = (data['type'] ?? '').trim();

  final state = navKey.currentState;
  if (state == null) return;

  // ไม่ต้อง addPostFrameCallback ซ้อนก็ได้ เพราะตอน tap app เปิดอยู่แล้ว
  if (collection == 'med_schedules' || type == 'med_schedule') {
    state.pushNamed(AppRoutes.dailyCare);
  } else {
    state.pushNamed(AppRoutes.notifications);
  }
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

  void _routeFromNotificationData(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString();
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
      case 'med_schedule':
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