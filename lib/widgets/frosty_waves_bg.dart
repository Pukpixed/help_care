import 'dart:ui';
import 'package:flutter/material.dart';

/// พื้นหลังกราเดียนต์ + คลื่นสีขาวซ้อนกัน (ฟุ้งนุ่ม ๆ)
class FrostyWavesBackground extends StatelessWidget {
  const FrostyWavesBackground({
    super.key,
    this.top = const Color(0xFF7B86D9), // สีบน (ม่วงน้ำเงิน)
    this.bottom = const Color(0xFF9FA9E8), // สีล่าง (ม่วงอ่อน)
    this.waveColor = Colors.white, // สีคลื่น
    this.heightFactor = .38, // ความสูงบริเวณคลื่น (สัดส่วนหน้าจอ)
  });

  final Color top, bottom, waveColor;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // พื้นหลังกราเดียนต์
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [top, bottom],
            ),
          ),
        ),

        // คลื่นซ้อน 3 ชั้นที่ด้านล่าง (ชั้นหลังจางที่สุด)
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * heightFactor,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _WaveLayer(
                  color: waveColor.withOpacity(.20),
                  amplitude: 24,
                  yOffset: 18,
                  blurSigma: 14,
                ),
                _WaveLayer(
                  color: waveColor.withOpacity(.35),
                  amplitude: 20,
                  yOffset: 8,
                  blurSigma: 10,
                ),
                _WaveLayer(
                  color: waveColor.withOpacity(.95),
                  amplitude: 18,
                  yOffset: 0,
                  blurSigma: 4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WaveLayer extends StatelessWidget {
  const _WaveLayer({
    required this.color,
    required this.amplitude,
    required this.yOffset,
    required this.blurSigma,
  });

  final Color color;
  final double amplitude;
  final double yOffset;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        // ให้ขอบคลื่นดูฟุ้งนุ่ม
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: CustomPaint(
          painter: _WavePainter(
            color: color,
            amplitude: amplitude,
            yOffset: yOffset,
          ),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required this.color,
    required this.amplitude,
    required this.yOffset,
  });

  final Color color;
  final double amplitude;
  final double yOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final path = Path();
    // เริ่มจากมุมล่างซ้าย
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * .40 + yOffset);

    // สร้างคลื่นโค้ง ๆ 3–4 ช่วง
    final double w = size.width;
    final double baseY = size.height * .42 + yOffset;

    path.cubicTo(
      w * .15,
      baseY - amplitude,
      w * .25,
      baseY + amplitude,
      w * .40,
      baseY - amplitude * .6,
    );
    path.cubicTo(
      w * .55,
      baseY - amplitude * 1.2,
      w * .70,
      baseY + amplitude * .9,
      w * .82,
      baseY - amplitude * .4,
    );
    path.cubicTo(
      w * .90,
      baseY - amplitude * 1.0,
      w * 1.05,
      baseY + amplitude * .6,
      w,
      baseY - amplitude,
    );

    // ปิด path ลงด้านล่าง
    path.lineTo(w, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.amplitude != amplitude ||
      oldDelegate.yOffset != yOffset;
}
