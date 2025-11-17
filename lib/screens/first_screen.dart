import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'second_screen.dart';
import '/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  @override
  void initState() {
    super.initState();
    // Splash 15 วินาทีแล้วไปหน้า SecondScreen
    Timer(const Duration(seconds: 15), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SecondScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // กำหนดขนาดอัตโนมัติ
    final logoHeight = screenHeight * 0.35;
    final loaderSize = screenWidth * 0.15;
    final carouselHeight = screenHeight * 0.15;
    final fontSize = screenWidth * 0.035;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkRed1, AppColors.pinkishRed],
          ),
        ),
        child: Column(
          children: [
            // ช่องว่างบน
            Spacer(flex: 2),

            /// โลโก้
            Flexible(
              flex: 4,
              child: Center(
                child: Image.asset(
                  'assets/icon/helpcare.white.png',
                  height: logoHeight,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // ช่องว่างระหว่างโลโก้กับ Loader
            Spacer(flex: 1),

            /// Loader
            Flexible(
              flex: 2,
              child: Center(
                child: SpinKitSpinningLines(
                  color: AppColors.pureWhite,
                  size: loaderSize,
                ),
              ),
            ),

            // ช่องว่างระหว่าง Loader กับ Carousel
            Spacer(flex: 1),

            /// Carousel
            Flexible(
              flex: 3,
              child: CarouselSlider(
                options: CarouselOptions(
                  height: carouselHeight,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.8,
                ),
                items:
                    [
                      "ดูแลกันด้วยใจ",
                      "HelpCare Application",
                      "เชื่อมต่อทุกวัยด้วยความห่วงใย",
                    ].map((text) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                            width: screenWidth * 0.8,
                            margin: const EdgeInsets.symmetric(horizontal: 5.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                text,
                                style: GoogleFonts.fraunces(
                                  color: AppColors.pureWhite,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
              ),
            ),

            // ช่องว่างล่าง
            Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
