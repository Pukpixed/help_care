// lib/screen/care_types_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../color.dart'; // ใช้ AppColors.redDeep (ถ้าไม่มีเปลี่ยนเป็นสีอื่นได้)

class CareTypesSettingsScreen extends StatefulWidget {
  final String patientId;
  const CareTypesSettingsScreen({super.key, required this.patientId});

  @override
  State<CareTypesSettingsScreen> createState() =>
      _CareTypesSettingsScreenState();
}

class _CareTypesSettingsScreenState extends State<CareTypesSettingsScreen> {
  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection('patients')
      .doc(widget.patientId)
      .collection('care_types');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 203, 203, 203),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF7B2D2D), // maroon
                Color(0xFFF24455), // red / pink
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'ตั้งค่าชนิดกิจวัตร',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: const [
          // ไอคอนจัดเรียง / ตัวเลือกอื่น ๆ (ไว้ต่อยอดทีหลังได้)
          Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.tune)),
          SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_care_type',
        onPressed: _showAddTypeDialog,
        backgroundColor: AppColors.redDeep,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มชนิดกิจวัตร'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _col.orderBy('order', descending: false).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs.toList()
            ..sort((a, b) {
              final ma = a.data();
              final mb = b.data();
              final ao = ma['order'] is int ? ma['order'] as int : 999999;
              final bo = mb['order'] is int ? mb['order'] as int : 999999;
              return ao.compareTo(bo);
            });

          if (docs.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemBuilder: (context, index) {
              final d = docs[index];
              final m = d.data();

              final label = (m['label'] ?? '').toString();
              final key = (m['key'] ?? '').toString();
              final iconName = (m['icon'] ?? '').toString();
              final colorInt = (m['color'] ?? 0xFF9E9E9E) as int;

              final enabled =
                  (m['notify'] ?? m['enabled'] ?? m['alarmEnabled'] ?? false) ==
                  true;

              final subtitle = _buildSubtitle(m, iconName);
              final remindText = _buildRemindText(m);

              return _CareTypeCard(
                color: Color(colorInt),
                title: label.isEmpty ? '(ไม่ระบุชื่อ)' : label,
                subtitle: subtitle,
                remindText: remindText,
                enabled: enabled,
                iconData: _iconFromName(iconName),
                onToggle: (v) => _updateNotify(d.reference, m, v),
                onEdit: () => _showEditTypeDialog(d),
                onDelete: () async {
                  final ok = await _confirmDelete(context, label);
                  if (ok) await d.reference.delete();
                },
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemCount: docs.length,
          );
        },
      ),
    );
  }

  // ---------- helpers ----------

  String _buildSubtitle(Map<String, dynamic> m, String iconName) {
    final key = (m['key'] ?? '').toString();
    final en = (m['en'] ?? '').toString();
    final parts = <String>[];
    if (en.isNotEmpty) parts.add(en);
    if (key.isNotEmpty) parts.add('key: $key');
    if (iconName.isNotEmpty) parts.add('icon: $iconName');
    return parts.join(' • ');
  }

  String _buildRemindText(Map<String, dynamic> m) {
    // พยายามใช้ฟิลด์ที่มีอยู่ให้ครอบคลุมหลายแบบ
    if (m['reminderText'] is String &&
        (m['reminderText'] as String).isNotEmpty) {
      return m['reminderText'] as String;
    }
    if (m['notifyText'] is String && (m['notifyText'] as String).isNotEmpty) {
      return m['notifyText'] as String;
    }
    if (m['notifyTime'] is String && (m['notifyTime'] as String).isNotEmpty) {
      return m['notifyTime'] as String;
    }

    final h = m['hour'];
    final mn = m['minute'];
    if (h is int && mn is int) {
      final hh = h.toString().padLeft(2, '0');
      final mm = mn.toString().padLeft(2, '0');
      return 'แจ้งเตือนทุกวัน $hh:$mm';
    }

    return 'ไม่ตั้งเวลาแจ้งเตือน';
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'restaurant_outlined':
        return Icons.restaurant_outlined;
      case 'local_drink_outlined':
        return Icons.local_drink_outlined;
      case 'medication_outlined':
        return Icons.medication_outlined;
      case 'rotate_90_degrees_ccw_outlined':
        return Icons.rotate_90_degrees_ccw_outlined;
      case 'wc_outlined':
        return Icons.wc_outlined;
      case 'fitness_center_outlined':
        return Icons.fitness_center_outlined;
      case 'healing_outlined':
        return Icons.healing_outlined;
      case 'monitor_heart_outlined':
        return Icons.monitor_heart_outlined;
      case 'shower_outlined':
        return Icons.shower_outlined;
      case 'bedtime_outlined':
        return Icons.bedtime_outlined;
      case 'bloodtype_outlined':
        return Icons.bloodtype_outlined;
      case 'vaccines_outlined':
        return Icons.vaccines_outlined;
      case 'masks_outlined':
        return Icons.masks_outlined;
      case 'child_friendly_outlined':
        return Icons.child_friendly_outlined;
      case 'cloud_outlined':
        return Icons.cloud_outlined;
      case 'set_meal_outlined':
        return Icons.set_meal_outlined;
      case 'chat_bubble_outline':
        return Icons.chat_bubble_outline;
      default:
        return Icons.widgets_outlined;
    }
  }

  Future<void> _updateNotify(
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> m,
    bool v,
  ) async {
    // อัปเดตฟิลด์ที่มีอยู่ ถ้าไม่มีจะใช้ 'notify'
    if (m.containsKey('notify')) {
      await ref.update({'notify': v});
    } else if (m.containsKey('enabled')) {
      await ref.update({'enabled': v});
    } else if (m.containsKey('alarmEnabled')) {
      await ref.update({'alarmEnabled': v});
    } else {
      await ref.update({'notify': v});
    }
  }

  Future<bool> _confirmDelete(BuildContext context, String label) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('ลบชนิดกิจวัตร'),
            content: Text('ต้องการลบ "$label" หรือไม่?'),
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
        ) ??
        false;
  }

  // ---------- Add / Edit dialogs ----------

  Future<void> _showAddTypeDialog() async {
    await _showEditDialogCore();
  }

  Future<void> _showEditTypeDialog(
    QueryDocumentSnapshot<Map<String, dynamic>> d,
  ) async {
    await _showEditDialogCore(doc: d);
  }

  Future<void> _showEditDialogCore({
    QueryDocumentSnapshot<Map<String, dynamic>>? doc,
  }) async {
    final editing = doc != null;
    final data = doc?.data() ?? {};
    final labelCtl = TextEditingController(
      text: (data['label'] ?? '').toString(),
    );
    final keyCtl = TextEditingController(text: (data['key'] ?? '').toString());
    final iconCtl = TextEditingController(
      text: (data['icon'] ?? '').toString(),
    );
    final colorCtl = TextEditingController(
      text: (data['color'] ?? 0xFF9E9E9E).toString(),
    );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(editing ? 'แก้ไขชนิดกิจวัตร' : 'เพิ่มชนิดกิจวัตร'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtl,
                decoration: const InputDecoration(labelText: 'ชื่อ (ภาษาไทย)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: keyCtl,
                decoration: const InputDecoration(
                  labelText: 'key (ตัวอักษรอังกฤษสั้น ๆ)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: iconCtl,
                decoration: const InputDecoration(
                  labelText: 'icon name (เช่น local_drink_outlined)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: colorCtl,
                decoration: const InputDecoration(
                  labelText: 'สี (int ARGB เช่น 0xFF2196F3)',
                ),
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
              final label = labelCtl.text.trim();
              final key = keyCtl.text.trim();
              final icon = iconCtl.text.trim().isEmpty
                  ? 'restaurant_outlined'
                  : iconCtl.text.trim();

              int color = 0xFF9E9E9E;
              try {
                color = int.parse(colorCtl.text.trim());
              } catch (_) {}

              if (label.isEmpty) return;

              if (editing) {
                await doc!.reference.update({
                  'label': label,
                  'key': key,
                  'icon': icon,
                  'color': color,
                });
              } else {
                // หา order สูงสุดแล้ว +1
                final snap = await _col.get();
                int maxOrder = 0;
                for (final d in snap.docs) {
                  final o = d['order'];
                  if (o is int && o > maxOrder) maxOrder = o;
                }

                await _col.add({
                  'label': label,
                  'key': key,
                  'icon': icon,
                  'color': color,
                  'order': maxOrder + 1,
                  'notify': false,
                });
              }

              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }
}

// ---------- UI widgets ----------

class _CareTypeCard extends StatelessWidget {
  final Color color;
  final String title;
  final String subtitle;
  final String remindText;
  final bool enabled;
  final IconData iconData;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CareTypeCard({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.remindText,
    required this.enabled,
    required this.iconData,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            // แถบสีด้านซ้าย
            Container(
              width: 6,
              height: 96,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 32,
                          width: 32,
                          decoration: BoxDecoration(
                            color: color.withOpacity(.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(iconData, color: color, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Switch(
                          value: enabled,
                          onChanged: onToggle,
                          activeColor: color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 14,
                          color: enabled ? color : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            remindText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: enabled
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'แก้ไข',
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  tooltip: 'ลบ',
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'ยังไม่มีการตั้งค่า “ชนิดกิจวัตร”',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'กดปุ่ม + ด้านล่างขวาเพื่อเพิ่มชนิดกิจวัตรใหม่',
              style: TextStyle(color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
