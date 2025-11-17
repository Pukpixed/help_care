// lib/screen/sos_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

import 'buddy_pair_screen.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  // แบรนด์สี HelpCare
  static const Color _brandMaroon = Color(0xFF7B2D2D);
  static const Color _brandRed = Color(0xFFF24455);
  static const Color _backgroundTop = Color(0xFFFFF2F4);
  static const Color _backgroundBottom = Color(0xFFFFF8FA);

  bool _sending = false;
  int _countdown = 0;
  Timer? _timer;

  String? _patientId;
  String? _caregiverPhone;
  String? _caregiverName;

  // Buddy
  String? _buddyUid;
  String? _buddyName;

  // Siren
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadDefaultPatient();
    _loadBuddy();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopSiren();
    _player.dispose();
    super.dispose();
  }

  // ───── โหลดผู้ป่วย/ผู้ดูแลหลัก ─────
  Future<void> _loadDefaultPatient() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final q = await FirebaseFirestore.instance
        .collection('patients')
        .where('uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (!mounted) return;
    if (q.docs.isNotEmpty) {
      final d = q.docs.first;
      final m = d.data();
      final cg = (m['caregiver'] is Map)
          ? Map<String, dynamic>.from(m['caregiver'])
          : <String, dynamic>{};

      setState(() {
        _patientId = d.id;
        _caregiverPhone = (cg['phone'] ?? m['caregiverPhone'] ?? '').toString();
        _caregiverName = (cg['name'] ?? m['caregiverName'] ?? '').toString();
      });
    }
  }

  // ───── โหลดบัดดี้จาก collection buddies/{uid} ─────
  Future<void> _loadBuddy() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('buddies')
        .doc(uid)
        .get();
    if (!mounted || !doc.exists) return;

    final data = doc.data()!;
    setState(() {
      _buddyUid = (data['buddyUid'] ?? '').toString();
      _buddyName = (data['buddyName'] ?? '').toString();
    });
  }

  // ───── Location permission ─────
  Future<bool> _ensureLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  // ───── Siren helpers ─────
  Future<void> _startSiren() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource('audio/siren.mp3'));
    } catch (_) {}
  }

  Future<void> _stopSiren() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  // ───── Countdown ─────
  void _startCountdown() {
    if (_sending) return;
    setState(() => _countdown = 5);
    _startSiren();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 1) {
        t.cancel();
        _fireSOS();
      } else if (mounted) {
        setState(() => _countdown--);
      }
    });
  }

  void _cancelCountdown() {
    _timer?.cancel();
    _stopSiren();
    setState(() => _countdown = 0);
  }

  // ───── ส่ง SOS ─────
  Future<void> _fireSOS() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _countdown = 0;
    });
    await _stopSiren();

    try {
      if (!await _ensureLocationPermission()) {
        _toast('เปิด Location และอนุญาตการเข้าถึงก่อนนะคะ');
        setState(() => _sending = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final uid = FirebaseAuth.instance.currentUser?.uid;

      final sosRef = FirebaseFirestore.instance.collection('sos_alerts');
      final doc = await sosRef.add({
        'patientId': _patientId,
        'uid': uid,
        'caregiverPhone': _caregiverPhone,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'location': {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'accuracy': pos.accuracy,
        },
      });

      // ส่งถึงบัดดี้ด้วย ถ้ามี
      if (_buddyUid != null && _buddyUid!.isNotEmpty) {
        await FirebaseFirestore.instance.collection('buddy_sos_alerts').add({
          'fromUid': uid,
          'toUid': _buddyUid,
          'fromPatientId': _patientId,
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
          'location': {
            'lat': pos.latitude,
            'lng': pos.longitude,
            'accuracy': pos.accuracy,
          },
        });
      }

      if (!mounted) return;
      _showAfterSendSheet(lat: pos.latitude, lng: pos.longitude, docId: doc.id);
    } catch (e) {
      _toast('ส่ง SOS ไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // ───── Bottom sheet หลังส่ง SOS ─────
  void _showAfterSendSheet({
    required double lat,
    required double lng,
    required String docId,
  }) {
    final mapUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            runSpacing: 8,
            children: [
              const Text(
                'ส่งสัญญาณ SOS แล้ว',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              Text('พิกัด: $lat, $lng'),
              if (_buddyUid != null && _buddyUid!.isNotEmpty)
                Text(
                  'แจ้งเตือนบัดดี้แล้ว: ${_buddyName ?? ''}',
                  style: const TextStyle(color: Color(0xFFB71C1C)),
                ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.map_outlined),
                title: const Text('เปิดตำแหน่งใน Google Maps'),
                onTap: () =>
                    launchUrl(mapUrl, mode: LaunchMode.externalApplication),
              ),
              ListTile(
                leading: const Icon(Icons.local_phone_outlined),
                title: const Text('โทรฉุกเฉิน 1669'),
                onTap: () => launchUrl(Uri.parse('tel:1669')),
              ),
              if ((_caregiverPhone ?? '').isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.sms_outlined),
                  title: Text(
                    'ส่ง SMS ไปยังผู้ดูแล ${_caregiverName ?? ''}'.trim(),
                  ),
                  onTap: () {
                    final body = Uri.encodeComponent(
                      '⚠️ SOS จากแอป HelpCare\nพิกัด: https://maps.google.com/?q=$lat,$lng',
                    );
                    final sms = Uri.parse('sms:${_caregiverPhone!}?body=$body');
                    launchUrl(sms);
                  },
                ),
              if ((_caregiverPhone ?? '').isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.call_outlined),
                  title: Text('โทรหาผู้ดูแล ${_caregiverName ?? ''}'.trim()),
                  onTap: () => launchUrl(Uri.parse('tel:${_caregiverPhone!}')),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('ปิดเหตุฉุกเฉิน'),
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection('sos_alerts')
                      .doc(docId)
                      .update({
                        'status': 'closed',
                        'closedAt': FieldValue.serverTimestamp(),
                      });
                  if (mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final hasBuddy = _buddyUid != null && _buddyUid!.isNotEmpty;

    return Scaffold(
      backgroundColor: _backgroundBottom,
      appBar: AppBar(
        title: const Text('แจ้งเหตุฉุกเฉิน (SOS)'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_brandMaroon, _brandRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'ตั้งค่าบัดดี้',
            icon: const Icon(Icons.group_outlined, color: Colors.white),
            onPressed: () async {
              final paired = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BuddyPairScreen()),
              );
              if (paired == true) {
                await _loadBuddy();
              }
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_backgroundTop, _backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // การ์ดสถานะบัดดี้
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: hasBuddy
                              ? const Color(0xFFFFE5E8)
                              : const Color(0xFFEFEFEF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Icon(
                          hasBuddy
                              ? Icons.favorite_rounded
                              : Icons.person_add_alt_1,
                          size: 18,
                          color: hasBuddy ? _brandRed : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          hasBuddy
                              ? 'บัดดี้ของคุณ: ${_buddyName ?? _buddyUid}'
                              : 'ยังไม่ได้ตั้งค่าบัดดี้ แนะนำให้จับคู่เพื่อนหรือญาติไว้ช่วยรับ SOS',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: hasBuddy
                                ? _brandMaroon
                                : Colors.grey.shade800,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final paired = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BuddyPairScreen(),
                            ),
                          );
                          if (paired == true) await _loadBuddy();
                        },
                        child: const Text('จัดการ'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // SOS button + คำอธิบาย
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // ปุ่ม SOS ใหญ่
                    GestureDetector(
                      onLongPress: _startCountdown,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // วงแหวนเรืองแสง
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            width: _countdown > 0 ? 260 : 240,
                            height: _countdown > 0 ? 260 : 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _brandRed.withOpacity(0.45),
                                  blurRadius: 42,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          // วงกลมหลัก
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _countdown > 0
                                    ? [_brandMaroon, _brandRed]
                                    : [_brandRed, const Color(0xFFFF6B7A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: _sending
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          'SOS',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 44,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 4,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _countdown > 0
                                              ? 'กำลังส่งใน $_countdown วิ'
                                              : 'กดค้างเพื่อส่ง SOS',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_countdown > 0)
                      TextButton.icon(
                        onPressed: _cancelCountdown,
                        icon: const Icon(Icons.close),
                        label: const Text('ยกเลิกการส่ง SOS'),
                        style: TextButton.styleFrom(
                          foregroundColor: _brandMaroon,
                        ),
                      ),
                    const SizedBox(height: 18),

                    // ปุ่มโทร 1669
                    OutlinedButton.icon(
                      icon: const Icon(Icons.local_phone_outlined),
                      label: const Text('โทรฉุกเฉิน 1669'),
                      onPressed: () => launchUrl(Uri.parse('tel:1669')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _brandMaroon,
                        side: const BorderSide(color: _brandRed, width: 1.4),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        'กดค้างที่ปุ่ม SOS เพื่อส่งสัญญาณฉุกเฉิน ระบบจะบันทึกพิกัดปัจจุบัน '
                        'และแจ้งเตือนไปยังผู้ดูแลของคุณ\n'
                        'หากตั้งค่าบัดดี้ไว้ ระบบจะส่ง SOS ไปแจ้งเตือนให้บัดดี้ด้วย\n'
                        'ระหว่างนับถอยหลังจะมีเสียงไซเรน หากกดผิดสามารถกดยกเลิกได้',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
