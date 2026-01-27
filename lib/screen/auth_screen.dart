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

    // ✅ ถ้ามี user อยู่แล้ว: เซฟ token แล้วค่อยไปหน้า Home
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
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
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
        return 'เชื่อมต่ออินเทอร์เน็ตไม่ได้ ลองสลับ Wi-Fi/ปิด VPN แล้วลองใหม่';
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้แล้ว ลอง Sign in หรือใช้อีเมลอื่น';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'weak-password':
        return 'รหัสผ่านสั้นเกินไป (อย่างน้อย 6 ตัวอักษร)';
      case 'user-not-found':
        return 'ไม่พบบัญชีนี้ ลองสมัครสมาชิกก่อน';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'account-exists-with-different-credential':
        return 'อีเมลนี้เคยสมัครด้วยวิธีอื่นแล้ว (ลอง Sign in ด้วยอีเมล/รหัสผ่าน)';
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

  Future<void> _signInWithGoogle() async {
    setState(() => loading = true);

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // ผู้ใช้กดยกเลิก

      final googleAuth = await googleUser.authentication;

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

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;

    final titleSize = (size.width * 0.09).clamp(26.0, 34.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // ===== Background =====
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.maroon, AppColors.redDeep],
                    ),
                  ),
                ),
              ),

              // วงกลมตกแต่ง
              Positioned(
                top: -40,
                right: -60,
                child: _GlowCircle(
                  size: (size.width * 0.55).clamp(200.0, 280.0),
                  color: Colors.white.withOpacity(0.10),
                ),
              ),
              Positioned(
                top: 110,
                left: -70,
                child: _GlowCircle(
                  size: (size.width * 0.45).clamp(180.0, 240.0),
                  color: Colors.white.withOpacity(0.06),
                ),
              ),

              // ✅ Content เต็มจอพอดี (และยัง scroll ได้)
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign in',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: titleSize,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'เข้าสู่ระบบเพื่อใช้งาน HelpCare',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Card
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 24,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              clipBehavior: Clip.antiAlias,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  18,
                                  16,
                                  18,
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Email',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: email,
                                        enabled: !loading,
                                        validator: _emailValidator,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(
                                            Icons.mail_outline,
                                          ),
                                          hintText: 'you@example.com',
                                          filled: true,
                                          fillColor: const Color(0xFFF5F6FA),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      const Text(
                                        'Password',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: password,
                                        enabled: !loading,
                                        validator: _passValidator,
                                        obscureText: obscure,
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(
                                            Icons.lock_outline,
                                          ),
                                          hintText: '••••••••',
                                          filled: true,
                                          fillColor: const Color(0xFFF5F6FA),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          suffixIcon: IconButton(
                                            onPressed: loading
                                                ? null
                                                : () => setState(
                                                    () => obscure = !obscure,
                                                  ),
                                            icon: Icon(
                                              obscure
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 18),

                                      SizedBox(
                                        height: 48,
                                        child: ElevatedButton(
                                          onPressed: loading ? null : _signIn,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.redDeep,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: loading
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
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

                                      SizedBox(
                                        height: 48,
                                        child: OutlinedButton(
                                          onPressed: loading ? null : _signUp,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.black87,
                                            side: const BorderSide(
                                              color: Color(0x22000000),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: const Text(
                                            'Create account',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 14),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 1,
                                              color: const Color(0x22000000),
                                            ),
                                          ),
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Text(
                                              'หรือ',
                                              style: TextStyle(
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              height: 1,
                                              color: const Color(0x22000000),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 14),

                                      SizedBox(
                                        height: 48,
                                        child: OutlinedButton.icon(
                                          onPressed: loading
                                              ? null
                                              : _signInWithGoogle,
                                          icon: const Icon(
                                            Icons.g_mobiledata_rounded,
                                            size: 28,
                                          ),
                                          label: const Text(
                                            'Continue with Google',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.black87,
                                            backgroundColor: const Color(
                                              0xFFF5F6FA,
                                            ),
                                            side: BorderSide.none,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 10),
                                      const Center(
                                        child: Text(
                                          'หากมีบัญชีอยู่แล้ว กด Continue เพื่อเข้าสู่ระบบ',
                                          style: TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const Spacer(), // ✅ ดันให้เต็มจอพอดี
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
