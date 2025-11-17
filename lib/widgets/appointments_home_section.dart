import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screen/appointments_screen.dart';

class AppointmentsHomeSection extends StatelessWidget {
  const AppointmentsHomeSection({super.key});

  String _two(int n) => n.toString().padLeft(2, '0');
  String _fmtRange(DateTime s, DateTime e) {
    final d = '${s.day}/${s.month}/${s.year}';
    final sh = '${_two(s.hour)}:${_two(s.minute)}';
    final eh = '${_two(e.hour)}:${_two(e.minute)}';
    return '$d  $sh–$eh';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final baseQuery = FirebaseFirestore.instance
        .collection('appointments')
        .where('uid', isEqualTo: uid)
        .where(
          'startAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
        );

    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.event_outlined),
                const SizedBox(width: 8),
                const Text(
                  'นัดหมาย',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AppointmentsScreen(),
                      ),
                    );
                  },
                  child: const Text('ดูทั้งหมด'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // สรุปจำนวนต่อหมวด
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: baseQuery.snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                final Map<String, (String label, int color, int count)> counts =
                    {};
                for (final d in docs) {
                  final m = d.data();
                  final key = (m['catKey'] as String?) ?? 'other';
                  final label = (m['catLabel'] as String?) ?? 'อื่น ๆ';
                  final color = (m['catColor'] as int?) ?? 0xFF455A64;
                  final cur = counts[key];
                  counts[key] = cur == null
                      ? (label, color, 1)
                      : (cur.$1, cur.$2, cur.$3 + 1);
                }

                if (counts.isEmpty) {
                  return const Text('— ยังไม่มีนัดหมายตั้งแต่วันนี้ —');
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: counts.entries.map((e) {
                      final label = e.value.$1;
                      final color = e.value.$2;
                      final count = e.value.$3;
                      return Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 8),
                        child: Chip(
                          backgroundColor: Color(color).withOpacity(0.12),
                          label: Text('$label  $count'),
                          avatar: CircleAvatar(
                            backgroundColor: Color(color),
                            radius: 10,
                            child: const SizedBox.shrink(),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // 3 นัดถัดไป
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: baseQuery.orderBy('startAt').limit(3).snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const SizedBox(height: 4);

                return Column(
                  children: docs.map((doc) {
                    final m = doc.data();
                    final start = (m['startAt'] as Timestamp?)?.toDate();
                    final end = (m['endAt'] as Timestamp?)?.toDate();
                    final title = (m['title'] as String?) ?? '-';
                    final catLabel = (m['catLabel'] as String?) ?? 'อื่น ๆ';
                    final catColor = (m['catColor'] as int?) ?? 0xFF455A64;

                    final when = (start != null && end != null)
                        ? _fmtRange(start, end)
                        : (start != null
                              ? '${start.day}/${start.month}/${start.year} ${_two(start.hour)}:${_two(start.minute)}'
                              : '-');

                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Color(catColor).withOpacity(0.12),
                        child: Icon(
                          Icons.event_note_outlined,
                          color: Color(catColor),
                        ),
                      ),
                      title: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('$catLabel • $when'),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
