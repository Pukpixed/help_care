import 'package:flutter/material.dart';
import '../routes.dart';
import '../color.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final headerH = size.height * 0.56;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // พื้นสีด้านบน
            Container(
              height: headerH,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.maroon, // น้ำตาลแดง
                    AppColors.redDeep, // แดงเข้ม
                  ],
                ),
              ),
            ),

            // เวฟขาวกินด้านล่างของหัว
            Positioned(
              top: headerH - 80,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: _WaveClipperDown(),
                child: Container(height: 160, color: AppColors.white),
              ),
            ),

            // เนื้อหา (โลโก้ + ข้อความ + ปุ่ม)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // โลโก้มุมซ้ายบน
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: size.width * 0.45,
                    child: Image.asset(
                      'assets/icon/helpcare.white.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ข้อความใต้โลโก้
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 26),
                  child: Text(
                    'Welcome',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'แอพดูแลผู้สูงวัยและผู้ป่วยติดเตียง\nติดตามสุขภาพ นัดหมาย\nและแชร์ข้อมูลกับครอบครัว',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      height: 1.35,
                    ),
                  ),
                ),

                const Spacer(),

                // ปุ่ม Continue
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24, bottom: 24),
                    child: SizedBox(
                      width: 160,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.maroon,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.auth),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// เวฟโค้งด้านล่างของส่วนหัว
class _WaveClipperDown extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 40);
    path.quadraticBezierTo(size.width * 0.25, 0, size.width * 0.5, 24);
    path.quadraticBezierTo(size.width * 0.75, 48, size.width, 12);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
