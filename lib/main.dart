import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'helpcare',
      theme: ThemeData(primarySwatch: Colors.purple, useMaterial3: true),
      debugShowCheckedModeBanner: false,

      // ✅ เริ่มที่ FirstScreen
      initialRoute: AppRoutes.first,

      // ✅ ใช้ระบบ route จาก routes.dart
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
