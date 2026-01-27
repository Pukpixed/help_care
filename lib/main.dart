import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'routes.dart';

// ✅ เพิ่มระบบแจ้งเตือน
import 'services/local_notif_service.dart';
import 'services/push_service.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ init Local Notifications + handle tap
  await LocalNotifService.instance.init(
    onTap: (data) {
      final collection = (data['collection'] ?? '').toString();
      final docId = (data['docId'] ?? '').toString();

      // ✅ ถ้าเป็นตารางยา -> ไปหน้า “ตารางการให้ยา”
      if (collection == 'med_schedules') {
        _safePushNamedStatic(AppRoutes.dailyCare); // ✅ ใช้ตัวเดียวพอ
        // ถ้ามีหน้ารายละเอียดค่อยส่ง docId ไปภายหลัง
        // if (docId.isNotEmpty) { ... }
        return;
      }

      // fallback
      _safePushNamedStatic(AppRoutes.notifications);
    },
  );

  await LocalNotifService.instance.requestAndroid13PermissionIfNeeded();

  // ✅ init Push
  await PushService.instance.init();
  await PushService.instance.saveTokenForCurrentUser();

  runApp(const MyApp());
}

// ✅ helper แบบ static ใช้ใน main() ได้
void _safePushNamedStatic(String route, {Object? arguments}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final st = navKey.currentState;
    if (st == null) return;
    st.pushNamed(route, arguments: arguments);
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    PushService.instance.onNotificationTap(_routeFromNotificationData);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PushService.instance.handleInitialMessage(
        _routeFromNotificationData,
      );
    });
  }

  void _safePushNamed(String route, {Object? arguments}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final st = navKey.currentState;
      if (st == null) return;
      st.pushNamed(route, arguments: arguments);
    });
  }

  void _routeFromNotificationData(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString();

    if (type.isEmpty) {
      _safePushNamed(AppRoutes.notifications);
      return;
    }

    if (type == 'sos') {
      _safePushNamed(AppRoutes.sos);
      return;
    }

    if (type == 'careLog') {
      final patientId = (data['patientId'] ?? '').toString();
      if (patientId.isEmpty) {
        _safePushNamed(AppRoutes.home);
        return;
      }
      _safePushNamed(AppRoutes.careLog, arguments: {'patientId': patientId});
      return;
    }

    // ✅ เปลี่ยน: dailyCare / medSchedule ใช้ route เดียว
    if (type == 'dailyCare' || type == 'medSchedule') {
      _safePushNamed(AppRoutes.dailyCare);
      return;
    }

    if (type == 'notification') {
      final nid = (data['notificationId'] ?? '').toString();
      if (nid.isNotEmpty) {
        _safePushNamed(
          AppRoutes.notificationDetail,
          arguments: {'notificationId': nid},
        );
      } else {
        _safePushNamed(AppRoutes.notifications);
      }
      return;
    }

    _safePushNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navKey,
      title: 'helpcare',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.purple),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.first,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
