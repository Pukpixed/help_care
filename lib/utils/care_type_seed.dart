import 'package:cloud_firestore/cloud_firestore.dart';

/// เพิ่มชนิดกิจวัตรชุดเริ่มต้นให้กับ global หรือของผู้ป่วยรายคน
/// - ถ้า patientId = null  -> เขียนลง collection: care_types (global)
/// - ถ้า patientId != null -> เขียนลง patients/{patientId}/care_types
Future<void> seedDefaultCareTypes({String? patientId}) async {
  final db = FirebaseFirestore.instance;
  final col = (patientId != null && patientId.isNotEmpty)
      ? db.collection('patients').doc(patientId).collection('care_types')
      : db.collection('care_types');

  final now = FieldValue.serverTimestamp();

  final items = <Map<String, dynamic>>[
    {
      'key': 'eat_meal',
      'label': 'กินข้าว',
      'icon': 'set_meal_outlined',
      'color': 0xFFEF5350,
      'remind': false, 'hour': 8, 'minute': 0,
    },
    {
      'key': 'turn_position',
      'label': 'พลิกตัว',
      'icon': 'rotate_90_degrees_ccw_outlined',
      'color': 0xFF42A5F5,
      'remind': false, 'hour': 10, 'minute': 0,
    },
    {
      'key': 'toilet',
      'label': 'ขับถ่าย',
      'icon': 'wc_outlined',
      'color': 0xFF8D6E63,
      'remind': false, 'hour': 7, 'minute': 30,
    },
    {
      'key': 'physio',
      'label': 'กายภาพ',
      'icon': 'fitness_center_outlined',
      'color': 0xFF66BB6A,
      'remind': false, 'hour': 15, 'minute': 0,
    },
    {
      'key': 'communication',
      'label': 'การสื่อสาร',
      'icon': 'forum_outlined',
      'color': 0xFF7E57C2,
      'remind': false, 'hour': 18, 'minute': 0,
    },

    // — เพิ่มเติมที่นิยม — //
    {
      'key': 'drink_water',
      'label': 'ดื่มน้ำ',
      'icon': 'local_drink_outlined',
      'color': 0xFF26C6DA,
      'remind': false, 'hour': 9, 'minute': 0,
    },
    {
      'key': 'take_med',
      'label': 'ทานยา',
      'icon': 'medication_outlined',
      'color': 0xFFFFA726,
      'remind': false, 'hour': 8, 'minute': 0,
    },
  ];

  for (var i = 0; i < items.length; i++) {
    await col.add({
      ...items[i],
      'order': i,
      'createdAt': now,
      'updatedAt': now,
    });
  }
}
