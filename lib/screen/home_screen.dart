// lib/screen/home_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:webview_flutter/webview_flutter.dart';

import '../routes.dart';

import 'health_history_screen.dart';
import 'documents_screen.dart';
import 'appointments_screen.dart';
import '../widgets/appointments_home_section.dart';

import 'care_dashboard_screen.dart';
import 'care_dashboard_multi_screen.dart'; // ✅ เพิ่ม
import 'care_log_screen.dart';
import 'care_types_settings_screen.dart';

import 'add_chat_screen.dart';
import 'add_notification_screen.dart';

import 'care_news_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _currentPatientId;

  // ✅ ข่าวล่าสุดบนหน้า Home
  bool _newsLoading = false;
  String? _newsError;
  List<_NewsItem> _news = const [];

  @override
  void initState() {
    super.initState();
    _loadLatestNews();
  }

  Future<void> _loadLatestNews() async {
    setState(() {
      _newsLoading = true;
      _newsError = null;
      _news = const [];
    });

    try {
      const url = 'https://anamai.moph.go.th/th/home';
      final res = await http
          .get(
            Uri.parse(url),
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome Safari',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw Exception('โหลดข่าวไม่สำเร็จ (${res.statusCode})');
      }

      final html = _decodeUtf8(res.bodyBytes);
      final parsed = _parseAnamaiHomeLatest(html).take(3).toList();

      setState(() {
        _news = parsed;
        _newsLoading = false;
      });
    } catch (e) {
      setState(() {
        _newsError = e.toString();
        _newsLoading = false;
      });
    }
  }

  String _decodeUtf8(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes);
    }
  }

  List<_NewsItem> _parseAnamaiHomeLatest(String html) {
    final doc = html_parser.parse(html);
    final out = <_NewsItem>[];
    final seen = <String>{};

    for (final a in doc.querySelectorAll('a')) {
      final title = a.text.trim();
      final href = a.attributes['href'] ?? '';

      if (title.isEmpty) continue;
      if (title.contains('อ่านรายละเอียด')) continue;
      if (!href.contains('/th/news/')) continue;

      final fullUrl = Uri.parse(
        'https://anamai.moph.go.th',
      ).resolve(href).toString();
      if (!seen.add(fullUrl)) continue;

      final parentText = (a.parent?.text ?? '').trim();
      final date = RegExp(
        r'\b\d{2}\.\d{2}\.\d{4}\b',
      ).firstMatch(parentText)?.group(0);

      out.add(_NewsItem(title: title, url: fullUrl, subtitle: date));
      if (out.length >= 6) break;
    }

    return out;
  }

  // ✅ เปิดหน้า “ข่าวสารการดูแล”
  void _openNews() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CareNewsScreen()),
    );
  }

  void _openWeb(String url, {String title = 'ข่าวสารล่าสุด'}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _WebViewPage(title: title, url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.email?.split('@').first ?? 'ผู้ใช้';

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      floatingActionButton: _FabMenu(
        onAddChat: () async {
          final id = await _ensurePatientId();
          if (id == null || !mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddChatScreen(patientId: id)),
          );
        },
        onAddNotify: () async {
          final id = await _ensurePatientId();
          if (id == null || !mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddNotificationScreen(patientId: id),
            ),
          );
        },
        onOpenNews: _openNews,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ✅ พื้นหลังไล่สี
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF5A0F1B),
                  Color(0xFFB31237),
                  Color(0xFFF24455),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // ไฮไลท์วงกลม
          Positioned(
            top: -120,
            right: -90,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -110,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                // Header
                Row(
                  children: [
                    Image.asset(
                      'assets/icon/helpcare.white.png',
                      width: 70,
                      height: 70,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HelpCare',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                            ),
                          ),
                          Text(
                            'ดูแลผู้สูงอายุ/ผู้ป่วยติดเตียง',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'ตั้งค่า',
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.settings),
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Greeting
                _GlassCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 30,
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
                              'ติดตามยา • น้ำ • สัญญาณชีพ • อาหาร • กายภาพ\nและแชร์ข้อมูลให้ผู้ดูแลได้ง่าย ๆ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(.92),
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Row(
                              children: [
                                _MiniStat(
                                  icon: Icons.medication_outlined,
                                  label: 'ยา',
                                ),
                                SizedBox(width: 10),
                                _MiniStat(
                                  icon: Icons.monitor_heart_outlined,
                                  label: 'สัญญาณชีพ',
                                ),
                                SizedBox(width: 10),
                                _MiniStat(
                                  icon: Icons.restaurant_outlined,
                                  label: 'อาหาร/น้ำ',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'เลือกผู้ป่วย',
                        onPressed: () async {
                          final id = await _ensurePatientId(forcePick: true);
                          if (id != null && mounted) {
                            setState(() => _currentPatientId = id);
                          }
                        },
                        icon: const Icon(
                          Icons.person_search_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // การ์ดผู้ป่วย
                _PatientCard(
                  patientId: _currentPatientId,
                  onPick: () async {
                    final id = await _ensurePatientId(forcePick: true);
                    if (id != null && mounted) {
                      setState(() => _currentPatientId = id);
                    }
                  },
                  onAddChat: () async {
                    final id = await _ensurePatientId();
                    if (id == null || !mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddChatScreen(patientId: id),
                      ),
                    );
                  },
                  onAddNotify: () async {
                    final id = await _ensurePatientId();
                    if (id == null || !mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddNotificationScreen(patientId: id),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 14),

                // ✅ ข่าวสารล่าสุด (ช่องข่าว)
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.newspaper_outlined,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'ข่าวสารล่าสุด (กรมอนามัย)',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'รีเฟรชข่าว',
                            onPressed: _newsLoading ? null : _loadLatestNews,
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                          ),
                          TextButton(
                            onPressed: _openNews,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withOpacity(0.12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('ดูทั้งหมด'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_newsLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      else if (_newsError != null)
                        Text(
                          'โหลดข่าวไม่สำเร็จ\n$_newsError',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else if (_news.isEmpty)
                        Text(
                          'ยังไม่มีรายการข่าว',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else
                        Column(
                          children: _news.map((n) {
                            return InkWell(
                              onTap: () =>
                                  _openWeb(n.url, title: 'ข่าวสารล่าสุด'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            n.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              height: 1.2,
                                            ),
                                          ),
                                          if ((n.subtitle ?? '').isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                'วันที่ ${n.subtitle}',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.85),
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'หมวดหมู่',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                // Grid
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 380;

                          return GridView.count(
                            crossAxisCount: isNarrow ? 1 : 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: isNarrow ? 3.4 : 2.9,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _CategoryTile(
                                icon: Icons.badge_outlined,
                                iconBg: const Color(0xFFE8F0FF),
                                title: 'โปรไฟล์ผู้ป่วย/ผู้สูงอายุ',
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.patients,
                                ),
                              ),

                              _CategoryTile(
                                icon: Icons.medication_outlined,
                                iconBg: const Color(0xFFE8FFF3),
                                title: 'ตารางการให้ยา',
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.medScheduleList,
                                ),
                              ),

                              _CategoryTile(
                                icon: Icons.warning_amber_outlined,
                                iconBg: const Color(0xFFFFEBEE),
                                title: 'แจ้งเหตุฉุกเฉิน (SOS)',
                                onTap: () =>
                                    Navigator.pushNamed(context, AppRoutes.sos),
                              ),
                              _CategoryTile(
                                icon: Icons.receipt_long_outlined,
                                iconBg: const Color(0xFFFFF4EE),
                                title: 'บันทึกกิจวัตร',
                                onTap: () => _openCareMenu(context),
                              ),
                              _CategoryTile(
                                icon: Icons.history_edu_outlined,
                                iconBg: const Color(0xFFEFF7FF),
                                title: 'ประวัติสุขภาพย้อนหลัง',
                                onTap: () async {
                                  final id = await _ensurePatientId();
                                  if (id == null || !mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          HealthHistoryScreen(patientId: id),
                                    ),
                                  );
                                },
                              ),
                              _CategoryTile(
                                icon: Icons.folder_open_outlined,
                                iconBg: const Color(0xFFFFF7EC),
                                title: 'รูปภาพ/ไฟล์เอกสาร',
                                onTap: () async {
                                  final id = await _ensurePatientId();
                                  if (id == null || !mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DocumentsScreen(patientId: id),
                                    ),
                                  );
                                },
                              ),
                              _CategoryTile(
                                icon: Icons.event_outlined,
                                iconBg: const Color(0xFFE8F0FF),
                                title: 'นัดหมาย / การนัดพบ',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AppointmentsScreen(),
                                  ),
                                ),
                              ),
                              _CategoryTile(
                                icon: Icons.newspaper_outlined,
                                iconBg: const Color(0xFFEFF7FF),
                                title: 'ข่าวสารการดูแล',
                                onTap: _openNews,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const AppointmentsHomeSection(),
                    ],
                  ),
                ),

                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ เพิ่ม: ดึงรายชื่อผู้ป่วยทั้งหมด
  Future<List<String>> _getAllPatientIds() async {
    final snap = await FirebaseFirestore.instance
        .collection('patients')
        .orderBy('name')
        .limit(100)
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  // เลือก/คืนค่า patientId ล่าสุด
  Future<String?> _ensurePatientId({bool forcePick = false}) async {
    if (!forcePick &&
        _currentPatientId != null &&
        _currentPatientId!.isNotEmpty) {
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

    if (!forcePick && snap.docs.length == 1) {
      _currentPatientId = snap.docs.first.id;
      return _currentPatientId;
    }

    final id = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
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
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: snap.docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final d = snap.docs[i];
                  final map = d.data();
                  final n = (map['name'] ?? '').toString();
                  final a = map.containsKey('age') && map['age'] != null
                      ? '${map['age']}'
                      : '';
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(n.isEmpty ? '(ไม่ระบุชื่อ)' : n),
                    subtitle: a.isEmpty ? null : Text('อายุ $a ปี'),
                    onTap: () => Navigator.pop(sheetContext, d.id),
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
      builder: (sheetContext) => SafeArea(
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
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),

            // ✅ แก้: Dashboard รองรับหลายผู้ป่วย
            ListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: const Text('Dashboard (สรุปกิจวัตร)'),
              onTap: () async {
                Navigator.pop(sheetContext);

                final ids = await _getAllPatientIds();
                if (!mounted) return;

                if (ids.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ยังไม่มีรายชื่อผู้ป่วย กรุณาเพิ่มก่อน'),
                    ),
                  );
                  return;
                }

                if (ids.length == 1) {
                  final id = ids.first;
                  _currentPatientId = id;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CareDashboardScreen(patientId: id),
                    ),
                  );
                  return;
                }

                // ✅ 2 คนขึ้นไป → เปิดแบบแท็บแยก
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CareDashboardMultiScreen(patientIds: ids),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('บันทึกกิจวัตร (Care Log)'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final id = await _ensurePatientId();
                if (id == null || !mounted) return;
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
              onTap: () async {
                Navigator.pop(sheetContext);
                final id = await _ensurePatientId();
                if (id == null || !mounted) return;
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

// -------- Models --------
class _NewsItem {
  final String title;
  final String url;
  final String? subtitle;
  const _NewsItem({required this.title, required this.url, this.subtitle});
}

// ----------------- WebView (ข่าวล่าสุด) -----------------
class _WebViewPage extends StatefulWidget {
  final String title;
  final String url;
  const _WebViewPage({required this.title, required this.url});

  @override
  State<_WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<_WebViewPage> {
  late final WebViewController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF660F24),
        foregroundColor: Colors.white,
      ),
      body: WebViewWidget(controller: _ctl),
    );
  }
}

// ----------------- UI helpers -----------------
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.12),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MiniStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatelessWidget {
  final String? patientId;
  final VoidCallback onPick;
  final VoidCallback onAddChat;
  final VoidCallback onAddNotify;

  const _PatientCard({
    required this.patientId,
    required this.onPick,
    required this.onAddChat,
    required this.onAddNotify,
  });

  @override
  Widget build(BuildContext context) {
    if (patientId == null || patientId!.isEmpty) {
      return _GlassCard(
        child: Row(
          children: [
            const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'ยังไม่ได้เลือกผู้ป่วย • แตะเพื่อเลือก',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: onPick,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('เลือก'),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _GlassCard(
            child: Row(
              children: const [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'กำลังโหลดข้อมูลผู้ป่วย...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return _GlassCard(
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'ไม่พบข้อมูลผู้ป่วย (อาจถูกลบ) • กรุณาเลือกใหม่',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onPick,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('เลือก'),
                ),
              ],
            ),
          );
        }

        final data = snap.data!.data();
        final name = (data?['name'] ?? 'ผู้ป่วย').toString();

        final age =
            (data != null && data.containsKey('age') && data['age'] != null)
            ? '${data['age']}'
            : '';

        final bed =
            (data != null &&
            data.containsKey('bedridden') &&
            data['bedridden'] == true);

        return _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0x33FFFFFF),
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (age.isNotEmpty) 'อายุ $age ปี',
                            if (bed) 'ผู้ป่วยติดเตียง',
                          ].join(' • '),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.90),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onPick,
                    icon: const Icon(
                      Icons.swap_horiz_rounded,
                      color: Colors.white,
                    ),
                    tooltip: 'สลับผู้ป่วย',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _OutlineLightButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'เพิ่มแชท',
                      onTap: onAddChat,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _OutlineLightButton(
                      icon: Icons.notifications_active_outlined,
                      label: 'เพิ่มแจ้งเตือน',
                      onTap: onAddNotify,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OutlineLightButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OutlineLightButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
          color: Colors.white.withOpacity(0.10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FabMenu extends StatelessWidget {
  final VoidCallback onAddChat;
  final VoidCallback onAddNotify;
  final VoidCallback onOpenNews;

  const _FabMenu({
    required this.onAddChat,
    required this.onAddNotify,
    required this.onOpenNews,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: const Color(0xFF660F24),
      foregroundColor: Colors.white,
      onPressed: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          builder: (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                const ListTile(
                  title: Text(
                    'เพิ่มรายการ',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline_rounded),
                  title: const Text('เพิ่มแชท'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onAddChat();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('เพิ่มแจ้งเตือน/การดูแล'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onAddNotify();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.newspaper_outlined),
                  title: const Text('ข่าวสารการดูแล'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onOpenNews();
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
      label: const Text('เพิ่ม'),
      icon: const Icon(Icons.add_rounded),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xFF660F24);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: mainColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
