// lib/screen/care_dashboard_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/report_utils.dart';
import 'care_log_screen.dart';

/// Dashboard สรุปข้อมูล care_logs ของผู้ป่วย
class CareDashboardScreen extends StatefulWidget {
  final String patientId;

  /// ✅ เพิ่ม: ถ้าเอาหน้านี้ไปวางใน Tab (หลายผู้ป่วย) ให้ปิด AppBar ซ้อน
  final bool showAppBar;

  /// เป้าหมายต่อวัน (ปรับได้ตอนเรียกหน้า)
  final int targetWaterPerDay; // แก้ว
  final int targetMedsPerDay; // ครั้งให้ยา
  final int targetPhysioPerDay; // ครั้งกายภาพ

  const CareDashboardScreen({
    super.key,
    required this.patientId,
    this.showAppBar = true, // ✅ เพิ่ม
    this.targetWaterPerDay = 8,
    this.targetMedsPerDay = 2,
    this.targetPhysioPerDay = 1,
  });

  @override
  State<CareDashboardScreen> createState() => _CareDashboardScreenState();
}

enum _Range { day, week, month }

class _CareType {
  final String key, label, icon;
  final int color; // ARGB
  const _CareType(this.key, this.label, this.icon, this.color);

  IconData get iconData {
    switch (icon) {
      case 'restaurant_outlined':
        return Icons.restaurant_outlined;
      case 'local_drink_outlined':
        return Icons.local_drink_outlined;
      case 'medication_outlined':
        return Icons.medication_outlined;
      case 'rotate_90_degrees_ccw_outlined':
        return Icons.rotate_90_degrees_ccw_outlined;
      case 'wc_outlined':
        return Icons.wc_outlined;
      case 'fitness_center_outlined':
        return Icons.fitness_center_outlined;
      case 'healing_outlined':
        return Icons.healing_outlined;
      case 'monitor_heart_outlined':
        return Icons.monitor_heart_outlined;
      case 'shower_outlined':
        return Icons.shower_outlined;
      case 'bedtime_outlined':
        return Icons.bedtime_outlined;
      case 'bloodtype_outlined':
        return Icons.bloodtype_outlined;
      case 'vaccines_outlined':
        return Icons.vaccines_outlined;
      case 'monitor_heart':
        return Icons.monitor_heart;
      case 'masks_outlined':
        return Icons.masks_outlined;
      case 'child_friendly_outlined':
        return Icons.child_friendly_outlined;
      case 'cloud_outlined':
        return Icons.cloud_outlined;
      case 'set_meal_outlined':
        return Icons.set_meal_outlined;
      case 'chat_bubble_outline':
        return Icons.chat_bubble_outline;
      default:
        return Icons.widgets_outlined;
    }
  }
}

class _CareDashboardScreenState extends State<CareDashboardScreen> {
  // สีหลักโทนแดงเข้ม (เผื่อใช้ต่อ)
  static const Color maroon = Color(0xFF660F24);

  /// ✅ NEW: patients/{patientId}/care_logs
  CollectionReference<Map<String, dynamic>> get _newCol => FirebaseFirestore
      .instance
      .collection('patients')
      .doc(widget.patientId)
      .collection('care_logs');

  /// ✅ LEGACY: care_logs (root) — ระหว่างช่วงย้ายข้อมูล
  final CollectionReference<Map<String, dynamic>> _legacyCol = FirebaseFirestore
      .instance
      .collection('care_logs');

  /// ✅ ระหว่างช่วงย้าย: อ่านทั้งใหม่ + เก่า
  static const bool _enableLegacyRead = true;

  /// legacy โหมดสำรอง (ไม่ใช้ index)
  bool _legacyNoIndexFallback = false;

  List<_CareType> _types = [];
  bool _loadingTypes = true;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _typesSub;

  _Range _range = _Range.week;
  DateTime _anchor = DateTime.now();

  CollectionReference<Map<String, dynamic>> get _typeCol => FirebaseFirestore
      .instance
      .collection('patients')
      .doc(widget.patientId)
      .collection('care_types');

  @override
  void initState() {
    super.initState();
    _listenTypes();
  }

  @override
  void didUpdateWidget(covariant CareDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patientId != widget.patientId) {
      _typesSub?.cancel();
      _typesSub = null;

      setState(() {
        _types = [];
        _loadingTypes = true;
        _legacyNoIndexFallback = false;
        // ถ้าอยาก reset ช่วงเวลาเมื่อเปลี่ยนคน ให้ปลด comment:
        // _range = _Range.week;
        // _anchor = DateTime.now();
      });

      _listenTypes();
    }
  }

  @override
  void dispose() {
    _typesSub?.cancel();
    super.dispose();
  }

  void _listenTypes() {
    _typesSub = _typeCol
        .orderBy('order', descending: false)
        .orderBy('label')
        .snapshots()
        .listen(
          (s) {
            final list = <_CareType>[];
            for (final d in s.docs) {
              final m = d.data();
              list.add(
                _CareType(
                  (m['key'] ?? '').toString(),
                  (m['label'] ?? '').toString(),
                  (m['icon'] ?? 'restaurant_outlined').toString(),
                  (m['color'] ?? 0xFFB00020) as int,
                ),
              );
            }
            if (mounted) {
              setState(() {
                _types = list;
                _loadingTypes = false;
              });
            }
          },
          onError: (_) {
            if (mounted) setState(() => _loadingTypes = false);
          },
        );
  }

  // ─── เวลา ───
  (DateTime, DateTime) _rangeStartEnd() {
    final a = DateTime(_anchor.year, _anchor.month, _anchor.day);
    switch (_range) {
      case _Range.day:
        return (a, a.add(const Duration(days: 1)));
      case _Range.week:
        final w = a.weekday % 7; // Mon=1..Sun=0
        final s = a.subtract(Duration(days: w == 0 ? 6 : (w - 1)));
        return (s, s.add(const Duration(days: 7)));
      case _Range.month:
        final s = DateTime(a.year, a.month, 1);
        return (s, DateTime(a.year, a.month + 1, 1));
    }
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year + 543}';
  String _rangeLabel() {
    switch (_range) {
      case _Range.day:
        return 'วันนี้ ${_fmtDate(_anchor)}';
      case _Range.week:
        final (s, e) = _rangeStartEnd();
        return 'สัปดาห์ ${_fmtDate(s)}–${_fmtDate(e.subtract(const Duration(days: 1)))}';
      case _Range.month:
        return 'เดือน ${_anchor.month}/${_anchor.year + 543}';
    }
  }

  /// ✅ merge docs ใหม่ + legacy แล้วเรียงเวลา desc
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _mergeAndSort(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> a,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> b,
  ) {
    final out = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    out.addAll(a);
    out.addAll(b);

    out.sort((x, y) {
      final tx = (x.data()['time'] as Timestamp?);
      final ty = (y.data()['time'] as Timestamp?);
      final vx = tx?.millisecondsSinceEpoch ?? 0;
      final vy = ty?.millisecondsSinceEpoch ?? 0;
      return vy.compareTo(vx);
    });
    return out;
  }

  /// ดึงลิงก์สร้าง Index ออกจากข้อความ error ของ Firestore
  String? _extractIndexUrl(String msg) {
    final re = RegExp(r'(https:\/\/console\.firebase\.google\.com\/[^\s]+)');
    final m = re.firstMatch(msg);
    return m?.group(1);
  }

  // ─── จัดหมวด ───
  String _categoryOf(_CareType t) {
    final k = t.key.toLowerCase();
    final l = t.label.toLowerCase();
    bool any(Iterable<String> a) =>
        a.any((x) => k.contains(x) || l.contains(x));
    if (any(['meal', 'eat', 'food', 'ข้าว', 'อาหาร', 'set_meal']))
      return 'อาหาร';
    if (any(['drink', 'water', 'ดื่ม', 'น้ำ', 'local_drink'])) return 'ดื่มน้ำ';
    if (any(['med', 'ยา', 'dose', 'vacc'])) return 'ยา';
    if (any(['turn', 'position', 'พลิก', 'rotate'])) return 'พลิกตัว';
    if (any(['toilet', 'wc', 'defec', 'urine', 'ขับถ่าย'])) return 'ขับถ่าย';
    if (any(['physio', 'exercise', 'กายภาพ', 'fitness'])) return 'กายภาพ';
    if (any(['sleep', 'nap', 'นอน'])) return 'นอนหลับ';
    if (any(['bp', 'vital', 'heart', 'ชีพ', 'blood'])) return 'สัญญาณชีพ';
    if (any(['shower', 'clean', 'อาบน้ำ', 'ทำความสะอาด'])) return 'ทำความสะอาด';
    return 'อื่น ๆ';
  }

  Map<String, List<_CareType>> _groupTypes() {
    final map = <String, List<_CareType>>{};
    for (final t in _types) {
      final g = _categoryOf(t);
      map.putIfAbsent(g, () => []).add(t);
    }
    return map;
  }

  // เป้า (%)
  double _percentFor(String group, Map<String, int> byType) {
    final keys = _types.where((t) => _categoryOf(t) == group).map((t) => t.key);
    final count = keys.fold<int>(0, (s, k) => s + (byType[k] ?? 0));
    final (s, e) = _rangeStartEnd();
    final days = e.difference(s).inDays.clamp(1, 31);

    int targetPerDay;
    switch (group) {
      case 'ดื่มน้ำ':
        targetPerDay = widget.targetWaterPerDay;
        break;
      case 'ยา':
        targetPerDay = widget.targetMedsPerDay;
        break;
      case 'กายภาพ':
        targetPerDay = widget.targetPhysioPerDay;
        break;
      default:
        targetPerDay = 0;
    }
    if (targetPerDay <= 0) return 0;
    final target = targetPerDay * days;
    return (count / target).clamp(0, 1).toDouble();
  }

  // รายวัน
  List<_DayCount> _dailyCounts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final (s, e) = _rangeStartEnd();
    final days = e.difference(s).inDays;
    final list = List.generate(
      days,
      (i) => _DayCount(s.add(Duration(days: i)), 0),
    );
    for (final d in docs) {
      final ts = (d['time'] as Timestamp?)?.toDate();
      if (ts == null) continue;
      final idx = ts.difference(s).inDays;
      if (idx >= 0 && idx < list.length) list[idx].count++;
    }
    return list;
  }

  // สี/ไอคอนสำหรับแต่ละหมวด
  Color _pickColor(String group) {
    switch (group) {
      case 'อาหาร':
        return const Color(0xFFF97316);
      case 'ดื่มน้ำ':
        return const Color(0xFF38BDF8);
      case 'ยา':
        return const Color(0xFFF43F5E);
      case 'กายภาพ':
        return const Color(0xFF22C55E);
      case 'สัญญาณชีพ':
        return const Color(0xFF8B5CF6);
      case 'ขับถ่าย':
        return const Color(0xFF06B6D4);
      case 'นอนหลับ':
        return const Color(0xFF64748B);
      case 'ทำความสะอาด':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _pickIcon(String group) {
    switch (group) {
      case 'อาหาร':
        return Icons.set_meal_outlined;
      case 'ดื่มน้ำ':
        return Icons.local_drink_outlined;
      case 'ยา':
        return Icons.medication_outlined;
      case 'กายภาพ':
        return Icons.fitness_center_outlined;
      case 'สัญญาณชีพ':
        return Icons.monitor_heart_outlined;
      case 'ขับถ่าย':
        return Icons.wc_outlined;
      case 'นอนหลับ':
        return Icons.bedtime_outlined;
      case 'ทำความสะอาด':
        return Icons.shower_outlined;
      default:
        return Icons.widgets_outlined;
    }
  }

  Widget _buildDashboardFromDocs(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docsRaw,
  ) {
    // sort desc by time (เผื่อกรณี legacy fallback ไม่ orderBy)
    var docs = [...docsRaw];
    docs.sort((a, b) {
      final ta = (a.data()['time'] as Timestamp?);
      final tb = (b.data()['time'] as Timestamp?);
      final va = ta?.millisecondsSinceEpoch ?? 0;
      final vb = tb?.millisecondsSinceEpoch ?? 0;
      return vb.compareTo(va);
    });

    if (docs.isEmpty) {
      return _NoDataCard(
        rangeText: _rangeLabel(),
        onAdd: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CareLogScreen(patientId: widget.patientId),
          ),
        ),
      );
    }

    // สรุป
    final byType = ReportUtils.aggregateByType(docs);
    final grouped = _groupTypes();
    final byGroup = <String, int>{};
    grouped.forEach((g, list) {
      byGroup[g] = list.fold(0, (s, t) => s + (byType[t.key] ?? 0));
    });
    final total = docs.length;

    // donut
    final segs = byGroup.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final showSegs = segs.take(4).toList();
    final shownSum = showSegs.fold<int>(0, (s, e) => s + e.value);
    final others = math.max(0, total - shownSum);
    if (others > 0) showSegs.add(MapEntry('อื่น ๆ', others));

    final days = _dailyCounts(docs);
    final maxDay = days.fold<int>(0, (m, e) => e.count > m ? e.count : m);

    // เป้าหมาย
    final waterPct = _percentFor('ดื่มน้ำ', byType);
    final medsPct = _percentFor('ยา', byType);
    final physioPct = _percentFor('กายภาพ', byType);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // ✅ ถ้า embed ในแท็บ (showAppBar=false) ให้โชว์แถบเลือกช่วงด้านบน
        if (!widget.showAppBar) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF7B2D2D),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<_Range>(
                        segments: const [
                          ButtonSegment(value: _Range.day, label: Text('วัน')),
                          ButtonSegment(
                            value: _Range.week,
                            label: Text('สัปดาห์'),
                          ),
                          ButtonSegment(
                            value: _Range.month,
                            label: Text('เดือน'),
                          ),
                        ],
                        selected: {_range},
                        onSelectionChanged: (v) =>
                            setState(() => _range = v.first),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _anchor = DateTime.now()),
                      icon: const Icon(Icons.today_outlined),
                      label: const Text('วันนี้'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _rangeLabel(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        _DonutCard(
          total: total,
          segments: showSegs
              .map(
                (e) => _DonutSegment(
                  label: e.key,
                  value: e.value.toDouble(),
                  color: _pickColor(e.key),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),

        const _SectionHeader(title: 'ความถี่การบันทึก (รายวัน)'),
        const SizedBox(height: 10),
        _BarChart(days: days, maxValue: maxDay),
        const SizedBox(height: 18),

        const _SectionHeader(title: 'ความคืบหน้าตามเป้าหมาย'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _GoalPill(
              icon: Icons.local_drink_outlined,
              label: 'ดื่มน้ำ',
              percent: waterPct,
              color: const Color(0xFF38BDF8),
            ),
            _GoalPill(
              icon: Icons.medication_outlined,
              label: 'ยา',
              percent: medsPct,
              color: const Color(0xFFF43F5E),
            ),
            _GoalPill(
              icon: Icons.fitness_center_outlined,
              label: 'กายภาพ',
              percent: physioPct,
              color: const Color(0xFF22C55E),
            ),
          ],
        ),

        const SizedBox(height: 18),

        const _SectionHeader(title: 'ภาพรวมตามหมวด'),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: byGroup.entries.where((e) => e.value > 0).length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.6,
          ),
          itemBuilder: (_, i) {
            final e = byGroup.entries.where((e) => e.value > 0).toList()[i];
            return _MiniStatCard(
              title: e.key,
              count: e.value,
              color: _pickColor(e.key),
              icon: _pickIcon(e.key),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CareLogScreen(patientId: widget.patientId),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 18),

        const _SectionHeader(title: 'ชนิดที่บันทึกบ่อย'),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final ent
                  in (byType.entries.where((e) => e.value > 0).toList()
                        ..sort((a, b) => b.value.compareTo(a.value)))
                      .take(6))
                _ChipCard(
                  title:
                      _types
                          .where((t) => t.key == ent.key)
                          .firstOrNull
                          ?.label ??
                      ent.key,
                  value: '${ent.value}',
                  color: _pickColor(
                    _categoryOf(
                      _types.where((t) => t.key == ent.key).firstOrNull ??
                          _CareType(ent.key, ent.key, '', 0xFF94A3B8),
                    ),
                  ),
                  icon:
                      _types
                          .where((t) => t.key == ent.key)
                          .firstOrNull
                          ?.iconData ??
                      Icons.widgets_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CareLogScreen(patientId: widget.patientId),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final (s, e) = _rangeStartEnd();

    // ✅ NEW (subcollection) — ไม่ต้อง where patientId
    final qNew = _newCol
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(s))
        .where('time', isLessThan: Timestamp.fromDate(e))
        .orderBy('time', descending: true);

    // ✅ LEGACY (root)
    final qLegacyNormal = _legacyCol
        .where('patientId', isEqualTo: widget.patientId)
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(s))
        .where('time', isLessThan: Timestamp.fromDate(e))
        .orderBy('time', descending: true);

    final qLegacyFallback = _legacyCol
        .where('patientId', isEqualTo: widget.patientId)
        .limit(50);

    final legacyStream =
        (_legacyNoIndexFallback ? qLegacyFallback : qLegacyNormal).snapshots();

    final bg = const Color.fromARGB(255, 202, 202, 202);

    final body = _loadingTypes
        ? const Center(child: CircularProgressIndicator())
        : (_types.isEmpty
              ? const _NoTypeCard()
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: qNew.snapshots(),
                  builder: (_, newSnap) {
                    if (newSnap.hasError) {
                      return const _ErrorCard(
                        text: 'โหลดข้อมูลไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
                      );
                    }
                    if (!newSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final newDocs = newSnap.data!.docs;

                    if (!_enableLegacyRead) {
                      return _buildDashboardFromDocs(context, newDocs);
                    }

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: legacyStream,
                      builder: (_, oldSnap) {
                        // legacy error แต่ new มี -> แสดง new ไปก่อน
                        if (oldSnap.hasError) {
                          if (newDocs.isNotEmpty) {
                            return _buildDashboardFromDocs(context, newDocs);
                          }

                          final msg = oldSnap.error.toString();
                          final link = _extractIndexUrl(msg);
                          return _LegacyIndexErrorCard(
                            message: msg,
                            indexUrl: link,
                            onUseFallback: () =>
                                setState(() => _legacyNoIndexFallback = true),
                          );
                        }

                        // legacy ยังไม่มา แต่ new มี -> แสดง new ไปก่อน
                        if (!oldSnap.hasData) {
                          if (newDocs.isNotEmpty) {
                            return _buildDashboardFromDocs(context, newDocs);
                          }
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final merged = _mergeAndSort(
                          newDocs,
                          oldSnap.data!.docs,
                        );
                        return _buildDashboardFromDocs(context, merged);
                      },
                    );
                  },
                ));

    // ✅ ถ้าเป็นหน้าเดี่ยว: มี AppBar เดิม
    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          title: const Text(
            'สรุปกิจวัตร',
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7B2D2D), Color(0xFFF24455)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
            const SizedBox(width: 8),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(84),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<_Range>(
                          segments: const [
                            ButtonSegment(
                              value: _Range.day,
                              label: Text('วัน'),
                            ),
                            ButtonSegment(
                              value: _Range.week,
                              label: Text('สัปดาห์'),
                            ),
                            ButtonSegment(
                              value: _Range.month,
                              label: Text('เดือน'),
                            ),
                          ],
                          selected: {_range},
                          onSelectionChanged: (v) =>
                              setState(() => _range = v.first),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _anchor = DateTime.now()),
                        icon: const Icon(Icons.today_outlined),
                        label: const Text('วันนี้'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _rangeLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: body,
      );
    }

    // ✅ ถ้า embed ในแท็บ: คืนเฉพาะ body (ไม่ทำ AppBar ซ้อน)
    return Container(color: bg, child: body);
  }
}

/// ====== Widgets ย่อย ======

class _NoTypeCard extends StatelessWidget {
  const _NoTypeCard();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.tune, size: 42, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'ยังไม่มีการตั้งค่า “ชนิดกิจวัตร”',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String text;
  const _ErrorCard({required this.text});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3F3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFCACA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFD14343)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                text,
                style: const TextStyle(color: Color(0xFFD14343)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacyIndexErrorCard extends StatelessWidget {
  final String message;
  final String? indexUrl;
  final VoidCallback onUseFallback;

  const _LegacyIndexErrorCard({
    required this.message,
    required this.indexUrl,
    required this.onUseFallback,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309)),
            const SizedBox(height: 10),
            const Text(
              'Legacy ต้องสร้าง Composite Index',
              style: TextStyle(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SelectableText(
              message,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (indexUrl != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                indexUrl!,
                style: const TextStyle(color: Colors.blue),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onUseFallback,
              child: const Text('แสดงข้อมูลชั่วคราว (ไม่ใช้ดัชนี)'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoDataCard extends StatelessWidget {
  final String rangeText;
  final VoidCallback onAdd;
  const _NoDataCard({required this.rangeText, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color.fromARGB(32, 255, 255, 255),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inbox_outlined,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ยังไม่มีบันทึกในช่วงนี้\n$rangeText',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('เพิ่มบันทึก'),
                style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

// Donut Card
class _DonutSegment {
  final String label;
  final double value;
  final Color color;
  _DonutSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _DonutCard extends StatelessWidget {
  final int total;
  final List<_DonutSegment> segments;
  const _DonutCard({required this.total, required this.segments});

  @override
  Widget build(BuildContext context) {
    final sum = segments.fold<double>(0, (s, e) => s + e.value);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(33, 255, 255, 255),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: _DonutPainter(
                segments: segments,
                total: sum == 0 ? 1 : sum,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('รวม', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final s in segments)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${s.label}  ${s.value.toInt()}'),
                    ],
                  ),
                if (segments.isEmpty)
                  const Text(
                    'ยังไม่มีข้อมูลในช่วงนี้',
                    style: TextStyle(color: Colors.black54),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSegment> segments;
  final double total;
  _DonutPainter({required this.segments, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = (Offset.zero & size).center;
    final radius = math.min(size.width, size.height) / 2;
    final stroke = radius * 0.22;

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0xFFEAEFF7);
    canvas.drawCircle(center, radius - stroke / 2, bg);

    double start = -math.pi / 2;
    for (final s in segments) {
      final sweep = (s.value / total) * 2 * math.pi;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke
        ..color = s.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - stroke / 2),
        start,
        sweep,
        false,
        p,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments || old.total != total;
}

// Goal pill
class _GoalPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final double percent;
  final Color color;
  const _GoalPill({
    required this.icon,
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pctText = '${(percent * 100).round()}%';
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 280,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percent.clamp(0, 1),
                      minHeight: 8,
                      color: color,
                      backgroundColor: color.withOpacity(.12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(pctText, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniStatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count ครั้ง',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
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

class _ChipCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _ChipCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const Spacer(),
                  Icon(Icons.more_horiz, color: Colors.grey.shade600),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '$value ครั้ง',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<_DayCount> days;
  final int maxValue;

  const _BarChart({required this.days, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    const maxH = 110.0;
    final safeMax = (maxValue <= 0 ? 1 : maxValue).toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in days)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: maxH * (d.count / safeMax),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFF4F46E5).withOpacity(.85),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${d.date.day}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCount {
  final DateTime date;
  int count;
  _DayCount(this.date, this.count);
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
