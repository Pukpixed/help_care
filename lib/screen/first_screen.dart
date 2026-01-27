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
    final mq = MediaQuery.of(context);
    final size = mq.size;

    // ===== Responsive sizes =====
    final logoW = (size.width * 0.42).clamp(150.0, 220.0);
    final titleSize = (size.width * 0.10).clamp(30.0, 40.0);
    final bodySize = (size.width * 0.048).clamp(14.0, 18.0);

    // ===== Waves (ชิดล่าง) =====
    // ยิ่งตัวเลขมาก คลื่นยิ่งลงล่าง (ปรับได้)
    final waveBaseTop = (size.height * 0.72).clamp(520.0, 760.0);

    // ความสูงคลื่น
    final waveH = (size.height * 0.22).clamp(150.0, 230.0);

    // คลื่นหลักสูงกว่าเพื่อกลบขอบให้เนียน
    final waveMainH = (waveH * 1.18).clamp(180.0, 280.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // ===== Background แดงเต็มจอ =====
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

            // วงกลมไฮไลต์ตกแต่ง
            Positioned(
              top: -40,
              right: -50,
              child: _GlowCircle(
                size: (size.width * 0.45).clamp(180.0, 260.0),
                color: Colors.white.withOpacity(0.10),
              ),
            ),
            Positioned(
              top: 90,
              left: -60,
              child: _GlowCircle(
                size: (size.width * 0.38).clamp(150.0, 220.0),
                color: Colors.white.withOpacity(0.06),
              ),
            ),

            // ===== Waves: ขาวไล่ขึ้นไป (3 ชั้น) =====
            // ชั้นบนสุด (จางสุด)
            Positioned(
              top: waveBaseTop - 34,
              left: 0,
              right: 0,
              child: ClipPath(
                clipBehavior: Clip.antiAlias,
                clipper: _WaveClipperLayer1(),
                child: Container(
                  height: waveH,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.white.withOpacity(0.35),
                        Colors.white.withOpacity(0.00),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ชั้นกลาง
            Positioned(
              top: waveBaseTop - 16,
              left: 0,
              right: 0,
              child: ClipPath(
                clipBehavior: Clip.antiAlias,
                clipper: _WaveClipperLayer2(),
                child: Container(
                  height: waveH,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.white.withOpacity(0.55),
                        Colors.white.withOpacity(0.00),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ชั้นหลัก (ขาวชัดสุด)
            Positioned(
              top: waveBaseTop,
              left: 0,
              right: 0,
              child: ClipPath(
                clipBehavior: Clip.antiAlias,
                clipper: _WaveClipperMainBottom(),
                child: Container(
                  height: waveMainH,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.white, Colors.white.withOpacity(0.00)],
                    ),
                  ),
                ),
              ),
            ),

            // ===== Content =====
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),

                // Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: SizedBox(
                    width: logoW,
                    child: Image.asset(
                      'assets/icon/helpcare.white.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Glass card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 22,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'แอพดูแลผู้สูงวัยและผู้ป่วยติดเตียง\nติดตามสุขภาพ นัดหมาย\nและแชร์ข้อมูลกับครอบครัว',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: bodySize,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Continue button
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: 22,
                      bottom: 14 + mq.padding.bottom,
                    ),
                    child: SizedBox(
                      width: 170,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF6B1022), Color(0xFFF24455)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF24455).withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.auth),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
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

// ===== Decor circle =====
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

// ===== Wave clippers =====
class _WaveClipperLayer1 extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final p = Path();
    p.lineTo(0, s.height * 0.45);
    p.quadraticBezierTo(
      s.width * 0.25,
      s.height * 0.18,
      s.width * 0.55,
      s.height * 0.40,
    );
    p.quadraticBezierTo(
      s.width * 0.82,
      s.height * 0.62,
      s.width,
      s.height * 0.36,
    );
    p.lineTo(s.width, s.height);
    p.lineTo(0, s.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _WaveClipperLayer2 extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final p = Path();
    p.lineTo(0, s.height * 0.50);
    p.quadraticBezierTo(
      s.width * 0.28,
      s.height * 0.22,
      s.width * 0.56,
      s.height * 0.45,
    );
    p.quadraticBezierTo(
      s.width * 0.84,
      s.height * 0.70,
      s.width,
      s.height * 0.42,
    );
    p.lineTo(s.width, s.height);
    p.lineTo(0, s.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// คลื่นหลักชิดล่าง
class _WaveClipperMainBottom extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    final p = Path();
    p.lineTo(0, s.height * 0.40);

    p.quadraticBezierTo(
      s.width * 0.22,
      s.height * 0.18,
      s.width * 0.52,
      s.height * 0.36,
    );

    p.quadraticBezierTo(
      s.width * 0.82,
      s.height * 0.58,
      s.width,
      s.height * 0.30,
    );

    p.lineTo(s.width, s.height);
    p.lineTo(0, s.height);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
