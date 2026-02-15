import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';

import '../color.dart';
import '../utils/report_utils.dart';
import 'care_types_settings_screen.dart';

class CareLogScreen extends StatefulWidget {
  final String patientId;
  const CareLogScreen({super.key, required this.patientId});

  @override
  State<CareLogScreen> createState() => _CareLogScreenState();
}

enum _Range { day, week, month }

class _CareType {
  final String key, label, icon;
  final int color; // ARGB
  const _CareType(this.key, this.label, this.icon, this.color);

  IconData get iconData {
    switch (icon) {
      // อาหาร/เครื่องดื่ม
      case 'restaurant_outlined':
        return Icons.restaurant_outlined;
      case 'breakfast_dining':
        return Icons.breakfast_dining;
      case 'lunch_dining':
        return Icons.lunch_dining;
      case 'dinner_dining':
        return Icons.dinner_dining;
      case 'bakery_dining':
        return Icons.bakery_dining;
      case 'icecream':
        return Icons.icecream;
      case 'coffee':
        return Icons.coffee;
      case 'local_drink_outlined':
        return Icons.local_drink_outlined;
      case 'water_drop_outlined':
        return Icons.water_drop_outlined;

      // ยา/สุขภาพ
      case 'medication_outlined':
        return Icons.medication_outlined;
      case 'medical_services_outlined':
        return Icons.medical_services_outlined;
      case 'vaccines_outlined':
        return Icons.vaccines_outlined;
      case 'vaccines':
        return Icons.vaccines;
      case 'monitor_heart_outlined':
        return Icons.monitor_heart_outlined;
      case 'monitor_heart':
        return Icons.monitor_heart;
      case 'bloodtype_outlined':
        return Icons.bloodtype_outlined;
      case 'bloodtype':
        return Icons.bloodtype;
      case 'clean_hands_outlined':
        return Icons.clean_hands_outlined;
      case 'masks_outlined':
        return Icons.masks_outlined;

      // กิจวัตร/พักผ่อน/ทำความสะอาด
      case 'rotate_90_degrees_ccw_outlined':
        return Icons.rotate_90_degrees_ccw_outlined;
      case 'wc_outlined':
        return Icons.wc_outlined;
      case 'hotel_outlined':
        return Icons.hotel_outlined;
      case 'shower_outlined':
        return Icons.shower_outlined;
      case 'bedtime_outlined':
        return Icons.bedtime_outlined;
      case 'schedule_outlined':
        return Icons.schedule_outlined;
      case 'alarm_outlined':
        return Icons.alarm_outlined;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'set_meal_outlined':
        return Icons.set_meal_outlined;
      case 'chat_bubble_outline':
        return Icons.chat_bubble_outline;

      // การเคลื่อนไหว/กายภาพ
      case 'directions_walk_outlined':
        return Icons.directions_walk_outlined;
      case 'directions_bike':
        return Icons.directions_bike;
      case 'hiking':
        return Icons.hiking;
      case 'fitness_center_outlined':
        return Icons.fitness_center_outlined;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'sports_gymnastics':
        return Icons.sports_gymnastics;

      // อื่น ๆ
      case 'child_friendly_outlined':
        return Icons.child_friendly_outlined;
      case 'cloud_outlined':
        return Icons.cloud_outlined;

      default:
        return Icons.widgets_outlined;
    }
  }
}

class _CareLogScreenState extends State<CareLogScreen> {
  /// ✅ ใหม่: patients/{patientId}/care_logs
  CollectionReference<Map<String, dynamic>> get _newCol => FirebaseFirestore
      .instance
      .collection('patients')
      .doc(widget.patientId)
      .collection('care_logs');

  /// ✅ เดิม: care_logs (root)
  final CollectionReference<Map<String, dynamic>> _legacyCol = FirebaseFirestore
      .instance
      .collection('care_logs');

  /// ✅ อ่านทั้งใหม่+เก่า ระหว่างช่วงย้าย
  static const bool _enableLegacyRead = true;

  List<_CareType> _types = [];
  bool _loadingTypes = true;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _typesSub;

  _Range _range = _Range.day;
  DateTime _anchor = DateTime.now();

  /// ตัวกรอง “หลายชนิดพร้อมกัน”
  final Set<String> _selectedTypeKeys = <String>{};

  final _noteCtl = TextEditingController();

  /// โหมดสำรอง (ไม่ใช้ Index) สำหรับ legacy เท่านั้น
  bool _noIndexFallback = false;

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
  void didUpdateWidget(covariant CareLogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patientId != widget.patientId) {
      _typesSub?.cancel();
      _typesSub = null;
      setState(() {
        _types = [];
        _loadingTypes = true;
        _selectedTypeKeys.clear();
        _noIndexFallback = false;
        // _anchor = DateTime.now(); // ถ้าอยาก reset ช่วงเวลาเมื่อเปลี่ยนคน
      });
      _listenTypes();
    }
  }

  @override
  void dispose() {
    _typesSub?.cancel();
    _noteCtl.dispose();
    super.dispose();
  }

  void _listenTypes() {
    _typesSub = _typeCol
        .orderBy('order', descending: false)
        .snapshots()
        .listen(
          (s) {
            final docs = s.docs.toList();
            docs.sort((a, b) {
              final ma = a.data();
              final mb = b.data();
              final ao = (ma['order'] is int) ? ma['order'] as int : 999999;
              final bo = (mb['order'] is int) ? mb['order'] as int : 999999;
              if (ao != bo) return ao.compareTo(bo);
              final al = (ma['label'] ?? '').toString().toLowerCase();
              final bl = (mb['label'] ?? '').toString().toLowerCase();
              return al.compareTo(bl);
            });

            final list = <_CareType>[
              for (final d in docs)
                _CareType(
                  (d['key'] ?? '').toString(),
                  (d['label'] ?? '').toString(),
                  (d['icon'] ?? 'restaurant_outlined').toString(),
                  (d['color'] ?? 0xFFB00020) as int,
                ),
            ];
            if (mounted) {
              setState(() {
                _types = list;
                _loadingTypes = false;
                _selectedTypeKeys.removeWhere(
                  (k) => !_types.any((t) => t.key == k),
                );
              });
            }
          },
          onError: (_) {
            if (mounted) setState(() => _loadingTypes = false);
          },
        );
  }

  // ───── Time helpers ─────
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

  // ───── Quick actions ─────
  Future<void> _quickAdd(_CareType t) async {
    await _newCol.add({
      'patientId': widget.patientId,
      'type': t.key,
      'note': '',
      'time': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _addManual() async {
    _noteCtl.clear();
    _CareType? sel = _types.isNotEmpty ? _types.first : null;
    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSB) => AlertDialog(
          title: const Text('บันทึกกิจวัตร'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<_CareType>(
                value: sel,
                items: _types
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Row(
                          children: [
                            Icon(t.iconData, color: Color(t.color)),
                            const SizedBox(width: 8),
                            Text(t.label),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setSB(() => sel = v),
                decoration: const InputDecoration(labelText: 'ชนิดกิจวัตร'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteCtl,
                decoration: const InputDecoration(
                  labelText: 'โน้ต (ไม่บังคับ)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: sel == null
                  ? null
                  : () async {
                      await _newCol.add({
                        'patientId': widget.patientId,
                        'type': sel!.key,
                        'note': _noteCtl.text.trim(),
                        'time': FieldValue.serverTimestamp(),
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if (mounted) Navigator.pop(ctx);
                    },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
  }

  // ───── UI helpers ─────
  String _typeLabel(String key) =>
      _types.where((e) => e.key == key).firstOrNull?.label ?? key;

  Icon _typeIcon(String key) {
    final t = _types.where((e) => e.key == key).firstOrNull;
    return Icon(
      (t?.iconData ?? Icons.circle_outlined),
      color: Color(t?.color ?? 0xFF9E9E9E),
    );
  }

  // ───── CSV ─────
  Future<void> _exportCsv(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final rows = <List<String>>[
      ['วันที่', 'เวลา', 'ชนิด', 'โน้ต'],
      ...docs.map((d) {
        final m = d.data();
        final ts = (m['time'] as Timestamp?)?.toDate();
        final dd = ts != null ? _fmtDate(ts) : '-';
        final tt = ts != null
            ? '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
            : '-';
        final label = _typeLabel((m['type'] ?? '').toString());
        return [dd, tt, label, (m['note'] ?? '').toString()];
      }),
    ];
    final csv = const ListToCsv().encode(rows);
    final x = XFile.fromData(
      utf8.encode(csv),
      mimeType: 'text/csv',
      name: 'care_logs.csv',
    );
    await Share.shareXFiles([x], text: _rangeLabel());
  }

  Widget _buildFilterChips(
    Map<String, int> byType,
    List<_CareType> availableTypes,
  ) {
    final items = availableTypes
        .where(
          (t) => byType.containsKey(t.key) || _selectedTypeKeys.contains(t.key),
        )
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          FilterChip(
            selected: _selectedTypeKeys.isEmpty,
            label: const Text('ทั้งหมด'),
            onSelected: (_) => setState(_selectedTypeKeys.clear),
          ),
          const SizedBox(width: 8),
          for (final t in items) ...[
            FilterChip(
              selected: _selectedTypeKeys.contains(t.key),
              avatar: Icon(t.iconData, color: Color(t.color), size: 18),
              label: Text(t.label),
              onSelected: (v) => setState(() {
                if (v) {
                  _selectedTypeKeys.add(t.key);
                } else {
                  _selectedTypeKeys.remove(t.key);
                }
              }),
            ),
            const SizedBox(width: 8),
          ],
          if (_selectedTypeKeys.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(_selectedTypeKeys.clear),
              icon: const Icon(Icons.clear),
              label: const Text('ล้างตัวกรอง'),
            ),
        ],
      ),
    );
  }

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

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _fetchRangeBoth(
    DateTime s,
    DateTime e,
  ) async {
    final newSnap = await _newCol
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(s))
        .where('time', isLessThan: Timestamp.fromDate(e))
        .get();

    List<QueryDocumentSnapshot<Map<String, dynamic>>> legacyDocs = const [];
    if (_enableLegacyRead) {
      try {
        final legacySnap = await _legacyCol
            .where('patientId', isEqualTo: widget.patientId)
            .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(s))
            .where('time', isLessThan: Timestamp.fromDate(e))
            .get();
        legacyDocs = legacySnap.docs;
      } catch (_) {
        legacyDocs = const [];
      }
    }

    return _mergeAndSort(newSnap.docs, legacyDocs);
  }

  @override
  Widget build(BuildContext context) {
    final (s, e) = _rangeStartEnd();

    final qNew = _newCol
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(s))
        .where('time', isLessThan: Timestamp.fromDate(e))
        .orderBy('time', descending: true);

    final qLegacyNormal = _legacyCol
        .where('patientId', isEqualTo: widget.patientId)
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(s))
        .where('time', isLessThan: Timestamp.fromDate(e))
        .orderBy('time', descending: true);

    final qLegacyFallback = _legacyCol
        .where('patientId', isEqualTo: widget.patientId)
        .limit(50);

    final legacyStream = (_noIndexFallback ? qLegacyFallback : qLegacyNormal)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 203, 203, 203),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          'บันทึกกิจวัตร',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black),
        ),
        actions: [
          IconButton(
            tooltip: 'ตั้งค่าชนิดกิจวัตร',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    CareTypesSettingsScreen(patientId: widget.patientId),
              ),
            ),
            icon: const Icon(Icons.tune),
          ),
          const SizedBox(width: 4),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                SegmentedButton<_Range>(
                  segments: const [
                    ButtonSegment(value: _Range.day, label: Text('วัน')),
                    ButtonSegment(value: _Range.week, label: Text('สัปดาห์')),
                    ButtonSegment(value: _Range.month, label: Text('เดือน')),
                  ],
                  selected: {_range},
                  onSelectionChanged: (v) => setState(() => _range = v.first),
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    padding: const MaterialStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    textStyle: const MaterialStatePropertyAll(
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(
                      horizontal: -2,
                      vertical: -2,
                    ),
                    minimumSize: const MaterialStatePropertyAll(Size(0, 0)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _anchor = DateTime.now()),
                  icon: const Icon(Icons.today_outlined),
                  label: const Text('วันนี้'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: const VisualDensity(
                      horizontal: -2,
                      vertical: -2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _types.isEmpty ? null : _addManual,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มบันทึก'),
        backgroundColor: _types.isEmpty ? Colors.grey : AppColors.redDeep,
        foregroundColor: Colors.white,
      ),
      body: _loadingTypes
          ? const Center(child: CircularProgressIndicator())
          : (_types.isEmpty
                ? _emptyTypesPlaceholder()
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: qNew.snapshots(),
                    builder: (_, newSnap) {
                      if (newSnap.hasError) {
                        return _IndexErrorCard(
                          message: newSnap.error.toString(),
                          indexUrl: _extractIndexUrl(newSnap.error.toString()),
                          onUseFallback: () {},
                        );
                      }
                      if (!newSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final newDocs = newSnap.data!.docs;

                      if (!_enableLegacyRead) {
                        return _buildMainList(newDocs);
                      }

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: legacyStream,
                        builder: (_, oldSnap) {
                          if (oldSnap.hasError) {
                            if (newDocs.isNotEmpty) {
                              return _buildMainList(newDocs);
                            }
                            final msg = oldSnap.error.toString();
                            final link = _extractIndexUrl(msg);
                            return _IndexErrorCard(
                              message: msg,
                              indexUrl: link,
                              onUseFallback: () => setState(() {
                                _noIndexFallback = true;
                              }),
                            );
                          }

                          if (!oldSnap.hasData) {
                            if (newDocs.isNotEmpty)
                              return _buildMainList(newDocs);
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final merged = _mergeAndSort(
                            newDocs,
                            oldSnap.data!.docs,
                          );
                          return _buildMainList(merged);
                        },
                      );
                    },
                  )),
    );
  }

  Widget _buildMainList(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docsAll,
  ) {
    final byTypeAll = ReportUtils.aggregateByType(docsAll);

    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = docsAll;
    if (_selectedTypeKeys.isNotEmpty) {
      docs = docsAll
          .where(
            (d) => _selectedTypeKeys.contains((d['type'] ?? '').toString()),
          )
          .toList();
    }

    const target = 20.0;
    final double pct = (docs.length / target).clamp(0, 1).toDouble();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _TopSummaryCard(
          title: _rangeLabel(),
          subtitle: _selectedTypeKeys.isEmpty
              ? 'บันทึกทั้งหมดในช่วงนี้'
              : 'ตัวกรอง: ${_selectedTypeKeys.map(_typeLabel).join(", ")}',
          valueText: '${docs.length}',
          progress: pct,
          chip: _selectedTypeKeys.isEmpty
              ? null
              : InputChip(
                  label: const Text('ล้างตัวกรอง'),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => setState(() => _selectedTypeKeys.clear()),
                ),
          onMore: () => _openMoreMenu(context, docs),
        ),
        const SizedBox(height: 8),

        _buildFilterChips(byTypeAll, _types),
        const SizedBox(height: 12),

        Row(
          children: [
            const Text(
              'รายการล่าสุด',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const Spacer(),
            TextButton(
              onPressed: _selectedTypeKeys.isEmpty
                  ? null
                  : () => setState(() => _selectedTypeKeys.clear()),
              child: const Text('ดูทั้งหมด'),
            ),
          ],
        ),

        if (docs.isEmpty)
          const _EmptyRoundedCard(text: 'ยังไม่มีบันทึกในช่วงนี้')
        else
          Material(
            color: Colors.white,
            elevation: 3,
            borderRadius: BorderRadius.circular(20),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) {
                final d = docs[i];
                final m = d.data();
                final ts = (m['time'] as Timestamp?)?.toDate();
                final date = ts != null ? _fmtDate(ts) : '-';
                final time = ts != null
                    ? '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
                    : '-';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: _typeIcon((m['type'] ?? '').toString()),
                    ),
                  ),
                  title: Text(_typeLabel((m['type'] ?? '').toString())),
                  subtitle: Text(
                    '$date  $time\n${(m['note'] ?? '').toString()}',
                  ),
                  isThreeLine: (m['note'] ?? '').toString().trim().isNotEmpty,
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showRowMenu(context, d),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _openMoreMenu(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_view_outlined),
                title: const Text('ส่งออก CSV (ตามตัวกรอง)'),
                onTap: () {
                  Navigator.pop(context);
                  _exportCsv(docs);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('สรุปเป็น PDF'),
                onTap: () async {
                  Navigator.pop(context);

                  final (s, e) = _rangeStartEnd();
                  var list = await _fetchRangeBoth(s, e);

                  if (_selectedTypeKeys.isNotEmpty) {
                    list = list
                        .where(
                          (d) => _selectedTypeKeys.contains(
                            (d['type'] ?? '').toString(),
                          ),
                        )
                        .toList();
                  }

                  final map = ReportUtils.aggregateByType(list);
                  final rows = <MapEntry<String, int>>[];
                  for (final t in _types) {
                    rows.add(MapEntry(t.label, map[t.key] ?? 0));
                  }
                  await ReportUtils.exportPdfSummary(
                    title: 'สรุปกิจวัตร ${_rangeLabel()}',
                    rows: rows,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRowMenu(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> d,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('เพิ่มโน้ต'),
              onTap: () async {
                Navigator.pop(context);
                final m = d.data();
                _noteCtl.text = (m['note'] ?? '').toString();
                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('แก้ไขโน้ต'),
                    content: TextField(
                      controller: _noteCtl,
                      decoration: const InputDecoration(hintText: 'โน้ต'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('ยกเลิก'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await d.reference.update({
                            'note': _noteCtl.text.trim(),
                          });
                          if (mounted) Navigator.pop(context);
                        },
                        child: const Text('บันทึก'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('ลบรายการ'),
              onTap: () async {
                Navigator.pop(context);
                await d.reference.delete();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyTypesPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ยังไม่มี “ชนิดกิจวัตร”'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.tune),
              label: const Text('ไปตั้งค่าชนิดกิจวัตร'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        CareTypesSettingsScreen(patientId: widget.patientId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String? _extractIndexUrl(String msg) {
    final re = RegExp(r'(https:\/\/console\.firebase\.google\.com\/[^\s]+)');
    final m = re.firstMatch(msg);
    return m?.group(1);
  }
}

// ───────────── Widgets ย่อย ─────────────

class _TopSummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String valueText;
  final double progress;
  final Widget? chip;
  final VoidCallback? onMore;

  const _TopSummaryCard({
    required this.title,
    required this.subtitle,
    required this.valueText,
    required this.progress,
    this.chip,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 120,
      ), // ✅ ไม่ fix ความสูงแล้ว
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 10,
                  backgroundColor: Colors.white.withOpacity(.25),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          /// ✅ Expanded กันล้นแนวนอน
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min, // ✅ สำคัญมาก
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valueText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (chip != null) ...[const SizedBox(height: 6), chip!],
              ],
            ),
          ),

          IconButton(
            onPressed: onMore,
            color: Colors.white,
            icon: const Icon(Icons.more_horiz),
          ),
        ],
      ),
    );
  }
}

class _EmptyRoundedCard extends StatelessWidget {
  final String text;
  const _EmptyRoundedCard({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Center(child: Text(text)),
    );
  }
}

class _IndexErrorCard extends StatelessWidget {
  final String message;
  final String? indexUrl;
  final VoidCallback onUseFallback;

  const _IndexErrorCard({
    required this.message,
    required this.indexUrl,
    required this.onUseFallback,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36, color: Colors.deepOrange),
            const SizedBox(height: 12),
            const Text(
              'ต้องสร้าง Composite Index สำหรับคิวรีนี้',
              style: TextStyle(fontWeight: FontWeight.w700),
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

class ListToCsv {
  const ListToCsv();
  String encode(List<List<String>> rows) =>
      rows.map((r) => r.map(_esc).join(',')).join('\n');
  String _esc(String v) {
    final need =
        v.contains(',') ||
        v.contains('"') ||
        v.contains('\n') ||
        v.contains('\r');
    if (!need) return v;
    final w = v.replaceAll('"', '""');
    return '"$w"';
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
