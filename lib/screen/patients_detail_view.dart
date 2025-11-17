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
            title: 'เก็บข้อมูลส่วนตัว',
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

  Future<void> _addCondition(Map<String, dynamic> data) async {
    final key = _condStorageKey(data);
    final ctl = TextEditingController();
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => _StyledDialog(
            title: 'เพิ่มโรคประจำตัว',
            child: _tf(ctl, 'เช่น ความดัน'),
            positiveText: 'เพิ่ม',
          ),
        ) ??
        false;
    if (!ok) return;
    final v = ctl.text.trim();
    if (v.isEmpty) return;
    await _doc.update({
      key: FieldValue.arrayUnion([v]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _removeCondition(Map<String, dynamic> data, String v) async {
    final key = _condStorageKey(data);
    await _doc.update({
      key: FieldValue.arrayRemove([v]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _addDrugAllergy() async {
    final ctl = TextEditingController();
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => _StyledDialog(
            title: 'เพิ่มการแพ้ยา',
            child: _tf(ctl, 'เช่น เพนิซิลลิน'),
            positiveText: 'เพิ่ม',
          ),
        ) ??
        false;
    if (!ok) return;
    final v = ctl.text.trim();
    if (v.isEmpty) return;
    await _doc.update({
      'drugAllergies': FieldValue.arrayUnion([v]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _removeDrugAllergy(String v) async {
    await _doc.update({
      'drugAllergies': FieldValue.arrayRemove([v]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _addMed() async {
    final nameCtl = TextEditingController();
    final noteCtl = TextEditingController();

    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => _StyledDialog(
            title: 'เพิ่มยาที่ใช้ประจำ',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _tf(nameCtl, 'ชื่อยา (เช่น Metformin)'),
                const SizedBox(height: 8),
                _tf(noteCtl, 'ขนาดยา/โน้ต (ถ้ามี)'),
              ],
            ),
            positiveText: 'เพิ่ม',
          ),
        ) ??
        false;
    if (!ok) return;

    final snap = await _doc.get();
    final data = snap.data() ?? {};
    final key = _medStorageKey(data);

    if (key == 'regularMeds') {
      final list = _asStringList(data['regularMeds']);
      final name = nameCtl.text.trim();
      if (name.isEmpty) return;
      list.add(name);
      await _doc.update({
        'regularMeds': list,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final current = _readMeds(data);
      current.add({'name': nameCtl.text.trim(), 'note': noteCtl.text.trim()});
      await _doc.update({
        'meds': current,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
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

        final name = (data['name'] ?? '').toString();
        final age = data['age'];
        final gender = (data['gender'] ?? 'other').toString();
        final blood = _readBlood(data);
        final height = data['heightCm'];
        final weight = data['weightKg'];

        final caregiver = _readCaregiver(data);
        final conditions = _readConditions(data);
        final drugAllergies = _readDrugAllergies(data);
        final meds = _readMeds(data);
        final doctor = _asMap(data['doctor']);

        _noteCtl.text = (data['note'] ?? '').toString();

        return Scaffold(
          backgroundColor: kWhite,
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _HeaderWave(
                  title: name.isEmpty ? 'รายละเอียดผู้ป่วย' : name,
                  subtitle: [
                    if (age is int) 'อายุ $age ปี',
                    if (blood.isNotEmpty) 'หมู่เลือด $blood',
                    if (height is num) 'ส่วนสูง ${height}ซม.',
                    if (weight is num) 'น้ำหนัก ${weight}กก.',
                  ].join(' • '),
                  onBack: () => Navigator.maybePop(context),
                  onEdit: () => _editBasics(data),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    children: [
                      _CardSection(
                        title: 'ติดต่อผู้ดูแล',
                        actions: [
                          IconButton(
                            onPressed: () => _editCaregiver(data),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: kPrimary,
                            ),
                            tooltip: 'แก้ไข',
                          ),
                        ],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _row('ชื่อ', (caregiver['name'] ?? '').toString()),
                            _row(
                              'ความเกี่ยวข้อง',
                              (caregiver['relation'] ?? '').toString(),
                            ),
                            _row(
                              'เบอร์โทร',
                              (caregiver['phone'] ?? '').toString(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CardSection(
                        title: 'โรคประจำตัว',
                        actions: [
                          IconButton(
                            onPressed: () => _addCondition(data),
                            icon: const Icon(Icons.add, color: kPrimary),
                            tooltip: 'เพิ่ม',
                          ),
                        ],
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
                      _CardSection(
                        title: 'การแพ้ยา',
                        actions: [
                          IconButton(
                            onPressed: _addDrugAllergy,
                            icon: const Icon(Icons.add, color: kPrimary),
                            tooltip: 'เพิ่ม',
                          ),
                        ],
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
                      _CardSection(
                        title: 'ยาที่ใช้ประจำ',
                        actions: [
                          IconButton(
                            onPressed: _addMed,
                            icon: const Icon(Icons.add, color: kPrimary),
                            tooltip: 'เพิ่ม',
                          ),
                        ],
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
                      _CardSection(
                        title: 'หมอประจำตัว',
                        actions: [
                          IconButton(
                            onPressed: () => _editDoctor(data),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: kPrimary,
                            ),
                            tooltip: 'แก้ไข',
                          ),
                        ],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _row(
                              'ชื่อแพทย์',
                              (doctor['name'] ?? '').toString(),
                            ),
                            _row(
                              'โรงพยาบาล',
                              (doctor['hospital'] ?? '').toString(),
                            ),
                            _row(
                              'เบอร์โทร',
                              (doctor['phone'] ?? '').toString(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: kWhite,
                        elevation: 4,
                        shadowColor: kPrimary.withOpacity(.12),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _CardTitle('บันทึก/หมายเหตุ'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _noteCtl,
                                maxLines: 5,
                                decoration: _inputDecoration(
                                  'ข้อมูลแพ้ยา ประวัติการรักษา อื่น ๆ',
                                ),
                              ),
                              const SizedBox(height: 8),
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
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: kWhite,
                        elevation: 4,
                        shadowColor: kPrimary.withOpacity(.12),
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          leading: const Icon(Icons.history, color: kPrimary),
                          title: const Text(
                            'เปิด Care Log ของผู้ป่วยนี้',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
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
                      Material(
                        color: kWhite,
                        elevation: 2,
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          iconColor: kPrimary,
                          textColor: kPrimary,
                          leading: const Icon(Icons.delete_outline),
                          title: const Text('ลบผู้ป่วยนี้'),
                          onTap: () async {
                            final ok =
                                await showDialog<bool>(
                                  context: context,
                                  builder: (_) => _StyledDialog(
                                    title: 'ยืนยันการลบ',
                                    child: Text(
                                      'ต้องการลบ “$name” หรือไม่? (ข้อมูล Care Log ยังอยู่)',
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

  // small UI helpers
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
      borderSide: BorderSide(color: kPrimary.withOpacity(.25), width: 1),
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

  Widget _row(String k, String v) {
    final s = v.isEmpty ? '-' : v;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: kPrimary,
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
    shape: StadiumBorder(side: BorderSide(color: kPrimary.withOpacity(.35))),
    deleteIconColor: kPrimary,
    onDeleted: onDeleted,
    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
  );
}

// ───────────────── Card section ─────────────────
class _CardSection extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget child;
  const _CardSection({required this.title, this.actions, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kWhite,
      elevation: 4,
      shadowColor: kPrimary.withOpacity(.12),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [_CardTitle(title), const Spacer(), ...?actions]),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  final String text;
  const _CardTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w800, color: kPrimary),
    );
  }
}

// ───────────────── Header wave ─────────────────
class _HeaderWave extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  const _HeaderWave({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    const h = 190.0;
    return SizedBox(
      height: h,
      child: Stack(
        children: [
          ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              color: kPrimary,
              height: h,
              width: double.infinity,
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.chevron_left, color: kWhite),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, color: kWhite),
                    tooltip: 'แก้ไขโปรไฟล์ละเอียด',
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            top: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: kWhite.withOpacity(.92),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 40);
    final cp1 = Offset(size.width * .25, size.height);
    final ep1 = Offset(size.width * .6, size.height - 28);
    path.quadraticBezierTo(cp1.dx, cp1.dy, ep1.dx, ep1.dy);

    final cp2 = Offset(size.width * .85, size.height - 52);
    final ep2 = Offset(size.width, size.height - 10);
    path.quadraticBezierTo(cp2.dx, cp2.dy, ep2.dx, ep2.dy);

    path
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// ───────────────── Styled dialog ─────────────────
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
        style: const TextStyle(color: kPrimary, fontWeight: FontWeight.w800),
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
