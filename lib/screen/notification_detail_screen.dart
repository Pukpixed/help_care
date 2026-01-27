import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/app_notification.dart';

class NotificationDetailScreen extends StatelessWidget {
  final String notificationId;
  const NotificationDetailScreen({super.key, required this.notificationId});

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId);

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดแจ้งเตือน')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: ref.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || !snap.data!.exists) {
            return const Center(child: Text('ไม่พบแจ้งเตือนนี้'));
          }

          final n = AppNotification.fromDoc(snap.data!);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(n.body, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                Text('สถานะ: ${n.status}'),
                const SizedBox(height: 8),
                Text('id: ${n.id}'),
                const SizedBox(height: 8),
                Text('data: ${n.data}'),
              ],
            ),
          );
        },
      ),
    );
  }
}
