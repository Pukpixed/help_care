import 'package:flutter/material.dart';
import 'local_notif_service.dart';

class MedNotifService {
  MedNotifService._();
  static final instance = MedNotifService._();

  /// แปลง "08:00" -> TimeOfDay
  TimeOfDay _toTimeOfDay(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// สร้าง schedule แจ้งเตือนรายวันตามเวลา
  Future<List<int>> scheduleForSchedule({
    required String docId,
    required String drug,
    required double dose,
    required String unit,
    required List<String> doseTimes, // ["08:00","12:00",...]
    String? mealTiming,
  }) async {
    final ids = <int>[];

    for (final t in doseTimes) {
      final time = _toTimeOfDay(t);

      // สร้าง id ไม่ซ้ำ
      final id = LocalNotifService.instance.buildNotifId(docId, time);

      ids.add(id);

      // จัดข้อความเรื่องอาหาร
      final mealText =
          (mealTiming == null ||
              mealTiming.isEmpty ||
              mealTiming == 'ไม่เกี่ยวกับอาหาร')
          ? ''
          : ' • $mealTiming';

      // ตั้งแจ้งเตือนรายวัน
      await LocalNotifService.instance.scheduleDailyAt(
        id: id,
        title: 'ถึงเวลาทานยา',
        body: '$drug $dose $unit • $t$mealText',
        time: time,
        payloadData: {'collection': 'med_schedules', 'docId': docId, 'time': t},
      );
    }

    return ids;
  }

  /// ยกเลิกแจ้งเตือนทั้งหมดของ schedule นี้
  Future<void> cancelSchedule({
    required String docId,
    required List<String> doseTimes,
  }) async {
    for (final t in doseTimes) {
      final time = _toTimeOfDay(t);
      final id = LocalNotifService.instance.buildNotifId(docId, time);

      await LocalNotifService.instance.cancel(id);
    }
  }
}
