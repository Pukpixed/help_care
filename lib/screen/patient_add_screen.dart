import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/app_notify_service.dart';

class PatientAddScreen extends StatelessWidget {
  const PatientAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มผู้ป่วย')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final ref = await FirebaseFirestore.instance
                .collection('patients')
                .add({
                  'name': 'ผู้ป่วยตัวอย่าง',
                  'createdAt': FieldValue.serverTimestamp(),
                });

            await AppNotifyService.instance.notifyOnSave(
              title: 'เพิ่มผู้ป่วยสำเร็จ',
              body: 'เลขที่: ${ref.id}',
              data: {'collection': 'patients', 'docId': ref.id},
            );

            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('บันทึก'),
        ),
      ),
    );
  }
}
