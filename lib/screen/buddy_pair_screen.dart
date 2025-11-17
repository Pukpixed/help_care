// lib/screen/buddy_pair_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BuddyPairScreen extends StatefulWidget {
  const BuddyPairScreen({super.key});

  @override
  State<BuddyPairScreen> createState() => _BuddyPairScreenState();
}

class _BuddyPairScreenState extends State<BuddyPairScreen> {
  static const Color _brandMaroon = Color(0xFF7B2D2D);
  static const Color _brandRed = Color(0xFFF24455);

  bool _saving = false;
  String? _myUid;

  @override
  void initState() {
    super.initState();
    _myUid = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _pairWithBuddy(String buddyUid) async {
    if (_myUid == null || _saving) return;
    if (buddyUid == _myUid) {
      _showSnack('ไม่สามารถจับคู่กับตัวเองได้');
      return;
    }

    setState(() => _saving = true);
    try {
      final users = FirebaseFirestore.instance.collection('users');
      final meDoc = await users.doc(_myUid).get();
      final buddyDoc = await users.doc(buddyUid).get();

      final meName = (meDoc.data()?['name'] ?? '').toString();
      final buddyName = (buddyDoc.data()?['name'] ?? '').toString();

      final buddies = FirebaseFirestore.instance.collection('buddies');
      final batch = FirebaseFirestore.instance.batch();

      batch.set(buddies.doc(_myUid), {
        'buddyUid': buddyUid,
        'buddyName': buddyName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(buddies.doc(buddyUid), {
        'buddyUid': _myUid,
        'buddyName': meName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      if (!mounted) return;
      _showSnack('จับคู่บัดดี้เรียบร้อยแล้ว');
      Navigator.pop(context, true); // ส่งค่า true กลับไปให้หน้า SOS
    } catch (e) {
      _showSnack('จับคู่ไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final uid = _myUid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('จับคู่บัดดี้ช่วย SOS'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_brandMaroon, _brandRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: uid == null
          ? const Center(child: Text('กรุณาเข้าสู่ระบบก่อน'))
          : Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF2F4), Color(0xFFFFF8FA)],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'เชื่อมเพื่อนหรือคนในครอบครัวให้เป็น “บัดดี้” คอยรับการแจ้งเตือน SOS',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. ให้เพื่อนเปิดจอนี้แล้วแสดง QR โค้ด\n'
                      '2. อีกคนกดปุ่ม “สแกน QR บัดดี้” แล้วสแกนเพื่อจับคู่',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // การ์ด QR
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDF3F5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: QrImageView(
                                data: 'helpcare-buddy:$uid',
                                size: 180,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'ให้เพื่อนเปิด QR นี้แล้วสแกน',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'รหัสไอดีของคุณ:\n$uid',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // ปุ่มสแกน
                    ElevatedButton.icon(
                      onPressed: _saving
                          ? null
                          : () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const _BuddyScanScreen(),
                                ),
                              );
                              if (result is String) {
                                await _pairWithBuddy(result);
                              }
                            },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('สแกน QR บัดดี้'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandRed,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_saving)
                      const Center(child: CircularProgressIndicator()),

                    const SizedBox(height: 18),
                    Text(
                      'Tip: สามารถเพิ่ม gesture เขย่าเพื่อเปิดหน้านี้จากหน้าอื่น ๆ ภายหลังได้ '
                      'เพื่อให้เข้าถึงการจับคู่บัดดี้ได้อย่างรวดเร็ว',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// หน้าสแกน QR เพื่ออ่าน UID ของบัดดี้
class _BuddyScanScreen extends StatelessWidget {
  const _BuddyScanScreen();

  static const Color _brandMaroon = Color(0xFF7B2D2D);
  static const Color _brandRed = Color(0xFFF24455);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกน QR บัดดี้'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_brandMaroon, _brandRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final raw = barcodes.first.rawValue ?? '';
              if (!raw.startsWith('helpcare-buddy:')) return;
              final buddyUid = raw.replaceFirst('helpcare-buddy:', '');
              Navigator.pop(context, buddyUid);
            },
          ),
          // overlay ข้อความ
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'นำกล้องไปสแกน QR โค้ดบัดดี้',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'เมื่อสแกนสำเร็จ ระบบจะจับคู่บัดดี้ให้โดยอัตโนมัติ\n'
                'บัดดี้ของคุณจะได้รับการแจ้งเตือนเมื่อมี SOS',
                style: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
