// lib/screen/health_history_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HealthHistoryScreen extends StatelessWidget {
  final String patientId;
  const HealthHistoryScreen({super.key, required this.patientId});

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year + 543}';
  String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  // โทนสีอ่อนสุ่มจาก type ให้สวย ตาอ่านง่าย
  Color _softColorFor(String key) {
    final base = key.hashCode & 0xFFFFFF;
    final r = ((base >> 16) & 0xFF);
    final g = ((base >> 8) & 0xFF);
    final b = ((base) & 0xFF);
    // ผสมให้สว่างขึ้น
    return Color.fromARGB(
      255,
      ((r + 240) ~/ 2),
      ((g + 240) ~/ 2),
      ((b + 240) ~/ 2),
    );
  }

  IconData _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('ยา') || t.contains('med') || t.contains('dose')) {
      return Icons.medication_outlined;
    } else if (t.contains('น้ำ') ||
        t.contains('drink') ||
        t.contains('water')) {
      return Icons.local_drink_outlined;
    } else if (t.contains('อาหาร') ||
        t.contains('meal') ||
        t.contains('food')) {
      return Icons.set_meal_outlined;
    } else if (t.contains('นอน') || t.contains('sleep')) {
      return Icons.bedtime_outlined;
    } else if (t.contains('กายภาพ') ||
        t.contains('exercise') ||
        t.contains('walk')) {
      return Icons.fitness_center_outlined;
    } else if (t.contains('ขับถ่าย') ||
        t.contains('toilet') ||
        t.contains('wc')) {
      return Icons.wc_outlined;
    } else if (t.contains('ชีพ') ||
        t.contains('bp') ||
        t.contains('blood') ||
        t.contains('vital')) {
      return Icons.monitor_heart_outlined;
    }
    return Icons.event_note_outlined;
  }

  @override
  Widget build(BuildContext context) {
    // ไม่บังคับ composite index: ดึงเฉพาะของคนนี้แล้ว sort ฝั่ง client
    final q = FirebaseFirestore.instance
        .collection('care_logs')
        .where('patientId', isEqualTo: patientId)
        .limit(500);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FE),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: const Text('ประวัติสุขภาพย้อนหลัง'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (_, snap) {
          if (snap.hasError) {
            return const Center(child: Text('โหลดข้อมูลไม่สำเร็จ'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // copy + sort ใหม่ (ล่าสุดก่อน)
          final docs = [...snap.data!.docs];
          docs.sort((a, b) {
            final ta = (a.data()['time'] as Timestamp?);
            final tb = (b.data()['time'] as Timestamp?);
            final va = ta?.millisecondsSinceEpoch ?? 0;
            final vb = tb?.millisecondsSinceEpoch ?? 0;
            return vb.compareTo(va);
          });

          // group by dayKey = DateTime(yyyy,mm,dd)
          final Map<DateTime, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
          byDay = {};
          for (final d in docs) {
            final ts = (d['time'] as Timestamp?)?.toDate();
            if (ts == null) continue;
            final k = DateTime(ts.year, ts.month, ts.day);
            byDay.putIfAbsent(k, () => []).add(d);
          }

          if (byDay.isEmpty) {
            return const Center(child: Text('ยังไม่มีประวัติ'));
          }

          final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: days.length,
            itemBuilder: (_, i) {
              final day = days[i];
              final list = byDay[day]!;
              return _DayCard(
                title: _fmtDate(day),
                total: list.length,
                children: [
                  for (int idx = 0; idx < list.length; idx++)
                    _HistoryRow(
                      type: (list[idx]['type'] ?? '').toString(),
                      time: (list[idx]['time'] as Timestamp?)?.toDate(),
                      note: (list[idx]['note'] ?? '').toString(),
                      softColor: _softColorFor(
                        (list[idx]['type'] ?? '').toString(),
                      ),
                      icon: _iconForType((list[idx]['type'] ?? '').toString()),
                      isLast: idx == list.length - 1,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// การ์ด “วันที่” โค้งมน + เงา + Badge จำนวนรายการ
class _DayCard extends StatelessWidget {
  final String title;
  final int total;
  final List<Widget> children;
  const _DayCard({
    required this.title,
    required this.total,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF660F24),
                  const Color(0xFFF24455).withOpacity(.90),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(.35)),
                  ),
                  child: Text(
                    '$total รายการ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

/// แถวข้อมูลสวยๆ: ไอคอนในกรอบสีอ่อน + เวลาเด่น + โน้ต
class _HistoryRow extends StatelessWidget {
  final String type;
  final DateTime? time;
  final String note;
  final Color softColor;
  final IconData icon;
  final bool isLast;

  const _HistoryRow({
    required this.type,
    required this.time,
    required this.note,
    required this.softColor,
    required this.icon,
    required this.isLast,
  });

  String _fmtTime(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final timeText = time == null ? '-' : _fmtTime(time!);
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // ไอคอนในกรอบสีอ่อน
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: softColor.withOpacity(.6)),
            ),
            child: Icon(icon, color: Colors.black87),
          ),
          const SizedBox(width: 10),
          // เนื้อหา
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8ECF7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // บรรทัดแรก: ชนิด + เวลา
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          type.isEmpty ? 'ไม่ระบุชนิด' : type,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 16,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeText,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // โน้ต (ถ้ามี)
                  if (note.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      note,
                      style: const TextStyle(
                        color: Colors.black87,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
