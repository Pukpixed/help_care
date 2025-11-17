import 'dart:math' as math;
import 'package:flutter/material.dart';

/// พื้นหลังไล่สี + ลายจุด (เบาเครื่อง ใช้ได้ทุกแพลตฟอร์ม)
class GradientDotsBackground extends StatelessWidget {
  const GradientDotsBackground({
    super.key,
    this.start = const Color(0xFFF8F9FF),
    this.end   = const Color(0xFFF6F8FE),
    this.tint1 = const Color(0xFF981F3D), // แสงไฮไลท์วงกลม (แดงอมชมพู)
    this.tint2 = const Color(0xFFEF4A57),
    this.dotColor = const Color(0xFFFFFFFF),
    this.dotOpacity = .18,
    this.dotSpacing = 22,
    this.dotRadius = 1.6,
  });

  final Color start, end;       // สีพื้นหลังไล่สี
  final Color tint1, tint2;     // วงกลมเรืองแสงนุ่ม ๆ
  final Color dotColor;         // สีจุด
  final double dotOpacity;      // ความโปร่งใสของจุด
  final double dotSpacing;      // ระยะห่างจุด
  final double dotRadius;       // ขนาดจุด

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ไล่สีหลักทั้งหน้า
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [start, end],
              ),
            ),
          ),

          // ไฮไลท์วงกลมฟุ้ง ๆ 2 วง (ให้รู้สึกมีมิติ)
          IgnorePointer(
            child: Stack(
              children: [
                Positioned(
                  left: -120, top: -80,
                  child: _blurCircle(color: tint1.withOpacity(.24), size: 320),
                ),
                Positioned(
                  right: -60, top: 180,
                  child: _blurCircle(color: tint2.withOpacity(.20), size: 260),
                ),
              ],
            ),
          ),

          // ลายจุดบาง ๆ ทับด้านบน
          CustomPaint(
            painter: _DotsPainter(
              color: dotColor.withOpacity(dotOpacity),
              spacing: dotSpacing,
              r: dotRadius,
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle({required Color color, required double size}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({required this.color, required this.spacing, required this.r});
  final Color color;
  final double spacing;
  final double r;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..isAntiAlias = true;
    // ทำเลย์เอาท์เป็นกริดแบบ offset (ให้ดูเป็นลายเฉียง)
    final double offset = spacing / 2;
    for (double y = 0; y < size.height; y += spacing) {
      final bool shift = ((y / spacing).floor() % 2) == 1;
      for (double x = shift ? offset : 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter old) {
    return old.color != color ||
        old.spacing != spacing ||
        old.r != r;
  }
}
