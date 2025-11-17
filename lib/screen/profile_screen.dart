import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../color.dart';
import '../routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final age = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();

  String gender = 'หญิง';
  bool loading = true;
  bool saving = false;

  late String uid;
  Map<String, dynamic>? _args;
  bool _listenersAdded = false;

  @override
  void dispose() {
    name.dispose();
    age.dispose();
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (loading) {
      _args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      uid = FirebaseAuth.instance.currentUser?.uid ?? _args?['uid'];
      _load();
    }

    // อัปเดตรูปตัวอักษรใน Avatar ตามชื่อ
    if (!_listenersAdded) {
      name.addListener(() => setState(() {}));
      _listenersAdded = true;
    }
  }

  Future<void> _load() async {
    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await ref.get();
      final data = snap.data() ?? {};

      final u = FirebaseAuth.instance.currentUser;

      name.text = (data['name'] ?? u?.displayName ?? '').toString();
      age.text = (data['age'] ?? '').toString();
      phone.text = (data['phone'] ?? '').toString();
      address.text = (data['address'] ?? '').toString();
      gender = (data['gender'] ?? 'หญิง').toString();
    } catch (e) {
      _snack('โหลดข้อมูลไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF5F6F7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  String get _initials {
    final raw = name.text.trim().isNotEmpty
        ? name.text.trim()
        : (_args?['displayName'] ??
              _args?['email'] ??
              FirebaseAuth.instance.currentUser?.email ??
              'U');
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0].isNotEmpty ? parts[0][0] : 'U').toUpperCase() +
          (parts[1].isNotEmpty ? parts[1][0] : '');
    }
    return raw.isNotEmpty ? raw[0].toUpperCase() : 'U';
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => saving = true);
    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(uid);
      await ref.set({
        'name': name.text.trim(),
        'age': int.tryParse(age.text.trim()) ?? 0,
        'phone': phone.text.trim(),
        'address': address.text.trim(),
        'gender': gender,
        'onboardingComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // อัปเดต displayName ใน Auth ถ้ายังว่าง
      final u = FirebaseAuth.instance.currentUser;
      if (u != null && (u.displayName == null || u.displayName!.isEmpty)) {
        await u.updateDisplayName(name.text.trim());
      }

      if (!mounted) return;
      _snack('บันทึกโปรไฟล์เรียบร้อย');
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } catch (e) {
      _snack('บันทึกไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _primaryButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.redDeep, AppColors.maroon],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.redDeep.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'บันทึกและไปต่อ',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerH = 210.0;

    return Scaffold(
      backgroundColor: AppColors.maroon,
      body: SafeArea(
        child: loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.6))
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    // Header โค้งมน
                    Container(
                      height: headerH,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.pink, AppColors.redDeep],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(50),
                          bottomRight: Radius.circular(50),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'โปรไฟล์',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'กรอกข้อมูลพื้นฐานของคุณ',
                              style: TextStyle(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // การ์ดฟอร์มลอย
                    Transform.translate(
                      offset: const Offset(0, -36),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(18),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Avatar อักษรย่อ
                                  CircleAvatar(
                                    radius: 34,
                                    backgroundColor: AppColors.pink.withOpacity(
                                      0.35,
                                    ),
                                    child: Text(
                                      _initials,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  TextFormField(
                                    controller: name,
                                    decoration: _input(
                                      'ชื่อ-นามสกุล',
                                      Icons.person_outline,
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'กรอกชื่อ'
                                        : null,
                                  ),
                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: age,
                                          keyboardType: TextInputType.number,
                                          decoration: _input(
                                            'อายุ (ปี)',
                                            Icons.cake_outlined,
                                          ),
                                          validator: (v) {
                                            final n = int.tryParse(
                                              (v ?? '').trim(),
                                            );
                                            if (n == null || n < 0)
                                              return 'กรอกอายุให้ถูกต้อง';
                                            return null;
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: gender,
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'หญิง',
                                              child: Text('หญิง'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'ชาย',
                                              child: Text('ชาย'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'อื่นๆ',
                                              child: Text('อื่น ๆ'),
                                            ),
                                          ],
                                          onChanged: (v) => setState(
                                            () => gender = v ?? 'หญิง',
                                          ),
                                          decoration:
                                              _input(
                                                'เพศ',
                                                Icons.wc_outlined,
                                              ).copyWith(
                                                prefixIcon: const Icon(
                                                  Icons.wc_outlined,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  TextFormField(
                                    controller: phone,
                                    keyboardType: TextInputType.phone,
                                    decoration: _input(
                                      'เบอร์โทร',
                                      Icons.phone_outlined,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  TextFormField(
                                    controller: address,
                                    decoration: _input(
                                      'ที่อยู่ (ไม่บังคับ)',
                                      Icons.home_outlined,
                                    ),
                                    maxLines: 2,
                                  ),
                                  const SizedBox(height: 18),

                                  saving
                                      ? const SizedBox(
                                          height: 52,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.6,
                                            ),
                                          ),
                                        )
                                      : _primaryButton(
                                          'บันทึกและไปหน้า Home',
                                          _save,
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
