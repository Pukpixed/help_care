import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/push_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String token = '-';

  Future<void> _loadToken() async {
    final t = await FirebaseMessaging.instance.getToken();
    setState(() => token = t ?? 'NO_TOKEN');
  }

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '-';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('uid: $uid'),
          const SizedBox(height: 12),
          const Text('FCM Token:'),
          SelectableText(token),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              await PushService.instance.saveTokenForCurrentUser();
              await _loadToken();
            },
            child: const Text('บันทึก/อัปเดต Token'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadToken,
            child: const Text('รีเฟรช Token'),
          ),
        ],
      ),
    );
  }
}
