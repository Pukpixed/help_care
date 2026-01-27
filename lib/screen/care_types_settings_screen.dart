// lib/screen/care_types_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../color.dart'; // ใช้ AppColors.redDeep (ถ้าไม่มีเปลี่ยนเป็นสีอื่นได้)

/// ✅ ต้องเป็น top-level (ห้ามประกาศ class ซ้อนใน State)
class _TimeHM {
  final int hour;
  final int minute;
  const _TimeHM(this.hour, this.minute);
}

/// ✅ Template ของ “ตัวอย่างกิจวัตร” + เวลาเริ่มต้น
class _CareTypeTemplate {
  final String id;
  final String label;
  final String key;
  final String icon;
  final int color; // ARGB
  final List<_TimeHM> defaultTimes;

  const _CareTypeTemplate({
    required this.id,
    required this.label,
    required this.key,
    required this.icon,
    required this.color,
    this.defaultTimes = const [],
  });
}

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

  // ✅ ตัวอย่างกิจวัตรประจำวัน (เพิ่ม/แก้ไขได้)
  // เพิ่มรายการใหม่: “เช็ดตัว”, “เปลี่ยนท่า”, “ให้อาหารทางสาย”
  static const List<_CareTypeTemplate> _templates = [
    _CareTypeTemplate(
      id: 'wipe',
      label: 'เช็ดตัว',
      key: 'wipe',
      icon: 'shower_outlined',
      color: 0xFF06B6D4,
      defaultTimes: [_TimeHM(9, 0)],
    ),
    _CareTypeTemplate(
      id: 'turn',
      label: 'เปลี่ยนท่า',
      key: 'turn',
      icon: 'rotate_90_degrees_ccw_outlined',
      color: 0xFF64748B,
      // ตัวอย่าง 4 เวลา/วัน (ปรับได้)
      defaultTimes: [
        _TimeHM(8, 0),
        _TimeHM(12, 0),
        _TimeHM(16, 0),
        _TimeHM(20, 0),
      ],
    ),
    _CareTypeTemplate(
      id: 'tube_feed',
      label: 'ให้อาหารทางสาย',
      key: 'tube_feed',
      icon: 'set_meal_outlined',
      color: 0xFFF59E0B,
      defaultTimes: [_TimeHM(6, 0), _TimeHM(12, 0), _TimeHM(18, 0)],
    ),

    // ตัวอย่างอื่น ๆ (ใส่ไว้เผื่อใช้)
    _CareTypeTemplate(
      id: 'meal',
      label: 'อาหาร',
      key: 'meal',
      icon: 'restaurant_outlined',
      color: 0xFFF59E0B,
      defaultTimes: [_TimeHM(8, 0), _TimeHM(12, 0), _TimeHM(18, 0)],
    ),
    _CareTypeTemplate(
      id: 'drink',
      label: 'ดื่มน้ำ',
      key: 'drink',
      icon: 'local_drink_outlined',
      color: 0xFF2196F3,
      defaultTimes: [_TimeHM(9, 0), _TimeHM(13, 0), _TimeHM(17, 0)],
    ),
    _CareTypeTemplate(
      id: 'med',
      label: 'ทานยา',
      key: 'med',
      icon: 'medication_outlined',
      color: 0xFF8B5CF6,
      // ✅ ค่าเริ่มต้น: 08:00 / 20:00
      defaultTimes: [_TimeHM(8, 0), _TimeHM(20, 0)],
    ),
  ];

  // ✅ format เวลา
  String _fmtHM(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  String _fmtTod(TimeOfDay t) => _fmtHM(t.hour, t.minute);

  // ✅ parse สีให้รองรับ: 0xFF2196F3 / #2196F3 / #FF2196F3 / เลขฐานสิบ
  int _parseColor(String input) {
    var s = input.trim();
    if (s.isEmpty) return 0xFF9E9E9E;

    if (s.startsWith('#')) {
      s = s.substring(1);
      if (s.length == 6) s = 'FF$s'; // เติม alpha
      return int.parse(s, radix: 16);
    }

    if (s.startsWith('0x') || s.startsWith('0X')) {
      return int.parse(s.substring(2), radix: 16);
    }

    return int.tryParse(s) ?? 0xFF9E9E9E;
  }

  // ✅ อ่านสีจาก Firestore แบบกันพัง (อาจเป็น num หรือ String)
  int _readColor(dynamic colorVal) {
    if (colorVal is num) return colorVal.toInt();
    if (colorVal is String) return _parseColor(colorVal);
    return 0xFF9E9E9E;
  }

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

          if (docs.isEmpty) return const _EmptyState();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemBuilder: (context, index) {
              final d = docs[index];
              final m = d.data();

              final label = (m['label'] ?? '').toString();
              final iconName = (m['icon'] ?? '').toString();

              final colorInt = _readColor(m['color']);
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
    // 1) ถ้ามี reminderText ให้ใช้ก่อน (รองรับแบบหลายเวลา)
    if (m['reminderText'] is String &&
        (m['reminderText'] as String).isNotEmpty) {
      return m['reminderText'] as String;
    }

    // 2) ถ้ามี notifyTimes (หลายเวลา)
    final nt = m['notifyTimes'];
    if (nt is List && nt.isNotEmpty) {
      final times = <String>[];
      for (final item in nt) {
        if (item is Map) {
          final t = item['time'];
          if (t is String && t.isNotEmpty) {
            times.add(t);
            continue;
          }
          final h = item['hour'];
          final mn = item['minute'];
          if (h is int && mn is int) times.add(_fmtHM(h, mn));
        }
      }
      if (times.isNotEmpty) return 'แจ้งเตือน ${times.join(', ')}';
    }

    // 3) fallback เดิม
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

  Future<void> _showAddTypeDialog() async => _showEditDialogCore();

  Future<void> _showEditTypeDialog(
    QueryDocumentSnapshot<Map<String, dynamic>> d,
  ) async => _showEditDialogCore(doc: d);

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

    final initColor = _readColor(data['color']);
    final colorCtl = TextEditingController(
      text: '0x${initColor.toRadixString(16).toUpperCase()}',
    );

    // ✅ อ่านเวลาเดิมจาก doc
    List<TimeOfDay> _readTimesFromData(Map<String, dynamic> m) {
      final out = <TimeOfDay>[];

      final nt = m['notifyTimes'];
      if (nt is List) {
        for (final item in nt) {
          if (item is Map) {
            final h = item['hour'];
            final mn = item['minute'];
            if (h is int && mn is int) out.add(TimeOfDay(hour: h, minute: mn));
          }
        }
      }

      final h = m['hour'];
      final mn = m['minute'];
      if (out.isEmpty && h is int && mn is int) {
        out.add(TimeOfDay(hour: h, minute: mn));
      }

      out.sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
      );
      return out;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        String? selectedTemplateId;
        int previewColor = _readColor(data['color']);

        List<TimeOfDay> times = _readTimesFromData(data);
        bool timesTouched = false;

        void dedupeAndSortTimes() {
          final map = <String, TimeOfDay>{};
          for (final t in times) {
            map['${t.hour}:${t.minute}'] = t;
          }
          times = map.values.toList()
            ..sort(
              (a, b) =>
                  (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
            );
        }

        void applyTemplate(_CareTypeTemplate t) {
          labelCtl.text = t.label;
          keyCtl.text = t.key;
          iconCtl.text = t.icon;
          colorCtl.text = '0x${t.color.toRadixString(16).toUpperCase()}';
          previewColor = t.color;

          times = t.defaultTimes
              .map((e) => TimeOfDay(hour: e.hour, minute: e.minute))
              .toList();
          dedupeAndSortTimes();
          timesTouched = true;
        }

        Future<void> pickTimeAndAdd(StateSetter setState) async {
          final picked = await showTimePicker(
            context: ctx,
            initialTime: times.isNotEmpty
                ? times.first
                : const TimeOfDay(hour: 8, minute: 0),
          );
          if (picked == null) return;
          setState(() {
            times.add(picked);
            dedupeAndSortTimes();
            timesTouched = true;
          });
        }

        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text(editing ? 'แก้ไขชนิดกิจวัตร' : 'เพิ่มชนิดกิจวัตร'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ เลือกตัวอย่างกิจวัตร
                  DropdownButtonFormField<String?>(
                    value: selectedTemplateId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'เลือกตัวอย่างกิจวัตรประจำวัน',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('— ไม่เลือก (กรอกเอง) —'),
                      ),
                      ..._templates.map(
                        (t) => DropdownMenuItem<String?>(
                          value: t.id,
                          child: Text(t.label),
                        ),
                      ),
                    ],
                    onChanged: (id) {
                      setState(() {
                        selectedTemplateId = id;
                        if (id == null) return;
                        final t = _templates.firstWhere((e) => e.id == id);
                        applyTemplate(t);
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  // ✅ preview สี+ไอคอน
                  Row(
                    children: [
                      Container(
                        height: 34,
                        width: 34,
                        decoration: BoxDecoration(
                          color: Color(previewColor).withOpacity(.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _iconFromName(iconCtl.text.trim()),
                          color: Color(previewColor),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          labelCtl.text.trim().isEmpty
                              ? '(ตัวอย่าง)'
                              : labelCtl.text.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: labelCtl,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อ (ภาษาไทย)',
                    ),
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
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: colorCtl,
                    decoration: const InputDecoration(
                      labelText: 'สี (0xFF2196F3 หรือ #2196F3 หรือ #FF2196F3)',
                    ),
                    onChanged: (_) => setState(() {
                      previewColor = _parseColor(colorCtl.text);
                    }),
                  ),

                  const SizedBox(height: 12),

                  // ✅ เวลาแจ้งเตือนเริ่มต้น (หลายเวลาได้)
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'เวลาแจ้งเตือนเริ่มต้น',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => pickTimeAndAdd(setState),
                        icon: const Icon(Icons.add_alarm, size: 18),
                        label: const Text('เพิ่มเวลา'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (times.isEmpty)
                    Text(
                      'ยังไม่ตั้งเวลา (เพิ่มเวลาได้)',
                      style: TextStyle(color: Colors.grey.shade700),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (int i = 0; i < times.length; i++)
                          Chip(
                            label: Text(_fmtTod(times[i])),
                            onDeleted: () {
                              setState(() {
                                times.removeAt(i);
                                timesTouched = true;
                              });
                            },
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
                  final label = labelCtl.text.trim();
                  final key = keyCtl.text.trim();
                  final icon = iconCtl.text.trim().isEmpty
                      ? 'restaurant_outlined'
                      : iconCtl.text.trim();
                  final color = _parseColor(colorCtl.text);

                  if (label.isEmpty) return;

                  // ✅ payload หลัก
                  final payload = <String, dynamic>{
                    'label': label,
                    'key': key,
                    'icon': icon,
                    'color': color,
                  };

                  // ✅ เวลาแจ้งเตือน: เซฟ hour/minute + notifyTime + notifyTimes + reminderText
                  if (times.isNotEmpty) {
                    times.sort(
                      (a, b) => (a.hour * 60 + a.minute).compareTo(
                        b.hour * 60 + b.minute,
                      ),
                    );

                    final first = times.first;
                    payload['hour'] = first.hour;
                    payload['minute'] = first.minute;
                    payload['notifyTime'] = _fmtTod(first);

                    if (times.length > 1) {
                      payload['notifyTimes'] = [
                        for (final t in times)
                          {
                            'hour': t.hour,
                            'minute': t.minute,
                            'time': _fmtTod(t),
                          },
                      ];
                      payload['reminderText'] =
                          'แจ้งเตือน ${times.map(_fmtTod).join(', ')}';
                    } else {
                      // ถ้าเหลือเวลาเดียว และผู้ใช้แก้เวลาเอง → เคลียร์ notifyTimes/reminderText เก่า
                      if (editing && timesTouched) {
                        payload['notifyTimes'] = FieldValue.delete();
                        payload['reminderText'] = FieldValue.delete();
                      }
                    }
                  } else {
                    // ถ้าผู้ใช้ลบเวลาจนหมด → ลบฟิลด์เวลา
                    if (editing && timesTouched) {
                      payload['hour'] = FieldValue.delete();
                      payload['minute'] = FieldValue.delete();
                      payload['notifyTime'] = FieldValue.delete();
                      payload['notifyTimes'] = FieldValue.delete();
                      payload['reminderText'] = FieldValue.delete();
                    }
                  }

                  if (editing) {
                    await doc!.reference.update(payload);
                  } else {
                    // หา max order
                    final snap = await _col.get();
                    int maxOrder = 0;
                    for (final d in snap.docs) {
                      final o = d['order'];
                      if (o is int && o > maxOrder) maxOrder = o;
                    }

                    await _col.add({
                      ...payload,
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
      },
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
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
