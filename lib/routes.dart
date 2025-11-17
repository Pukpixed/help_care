// lib/routes.dart
import 'package:flutter/material.dart';

// ─── Screens หลัก ─────────────────────────────────────────────────────────
import 'screen/first_screen.dart';
import 'screen/auth_screen.dart';
import 'screen/home_screen.dart';
import 'screen/settings_screen.dart';
import 'screen/editprofile_screen.dart';
import 'screen/patients_screen.dart';

// ─── ฟีเจอร์กิจวัตร/ยา ───────────────────────────────────────────────────
import 'screen/daily_care_screen.dart';
import 'screen/care_log_screen.dart';
import 'screen/care_dashboard_screen.dart';

// ─── SOS ──────────────────────────────────────────────────────────────────
import 'screen/sos_screen.dart';

class AppRoutes {
  static const String first = '/';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';
  static const String patients = '/patients';

  static const String dailyCare = '/daily-care';
  static const String careLog = '/care-log';
  static const String careDashboard = '/care-dashboard';

  static const String sos = '/sos';

  // ❗ เปลี่ยนชื่อพารามิเตอร์เป็น routeSettings แทนคำว่า settings
  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case first:
        return MaterialPageRoute(builder: (_) => FirstScreen());
      case auth:
        return MaterialPageRoute(builder: (_) => AuthScreen());
      case home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case settings:
        return MaterialPageRoute(builder: (_) => SettingsScreen());
      case editProfile:
        return MaterialPageRoute(builder: (_) => EditProfileScreen());
      case patients:
        return MaterialPageRoute(builder: (_) => PatientsScreen());
      case dailyCare:
        return MaterialPageRoute(builder: (_) => DailyCareScreen());
      case careLog:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        final patientId = args?['patientId'] as String?;
        if (patientId == null) return _error('care_log ต้องมี patientId');
        return MaterialPageRoute(
          builder: (_) => CareLogScreen(patientId: patientId),
        );
      case careDashboard:
        final args = routeSettings.arguments as Map<String, dynamic>?;
        final patientId = args?['patientId'] as String?;
        if (patientId == null) return _error('dashboard ต้องมี patientId');
        return MaterialPageRoute(
          builder: (_) => CareDashboardScreen(patientId: patientId),
        );
      case sos:
        return MaterialPageRoute(builder: (_) => SosScreen());
      default:
        return _error('ไม่พบหน้า: ${routeSettings.name}');
    }
  }

  static Route<dynamic> _error(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('เกิดข้อผิดพลาด')),
        body: Center(child: Text(message)),
      ),
    );
  }
}
