import 'package:flutter/material.dart';
import 'local_notif_service.dart';

class MedNotifService {
  MedNotifService._();
  static final instance = MedNotifService._();

  TimeOfDay _toTimeOfDay(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

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
      final id = LocalNotifService.instance.buildNotifId(docId, t);
      ids.add(id);

      final mealText =
          (mealTiming == null ||
              mealTiming.isEmpty ||
              mealTiming == 'ไม่เกี่ยวกับอาหาร')
          ? ''
          : ' • $mealTiming';

      await LocalNotifService.instance.scheduleDailyAt(
        id: id,
        title: 'ถึงเวลาทานยา',
        body: '$drug $dose $unit • $t$mealText',
        time: _toTimeOfDay(t),
        payloadData: {'collection': 'med_schedules', 'docId': docId, 'time': t},
      );
    }

    return ids;
  }
}
