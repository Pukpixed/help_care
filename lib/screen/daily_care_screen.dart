import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyCareScreen extends StatefulWidget {
  const DailyCareScreen({super.key});

  @override
  State<DailyCareScreen> createState() => _DailyCareScreenState();
}

class _DailyCareScreenState extends State<DailyCareScreen> {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('med_schedules');

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ---------- Utils ----------
  String _fmtTime(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  Future<void> _addOrEdit({DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    final isEdit = doc != null;
    final data = doc?.data();

    final title = TextEditingController(
      text: (data?['title'] ?? '').toString(),
    );
    final dose = TextEditingController(text: (data?['dose'] ?? '').toString());

    int hour = (data?['hour'] is int) ? data!['hour'] as int : 9;
    int minute = (data?['minute'] is int) ? data!['minute'] as int : 0;
    bool enabled = (data?['enabled'] is bool) ? data!['enabled'] as bool : true;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(isEdit ? 'แก้ไขการให้ยา' : 'เพิ่มการให้ยา'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อยา / รายการ',
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dose,
                  decoration: const InputDecoration(
                    labelText: 'ขนาดยา / หมายเหตุ (เช่น 1 เม็ด หลังอาหาร)',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text('เวลา  ${_fmtTime(hour, minute)}'),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay(hour: hour, minute: minute),
                          );
                          if (picked != null) {
                            setState(() {
                              hour = picked.hour;
                              minute = picked.minute;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Text('เปิดใช้งาน'),
                        Switch(
                          value: enabled,
                          onChanged: (v) => setState(() => enabled = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () async {
                if (_uid == null || title.text.trim().isEmpty) return;

                final payload = <String, dynamic>{
                  'uid': _uid,
                  'title': title.text.trim(),
                  'dose': dose.text.trim(),
                  'hour': hour,
                  'minute': minute,
                  'enabled': enabled,
                  'updatedAt': FieldValue.serverTimestamp(),
                  if (!isEdit) 'createdAt': FieldValue.serverTimestamp(),
                };

                if (isEdit) {
                  await doc!.reference.update(payload);
                } else {
                  await _col.add(payload);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'บันทึก' : 'เพิ่ม'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(
    DocumentSnapshot<Map<String, dynamic>> doc,
    bool value,
  ) async {
    await doc.reference.update({'enabled': value});
  }

  Future<void> _delete(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบรายการนี้?'),
        content: Text((doc['title'] ?? '').toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (ok == true) await doc.reference.delete();
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FE),
      appBar: AppBar(
        title: const Text('ตารางการให้ยา'),
        backgroundColor: const Color.fromARGB(255, 96, 7, 16),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่ม'),
        backgroundColor: const Color.fromARGB(255, 115, 9, 20),
      ),
      body: _uid == null
          ? const Center(child: Text('กรุณาเข้าสู่ระบบ'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              // ทางเลือก A: ไม่ใช้ orderBy แล้ว sort ฝั่ง client
              stream: _col.where('uid', isEqualTo: _uid).limit(500).snapshots(),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return const Center(
                    child: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล'),
                  );
                }

                // เรียงตาม hour -> minute ฝั่ง client
                final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [
                  ...(snap.data?.docs ?? const []),
                ];
                docs.sort((a, b) {
                  final ah = (a.data()['hour'] ?? 0) as int;
                  final bh = (b.data()['hour'] ?? 0) as int;
                  if (ah != bh) return ah.compareTo(bh);
                  final am = (a.data()['minute'] ?? 0) as int;
                  final bm = (b.data()['minute'] ?? 0) as int;
                  return am.compareTo(bm);
                });

                if (docs.isEmpty) {
                  return _EmptyState(onAdd: _addOrEdit);
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final data = d.data();

                    final title = (data['title'] ?? '').toString();
                    final dose = (data['dose'] ?? '').toString();
                    final hour = (data['hour'] is int)
                        ? data['hour'] as int
                        : 0;
                    final minute = (data['minute'] is int)
                        ? data['minute'] as int
                        : 0;
                    final enabled = (data['enabled'] is bool)
                        ? data['enabled'] as bool
                        : true;

                    return Dismissible(
                      key: ValueKey(d.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 98, 16, 16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (_) async {
                        await _delete(d);
                        return false; // ให้ _delete เป็นคนลบ
                      },
                      child: _MedCard(
                        title: title,
                        subtitle: dose.isEmpty
                            ? 'เวลา: ${_fmtTime(hour, minute)}'
                            : 'เวลา: ${_fmtTime(hour, minute)} • $dose',
                        enabled: enabled,
                        onToggle: (v) => _toggle(d, v),
                        onTap: () => _addOrEdit(doc: d),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _MedCard extends StatelessWidget {
  const _MedCard({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onToggle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2.5,
      shadowColor: Colors.black.withOpacity(.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // ไอคอนยาในกล่องสี
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: Color.fromARGB(255, 105, 8, 18),
                ),
              ),
              const SizedBox(width: 12),

              // ข้อความ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? '(ไม่ระบุชื่อยา)' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black.withOpacity(.60),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // สวิตช์เปิด/ปิด
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeColor: const Color.fromARGB(255, 150, 10, 24),
              ),

              const SizedBox(width: 4),

              // ปุ่มแก้ไข
              IconButton(
                tooltip: 'แก้ไข',
                visualDensity: const VisualDensity(
                  horizontal: -3,
                  vertical: -3,
                ),
                onPressed: onTap,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEF0),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.05),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.medication_outlined,
                color: Color.fromARGB(255, 139, 13, 26),
                size: 42,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ยังไม่มีตารางการให้ยา',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'เพิ่มรายการและตั้งเวลาเตือนการให้ยาได้ที่ปุ่ม “เพิ่ม” ด้านล่างขวา',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black.withOpacity(.65)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มรายการแรก'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
