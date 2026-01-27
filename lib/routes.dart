import 'package:flutter/material.dart';

import 'screen/first_screen.dart';
import 'screen/auth_screen.dart';
import 'screen/home_screen.dart';
import 'screen/settings_screen.dart';
import 'screen/editprofile_screen.dart';
import 'screen/patients_screen.dart';

import 'screen/care_log_screen.dart';
import 'screen/care_dashboard_screen.dart';
import 'screen/sos_screen.dart';

import 'screen/notifications_screen.dart';
import 'screen/notification_detail_screen.dart';

// ✅ หน้าข่าวสารการดูแล
import 'screen/care_news_screen.dart';

// ✅ หน้าบันทึก/เพิ่มข้อมูล
import 'screen/appointment_add_screen.dart';
import 'screen/care_log_add_screen.dart';
import 'screen/patient_add_screen.dart';
import 'screen/user_profile_update_screen.dart';

// ✅ หน้าดูตารางยา (รายการ)
import 'screen/med_schedule_list_screen.dart';

class AppRoutes {
  static const String first = '/';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';
  static const String patients = '/patients';

  // ✅ เดิมใช้ชื่อ dailyCare แต่ให้ชี้ไปหน้าตารางยาแทน
  static const String dailyCare = '/daily-care';

  static const String careLog = '/care-log';
  static const String careDashboard = '/care-dashboard';
  static const String sos = '/sos';

  // ✅ ข่าวสารการดูแล
  static const String careNews = '/care-news';

  static const String notifications = '/notifications';
  static const String notificationDetail = '/notification-detail';

  // ✅ เพิ่มข้อมูล
  static const String addAppointment = '/add-appointment';
  static const String addCareLog = '/add-carelog';
  static const String addPatient = '/add-patient';
  static const String updateProfile = '/update-profile';

  // ✅ route ชื่อใหม่ของหน้าตารางยา
  static const String medScheduleList = '/med-schedule-list';

  static Route<dynamic> onGenerateRoute(RouteSettings rs) {
    switch (rs.name) {
      case first:
        return MaterialPageRoute(builder: (_) => const FirstScreen());

      case auth:
        return MaterialPageRoute(builder: (_) => const AuthScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      case patients:
        return MaterialPageRoute(builder: (_) => const PatientsScreen());

      // ✅ เปลี่ยนจาก DailyCareScreen -> MedScheduleListScreen
      case dailyCare:
        return MaterialPageRoute(builder: (_) => const MedScheduleListScreen());

      case medScheduleList:
        return MaterialPageRoute(builder: (_) => const MedScheduleListScreen());

      case sos:
        return MaterialPageRoute(builder: (_) => const SosScreen());

      case careNews:
        return MaterialPageRoute(builder: (_) => const CareNewsScreen());

      case careLog:
        {
          final args = rs.arguments as Map<String, dynamic>?;
          final patientId = args?['patientId'] as String?;
          if (patientId == null || patientId.isEmpty) {
            return _error('careLog ต้องมี patientId');
          }
          return MaterialPageRoute(
            builder: (_) => CareLogScreen(patientId: patientId),
          );
        }

      case careDashboard:
        {
          final args = rs.arguments as Map<String, dynamic>?;
          final patientId = args?['patientId'] as String?;
          if (patientId == null || patientId.isEmpty) {
            return _error('careDashboard ต้องมี patientId');
          }
          return MaterialPageRoute(
            builder: (_) => CareDashboardScreen(patientId: patientId),
          );
        }

      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case notificationDetail:
        {
          final args = rs.arguments as Map<String, dynamic>?;
          final id = args?['notificationId'] as String?;
          if (id == null || id.isEmpty) {
            return _error('notificationDetail ต้องมี notificationId');
          }
          return MaterialPageRoute(
            builder: (_) => NotificationDetailScreen(notificationId: id),
          );
        }

      case addAppointment:
        return MaterialPageRoute(builder: (_) => const AppointmentAddScreen());

      // ✅ สำคัญ: Add care log ต้องส่ง patientId
      case addCareLog:
        {
          final args = rs.arguments as Map<String, dynamic>?;
          final patientId = args?['patientId'] as String?;
          if (patientId == null || patientId.isEmpty) {
            return _error('addCareLog ต้องมี patientId');
          }
          return MaterialPageRoute(
            builder: (_) => CareLogAddScreen(patientId: patientId),
          );
        }

      case addPatient:
        return MaterialPageRoute(builder: (_) => const PatientAddScreen());

      case updateProfile:
        return MaterialPageRoute(
          builder: (_) => const UserProfileUpdateScreen(),
        );

      default:
        return _error('ไม่พบหน้า: ${rs.name}');
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
