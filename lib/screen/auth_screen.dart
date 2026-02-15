// lib/screen/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../routes.dart';
import '../color.dart';
import '../services/push_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();

  bool obscure = true;
  bool loading = false;

  @override
  void initState() {
    super.initState();

    final u = FirebaseAuth.instance.currentUser;

    if (u != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await PushService.instance.saveTokenForCurrentUser();
        } catch (_) {}
        if (mounted) _goHome();
      });
    }
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  String? _emailValidator(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'กรอกอีเมล';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
    if (!ok) return 'รูปแบบอีเมลไม่ถูกต้อง';
    return null;
  }

  String? _passValidator(String? v) {
    final t = v ?? '';
    if (t.isEmpty) return 'กรอกรหัสผ่าน';
    if (t.length < 6) return 'อย่างน้อย 6 ตัวอักษร';
    return null;
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'network-request-failed':
        return 'เชื่อมต่ออินเทอร์เน็ตไม่ได้';
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้แล้ว';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านสั้นเกินไป';
      case 'user-not-found':
        return 'ไม่พบบัญชีนี้';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'account-exists-with-different-credential':
        return 'บัญชีนี้เคยสมัครด้วยวิธีอื่น';
      default:
        return 'เกิดข้อผิดพลาด ($code)';
    }
  }

  Future<void> _upsertUserDoc(User user, {bool isNew = false}) async {
    final ref =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    await ref.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'provider': user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : null,
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ===============================
  // EMAIL SIGN IN
  // ===============================
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final cred =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );

      await _upsertUserDoc(cred.user!, isNew: false);
      await PushService.instance.saveTokenForCurrentUser();

      if (!mounted) return;
      _goHome();
    } on FirebaseAuthException catch (e) {
      _toast(_mapAuthError(e.code));
    } catch (e) {
      _toast('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ===============================
  // SIGN UP
  // ===============================
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );

      await _upsertUserDoc(cred.user!, isNew: true);
      await PushService.instance.saveTokenForCurrentUser();

      if (!mounted) return;
      _goHome();
    } on FirebaseAuthException catch (e) {
      _toast(_mapAuthError(e.code));
    } catch (e) {
      _toast('สมัครสมาชิกไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ===============================
  // GOOGLE SIGN IN (เวอร์ชันเสถียร)
  // ===============================
  Future<void> _signInWithGoogle() async {
    setState(() => loading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email'],
      );

      final GoogleSignInAccount? googleUser =
          await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => loading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred =
          await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final isNew =
          userCred.additionalUserInfo?.isNewUser ?? false;

      await _upsertUserDoc(userCred.user!, isNew: isNew);
      await PushService.instance.saveTokenForCurrentUser();

      if (!mounted) return;
      _goHome();
    } on FirebaseAuthException catch (e) {
      _toast(_mapAuthError(e.code));
    } catch (e) {
      _toast('Google Sign-In ไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.redDeep,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        "Sign In",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextFormField(
                        controller: email,
                        validator: _emailValidator,
                        decoration: const InputDecoration(
                          labelText: "Email",
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: password,
                        validator: _passValidator,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: "Password",
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() => obscure = !obscure);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : _signIn,
                          child: loading
                              ? const CircularProgressIndicator()
                              : const Text("Continue"),
                        ),
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: loading ? null : _signUp,
                          child: const Text("Create account"),
                        ),
                      ),
                      const SizedBox(height: 10),

                      const Divider(),
                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                              loading ? null : _signInWithGoogle,
                          icon: const Icon(Icons.g_mobiledata),
                          label: const Text(
                            "Continue with Google",
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
      ),
    );
  }
}
