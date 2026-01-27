import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/app_notify_service.dart';

class AppointmentAddScreen extends StatelessWidget {
  const AppointmentAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เพิ่มนัดหมาย')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final ref = await FirebaseFirestore.instance
                .collection('appointments')
                .add({
                  'title': 'นัดหมายตัวอย่าง',
                  'createdAt': FieldValue.serverTimestamp(),
                });

            await AppNotifyService.instance.notifyOnSave(
              title: 'บันทึกนัดหมายสำเร็จ',
              body: 'สร้างนัดหมาย: ${ref.id}',
              type: 'notification',
              data: {'collection': 'appointments', 'docId': ref.id},
            );

            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('บันทึก'),
        ),
      ),
    );
  }
}
