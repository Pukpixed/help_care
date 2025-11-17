import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'patients_detail_view.dart';

class PatientsSearchDelegate extends SearchDelegate<String?> {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  PatientsSearchDelegate({required this.docs});

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filter(String q) {
    final t = q.trim().toLowerCase();
    if (t.isEmpty) return docs;
    return docs.where((d) {
      final m = d.data();
      final name = (m['name'] ?? '').toString().toLowerCase();
      final kw =
          (m['keywords'] as List?)?.map((e) => e.toString()).toList() ??
          const [];
      return name.contains(t) || kw.any((k) => k.contains(t));
    }).toList();
  }

  @override
  String get searchFieldLabel => 'ค้นหาชื่อผู้ป่วย';

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: 'ล้าง',
        onPressed: () => query = '',
        icon: const Icon(Icons.clear),
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    tooltip: 'ย้อนกลับ',
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final results = _filter(query);
    if (results.isEmpty) {
      return const Center(child: Text('ไม่พบผู้ป่วยที่ตรงกับคำค้น'));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final d = results[i];
        final m = d.data();
        final name = (m['name'] ?? '').toString();
        final age = m['age'];
        final gender = (m['gender'] ?? 'other').toString();

        return Material(
          color: Colors.white,
          elevation: 2,
          borderRadius: BorderRadius.circular(14),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFEFF4FF),
              child: Icon(
                gender == 'female'
                    ? Icons.female
                    : (gender == 'male' ? Icons.male : Icons.person),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(age is int ? 'อายุ $age ปี' : 'ไม่ระบุอายุ'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              close(context, d.id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientsDetailView(patientId: d.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
