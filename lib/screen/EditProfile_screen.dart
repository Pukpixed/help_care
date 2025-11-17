// lib/screen/edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// ✅ ใช้ GPS + แปลงเป็นที่อยู่
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;

import '../color.dart'; // <- ใช้ AppColors ตามที่ให้มา

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _age = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();

  XFile? _picked;
  bool _saving = false;

  // โหลดรูปเดิมจาก Firestore ถ้ายังไม่ได้เลือกรูปใหม่
  String? _remotePhotoUrl;
  bool _hasDoc = false; // ใช้ตัดสินใจว่าจะตั้ง createdAt ครั้งแรกเท่านั้น

  // ✅ สถานะกำลังดึงตำแหน่ง GPS
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    _hasDoc = snap.exists;
    final data = snap.data() ?? {};

    _name.text =
        (data['displayName'] as String?)?.trim() ?? (user.displayName ?? '');
    final ageVal = data['age'];
    _age.text = ageVal == null ? '' : '$ageVal';
    _phone.text = (data['phone'] as String?)?.trim() ?? '';
    _address.text = (data['address'] as String?)?.trim() ?? '';
    _remotePhotoUrl = (data['photoUrl'] as String?) ?? user.photoURL;

    if (mounted) setState(() {});
  }

  Future<void> _pick() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x != null) setState(() => _picked = x);
  }

  ImageProvider? _avatarProvider() {
    if (_picked != null) return FileImage(File(_picked!.path));
    if (_remotePhotoUrl != null && _remotePhotoUrl!.isNotEmpty) {
      return NetworkImage(_remotePhotoUrl!);
    }
    return null;
  }

  String? _nameValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'กรุณากรอกชื่อ';
    if (v.trim().length < 2) return 'ชื่อควรยาวอย่างน้อย 2 ตัวอักษร';
    return null;
  }

  String? _ageValidator(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'กรุณากรอกอายุ';
    final n = int.tryParse(t);
    if (n == null) return 'อายุต้องเป็นตัวเลข';
    if (n < 1 || n > 120) return 'กรอกอายุระหว่าง 1–120 ปี';
    return null;
  }

  String? _phoneValidator(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'กรุณากรอกเบอร์โทร';
    // อนุญาต 8–15 หลัก (ไทยนิยม 10 หลัก)
    final ok = RegExp(r'^\d{8,15}$').hasMatch(t);
    if (!ok) return 'กรุณากรอกเฉพาะตัวเลข 8–15 หลัก';
    return null;
  }

  String? _addressValidator(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'กรุณากดปุ่ม GPS เพื่อดึงที่อยู่';
    }
    if (v.trim().length < 5) return 'ที่อยู่สั้นเกินไป';
    return null;
  }

  InputDecoration _dec({required String label, String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: AppColors.burgundy) : null,
      filled: true,
      fillColor: AppColors.pinkLight.withOpacity(0.9),
      labelStyle: const TextStyle(
        color: AppColors.maroon,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: AppColors.black.withOpacity(0.35),
        fontSize: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: AppColors.pink.withOpacity(0.7),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.redDeep, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.red, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.redDeep, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  // ---------- ฟังก์ชันจัดการ GPS + แปลงเป็นที่อยู่ ----------

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // เช็คว่าเปิด Location service หรือยัง
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'กรุณาเปิด Location (GPS) ในเครื่องก่อน';
    }

    // เช็คสิทธิ์
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'แอปไม่ได้รับอนุญาตให้ใช้ตำแหน่ง';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'ระบบถูกปฏิเสธตลอด กรุณาไปเปิดสิทธิ์ใน Settings ของเครื่อง';
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _fillAddressFromGps() async {
    setState(() => _locating = true);
    try {
      final pos = await _determinePosition();

      // แปลง lat / lng -> ที่อยู่
      final placemarks = await geo.placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );

      if (placemarks.isNotEmpty) {
        final geo.Placemark p = placemarks.first;

        final addr = <String?>[
          p.name,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
        ].whereType<String>().where((e) => e.trim().isNotEmpty).join(' ');

        _address.text = addr;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  // -------------------------------------------------------------

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;
    String? photoUrl;
    String? avatarPath;

    try {
      // อัปโหลดรูป (ถ้ามี)
      if (_picked != null) {
        avatarPath = 'users/$uid/avatar.jpg';
        final ref = FirebaseStorage.instance.ref(avatarPath);
        await ref.putFile(File(_picked!.path));
        photoUrl = await ref.getDownloadURL();
      }

      final name = _name.text.trim();
      final age = int.tryParse(_age.text.trim());
      final phone = _phone.text.trim();
      final address = _address.text.trim();

      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

      final data = <String, dynamic>{
        'uid': uid,
        'email': user.email,
        'displayName': name,
        'age': age,
        'phone': phone,
        'address': address,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (avatarPath != null) 'avatarPath': avatarPath,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!_hasDoc) 'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data, SetOptions(merge: true));

      // อัปเดตโปรไฟล์ใน Firebase Auth เพื่อให้สะท้อนทันที
      try {
        await user.updateDisplayName(name);
        if (photoUrl != null) {
          await user.updatePhotoURL(photoUrl);
        }
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('บันทึกโปรไฟล์สำเร็จ')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _avatarProvider();

    return Scaffold(
      backgroundColor: AppColors.pinkLight,
      appBar: AppBar(
        backgroundColor: AppColors.maroon,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'แก้ไขโปรไฟล์',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.pinkLight, AppColors.pink],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  children: [
                    // Header + Avatar card
                    Card(
                      color: Colors.white.withOpacity(0.96),
                      elevation: 10,
                      shadowColor: AppColors.maroon.withOpacity(0.18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Chip หัวข้อ
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.pinkLight.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.person_outline,
                                    size: 16,
                                    color: AppColors.burgundy,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'ข้อมูลโปรไฟล์ผู้ใช้',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.maroon,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Avatar วงกลมเนียน ๆ
                            GestureDetector(
                              onTap: _pick,
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 116,
                                    height: 116,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.pinkLight,
                                          AppColors.pink,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.maroon.withOpacity(
                                            0.12,
                                          ),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: ClipOval(
                                        child: Container(
                                          color: AppColors.white,
                                          child: avatar != null
                                              ? Image(
                                                  image: avatar,
                                                  fit: BoxFit.cover,
                                                )
                                              : const Center(
                                                  child: Icon(
                                                    Icons.add_a_photo,
                                                    size: 32,
                                                    color: AppColors.burgundy,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // ปุ่มกล้องเล็ก
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.maroon,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.maroon.withOpacity(
                                            0.35,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'แตะที่รูปเพื่อเปลี่ยนรูปโปรไฟล์',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 20),

                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // ชื่อ
                                  TextFormField(
                                    controller: _name,
                                    decoration: _dec(
                                      label: 'ชื่อที่แสดง',
                                      icon: Icons.person,
                                    ),
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [AutofillHints.name],
                                    validator: _nameValidator,
                                  ),
                                  const SizedBox(height: 14),

                                  // อายุ
                                  TextFormField(
                                    controller: _age,
                                    decoration: _dec(
                                      label: 'อายุ (ปี)',
                                      icon: Icons.cake_outlined,
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    textInputAction: TextInputAction.next,
                                    validator: _ageValidator,
                                  ),
                                  const SizedBox(height: 14),

                                  // เบอร์โทร
                                  TextFormField(
                                    controller: _phone,
                                    decoration: _dec(
                                      label: 'เบอร์โทร',
                                      hint: 'เช่น 0812345678',
                                      icon: Icons.phone_iphone,
                                    ),
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(15),
                                    ],
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.telephoneNumber,
                                    ],
                                    validator: _phoneValidator,
                                  ),
                                  const SizedBox(height: 14),

                                  // ที่อยู่ (เลือกจาก GPS)
                                  TextFormField(
                                    controller: _address,
                                    readOnly: true,
                                    decoration:
                                        _dec(
                                          label: 'ที่อยู่ (เลือกจาก GPS)',
                                          icon: Icons.home_outlined,
                                        ).copyWith(
                                          suffixIcon: IconButton(
                                            onPressed: _locating
                                                ? null
                                                : _fillAddressFromGps,
                                            icon: _locating
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.my_location,
                                                    color: AppColors.burgundy,
                                                  ),
                                          ),
                                        ),
                                    maxLines: 3,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.fullStreetAddress,
                                    ],
                                    validator: _addressValidator,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ปุ่มบันทึกแยกด้านล่าง ใหญ่ ๆ เต็มความกว้าง
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: _saving
                          ? const Center(
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : DecoratedBox(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.red, AppColors.redDeep],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(18),
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  foregroundColor: AppColors.white,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                child: const Text('บันทึก'),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
