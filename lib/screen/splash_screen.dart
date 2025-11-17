import 'dart:async';
import 'package:flutter/material.dart';
import 'first_screen.dart';
import '../color.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _logoPath = 'assets/icon/helpcare.white.png'; // ← ใช้ขีดกลาง

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // โหลดรูปเข้าหน่วยความจำล่วงหน้า ลดอาการกระพริบ
    precacheImage(const AssetImage(_logoPath), context).catchError((_) {});
  }

  @override
  void initState() {
    super.initState();
    // รอ 10 วิ แล้วไป FirstScreen
    Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FirstScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // พื้นหลังไล่เฉด (เข้ม -> แดง)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.maroon, AppColors.redDeep],
              ),
            ),
          ),
          // วงแหวนศูนย์กลางโปร่งแสง
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 0),
                radius: 1.15,
                stops: const [
                  0.00,
                  0.08,
                  0.08,
                  0.16,
                  0.16,
                  0.24,
                  0.24,
                  0.32,
                  0.32,
                  0.40,
                  0.40,
                  0.48,
                  0.48,
                  0.56,
                  0.56,
                  1.00,
                ],
                colors: [
                  for (final o in [
                    0.18,
                    0.06,
                    0.18,
                    0.06,
                    0.18,
                    0.06,
                    0.18,
                    0.06,
                  ]) ...[
                    AppColors.white.withOpacity(o),
                    AppColors.white.withOpacity(o),
                  ],
                ],
              ),
            ),
          ),
          // โลโก้ + ตัวโหลด
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  _logoPath,
                  width: size.width * 0.60,
                  fit: BoxFit.contain,
                  // ถ้า asset หาไม่เจอ ให้เงียบ ๆ
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
