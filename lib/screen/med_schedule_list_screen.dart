// lib/screen/med_schedule_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// -----------------------------
/// ✅ Presets (ตัวอย่างยา) + หมวดหมู่
/// -----------------------------
class MedPreset {
  final String category; // ✅ หมวด
  final String title; // ชื่อยา/รายการ
  final String dose; // ขนาดยา/วิธีใช้ (ตัวอย่าง)
  final String note; // หมายเหตุ
  final String meal; // none / before / after / with
  final int hour;
  final int minute;
  final List<int> days; // [] = ทุกวัน
  final IconData icon;

  const MedPreset({
    required this.category,
    required this.title,
    required this.dose,
    this.note = '',
    this.meal = 'none',
    this.hour = 9,
    this.minute = 0,
    this.days = const [],
    this.icon = Icons.medication_outlined,
  });
}

/// ✅ หมวดทั้งหมด (ใช้กับตัวกรอง)
const List<String> kPresetCategories = [
  'ทั้งหมด',
  'แก้ปวด/ไข้',
  'ความดัน',
  'เบาหวาน',
  'ไขมัน',
  'หัวใจ',
  'กระเพาะ/กรดไหลย้อน',
  'วิตามิน/เสริม',
  'แก้แพ้',
  'นอนหลับ',
  'อื่นๆ',
];

/// ✅ ตัวอย่างยาเบื้องต้น (เพิ่ม/แก้ได้ตามต้องการ)
/// หมายเหตุ: เป็น “ตัวอย่าง” ผู้ใช้แก้ไขได้ก่อนบันทึก
const List<MedPreset> kMedPresets = [
  // แก้ปวด/ไข้
  MedPreset(
    category: 'แก้ปวด/ไข้',
    title: 'พาราเซตามอล (Paracetamol)',
    dose: '1 เม็ด เมื่อมีอาการปวด/ไข้',
    meal: 'after',
    hour: 9,
    minute: 0,
    icon: Icons.local_fire_department_outlined,
  ),
  MedPreset(
    category: 'แก้ปวด/ไข้',
    title: 'ยาคลายกล้ามเนื้อ (ตัวอย่าง)',
    dose: '1 เม็ด หลังอาหาร',
    meal: 'after',
    hour: 20,
    minute: 0,
    icon: Icons.fitness_center_outlined,
  ),

  // ความดัน
  MedPreset(
    category: 'ความดัน',
    title: 'ยาลดความดัน (ตัวอย่าง)',
    dose: '1 เม็ด หลังอาหารเช้า',
    meal: 'after',
    hour: 8,
    minute: 30,
    icon: Icons.monitor_heart_outlined,
  ),
  MedPreset(
    category: 'ความดัน',
    title: 'ยาขับปัสสาวะ (ตัวอย่าง)',
    dose: '1 เม็ด ตอนเช้า',
    meal: 'none',
    hour: 7,
    minute: 30,
    icon: Icons.water_drop_outlined,
  ),

  // เบาหวาน
  MedPreset(
    category: 'เบาหวาน',
    title: 'ยาเบาหวาน (ตัวอย่าง)',
    dose: '1 เม็ด ก่อนอาหารเช้า',
    meal: 'before',
    hour: 7,
    minute: 30,
    icon: Icons.bloodtype_outlined,
  ),
  MedPreset(
    category: 'เบาหวาน',
    title: 'ยาเบาหวาน (ตัวอย่าง) มื้อเย็น',
    dose: '1 เม็ด ก่อนอาหารเย็น',
    meal: 'before',
    hour: 17,
    minute: 30,
    icon: Icons.bloodtype_outlined,
  ),

  // ไขมัน
  MedPreset(
    category: 'ไขมัน',
    title: 'ยาลดไขมัน (ตัวอย่าง)',
    dose: '1 เม็ด ก่อนนอน',
    meal: 'none',
    hour: 21,
    minute: 0,
    icon: Icons.shield_outlined,
  ),

  // หัวใจ
  MedPreset(
    category: 'หัวใจ',
    title: 'ยาหัวใจ (ตัวอย่าง)',
    dose: '1 เม็ด หลังอาหารเช้า',
    meal: 'after',
    hour: 8,
    minute: 0,
    icon: Icons.favorite_border,
  ),

  // กระเพาะ/กรดไหลย้อน
  MedPreset(
    category: 'กระเพาะ/กรดไหลย้อน',
    title: 'ยาลดกรด/กระเพาะ (ตัวอย่าง)',
    dose: '1 เม็ด ก่อนอาหารเช้า',
    meal: 'before',
    hour: 7,
    minute: 0,
    icon: Icons.spa_outlined,
  ),

  // วิตามิน/เสริม
  MedPreset(
    category: 'วิตามิน/เสริม',
    title: 'วิตามินบีรวม',
    dose: '1 เม็ด หลังอาหารเช้า',
    meal: 'after',
    hour: 8,
    minute: 0,
    icon: Icons.auto_awesome_outlined,
  ),
  MedPreset(
    category: 'วิตามิน/เสริม',
    title: 'แคลเซียม (ตัวอย่าง)',
    dose: '1 เม็ด หลังอาหารเย็น',
    meal: 'after',
    hour: 18,
    minute: 30,
    icon: Icons.brightness_5_outlined,
  ),

  // แก้แพ้
  MedPreset(
    category: 'แก้แพ้',
    title: 'ยาแก้แพ้ (ตัวอย่าง)',
    dose: '1 เม็ด ก่อนนอน',
    meal: 'none',
    hour: 21,
    minute: 0,
    icon: Icons.air_outlined,
  ),

  // นอนหลับ
  MedPreset(
    category: 'นอนหลับ',
    title: 'ยาช่วยนอนหลับ (ตัวอย่าง)',
    dose: '1 เม็ด ก่อนนอน',
    meal: 'none',
    hour: 22,
    minute: 0,
    icon: Icons.nightlight_outlined,
  ),

  // อื่นๆ
  MedPreset(
    category: 'อื่นๆ',
    title: 'ยาหยอดตา (ตัวอย่าง)',
    dose: 'หยอดวันละ 2 ครั้ง',
    meal: 'none',
    hour: 9,
    minute: 0,
    icon: Icons.remove_red_eye_outlined,
  ),
];

class MedScheduleListScreen extends StatefulWidget {
  const MedScheduleListScreen({super.key});

  @override
  State<MedScheduleListScreen> createState() => _MedScheduleListScreenState();
}

class _MedScheduleListScreenState extends State<MedScheduleListScreen> {
  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('med_schedules');

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ---- theme ----
  static const Color _bg = Color(0xFFF6F8FE);
  static const Color _wine = Color(0xFF660F24);
  static const Color _wine2 = Color(0xFF8C1734);
  static const Color _soft = Color(0xFFFFEEF0);

  String _q = '';

  // ---- utils ----
  String _fmtTime(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  int _safeInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  bool _safeBool(dynamic v, bool fallback) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  String _safeStr(dynamic v) => (v ?? '').toString().trim();

  List<int> _safeDays(dynamic v) {
    if (v is List) {
      return v
          .map((e) => _safeInt(e, -1))
          .where((x) => x >= 1 && x <= 7)
          .toSet()
          .toList()
        ..sort();
    }
    return const <int>[];
  }

  String _dayLabel(int d) {
    switch (d) {
      case 1:
        return 'จ';
      case 2:
        return 'อ';
      case 3:
        return 'พ';
      case 4:
        return 'พฤ';
      case 5:
        return 'ศ';
      case 6:
        return 'ส';
      case 7:
        return 'อา';
      default:
        return '?';
    }
  }

  String _mealLabel(String meal) {
    switch (meal) {
      case 'before':
        return 'ก่อนอาหาร';
      case 'after':
        return 'หลังอาหาร';
      case 'with':
        return 'พร้อมอาหาร';
      case 'none':
      default:
        return 'ไม่ระบุ';
    }
  }

  Color _mealColor(String meal) {
    switch (meal) {
      case 'before':
        return const Color(0xFFE8F0FF);
      case 'after':
        return const Color(0xFFE8FFF3);
      case 'with':
        return const Color(0xFFFFF4EE);
      default:
        return const Color(0xFFF7F8FD);
    }
  }

  /// -----------------------------
  /// ✅ Picker: เลือกจากตัวอย่างยา (แยกหมวด + ค้นหา)
  /// -----------------------------
  Future<MedPreset?> _pickPreset(BuildContext context) async {
    final searchCtl = TextEditingController();
    String selectedCat = 'ทั้งหมด';

    List<MedPreset> filterList(String q, String cat) {
      final qq = q.trim().toLowerCase();
      return kMedPresets.where((p) {
        final okCat = (cat == 'ทั้งหมด') ? true : p.category == cat;
        if (!okCat) return false;
        if (qq.isEmpty) return true;
        return p.title.toLowerCase().contains(qq) ||
            p.dose.toLowerCase().contains(qq) ||
            p.note.toLowerCase().contains(qq);
      }).toList();
    }

    return showModalBottomSheet<MedPreset>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
            final isNarrow = MediaQuery.of(ctx).size.width < 360;

            final list = filterList(searchCtl.text, selectedCat);

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ListTile(
                      title: Text(
                        'เลือกจากตัวอย่างยา',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        'เลือกหมวด/ค้นหา แล้วแตะ 1 รายการเพื่อเติมข้อมูลอัตโนมัติ',
                      ),
                    ),

                    // Search
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: TextField(
                        controller: searchCtl,
                        onChanged: (_) => setSheet(() {}),
                        decoration: InputDecoration(
                          hintText: 'ค้นหาชื่อยา / ขนาดยา / หมายเหตุ',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: const Color(0xFFF7F8FD),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    // Categories chips (horizontal)
                    SizedBox(
                      height: isNarrow ? 44 : 48,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        scrollDirection: Axis.horizontal,
                        itemCount: kPresetCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          final cat = kPresetCategories[i];
                          final sel = selectedCat == cat;
                          return InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => setSheet(() => selectedCat = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: sel ? _wine : const Color(0xFFF7F8FD),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: _wine.withOpacity(sel ? 0 : .18),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: sel ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    // List
                    Flexible(
                      child: list.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(18),
                              child: Text(
                                'ไม่พบตัวอย่างยาในหมวดนี้/คำค้นนี้',
                                style: TextStyle(
                                  color: Colors.black.withOpacity(.65),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final p = list[i];
                                return ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _soft,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(p.icon, color: _wine),
                                  ),
                                  title: Text(p.title),
                                  subtitle: Text(
                                    '${p.dose}\nหมวด: ${p.category}',
                                  ),
                                  isThreeLine: true,
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
                                  onTap: () => Navigator.pop(sheetCtx, p),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// -----------------------------
  /// ✅ Add/Edit (BottomSheet Responsive)
  /// -----------------------------
  Future<void> _addOrEdit({DocumentSnapshot<Map<String, dynamic>>? doc}) async {
    if (_uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเข้าสู่ระบบ')));
      return;
    }

    final isEdit = doc != null;
    final data = doc?.data() ?? <String, dynamic>{};

    final titleCtl = TextEditingController(text: _safeStr(data['title']));
    final doseCtl = TextEditingController(text: _safeStr(data['dose']));
    final noteCtl = TextEditingController(text: _safeStr(data['note']));

    int hour = _safeInt(data['hour'], 9);
    int minute = _safeInt(data['minute'], 0);
    bool enabled = _safeBool(data['enabled'], true);
    String meal = _safeStr(data['meal']).isEmpty
        ? 'none'
        : _safeStr(data['meal']);
    List<int> days = _safeDays(data['days']); // [] = ทุกวัน

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return SafeArea(
          child: LayoutBuilder(
            builder: (ctx, c) {
              final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
              final maxH = MediaQuery.of(ctx).size.height * 0.92;
              final isNarrow = MediaQuery.of(ctx).size.width < 360;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 520, maxHeight: maxH),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 24,
                          offset: Offset(0, 14),
                        ),
                      ],
                      border: Border.all(color: _wine.withOpacity(.10)),
                    ),
                    child: StatefulBuilder(
                      builder: (ctx2, setSheet) {
                        void toggleDay(int d) {
                          setSheet(() {
                            if (days.contains(d)) {
                              days = [...days]..remove(d);
                            } else {
                              days = [...days, d]
                                ..toSet().toList()
                                ..sort();
                            }
                          });
                        }

                        return SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 6,
                            bottom: bottomInset + 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Header
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _soft,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.medication_outlined,
                                      color: _wine,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      isEdit
                                          ? 'แก้ไขตารางการให้ยา'
                                          : 'เพิ่มตารางการให้ยา',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // ✅ Preset Button (หมวด+ค้นหา)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.auto_awesome),
                                  label: const Text(
                                    'เลือกจากตัวอย่างยา (แยกหมวด/ค้นหา)',
                                  ),
                                  onPressed: () async {
                                    final preset = await _pickPreset(ctx2);
                                    if (preset == null) return;

                                    setSheet(() {
                                      titleCtl.text = preset.title;
                                      doseCtl.text = preset.dose;
                                      noteCtl.text = preset.note;
                                      hour = preset.hour;
                                      minute = preset.minute;
                                      meal = preset.meal;
                                      days = [...preset.days];
                                      enabled = true;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),

                              _Input(
                                controller: titleCtl,
                                label: 'ชื่อยา / รายการ *',
                                icon: Icons.medication_outlined,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 12),

                              _Input(
                                controller: doseCtl,
                                label: 'ขนาดยา / วิธีใช้ (เช่น 1 เม็ด)',
                                icon: Icons.numbers_outlined,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 12),

                              _Input(
                                controller: noteCtl,
                                label: 'หมายเหตุเพิ่มเติม',
                                icon: Icons.notes_outlined,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 14),

                              // Status + Time
                              _SectionTitle(
                                title: 'เวลา และสถานะ',
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      enabled ? 'เปิดใช้งาน' : 'ปิดใช้งาน',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: enabled ? _wine : Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: enabled,
                                      activeColor: _wine2,
                                      onChanged: (v) =>
                                          setSheet(() => enabled = v),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),

                              _PillButton(
                                icon: Icons.access_time,
                                label: 'เวลา  ${_fmtTime(hour, minute)}',
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: ctx2,
                                    initialTime: TimeOfDay(
                                      hour: hour,
                                      minute: minute,
                                    ),
                                  );
                                  if (picked != null) {
                                    setSheet(() {
                                      hour = picked.hour;
                                      minute = picked.minute;
                                    });
                                  }
                                },
                              ),

                              const SizedBox(height: 16),

                              // Meal
                              const _SectionTitle(title: 'ช่วงอาหาร'),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _PrettyChip(
                                    label: 'ไม่ระบุ',
                                    selected: meal == 'none',
                                    onTap: () => setSheet(() => meal = 'none'),
                                    dense: isNarrow,
                                  ),
                                  _PrettyChip(
                                    label: 'ก่อนอาหาร',
                                    selected: meal == 'before',
                                    onTap: () =>
                                        setSheet(() => meal = 'before'),
                                    dense: isNarrow,
                                  ),
                                  _PrettyChip(
                                    label: 'หลังอาหาร',
                                    selected: meal == 'after',
                                    onTap: () => setSheet(() => meal = 'after'),
                                    dense: isNarrow,
                                  ),
                                  _PrettyChip(
                                    label: 'พร้อมอาหาร',
                                    selected: meal == 'with',
                                    onTap: () => setSheet(() => meal = 'with'),
                                    dense: isNarrow,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Days
                              _SectionTitle(
                                title: 'วันในสัปดาห์',
                                subtitle: 'ไม่เลือก = ทุกวัน',
                                trailing: TextButton(
                                  onPressed: () =>
                                      setSheet(() => days = const []),
                                  child: const Text('ทุกวัน'),
                                ),
                              ),
                              const SizedBox(height: 10),

                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: List.generate(7, (i) {
                                  final d = i + 1;
                                  final sel = days.contains(d);
                                  return _DayChip(
                                    label: _dayLabel(d),
                                    selected: sel,
                                    onTap: () => toggleDay(d),
                                    size: isNarrow ? 42 : 44,
                                  );
                                }),
                              ),

                              const SizedBox(height: 18),

                              // Actions
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      onPressed: () => Navigator.pop(ctx2),
                                      child: const Text('ยกเลิก'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _wine,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final title = titleCtl.text.trim();
                                        if (title.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'กรุณากรอกชื่อยา/รายการ',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        final payload = <String, dynamic>{
                                          'uid': _uid,
                                          'title': title,
                                          'dose': doseCtl.text.trim(),
                                          'note': noteCtl.text.trim(),
                                          'hour': hour,
                                          'minute': minute,
                                          'enabled': enabled,
                                          'meal': meal,
                                          'days': days, // [] = every day
                                          'updatedAt':
                                              FieldValue.serverTimestamp(),
                                          if (!isEdit)
                                            'createdAt':
                                                FieldValue.serverTimestamp(),
                                        };

                                        try {
                                          if (isEdit) {
                                            await doc!.reference.update(
                                              payload,
                                            );
                                          } else {
                                            await _col.add(payload);
                                          }
                                          if (ctx2.mounted) Navigator.pop(ctx2);
                                        } catch (e) {
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'บันทึกไม่สำเร็จ: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Text(isEdit ? 'บันทึก' : 'เพิ่ม'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _toggle(
    DocumentSnapshot<Map<String, dynamic>> doc,
    bool value,
  ) async {
    try {
      await doc.reference.update({
        'enabled': value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('อัปเดตไม่สำเร็จ: $e')));
    }
  }

  Future<void> _delete(DocumentSnapshot<Map<String, dynamic>> doc) async {
    final title = _safeStr(doc.data()?['title']);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลบรายการนี้?'),
        content: Text(title.isEmpty ? '(ไม่ระบุชื่อยา)' : title),
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

    if (ok == true) {
      try {
        await doc.reference.delete();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('ตารางการให้ยา'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_wine, _wine2],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'เพิ่ม',
            onPressed: () => _addOrEdit(),
            icon: const Icon(Icons.add),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: _SearchBox(
              hint: 'ค้นหาชื่อยา / ขนาดยา / หมายเหตุ',
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _wine,
        foregroundColor: Colors.white,
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.add_rounded),
        label: Text(isNarrow ? 'เพิ่ม' : 'เพิ่มรายการ'),
      ),
      body: _uid == null
          ? const Center(child: Text('กรุณาเข้าสู่ระบบ'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

                final docs = [...(snap.data?.docs ?? const [])];
                docs.sort((a, b) {
                  final ah = _safeInt(a.data()['hour'], 0);
                  final bh = _safeInt(b.data()['hour'], 0);
                  if (ah != bh) return ah.compareTo(bh);
                  final am = _safeInt(a.data()['minute'], 0);
                  final bm = _safeInt(b.data()['minute'], 0);
                  return am.compareTo(bm);
                });

                final q = _q;
                final filtered = q.isEmpty
                    ? docs
                    : docs.where((d) {
                        final m = d.data();
                        final t = _safeStr(m['title']).toLowerCase();
                        final dose = _safeStr(m['dose']).toLowerCase();
                        final note = _safeStr(m['note']).toLowerCase();
                        return t.contains(q) ||
                            dose.contains(q) ||
                            note.contains(q);
                      }).toList();

                if (filtered.isEmpty) {
                  return _EmptyState(
                    message: q.isEmpty
                        ? 'ยังไม่มีตารางการให้ยา'
                        : 'ไม่พบรายการที่ค้นหา',
                    onAdd: _addOrEdit,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final d = filtered[i];
                    final data = d.data();

                    final title = _safeStr(data['title']);
                    final dose = _safeStr(data['dose']);
                    final note = _safeStr(data['note']);
                    final hour = _safeInt(data['hour'], 0);
                    final minute = _safeInt(data['minute'], 0);
                    final enabled = _safeBool(data['enabled'], true);
                    final meal = _safeStr(data['meal']).isEmpty
                        ? 'none'
                        : _safeStr(data['meal']);
                    final days = _safeDays(data['days']);

                    final timeText = _fmtTime(hour, minute);
                    final daysText = days.isEmpty
                        ? 'ทุกวัน'
                        : days.map(_dayLabel).join(' ');

                    return Dismissible(
                      key: ValueKey(d.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFB31237),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (_) async {
                        await _delete(d);
                        return false;
                      },
                      child: _MedModernCard(
                        title: title.isEmpty ? '(ไม่ระบุชื่อยา)' : title,
                        dose: dose,
                        note: note,
                        time: timeText,
                        enabled: enabled,
                        mealText: _mealLabel(meal),
                        mealBg: _mealColor(meal),
                        daysText: daysText,
                        onToggle: (v) => _toggle(d, v),
                        onEdit: () => _addOrEdit(doc: d),
                        onMore: () async {
                          final action = await showModalBottomSheet<String>(
                            context: context,
                            showDragHandle: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(18),
                              ),
                            ),
                            builder: (sheetCtx) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit_outlined),
                                    title: const Text('แก้ไข'),
                                    onTap: () =>
                                        Navigator.pop(sheetCtx, 'edit'),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.delete_outline),
                                    title: const Text('ลบ'),
                                    onTap: () =>
                                        Navigator.pop(sheetCtx, 'delete'),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          );

                          if (action == 'edit') _addOrEdit(doc: d);
                          if (action == 'delete') _delete(d);
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

/// ---------------- UI widgets ----------------

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              if ((subtitle ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.black.withOpacity(.55),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.label,
    required this.icon,
    this.textInputAction,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputAction? textInputAction;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: textInputAction,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: const Color(0xFFF7F8FD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  static const _wine = Color(0xFF660F24);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _wine.withOpacity(.18)),
          color: const Color(0xFFF7F8FD),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _wine),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrettyChip extends StatelessWidget {
  const _PrettyChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.dense,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;

  static const _wine = Color(0xFF660F24);

  @override
  Widget build(BuildContext context) {
    final pad = dense
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 9)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 10);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: pad,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? _wine : const Color(0xFFF7F8FD),
          border: Border.all(color: _wine.withOpacity(selected ? .0 : .18)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.size,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double size;

  static const _wine = Color(0xFF660F24);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected ? _wine : const Color(0xFFF7F8FD),
          border: Border.all(color: _wine.withOpacity(selected ? .0 : .18)),
        ),
        child: FittedBox(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(.75)),
        prefixIcon: const Icon(Icons.search, color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _MedModernCard extends StatelessWidget {
  const _MedModernCard({
    required this.title,
    required this.dose,
    required this.note,
    required this.time,
    required this.enabled,
    required this.mealText,
    required this.mealBg,
    required this.daysText,
    required this.onToggle,
    required this.onEdit,
    required this.onMore,
  });

  final String title;
  final String dose;
  final String note;
  final String time;
  final bool enabled;
  final String mealText;
  final Color mealBg;
  final String daysText;

  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onMore;

  static const _wine = Color(0xFF660F24);
  static const _soft = Color(0xFFFFEEF0);

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 360;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onEdit,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _wine.withOpacity(.10)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _soft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.medication_outlined, color: _wine),
              ),
              const SizedBox(width: 10),

              /// ===== CONTENT =====
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// title + time
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: _Badge(
                            icon: Icons.access_time,
                            text: time,
                            bg: const Color(0xFFEFF7FF),
                            fg: _wine,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    /// badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Badge(
                          icon: Icons.restaurant_outlined,
                          text: mealText,
                          bg: mealBg,
                          fg: _wine,
                        ),
                        _Badge(
                          icon: Icons.event_repeat_outlined,
                          text: daysText,
                          bg: const Color(0xFFF7F8FD),
                          fg: Colors.black87,
                        ),
                      ],
                    ),

                    if (dose.isNotEmpty || note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        [
                          if (dose.isNotEmpty) 'ขนาดยา: $dose',
                          if (note.isNotEmpty) 'หมายเหตุ: $note',
                        ].join('\n'),
                        style: TextStyle(
                          height: 1.25,
                          color: Colors.black.withOpacity(.65),
                          fontSize: isNarrow ? 12.5 : 13.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 6),

              /// ===== RIGHT SIDE =====
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: isNarrow ? 0.85 : 1,
                    child: Switch(
                      value: enabled,
                      activeColor: _wine,
                      onChanged: onToggle,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: const VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                      IconButton(
                        visualDensity: const VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        onPressed: onMore,
                        icon: const Icon(Icons.more_vert, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.text,
    required this.bg,
    required this.fg,
  });

  final IconData icon;
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 140),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: fg,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, required this.onAdd});
  final String message;
  final VoidCallback onAdd;

  static const _wine = Color(0xFF660F24);
  static const _soft = Color(0xFFFFEEF0);

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 360;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: _soft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medication_outlined,
                color: _wine,
                size: 42,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'เพิ่มรายการยา ตั้งเวลา เลือกวัน และช่วงอาหารได้',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black.withOpacity(.65)),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _wine,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isNarrow ? 14 : 18,
                  vertical: 12,
                ),
              ),
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มรายการแรก'),
            ),
          ],
        ),
      ),
    );
  }
}
