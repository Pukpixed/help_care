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
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

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
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
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
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
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
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) setState(() => loading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final isNew = userCred.additionalUserInfo?.isNewUser ?? false;

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
  // UI (ดีไซน์หน้าอันที่ 1)
  // ===============================
  @override
  Widget build(BuildContext context) {
    // โทนสีตามภาพ (ใช้ AppColors.redDeep เป็นฐาน)
    const bgTop = Color(0xFF660F24);
    const bgBottom = Color.fromARGB(255, 154, 18, 29); // แดงสด
    const primaryRed = Color(0xFFE01B2D);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bgTop, bgBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // วงกลมตกแต่งพื้นหลัง (ขวาบน)
            const Positioned(
              right: -90,
              top: -70,
              child: _BgCircle(size: 220, opacity: 0.14),
            ),
            const Positioned(
              right: -40,
              top: 40,
              child: _BgCircle(size: 140, opacity: 0.08),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      const Text(
                        'Sign in',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'เข้าสู่ระบบเพื่อใช้งาน HelpCare',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // การ์ดขาว
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _FieldLabel('Email'),
                              const SizedBox(height: 8),
                              _InputBox(
                                leading: Icons.mail_outline,
                                hintText: 'you@example.com',
                                controller: email,
                                validator: _emailValidator,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !loading,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 14),

                              const _FieldLabel('Password'),
                              const SizedBox(height: 8),
                              _InputBox(
                                leading: Icons.lock_outline,
                                hintText: '••••••••',
                                controller: password,
                                validator: _passValidator,
                                obscureText: obscure,
                                enabled: !loading,
                                textInputAction: TextInputAction.done,
                                trailing: IconButton(
                                  splashRadius: 18,
                                  icon: Icon(
                                    obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.black54,
                                    size: 20,
                                  ),
                                  onPressed: loading
                                      ? null
                                      : () =>
                                            setState(() => obscure = !obscure),
                                ),
                                onFieldSubmitted: (_) {
                                  if (!loading) _signIn();
                                },
                              ),

                              const SizedBox(height: 16),

                              // Continue (แดง)
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.maroon,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: loading ? null : _signIn,
                                  child: loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Continue',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Create account (ขอบ)
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black87,
                                    side: BorderSide(
                                      color: Colors.black12.withOpacity(0.12),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: loading ? null : _signUp,
                                  child: const Text(
                                    'Create account',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Divider "หรือ"
                              Row(
                                children: const [
                                  Expanded(child: Divider(height: 1)),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Text(
                                      'หรือ',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(height: 1)),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Google
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF3F4F6),
                                    foregroundColor: Colors.black87,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: loading ? null : _signInWithGoogle,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      _GoogleG(),
                                      SizedBox(width: 10),
                                      Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              const Center(
                                child: Text(
                                  'หากมีบัญชีอยู่แล้ว กด Continue เพื่อเข้าสู่ระบบ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black45,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================
// UI Widgets
// ===============================
class _BgCircle extends StatelessWidget {
  final double size;
  final double opacity;
  const _BgCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _InputBox extends StatelessWidget {
  final IconData leading;
  final String hintText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;
  final bool enabled;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const _InputBox({
    required this.leading,
    required this.hintText,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
    this.enabled = true,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(leading, color: Colors.black54, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: controller,
              validator: validator,
              keyboardType: keyboardType,
              obscureText: obscureText,
              enabled: enabled,
              textInputAction: textInputAction,
              onFieldSubmitted: onFieldSubmitted,
              style: const TextStyle(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Colors.black45,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.black12),
      ),
      child: const Text('G', style: TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}
