import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/app_notify_service.dart';

class UserProfileUpdateScreen extends StatelessWidget {
  const UserProfileUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('อัปเดตโปรไฟล์')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final uid = FirebaseAuth.instance.currentUser!.uid;

            await FirebaseFirestore.instance.collection('users').doc(uid).set({
              'updatedAt': FieldValue.serverTimestamp(),
              'displayName': 'Updated Name',
            }, SetOptions(merge: true));

            await AppNotifyService.instance.notifyOnSave(
              title: 'อัปเดตโปรไฟล์สำเร็จ',
              body: 'บันทึกข้อมูลผู้ใช้แล้ว',
              data: {'collection': 'users', 'docId': uid},
            );

            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('บันทึก'),
        ),
      ),
    );
  }
}
