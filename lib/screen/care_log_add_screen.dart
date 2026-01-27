import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/app_notify_service.dart';

class CareLogAddScreen extends StatelessWidget {
  final String patientId;

  const CareLogAddScreen({super.key, required this.patientId});

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('patients')
      .doc(patientId)
      .collection('care_logs');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('บันทึก Care Log')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final ref = await _col.add({
              'patientId': patientId, // ✅ แนะนำให้เก็บไว้
              'type': 'note', // ✅ ปรับให้ตรง key ใน care_types ของคุณได้
              'note': 'บันทึกตัวอย่าง',
              'time':
                  FieldValue.serverTimestamp(), // ✅ สำคัญ (ใช้ query ช่วงเวลา)
              'createdAt': FieldValue.serverTimestamp(),
            });

            await AppNotifyService.instance.notifyOnSave(
              title: 'บันทึก Care Log สำเร็จ',
              body: 'เลขที่: ${ref.id}',
              data: {
                'collection': 'patients/$patientId/care_logs',
                'docId': ref.id,
                'patientId': patientId,
              },
            );

            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('บันทึก'),
        ),
      ),
    );
  }
}
