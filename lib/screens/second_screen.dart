import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // ✅ ใช้ Google Fonts
import '/colors.dart';

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "HelpCare",
          style: GoogleFonts.fraunces(
            fontSize: 34, // <-- เพิ่มขนาดฟอนต์ตรงนี้
            fontWeight: FontWeight.bold,
            color: AppColors.pureWhite,
          ),
        ),
        backgroundColor: AppColors.darkRed1,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.darkRed2, AppColors.pinkishRed],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, color: AppColors.pureWhite, size: 100),
              const SizedBox(height: 20),
              Text(
                "ยินดีต้อนรับสู่ HelpCare",
                style: GoogleFonts.fraunces(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pureWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "เชื่อมต่อทุกวัยด้วยความห่วงใย",
                style: TextStyle(fontSize: 16, color: AppColors.pureWhite),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
