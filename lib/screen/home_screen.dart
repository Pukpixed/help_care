// lib/screen/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../routes.dart';
import '../color.dart';

// screens ที่อยู่โฟลเดอร์เดียวกัน
import './health_history_screen.dart';
import './documents_screen.dart';
import './appointments_screen.dart';

import '../widgets/appointments_home_section.dart';
import '../widgets/frosty_waves_bg.dart'; // ⬅️ พื้นหลังคลื่นฟุ้ง

import 'care_dashboard_screen.dart';
import 'care_log_screen.dart';
import 'care_types_settings_screen.dart';

// แจ้งเตือน LINE
import '../utils/line_notify.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _currentPatientId;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.email?.split('@').first ?? 'ผู้ใช้';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // พื้นหลังคลื่นฟุ้งโทนแดงของแบรนด์
          const FrostyWavesBackground(
            top: Color(0xFF7B2D2D), // maroon
            bottom: Color(0xFFF24455), // red
            waveColor: Colors.white,
            heightFactor: .40,
          ),

          // เนื้อหาหลัก
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // Header
                Row(
                  children: [
                    Image.asset(
                      'assets/icon/helpcare.white.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'ตั้งค่า',
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.settings),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Greeting card
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF660F24), Color(0xFFF24455)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'สวัสดี ${name.isEmpty ? '' : name} 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'เริ่มติดตามกิจวัตร, ดื่มน้ำ, ยา และสรุปงาน\nให้ผู้ดูแลได้ง่าย ๆ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(.95),
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                const Text(
                  'หมวดหมู่',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),

                // Categories
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // โปรไฟล์ผู้ป่วย/ผู้สูงอายุ
                    _CategoryChip(
                      icon: Icons.badge_outlined,
                      iconBg: const Color(0xFFE8F0FF),
                      title: 'โปรไฟล์ผู้ป่วย/ผู้สูงอายุ',
                      onTap: () async {
                        await LineNotify.send(
                          'เปิดเมนูโปรไฟล์ผู้ป่วย/ผู้สูงอายุ โดยผู้ใช้ $name',
                        );
                        if (!mounted) return;
                        Navigator.pushNamed(context, AppRoutes.patients);
                      },
                    ),
                    // ตารางการให้ยา
                    _CategoryChip(
                      icon: Icons.medication_outlined,
                      iconBg: const Color(0xFFE8FFF3),
                      title: 'ตารางการให้ยา',
                      onTap: () async {
                        await LineNotify.send(
                          'เปิดเมนูตารางการให้ยา โดยผู้ใช้ $name',
                        );
                        if (!mounted) return;
                        Navigator.pushNamed(context, AppRoutes.dailyCare);
                      },
                    ),
                    // SOS
                    _CategoryChip(
                      icon: Icons.warning_amber_outlined,
                      iconBg: const Color(0xFFFFEBEE),
                      title: 'แจ้งเหตุฉุกเฉิน (SOS)',
                      onTap: () async {
                        await LineNotify.send(
                          'เปิดเมนูแจ้งเหตุฉุกเฉิน (SOS) โดยผู้ใช้ $name',
                        );
                        if (!mounted) return;
                        Navigator.pushNamed(context, AppRoutes.sos);
                      },
                    ),
                    // บันทึกกิจวัตร (มีเมนูย่อย)
                    _CategoryChip(
                      icon: Icons.receipt_long_outlined,
                      iconBg: const Color(0xFFFFF4EE),
                      title: 'บันทึกกิจวัตร',
                      onTap: () async {
                        await LineNotify.send(
                          'เปิดเมนูบันทึกกิจวัตร โดยผู้ใช้ $name',
                        );
                        if (!mounted) return;
                        _openCareMenu(context);
                      },
                    ),
                    // ประวัติสุขภาพย้อนหลัง
                    _CategoryChip(
                      icon: Icons.history_edu_outlined,
                      iconBg: const Color(0xFFEFF7FF),
                      title: 'ประวัติสุขภาพย้อนหลัง',
                      onTap: () async {
                        final id = await _ensurePatientId();
                        if (id == null || !mounted) return;

                        await LineNotify.send(
                          'เปิดประวัติสุขภาพย้อนหลัง (patientId: $id) โดยผู้ใช้ $name',
                        );

                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HealthHistoryScreen(patientId: id),
                          ),
                        );
                      },
                    ),
                    // รูปภาพ/ไฟล์เอกสาร
                    _CategoryChip(
                      icon: Icons.folder_open_outlined,
                      iconBg: const Color(0xFFFFF7EC),
                      title: 'รูปภาพ/ไฟล์เอกสาร',
                      onTap: () async {
                        final id = await _ensurePatientId();
                        if (id == null || !mounted) return;

                        await LineNotify.send(
                          'เปิดเมนูรูปภาพ/ไฟล์เอกสาร (patientId: $id) โดยผู้ใช้ $name',
                        );

                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DocumentsScreen(patientId: id),
                          ),
                        );
                      },
                    ),
                    // นัดหมาย / การนัดพบ
                    _CategoryChip(
                      icon: Icons.event_outlined,
                      iconBg: const Color(0xFFE8F0FF),
                      title: 'นัดหมาย / การนัดพบ',
                      onTap: () async {
                        await LineNotify.send(
                          'เปิดเมนูนัดหมาย/การนัดพบ โดยผู้ใช้ $name',
                        );
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AppointmentsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const AppointmentsHomeSection(),
                const SizedBox(height: 16),

                // ปุ่มเทสแจ้งเตือน LINE ตรง ๆ
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await LineNotify.send(
                        'ทดสอบแจ้งเตือนจากหน้าแรกของ HelpCare 🚑',
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ลองส่งแจ้งเตือนไปที่ LINE แล้ว'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('เทสแจ้งเตือน LINE'),
                    style: ElevatedButton.styleFrom(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // เลือก/คืนค่า patientId ล่าสุด
  Future<String?> _ensurePatientId() async {
    if (_currentPatientId != null && _currentPatientId!.isNotEmpty) {
      return _currentPatientId;
    }
    final snap = await FirebaseFirestore.instance
        .collection('patients')
        .orderBy('name')
        .limit(100)
        .get();

    if (!mounted) return null;

    if (snap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีรายชื่อผู้ป่วย กรุณาเพิ่มก่อน')),
      );
      return null;
    }
    if (snap.docs.length == 1) {
      _currentPatientId = snap.docs.first.id;
      return _currentPatientId;
    }

    final id = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const ListTile(
              title: Text(
                'เลือกผู้ป่วย',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: snap.docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final d = snap.docs[i];
                  final name = (d['name'] ?? '').toString();
                  final age = d.data().containsKey('age')
                      ? (d['age']).toString()
                      : '';
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(name.isEmpty ? '(ไม่ระบุชื่อ)' : name),
                    subtitle: age.isEmpty ? null : Text('อายุ $age ปี'),
                    onTap: () => Navigator.pop(context, d.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (id != null && id.isNotEmpty) {
      _currentPatientId = id;
      return id;
    }
    return null;
  }

  // เมนูบันทึกกิจวัตร
  void _openCareMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const ListTile(
              title: Text(
                'เมนูบันทึกกิจวัตร',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: const Text('Dashboard (สรุปกิจวัตร)'),
              subtitle: const Text('CareDashboardScreen'),
              onTap: () async {
                Navigator.pop(context);
                final id = await _ensurePatientId();
                if (id == null || !mounted) return;

                await LineNotify.send(
                  'เปิด Dashboard สรุปกิจวัตร (patientId: $id)',
                );

                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CareDashboardScreen(patientId: id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('บันทึกกิจวัตร (Care Log)'),
              subtitle: const Text('CareLogScreen'),
              onTap: () async {
                Navigator.pop(context);
                final id = await _ensurePatientId();
                if (id == null || !mounted) return;

                await LineNotify.send('เปิดหน้า Care Log (patientId: $id)');

                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CareLogScreen(patientId: id),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('ตั้งค่าชนิดกิจวัตร'),
              subtitle: const Text('CareTypesSettingsScreen'),
              onTap: () async {
                Navigator.pop(context);
                final id = await _ensurePatientId();
                if (id == null || !mounted) return;

                await LineNotify.send(
                  'เปิดตั้งค่าชนิดกิจวัตร (patientId: $id)',
                );

                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CareTypesSettingsScreen(patientId: id),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ----------------- UI helpers -----------------
class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // จอแคบ < 380px ใช้ 1 คอลัมน์
    final int columns = size.width < 380 ? 1 : 2;
    const double outerPadding = 16;
    const double gap = 12;

    final double w =
        (size.width - outerPadding * 2 - gap * (columns - 1)) / columns;

    final double cardHeight = columns == 1 ? 92 : 88;
    final double iconBox = columns == 1 ? 50 : 46;
    final double iconSize = columns == 1 ? 28 : 26;
    final double fontSize = columns == 1 ? 16 : 15;

    return SizedBox(
      width: w,
      height: cardHeight,
      child: Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  height: iconBox,
                  width: iconBox,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.redDeep, size: iconSize),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: fontSize,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
