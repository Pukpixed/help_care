// lib/screen/add_notification_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../color.dart';

class AddNotificationScreen extends StatefulWidget {
  final String patientId;
  const AddNotificationScreen({super.key, required this.patientId});

  @override
  State<AddNotificationScreen> createState() => _AddNotificationScreenState();
}

class _AddNotificationScreenState extends State<AddNotificationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _detail = TextEditingController();

  final _bp = TextEditingController(); // ความดัน
  final _sugar = TextEditingController(); // น้ำตาล
  final _temp = TextEditingController(); // อุณหภูมิ
  final _pulse = TextEditingController(); // ชีพจร

  bool loading = false;
  String type = 'การดูแล';

  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
    _bp.dispose();
    _sugar.dispose();
    _temp.dispose();
    _pulse.dispose();
    super.dispose();
  }

  String? _req(String? v, String msg) {
    if ((v ?? '').trim().isEmpty) return msg;
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patientId)
          .collection('careAlerts')
          .add({
            'type': type,
            'title': _title.text.trim(),
            'detail': _detail.text.trim(),
            'vitals': {
              'bp': _bp.text.trim(),
              'sugar': _sugar.text.trim(),
              'temp': _temp.text.trim(),
              'pulse': _pulse.text.trim(),
            },
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลการดูแลเรียบร้อย')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('เพิ่มแจ้งเตือน/การดูแล'),
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEAEAF2)),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ประเภท',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: type,
                      items: const [
                        DropdownMenuItem(
                          value: 'การดูแล',
                          child: Text('การดูแล'),
                        ),
                        DropdownMenuItem(
                          value: 'นัดหมาย',
                          child: Text('นัดหมาย'),
                        ),
                        DropdownMenuItem(value: 'ยา', child: Text('ยา')),
                        DropdownMenuItem(
                          value: 'ฉุกเฉิน',
                          child: Text('ฉุกเฉิน'),
                        ),
                      ],
                      onChanged: loading
                          ? null
                          : (v) => setState(() => type = v!),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'หัวข้อ',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _title,
                      enabled: !loading,
                      validator: (v) => _req(v, 'กรอกหัวข้อ'),
                      decoration: InputDecoration(
                        hintText: 'เช่น วัดความดัน / เปลี่ยนผ้าอ้อม / ให้อาหาร',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'รายละเอียด',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _detail,
                      enabled: !loading,
                      validator: (v) => _req(v, 'กรอกรายละเอียด'),
                      minLines: 3,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'เช่น เวลา/อาการ/ข้อสังเกตเพิ่มเติม',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'สัญญาณชีพ (ถ้ามี)',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),

                    _TwoFieldRow(
                      left: _VitalField(
                        controller: _bp,
                        label: 'ความดัน',
                        hint: '120/80',
                        icon: Icons.monitor_heart_outlined,
                        enabled: !loading,
                      ),
                      right: _VitalField(
                        controller: _sugar,
                        label: 'น้ำตาล',
                        hint: 'mg/dL',
                        icon: Icons.bloodtype_outlined,
                        enabled: !loading,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _TwoFieldRow(
                      left: _VitalField(
                        controller: _temp,
                        label: 'อุณหภูมิ',
                        hint: '°C',
                        icon: Icons.thermostat_outlined,
                        enabled: !loading,
                      ),
                      right: _VitalField(
                        controller: _pulse,
                        label: 'ชีพจร',
                        hint: 'ครั้ง/นาที',
                        icon: Icons.favorite_outline,
                        enabled: !loading,
                      ),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.redDeep,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'บันทึก',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TwoFieldRow extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _TwoFieldRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }
}

class _VitalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool enabled;

  const _VitalField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
