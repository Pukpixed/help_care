// lib/services/account_service.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AccountService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  /// ลบไฟล์จาก Storage อย่างปลอดภัย (ไฟล์ไม่มีก็ไม่เป็นไร)
  static Future<void> _safeDeleteStorage({
    String? avatarPath,
    String? photoUrl,
  }) async {
    try {
      if (avatarPath != null && avatarPath.isNotEmpty) {
        await _storage.ref(avatarPath).delete();
      } else if (photoUrl != null &&
          photoUrl.isNotEmpty &&
          (photoUrl.startsWith('gs://') ||
              photoUrl.contains('firebasestorage.googleapis.com'))) {
        await _storage.refFromURL(photoUrl).delete();
      }
    } on FirebaseException catch (e) {
      // มองข้ามถ้าไฟล์ไม่มี
      if (e.code != 'object-not-found') rethrow;
    } catch (_) {}
  }

  /// ขอรหัสผ่านเพื่อนำมา reauthenticate (สำหรับ email/password)
  static Future<bool> _promptReauthEmailPassword(BuildContext context) async {
    final user = _auth.currentUser;
    final email = user?.email ?? '';
    if (email.isEmpty) return false;

    final c = TextEditingController();
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('ยืนยันตัวตน'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('กรอกรหัสผ่านของบัญชี\n$email'),
                const SizedBox(height: 12),
                TextField(
                  controller: c,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'รหัสผ่าน',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('ยืนยัน'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return false;
    try {
      final cred = EmailAuthProvider.credential(
        email: email,
        password: c.text.trim(),
      );
      await user!.reauthenticateWithCredential(cred);
      return true;
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ยืนยันตัวตนไม่สำเร็จ')));
      return false;
    }
  }

  /// ลบบัญชีผู้ใช้แบบครบลูป (Storage → Firestore → Auth)
  static Future<void> deleteCurrentUser(BuildContext context) async {
    final user = _auth.currentUser;
    final uid = user?.uid;
    if (uid == null) return;

    try {
      // อ่านข้อมูล Firestore เพื่อดึง path/URL รูป
      final userRef = _db.collection('users').doc(uid);
      final snap = await userRef.get();
      final data = snap.data() ?? {};
      final avatarPath = (data['avatarPath'] as String?)?.trim();
      final photoUrl = (data['photoUrl'] as String?)?.trim();

      // ลบรูป (ถ้ามี) แต่ถ้าไม่มี ไม่ต้อง error
      await _safeDeleteStorage(avatarPath: avatarPath, photoUrl: photoUrl);

      // ลบเอกสารผู้ใช้ (ถ้ามี subcollections จำนวนมาก แนะนำย้ายไป Cloud Functions)
      await userRef.delete().catchError((_) {});

      // ลบตัวตนใน Auth (ถ้าต้อง reauth จะจับด้านล่าง)
      await user!.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // ขอรหัสผ่านมา reauth แล้วลองลบใหม่
        final ok = await _promptReauthEmailPassword(context);
        if (!ok) return;
        await _auth.currentUser!.delete();
      } else {
        rethrow;
      }
    }
  }

  static Future<void> signOut(BuildContext context) async {
    await _auth.signOut();
  }
}
