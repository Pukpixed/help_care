import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../routes.dart';
import 'patients_search_delegate.dart';
import 'patients_detail_view.dart';

class PatientsScreen extends StatelessWidget {
  const PatientsScreen({super.key});

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('patients');

  // ───────────────────────── Quick Add ─────────────────────────
  Future<void> _quickAdd(BuildContext context) async {
    final nameCtl = TextEditingController();
    final ageCtl = TextEditingController();

    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('เพิ่มผู้ป่วยอย่างเร็ว'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อ-สกุล',
                    hintText: 'เช่น นายสมชาย ใจดี',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ageCtl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'อายุ (ปี)'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('บันทึก'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;
    final name = nameCtl.text.trim();
    final age = int.tryParse(ageCtl.text.trim());

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อผู้ป่วย')));
      return;
    }

    final now = FieldValue.serverTimestamp();
    await _col.add({
      'name': name,
      'age': age,
      'gender': 'other',
      'note': '',
      'createdAt': now,
      'updatedAt': now,
      'keywords': name.toLowerCase().split(RegExp(r'\s+')),
    });
  }

  void _openSearch(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    showSearch(
      context: context,
      delegate: PatientsSearchDelegate(docs: docs),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _col.orderBy('name');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FE),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _quickAdd(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('เพิ่มผู้ป่วย'),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: q.snapshots(),
          builder: (context, snap) {
            // ─────────── Errors / Loading ───────────
            if (snap.hasError) {
              return _ErrorState(
                message: 'โหลดข้อมูลไม่สำเร็จ',
                detail: '${snap.error}',
                onRetry: () => {},
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;
            return CustomScrollView(
              slivers: [
                // ─────────── Header Gradient ───────────
                SliverToBoxAdapter(
                  child: _Header(
                    count: docs.length,
                    onTapSearch: docs.isEmpty
                        ? null
                        : () => _openSearch(context, docs),
                  ),
                ),

                // ─────────── Empty State ───────────
                if (docs.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 80),
                      child: _EmptyState(),
                    ),
                  )
                else
                  // ─────────── List of Patients ───────────
                  SliverList.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final d = docs[i];
                      final m = d.data();
                      final name = (m['name'] ?? '').toString();
                      final age = m['age'];
                      final gender = (m['gender'] ?? 'other').toString();

                      final icon = gender == 'female'
                          ? Icons.female
                          : (gender == 'male' ? Icons.male : Icons.person);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 3,
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFFEDE9FF),
                              child: Icon(icon, color: const Color(0xFF7B2DFF)),
                            ),
                            title: Text(
                              name.isEmpty ? 'ไม่ระบุชื่อ' : name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              age is int ? 'อายุ $age ปี' : 'ไม่ระบุอายุ',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PatientsDetailView(patientId: d.id),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ───────────────────────── Widgets ─────────────────────────

class _Header extends StatelessWidget {
  final int count;
  final VoidCallback? onTapSearch;
  const _Header({required this.count, this.onTapSearch});

  @override
  Widget build(BuildContext context) {
    final h = math.max(200.0, MediaQuery.of(context).size.height * 0.26);

    return SizedBox(
      height: h,
      width: double.infinity,
      child: Stack(
        children: [
          // Gradient + Wave
          ClipPath(
            clipper: _WaveClipper(),
            child: Container(
              height: h,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF660F24), Color(0xFFF24455)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AppBar Row
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => onTapSearch?.call(),
                      icon: const Icon(Icons.search, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'โปรไฟล์ผู้ป่วย/ผู้สูงอายุ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ทั้งหมด $count รายชื่อ',
                  style: TextStyle(color: Colors.white.withOpacity(.9)),
                ),
                const SizedBox(height: 16),

                // Search fake field (tap to open delegate)
                InkWell(
                  onTap: onTapSearch,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF7B2DFF)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'ค้นหาโดยชื่อผู้ป่วย',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                        if (onTapSearch == null)
                          const Text(
                            'ไม่มีข้อมูล',
                            style: TextStyle(color: Colors.black38),
                          ),
                      ],
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: const [
          Icon(Icons.inbox_outlined),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'ยังไม่มีรายชื่อผู้ป่วย – แตะ “เพิ่มผู้ป่วย” ที่มุมขวาล่างเพื่อเริ่มต้น',
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String? detail;
  final VoidCallback onRetry;
  const _ErrorState({
    required this.message,
    this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }
}

/// คลื่นโค้งของส่วนหัว (ให้ mood ใกล้กับ UI ตัวอย่าง)
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 40);
    final cp1 = Offset(size.width * .25, size.height);
    final ep1 = Offset(size.width * .6, size.height - 28);
    path.quadraticBezierTo(cp1.dx, cp1.dy, ep1.dx, ep1.dy);

    final cp2 = Offset(size.width * .85, size.height - 52);
    final ep2 = Offset(size.width, size.height - 10);
    path.quadraticBezierTo(cp2.dx, cp2.dy, ep2.dx, ep2.dy);

    path
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
