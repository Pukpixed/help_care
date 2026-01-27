import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'care_dashboard_screen.dart';

class CareDashboardMultiScreen extends StatelessWidget {
  final List<String> patientIds;

  const CareDashboardMultiScreen({super.key, required this.patientIds});

  @override
  Widget build(BuildContext context) {
    if (patientIds.length > 10) {
      return Scaffold(
        appBar: AppBar(title: const Text('สรุปกิจวัตร (ผู้ป่วยทั้งหมด)')),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: patientIds.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final id = patientIds[i];
            return ListTile(
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text('ผู้ป่วย: $id'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CareDashboardScreen(patientId: id),
                ),
              ),
            );
          },
        ),
      );
    }

    final patientsQ = FirebaseFirestore.instance
        .collection('patients')
        .where(FieldPath.documentId, whereIn: patientIds);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: patientsQ.snapshots(),
      builder: (context, snap) {
        final mapName = <String, String>{};

        if (snap.hasData) {
          for (final d in snap.data!.docs) {
            final m = d.data();
            mapName[d.id] = (m['name'] ?? m['fullName'] ?? 'ผู้ป่วย: ${d.id}')
                .toString();
          }
        }

        final tabs = patientIds
            .map(
              (id) => _PatientTab(id: id, name: mapName[id] ?? 'ผู้ป่วย: $id'),
            )
            .toList();

        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('สรุปกิจวัตร'),
              bottom: TabBar(
                isScrollable: true,
                tabs: [for (final t in tabs) Tab(text: t.name)],
              ),
            ),
            body: TabBarView(
              children: [
                for (final t in tabs)
                  CareDashboardScreen(patientId: t.id, showAppBar: false),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PatientTab {
  final String id;
  final String name;
  _PatientTab({required this.id, required this.name});
}
