import 'package:flutter/material.dart';

class AppColors {
  static const Color pinkLight = Color(0xFFFFDBE8); // สีชมพูอ่อน
  static const Color pink = Color(0xFFFF94B2); // ชมพู
  static const Color red = Color(0xFFF24455); // แดงสด
  static const Color redDeep = Color(0xFFE5203A); // แดงเข้ม
  static const Color maroon = Color(0xFF660F24); // น้ำตาลแดง
  static const Color burgundy = Color(0xFF2B0013); // แดงเลือดหมูเข้ม
  static const Color white = Color(0xFFFFFFFF); // ขาว
  static const Color black = Color(0xFF000000); // ดำ
  static const Color greyLight = Color(0xFFF5F5F5); // เทาอ่อน
  static const Color grey = Color(0xFF9E9E9E); // เทา

  // สรุปด้านบน (สำรองเผื่อใช้)
  static const Gradient topSummaryGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF22D3EE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
