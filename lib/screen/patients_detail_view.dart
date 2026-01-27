// lib/screen/patients_detail_view.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../routes.dart';

const kPrimary = Color(0xFF660F24);
const kWhite = Color(0xFFFFFFFF);

class PatientsDetailView extends StatefulWidget {
  final String patientId;
  const PatientsDetailView({super.key, required this.patientId});

  @override
  State<PatientsDetailView> createState() => _PatientsDetailViewState();
}

class _PatientsDetailViewState extends State<PatientsDetailView> {
  DocumentReference<Map<String, dynamic>> get _doc =>
      FirebaseFirestore.instance.collection('patients').doc(widget.patientId);

  final _noteCtl = TextEditingController();

  @override
  void dispose() {
    _noteCtl.dispose();
    super.dispose();
  }

  // ───────────────── helpers ─────────────────
  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String && v.trim().isNotEmpty) return {'name': v.trim()};
    return <String, dynamic>{};
  }

  List<String> _asStringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String && v.trim().isNotEmpty) return [v.trim()];
    return const <String>[];
  }

  String _readBlood(Map<String, dynamic> data) {
    final t = (data['bloodType'] ?? '').toString().trim();
    final g = (data['bloodGroup'] ?? '').toString().trim();
    return t.isNotEmpty ? t : g;
  }

  Map<String, dynamic> _readCaregiver(Map<String, dynamic> data) {
    final m = _asMap(data['caregiver']);
    if (m.isNotEmpty) return m;
    return {
      'name': (data['caregiverName'] ?? '').toString(),
      'relation': (data['caregiverRelation'] ?? '').toString(),
      'phone': (data['caregiverPhone'] ?? '').toString(),
    };
  }

  List<String> _readConditions(Map<String, dynamic> data) {
    final c = _asStringList(data['conditions']);
    if (c.isNotEmpty) return c;
    return _asStringList(data['chronicDiseases']);
  }

  List<String> _readDrugAllergies(Map<String, dynamic> data) =>
      _asStringList(data['drugAllergies']);

  List<Map<String, dynamic>> _readMeds(Map<String, dynamic> data) {
    final regular = data['regularMeds'];
    if (regular is List) {
      return regular
          .map<Map<String, dynamic>>((e) => {'name': e.toString(), 'note': ''})
          .toList();
    }
    final meds = data['meds'];
    if (meds is List) {
      return meds.map<Map<String, dynamic>>((e) {
        if (e is Map) {
          final m = Map<String, dynamic>.from(e);
          return {
            'name': (m['name'] ?? '').toString(),
            'note': (m['note'] ?? '').toString(),
          };
        }
        return {'name': e.toString(), 'note': ''};
      }).toList();
    }
    return const <Map<String, dynamic>>[];
  }

  String _medStorageKey(Map<String, dynamic> data) =>
      (data['regularMeds'] is List) ? 'regularMeds' : 'meds';

  String _condStorageKey(Map<String, dynamic> data) {
    if (data['conditions'] != null) return 'conditions';
    if (data['chronicDiseases'] != null) return 'chronicDiseases';
    return 'conditions';
  }

  String _medLabel(Map<String, dynamic> m) {
    final name = (m['name'] ?? '').toString().trim();
    final note = (m['note'] ?? '').toString().trim();
    if (name.isEmpty) return '-';
    return note.isEmpty ? name : '$name • $note';
  }

  // ───────────────── presets ─────────────────
  static const List<String> kConditionPresets = [
    'ความดันโลหิตสูง',
    'เบาหวาน',
    'ไขมันในเลือดสูง',
    'โรคหัวใจ',
    'โรคไต',
    'โรคปอด/หอบหืด',
    'หลอดเลือดสมอง (Stroke)',
    'สมองเสื่อม/อัลไซเมอร์',
    'ข้อเข่าเสื่อม',
    'แผลกดทับ',
  ];

  static const List<String> kDrugAllergyPresets = [
    'เพนิซิลลิน (Penicillin)',
    'อะม็อกซิซิลลิน (Amoxicillin)',
    'ซัลฟา (Sulfa)',
    'แอสไพริน (Aspirin)',
    'ไอบูโพรเฟน (Ibuprofen)',
    'พาราเซตามอล (Paracetamol)',
  ];

  static const List<String> kMedPresets = [
    'Metformin',
    'Amlodipine',
    'Losartan',
    'Atorvastatin',
    'Aspirin',
    'Omeprazole',
    'Insulin',
    'Paracetamol',
  ];

  // ───────────────── actions ─────────────────
  Future<void> _saveNote() async {
    await _doc.update({
      'note': _noteCtl.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('บันทึกโน้ตแล้ว')));
  }

  Future<void> _editBasics(Map<String, dynamic> data) async {
    final nameCtl = TextEditingController(
      text: (data['name'] ?? '').toString(),
    );
    final ageCtl = TextEditingController(
      text: data['age'] == null ? '' : (data['age']).toString(),
    );
    String gender = (data['gender'] ?? 'other').toString();
    String blood = _readBlood(data);
    final heightCtl = TextEditingController(
      text: data['heightCm'] == null ? '' : (data['heightCm']).toString(),
    );
    final weightCtl = TextEditingController(
      text: data['weightKg'] == null ? '' : (data['weightKg']).toString(),
    );

    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => _StyledDialog(
            title: 'ข้อมูลส่วนตัว',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tf(nameCtl, 'ชื่อ-สกุล'),
                const SizedBox(height: 8),
                _tf(ageCtl, 'อายุ (ปี)', number: true),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: ['male', 'female', 'other'].contains(gender)
                      ? gender
                      : 'other',
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('ชาย')),
                    DropdownMenuItem(value: 'female', child: Text('หญิง')),
                    DropdownMenuItem(value: 'other', child: Text('อื่น ๆ')),
                  ],
                  onChanged: (v) => gender = v ?? 'other',
                  decoration: _ddDecoration('เพศ'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: ['A', 'B', 'AB', 'O'].contains(blood) ? blood : null,
                  items: const [
                    DropdownMenuItem(value: 'A', child: Text('A')),
                    DropdownMenuItem(value: 'B', child: Text('B')),
                    DropdownMenuItem(value: 'AB', child: Text('AB')),
                    DropdownMenuItem(value: 'O', child: Text('O')),
                  ],
                  onChanged: (v) => blood = v ?? '',
                  decoration: _ddDecoration('หมู่เลือด'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _tf(heightCtl, 'ส่วนสูง (ซม.)', number: true),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _tf(weightCtl, 'น้ำหนัก (กก.)', number: true),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ) ??
        false;

    if (!ok) return;

    final age = int.tryParse(ageCtl.text.trim());
    final height = double.tryParse(heightCtl.text.trim());
    final weight = double.tryParse(weightCtl.text.trim());

    await _doc.update({
      'name': nameCtl.text.trim(),
      'age': age,
      'gender': gender,
      'bloodType': blood.isEmpty ? null : blood,
      'bloodGroup': blood.isEmpty ? null : blood,
      'heightCm': height,
      'weightKg': weight,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _editCaregiver(Map<String, dynamic> data) async {
    final cg = _readCaregiver(data);
    final nameCtl = TextEditingController(text: (cg['name'] ?? '').toString());
    final relCtl = TextEditingController(
      text: (cg['relation'] ?? '').toString(),
    );
    final phoneCtl = TextEditingController(
      text: (cg['phone'] ?? '').toString(),
    );

    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => _StyledDialog(
            title: 'ติดต่อผู้ดูแล',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tf(nameCtl, 'ชื่อผู้ดูแล'),
                const SizedBox(height: 8),
                _tf(relCtl, 'ความเกี่ยวข้อง'),
                const SizedBox(height: 8),
                _tf(phoneCtl, 'เบอร์โทร', phone: true),
              ],
            ),
          ),
        ) ??
        false;
    if (!ok) return;

    await _doc.update({
      'caregiver': {
        'name': nameCtl.text.trim(),
        'relation': relCtl.text.trim(),
        'phone': phoneCtl.text.trim(),
      },
      'caregiverName': nameCtl.text.trim(),
      'caregiverRelation': relCtl.text.trim(),
      'caregiverPhone': phoneCtl.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _editDoctor(Map<String, dynamic> data) async {
    final docx = _asMap(data['doctor']);
    final nameCtl = TextEditingController(
      text: (docx['name'] ?? '').toString(),
    );
    final hospCtl = TextEditingController(
      text: (docx['hospital'] ?? '').toString(),
    );
    final phoneCtl = TextEditingController(
      text: (docx['phone'] ?? '').toString(),
    );

    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => _StyledDialog(
            title: 'หมอประจำตัว',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tf(nameCtl, 'ชื่อแพทย์'),
                const SizedBox(height: 8),
                _tf(hospCtl, 'โรงพยาบาล/คลินิก'),
                const SizedBox(height: 8),
                _tf(phoneCtl, 'เบอร์โทร', phone: true),
              ],
            ),
          ),
        ) ??
        false;
    if (!ok) return;

    await _doc.update({
      'doctor': {
        'name': nameCtl.text.trim(),
        'hospital': hospCtl.text.trim(),
        'phone': phoneCtl.text.trim(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ✅ โหมดเลือกโรคประจำตัว (มี preset + เพิ่มเอง + บันทึกเป็น list)
  Future<void> _pickConditions(Map<String, dynamic> data) async {
    final key = _condStorageKey(data);
    final current = _readConditions(data).toSet();

    final result = await _multiSelectDialog(
      title: 'เลือกโรคประจำตัว',
      presets: kConditionPresets,
      initialSelected: current,
      addHint: 'พิมพ์โรคอื่น ๆ แล้วกด “เพิ่ม”',
    );

    if (result == null) return;
    await _doc.update({
      key: result.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ✅ โหมดเลือกการแพ้ยา (มี preset + เพิ่มเอง)
  Future<void> _pickDrugAllergies(Map<String, dynamic> data) async {
    final current = _readDrugAllergies(data).toSet();

    final result = await _multiSelectDialog(
      title: 'เลือกการแพ้ยา',
      presets: kDrugAllergyPresets,
      initialSelected: current,
      addHint: 'พิมพ์ชื่อยาอื่น ๆ แล้วกด “เพิ่ม”',
    );

    if (result == null) return;
    await _doc.update({
      'drugAllergies': result.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ✅ โหมดเลือกยาที่ใช้ประจำ (มี preset + เพิ่มเอง + ใส่โน้ตได้)
  Future<void> _pickMeds(Map<String, dynamic> data) async {
    final storageKey = _medStorageKey(data);

    // ดึงค่าเดิม
    final current = _readMeds(
      data,
    ).where((m) => (m['name'] ?? '').toString().trim().isNotEmpty).toList();

    final result = await _medSelectDialog(
      title: 'ยาที่ใช้ประจำ',
      presets: kMedPresets,
      initial: current,
      // ถ้าเดิมเป็น regularMeds จะเซฟกลับเป็น string list
      stringOnly: storageKey == 'regularMeds',
    );

    if (result == null) return;

    if (storageKey == 'regularMeds') {
      // เก็บเป็น List<String>
      final next = result
          .map((m) => (m['name'] ?? '').toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      await _doc.update({
        'regularMeds': next,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // เก็บเป็น List<Map> {name,note}
      final next = result
          .map(
            (m) => {
              'name': (m['name'] ?? '').toString().trim(),
              'note': (m['note'] ?? '').toString().trim(),
            },
          )
          .where((m) => (m['name'] ?? '').toString().isNotEmpty)
          .toList();
      await _doc.update({
        'meds': next,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ลบ chip แบบเดิมยังทำได้
  Future<void> _removeCondition(Map<String, dynamic> data, String v) async {
    final key = _condStorageKey(data);
    await _doc.update({
      key: FieldValue.arrayRemove([v]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _removeDrugAllergy(String v) async {
    await _doc.update({
      'drugAllergies': FieldValue.arrayRemove([v]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _removeMed(Map<String, dynamic> med) async {
    final snap = await _doc.get();
    final data = snap.data() ?? {};
    final key = _medStorageKey(data);

    if (key == 'regularMeds') {
      final list = _asStringList(data['regularMeds']);
      final next = list
          .where((e) => e.toString() != (med['name'] ?? '').toString())
          .toList();
      await _doc.update({
        'regularMeds': next,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final current = _readMeds(data);
      final next = current
          .where(
            (m) =>
                !(m['name'] == med['name'] &&
                    (m['note'] ?? '') == (med['note'] ?? '')),
          )
          .toList();
      await _doc.update({
        'meds': next,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // ───────────────── UI ─────────────────
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _doc.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: kPrimary,
              title: const Text('รายละเอียดผู้ป่วย'),
            ),
            body: Center(child: Text('เกิดข้อผิดพลาด: ${snap.error}')),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snap.data!.data();
        if (data == null) {
          return const Scaffold(
            body: Center(child: Text('ไม่พบข้อมูลผู้ป่วย')),
          );
        }

        final name = (data['name'] ?? '').toString().trim();
        final age = data['age'];
        final blood = _readBlood(data);

        final caregiver = _readCaregiver(data);
        final conditions = _readConditions(data);
        final drugAllergies = _readDrugAllergies(data);
        final meds = _readMeds(data);
        final doctor = _asMap(data['doctor']);

        final noteFromDb = (data['note'] ?? '').toString();
        if (_noteCtl.text != noteFromDb) {
          _noteCtl.value = _noteCtl.value.copyWith(
            text: noteFromDb,
            selection: TextSelection.collapsed(offset: noteFromDb.length),
          );
        }

        final subtitle = [
          if (age is int) 'อายุ $age ปี',
          if (blood.isNotEmpty) 'หมู่เลือด $blood',
        ].join(' • ');

        return Scaffold(
          backgroundColor: const Color(0xFFF7F7FB),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 210,
                backgroundColor: kPrimary,
                leading: IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                ),
                actions: [
                  IconButton(
                    tooltip: 'แก้ไขข้อมูลส่วนตัว',
                    onPressed: () => _editBasics(data),
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF5A0F1B),
                              Color(0xFFB31237),
                              Color(0xFFF24455),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: -80,
                        right: -60,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.10),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -110,
                        left: -80,
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.isEmpty ? 'รายละเอียดผู้ป่วย' : name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                subtitle.isEmpty ? '—' : subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(.92),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  child: Column(
                    children: [
                      // ผู้ดูแล
                      _SectionCard(
                        icon: Icons.call_outlined,
                        title: 'ติดต่อผู้ดูแล',
                        trailing: _SmallAction(
                          text: 'แก้ไข',
                          icon: Icons.edit_outlined,
                          onTap: () => _editCaregiver(data),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _kv('ชื่อ', (caregiver['name'] ?? '').toString()),
                            _kv(
                              'ความเกี่ยวข้อง',
                              (caregiver['relation'] ?? '').toString(),
                            ),
                            _kv(
                              'เบอร์โทร',
                              (caregiver['phone'] ?? '').toString(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // โรคประจำตัว (เลือกจากรายการ + เพิ่มเอง)
                      _SectionCard(
                        icon: Icons.medical_information_outlined,
                        title: 'โรคประจำตัว',
                        trailing: _SmallAction(
                          text: 'เลือก',
                          icon: Icons.tune_rounded,
                          onTap: () => _pickConditions(data),
                        ),
                        child: conditions.isEmpty
                            ? const Text('ยังไม่ได้ระบุ')
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final c in conditions)
                                    _chip(
                                      label: c,
                                      onDeleted: () =>
                                          _removeCondition(data, c),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),

                      // การแพ้ยา
                      _SectionCard(
                        icon: Icons.report_gmailerrorred_outlined,
                        title: 'การแพ้ยา',
                        trailing: _SmallAction(
                          text: 'เลือก',
                          icon: Icons.tune_rounded,
                          onTap: () => _pickDrugAllergies(data),
                        ),
                        child: drugAllergies.isEmpty
                            ? const Text('ยังไม่ได้ระบุ')
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final a in drugAllergies)
                                    _chip(
                                      label: a,
                                      onDeleted: () => _removeDrugAllergy(a),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),

                      // ยาที่ใช้ประจำ
                      _SectionCard(
                        icon: Icons.medication_outlined,
                        title: 'ยาที่ใช้ประจำ',
                        trailing: _SmallAction(
                          text: 'เลือก',
                          icon: Icons.tune_rounded,
                          onTap: () => _pickMeds(data),
                        ),
                        child: meds.isEmpty
                            ? const Text('ยังไม่ได้ระบุ')
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final m in meds)
                                    _chip(
                                      label: _medLabel(m),
                                      onDeleted: () => _removeMed(m),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),

                      // หมอประจำตัว
                      _SectionCard(
                        icon: Icons.local_hospital_outlined,
                        title: 'หมอประจำตัว',
                        trailing: _SmallAction(
                          text: 'แก้ไข',
                          icon: Icons.edit_outlined,
                          onTap: () => _editDoctor(data),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _kv('ชื่อแพทย์', (doctor['name'] ?? '').toString()),
                            _kv(
                              'โรงพยาบาล',
                              (doctor['hospital'] ?? '').toString(),
                            ),
                            _kv('เบอร์โทร', (doctor['phone'] ?? '').toString()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // โน้ต
                      _SectionCard(
                        icon: Icons.sticky_note_2_outlined,
                        title: 'บันทึก/หมายเหตุ',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _noteCtl,
                              maxLines: 5,
                              decoration: _inputDecoration(
                                'ข้อมูลแพ้ยา ประวัติการรักษา อื่น ๆ',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: _saveNote,
                                icon: const Icon(Icons.save_outlined),
                                label: const Text('บันทึก'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimary,
                                  foregroundColor: kWhite,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ไป Care Log
                      _SectionCard(
                        icon: Icons.history_rounded,
                        title: 'Care Log',
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'เปิด Care Log ของผู้ป่วยนี้',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: const Text('บันทึกกิจวัตร/การดูแลรายวัน'),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: kPrimary,
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.careLog,
                              arguments: {'patientId': widget.patientId},
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ลบ
                      _SectionCard(
                        icon: Icons.delete_outline,
                        title: 'ลบผู้ป่วย',
                        danger: true,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFB00020),
                          ),
                          title: const Text('ลบผู้ป่วยนี้'),
                          subtitle: const Text(
                            'การลบจะลบเอกสารผู้ป่วย (โปรดตรวจสอบก่อน)',
                          ),
                          onTap: () async {
                            final ok =
                                await showDialog<bool>(
                                  context: context,
                                  builder: (_) => _StyledDialog(
                                    title: 'ยืนยันการลบ',
                                    child: Text(
                                      'ต้องการลบ “${name.isEmpty ? 'ผู้ป่วย' : name}” หรือไม่?',
                                    ),
                                    positiveText: 'ลบ',
                                  ),
                                ) ??
                                false;
                            if (!ok) return;
                            await _doc.delete();
                            if (mounted) Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ───────────────── dialogs ─────────────────

  Future<Set<String>?> _multiSelectDialog({
    required String title,
    required List<String> presets,
    required Set<String> initialSelected,
    required String addHint,
  }) async {
    final addCtl = TextEditingController();
    final options = [...presets];
    final selected = {...initialSelected};

    final res = await showDialog<Set<String>>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            void addCustom() {
              final v = addCtl.text.trim();
              if (v.isEmpty) return;
              if (!options.contains(v)) options.insert(0, v);
              selected.add(v);
              addCtl.clear();
              setState(() {});
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: kPrimary,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      addHint,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: addCtl,
                            decoration: _inputDecoration('เพิ่มเอง…').copyWith(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            onSubmitted: (_) => addCustom(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: addCustom,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('เพิ่ม'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in options)
                          FilterChip(
                            selected: selected.contains(o),
                            label: Text(o),
                            selectedColor: kPrimary.withOpacity(.14),
                            checkmarkColor: kPrimary,
                            onSelected: (v) {
                              if (v) {
                                selected.add(o);
                              } else {
                                selected.remove(o);
                              }
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(color: Colors.grey.shade300),
                    const SizedBox(height: 6),
                    Text(
                      'เลือกแล้ว: ${selected.length} รายการ',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );

    addCtl.dispose();
    return res;
  }

  Future<List<Map<String, dynamic>>?> _medSelectDialog({
    required String title,
    required List<String> presets,
    required List<Map<String, dynamic>> initial,
    required bool stringOnly,
  }) async {
    final addCtl = TextEditingController();

    // ใช้ key เป็นชื่อยา
    final selected = <String, Map<String, dynamic>>{
      for (final m in initial)
        (m['name'] ?? '').toString().trim(): {
          'name': (m['name'] ?? '').toString().trim(),
          'note': (m['note'] ?? '').toString().trim(),
        },
    }..removeWhere((k, v) => k.isEmpty);

    final options = [...presets];

    final res = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            void addCustom() {
              final v = addCtl.text.trim();
              if (v.isEmpty) return;
              if (!options.contains(v)) options.insert(0, v);
              selected[v] = {'name': v, 'note': ''};
              addCtl.clear();
              setState(() {});
            }

            final keys = selected.keys.toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: kPrimary,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stringOnly
                          ? 'เลือกยาได้จากรายการ หรือพิมพ์เพิ่มเอง (โหมดนี้จะบันทึกเฉพาะชื่อยา)'
                          : 'เลือกยาได้จากรายการ หรือพิมพ์เพิ่มเอง และใส่โน้ต/ขนาดยาได้',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: addCtl,
                            decoration: _inputDecoration('เพิ่มชื่อยา…')
                                .copyWith(
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                            onSubmitted: (_) => addCustom(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: addCustom,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('เพิ่ม'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final o in options)
                          FilterChip(
                            selected: selected.containsKey(o),
                            label: Text(o),
                            selectedColor: kPrimary.withOpacity(.14),
                            checkmarkColor: kPrimary,
                            onSelected: (v) {
                              if (v) {
                                selected[o] = {'name': o, 'note': ''};
                              } else {
                                selected.remove(o);
                              }
                              setState(() {});
                            },
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade300),
                    const SizedBox(height: 6),
                    Text(
                      'รายการที่เลือก (${selected.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (selected.isEmpty)
                      Text(
                        'ยังไม่ได้เลือก',
                        style: TextStyle(color: Colors.grey.shade700),
                      )
                    else
                      Column(
                        children: [
                          for (final k in keys)
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F7FB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: kPrimary.withOpacity(.12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          k,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: kPrimary,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          selected.remove(k);
                                          setState(() {});
                                        },
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: kPrimary,
                                        ),
                                        tooltip: 'ลบ',
                                      ),
                                    ],
                                  ),
                                  if (!stringOnly) ...[
                                    const SizedBox(height: 6),
                                    TextField(
                                      controller: TextEditingController(
                                        text: (selected[k]?['note'] ?? '')
                                            .toString(),
                                      ),
                                      onChanged: (v) =>
                                          selected[k]!['note'] = v,
                                      decoration: _inputDecoration(
                                        'โน้ต/ขนาดยา เช่น 1 เม็ดหลังอาหารเช้า',
                                      ).copyWith(isDense: true),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, selected.values.toList()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );

    addCtl.dispose();
    return res;
  }

  // ───────────────── small UI helpers ─────────────────
  static InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: kWhite,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: kPrimary.withOpacity(.25), width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: kPrimary.withOpacity(.18), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimary, width: 1.6),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  static InputDecoration _ddDecoration(String label) =>
      _inputDecoration(label).copyWith(labelText: label, hintText: null);

  static Widget _tf(
    TextEditingController c,
    String label, {
    bool number = false,
    bool phone = false,
  }) => TextField(
    controller: c,
    keyboardType: number
        ? TextInputType.number
        : (phone ? TextInputType.phone : TextInputType.text),
    decoration: _inputDecoration(
      label,
    ).copyWith(labelText: label, hintText: null),
  );

  Widget _kv(String k, String v) {
    final s = v.trim().isEmpty ? '-' : v;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: kPrimary.withOpacity(.9),
              ),
            ),
          ),
          Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  static Widget _chip({
    required String label,
    required VoidCallback onDeleted,
  }) => InputChip(
    label: Text(label),
    backgroundColor: kWhite,
    shape: StadiumBorder(side: BorderSide(color: kPrimary.withOpacity(.22))),
    deleteIconColor: kPrimary,
    onDeleted: onDeleted,
    labelStyle: const TextStyle(fontWeight: FontWeight.w700),
  );
}

// ───────────────── components ─────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;
  final bool danger;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = danger ? const Color(0xFFB00020) : kPrimary;

    return Material(
      color: kWhite,
      elevation: 3,
      shadowColor: kPrimary.withOpacity(.10),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: titleColor.withOpacity(.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: titleColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: titleColor,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _SmallAction({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: kPrimary),
      label: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w900, color: kPrimary),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: kPrimary.withOpacity(.08),
      ),
    );
  }
}

class _StyledDialog extends StatelessWidget {
  final String title;
  final Widget child;
  final String positiveText;
  final String negativeText;

  const _StyledDialog({
    super.key,
    required this.title,
    required this.child,
    this.positiveText = 'บันทึก',
    this.negativeText = 'ยกเลิก',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w900),
      ),
      content: SingleChildScrollView(child: child),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(negativeText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: kWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(positiveText),
        ),
      ],
    );
  }
}
