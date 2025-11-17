// lib/utils/export_utils.dart
import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart'
    show Printing, PdfGoogleFonts; // ใช้ Printing + PdfGoogleFonts ให้ชัด

class ExportUtils {
  // ดึงรายการผู้ป่วยของผู้ใช้ปัจจุบัน
  static Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  fetchMyPatients() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('ยังไม่ได้เข้าสู่ระบบ');
    }
    final snap = await FirebaseFirestore.instance
        .collection('patients')
        .where('uid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs;
  }

  /// ส่งออกเป็น CSV (รองรับ Excel): UTF-8 with BOM + CRLF
  static Future<void> exportCsv() async {
    final docs = await fetchMyPatients();

    // หัวตาราง
    final rows = <List<String>>[
      [
        'ชื่อ',
        'อายุ',
        'เพศ',
        'กรุ๊ปเลือด',
        'หมอ',
        'ผู้ดูแล',
        'เบอร์',
        'โรคประจำตัว',
        'ยา',
        'แพ้ยา',
        'หมายเหตุ',
      ],
    ];

    // ข้อมูล
    for (final d in docs) {
      final m = d.data();
      rows.add([
        (m['name'] ?? '').toString(),
        (m['age'] ?? '').toString(),
        (m['gender'] ?? '').toString(),
        (m['bloodGroup'] ?? '').toString(),
        (m['doctor'] ?? '').toString(),
        (m['caregiverName'] ?? '').toString(),
        (m['caregiverPhone'] ?? '').toString(),
        (m['chronicDiseases'] is List)
            ? (m['chronicDiseases'] as List).join('|')
            : '',
        (m['regularMeds'] is List) ? (m['regularMeds'] as List).join('|') : '',
        (m['drugAllergies'] is List)
            ? (m['drugAllergies'] as List).join('|')
            : '',
        (m['note'] ?? '').toString(),
      ]);
    }

    // สร้าง CSV: escape + CRLF
    final csvBody = rows.map((r) => r.map(_csvEscape).join(',')).join('\r\n');

    // เขียนไฟล์แบบ UTF-8 with BOM (สำหรับ Excel)
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/patients_export.csv');
    final bom = const [0xEF, 0xBB, 0xBF]; // UTF-8 BOM
    final bytes = <int>[]
      ..addAll(bom)
      ..addAll(utf8.encode(csvBody));
    await file.writeAsBytes(bytes, flush: true);

    await Share.shareXFiles([
      XFile(file.path),
    ], subject: 'Patients Export (CSV)');
  }

  // Escape ค่าที่มี , " หรือขึ้นบรรทัดใหม่
  static String _csvEscape(String s) {
    if (s.contains(',') ||
        s.contains('"') ||
        s.contains('\n') ||
        s.contains('\r')) {
      s = s.replaceAll('"', '""');
      return '"$s"';
    }
    return s;
  }

  /// ส่งออกเป็น PDF รวม (ฟอนต์ไทย NotoSansThai)
  static Future<void> exportPdfAll() async {
    final docs = await fetchMyPatients();

    // ฟอนต์ไทยจาก printing
    final font = await PdfGoogleFonts.notoSansThaiRegular();
    final bold = await PdfGoogleFonts.notoSansThaiBold();

    final pdf = pw.Document();

    for (final d in docs) {
      final m = d.data();
      pdf.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            theme: pw.ThemeData.withFont(base: font, bold: bold),
            margin: const pw.EdgeInsets.all(24),
          ),
          build: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ผู้ป่วย: ${m['name'] ?? '-'}',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              _kv(
                'อายุ',
                (m['age'] is num && m['age'] > 0) ? '${m['age']} ปี' : '-',
              ),
              _kv('เพศ', (m['gender'] ?? '-').toString()),
              _kv('กรุ๊ปเลือด', (m['bloodGroup'] ?? '-').toString()),
              _kv('หมอประจำตัว', (m['doctor'] ?? '-').toString()),
              _kv('ผู้ดูแล', (m['caregiverName'] ?? '-').toString()),
              _kv('เบอร์ผู้ดูแล', (m['caregiverPhone'] ?? '-').toString()),
              _kv('โรคประจำตัว', _list(m['chronicDiseases'])),
              _kv('ยาที่ใช้รักษา', _list(m['regularMeds'])),
              _kv('ประวัติการแพ้ยา', _list(m['drugAllergies'])),
              _kv('หมายเหตุ', (m['note'] ?? '-').toString()),
            ],
          ),
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (f) async => pdf.save());
  }

  static pw.Widget _kv(String k, String v) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 150,
          child: pw.Text(
            k,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
            ), // ✅ เอา const ออก
          ),
        ),
        pw.Expanded(child: pw.Text(v)),
      ],
    ),
  );

  static String _list(dynamic x) =>
      (x is List && x.isNotEmpty) ? x.join(', ') : '-';
}
