import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String targetUid;
  final String title;
  final String body;
  final String status;
  final Timestamp? createdAt;
  final Map<String, dynamic> data;

  AppNotification({
    required this.id,
    required this.targetUid,
    required this.title,
    required this.body,
    required this.status,
    required this.createdAt,
    required this.data,
  });

  factory AppNotification.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>? ?? {});
    return AppNotification(
      id: doc.id,
      targetUid: (d['targetUid'] ?? '').toString(),
      title: (d['title'] ?? '').toString(),
      body: (d['body'] ?? '').toString(),
      status: (d['status'] ?? '').toString(),
      createdAt: d['createdAt'] as Timestamp?,
      data: (d['data'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
    );
  }
}
