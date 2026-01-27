import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/push_service.dart';
import '../screen/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> _signInAnon() async {
    await FirebaseAuth.instance.signInAnonymously();
    await PushService.instance.saveTokenForCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Login')),
            body: Center(
              child: ElevatedButton(
                onPressed: _signInAnon,
                child: const Text('เข้าสู่ระบบ (Anonymous)'),
              ),
            ),
          );
        }
        return const HomeScreen();
      },
    );
  }
}
