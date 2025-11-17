import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../color.dart';

// ──────────────────────────────────────────
// หมวดนัดหมาย (key, label, iconName, colorARGB)
// ──────────────────────────────────────────
class _ApptCat {
  final String key, label, icon;
  final int color;
  const _ApptCat(this.key, this.label, this.icon, this.color);

  IconData get iconData {
    switch (icon) {
      case 'local_hospital_outlined':
        return Icons.local_hospital_outlined;
      case 'vaccines_outlined':
        return Icons.vaccines_outlined;
      case 'psychology_alt_outlined':
        return Icons.psychology_alt_outlined;
      case 'elderly_woman_outlined':
        return Icons.elderly_woman_outlined;
      case 'event_note_outlined':
      default:
        return Icons.event_note_outlined;
    }
  }
}

const List<_ApptCat> _CATS = [
  _ApptCat('doctor',  'พบแพทย์',        'local_hospital_outlined', 0xFF1565C0),
  _ApptCat('drug',    'รับ/ฉีดยา',       'vaccines_outlined',        0xFF2E7D32),
  _ApptCat('therapy', 'กายภาพ/บำบัด',    'psychology_alt_outlined',  0xFF6A1B9A),
  _ApptCat('care',    'ดูแลผู้สูงวัย',    'elderly_woman_outlined',   0xFFEF6C00),
  _ApptCat('other',   'อื่น ๆ',          'event_note_outlined',      0xFF455A64),
];

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  String _two(int n) => n.toString().padLeft(2, '0');
  String _fmtRange(DateTime s, DateTime? e) {
    final d = '${s.day}/${s.month}/${s.year}';
    final sh = '${_two(s.hour)}:${_two(s.minute)}';
    final eh = e != null ? '${_two(e.hour)}:${_two(e.minute)}' : '';
    return e == null ? '$d  $sh' : '$d  $sh–$eh';
  }

  Future<void> _addAppointment(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final title = TextEditingController();
    final note  = TextEditingController();
    DateTime? date;
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    int durationMin = 30;
    _ApptCat selected = _CATS.first;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('สร้างนัดหมาย'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<_ApptCat>(
                  value: selected,
                  decoration: const InputDecoration(labelText: 'หมวดหมู่'),
                  items: _CATS.map((c) => DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Icon(c.iconData, color: Color(c.color)),
                        const SizedBox(width: 8),
                        Text(c.label),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) { if (v != null) setState(() => selected = v); },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'หัวข้อ', hintText: 'เช่น พบแพทย์, ฉีดยา, ตรวจตามนัด'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: note, maxLines: 2,
                  decoration: const InputDecoration(labelText: 'รายละเอียด (ถ้ามี)'),
                ),
                const SizedBox(height: 12),

                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.event_outlined),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: date ?? now,
                          firstDate: DateTime(now.year - 1),
                          lastDate: DateTime(now.year + 3),
                        );
                        if (picked != null) setState(() => date = picked);
                      },
                      label: Text(date == null
                          ? 'เลือกวันที่'
                          : '${date!.day}/${date!.month}/${date!.year}'),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),

                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.schedule_outlined),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: startTime ?? const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (picked != null) {
                          TimeOfDay? newEnd = endTime;
                          if (date != null) {
                            final s = DateTime(date!.year, date!.month, date!.day,
                                picked.hour, picked.minute);
                            final guess = s.add(Duration(minutes: durationMin));
                            newEnd ??= TimeOfDay(hour: guess.hour, minute: guess.minute);
                          }
                          setState(() { startTime = picked; endTime = newEnd; });
                        }
                      },
                      label: Text(startTime == null
                          ? 'เวลาเริ่ม'
                          : '${_two(startTime!.hour)}:${_two(startTime!.minute)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.more_time_outlined),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: endTime ??
                              TimeOfDay(
                                hour: (startTime?.hour ?? 9),
                                minute: (startTime?.minute ?? 0) + durationMin,
                              ),
                        );
                        if (picked != null) setState(() => endTime = picked);
                      },
                      label: Text(endTime == null
                          ? 'เวลาสิ้นสุด'
                          : '${_two(endTime!.hour)}:${_two(endTime!.minute)}'),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),

                Row(children: [
                  const Text('ความยาว', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: durationMin,
                    items: const [15, 30, 45, 60, 90, 120]
                        .map((m) => DropdownMenuItem(value: m, child: Text('$m นาที')))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        durationMin = v;
                        if (date != null && startTime != null) {
                          final s = DateTime(date!.year, date!.month, date!.day,
                              startTime!.hour, startTime!.minute);
                          final e = s.add(Duration(minutes: durationMin));
                          endTime = TimeOfDay(hour: e.hour, minute: e.minute);
                        }
                      });
                    },
                  ),
                ]),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () async {
                if (title.text.trim().isEmpty || date == null || startTime == null) return;

                final st = DateTime(date!.year, date!.month, date!.day,
                    startTime!.hour, startTime!.minute);
                DateTime et;
                if (endTime == null) {
                  et = st.add(Duration(minutes: durationMin));
                } else {
                  et = DateTime(date!.year, date!.month, date!.day,
                      endTime!.hour, endTime!.minute);
                }
                if (!et.isAfter(st)) et = st.add(const Duration(minutes: 15));

                await FirebaseFirestore.instance.collection('appointments').add({
                  'uid': FirebaseAuth.instance.currentUser!.uid,
                  'title': title.text.trim(),
                  'note':  note.text.trim(),
                  'startAt': Timestamp.fromDate(st),
                  'endAt'  : Timestamp.fromDate(et),
                  'durationMin': et.difference(st).inMinutes,
                  'catKey'  : selected.key,
                  'catLabel': selected.label,
                  'catIcon' : selected.icon,
                  'catColor': selected.color,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(String id) async {
    await FirebaseFirestore.instance.collection('appointments').doc(id).delete();
  }

  // เผื่อใช้ครั้งเดียว: migrate เอกสารเก่าที่มีแค่ dateTime → startAt
  Future<void> _migrateLegacyAppointments(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final col = FirebaseFirestore.instance.collection('appointments');
    final q = await col.where('uid', isEqualTo: uid).get();
    int updated = 0;
    for (final doc in q.docs) {
      final m = doc.data();
      final hasStartAt = m.containsKey('startAt');
      final legacy = m['dateTime'] as Timestamp?;
      if (!hasStartAt && legacy != null) {
        final start = legacy.toDate();
        final end   = (m['endAt'] as Timestamp?)?.toDate() ?? start.add(const Duration(minutes: 30));
        await doc.reference.update({
          'startAt': Timestamp.fromDate(start),
          'endAt'  : Timestamp.fromDate(end),
          'durationMin': end.difference(start).inMinutes,
        });
        updated++;
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัปเดตเอกสารเก่าแล้ว $updated รายการ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('กรุณาเข้าสู่ระบบ')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('นัดหมาย'),
        backgroundColor: AppColors.redDeep,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Migrate legacy',
            icon: const Icon(Icons.build_outlined),
            onPressed: () => _migrateLegacyAppointments(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addAppointment(context),
        backgroundColor: AppColors.redDeep,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('uid', isEqualTo: uid)
            .orderBy('startAt') // ← ใช้ Composite Index (uid↑, startAt↑)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('โหลดข้อมูลผิดพลาด\n${snap.error}', textAlign: TextAlign.center),
              ),
            );
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('ยังไม่มีนัดหมาย'));
          }

          IconData toIcon(String? name) {
            switch (name) {
              case 'local_hospital_outlined': return Icons.local_hospital_outlined;
              case 'vaccines_outlined'      : return Icons.vaccines_outlined;
              case 'psychology_alt_outlined': return Icons.psychology_alt_outlined;
              case 'elderly_woman_outlined' : return Icons.elderly_woman_outlined;
              default: return Icons.event_note_outlined;
            }
          }

          String two(int n) => n.toString().padLeft(2, '0');

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d   = docs[i].data();
              final id  = docs[i].id;
              final st  = (d['startAt'] as Timestamp?)?.toDate();
              final et  = (d['endAt']   as Timestamp?)?.toDate();
              final when = (st != null)
                  ? '${st.day}/${st.month}/${st.year}  ${two(st.hour)}:${two(st.minute)}' +
                    (et != null ? '–${two(et.hour)}:${two(et.minute)}' : '')
                  : '-';

              final catColor = (d['catColor'] as int?) ?? 0xFF455A64;
              final catIcon  = (d['catIcon']  as String?) ?? 'event_note_outlined';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(catColor).withOpacity(.12),
                  child: Icon(toIcon(catIcon), color: Color(catColor)),
                ),
                title: Text((d['title'] ?? '-') as String),
                subtitle: Text([
                  if (((d['note'] ?? '') as String).isNotEmpty) d['note'],
                  if (d['catLabel'] != null) 'หมวด: ${d['catLabel']}',
                  when,
                ].join('\n')),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
