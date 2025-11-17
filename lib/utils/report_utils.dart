import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:printing/printing.dart' show PdfGoogleFonts, networkImage;

class ReportUtils {
  /// รวมข้อมูลเป็นตาราง {typeKey: count} ในช่วง [start,end)
  static Map<String, int> aggregateByType(
      Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final map = <String, int>{};
    for (final d in docs) {
      final k = (d.data()['type'] ?? '') as String;
      map[k] = (map[k] ?? 0) + 1;
    }
    return map;
  }

  /// สร้าง PDF สรุปรายช่วง พร้อมโลโก้ (ออปชัน)
  static Future<void> exportPdfSummary({
    required String title,
    required List<MapEntry<String, int>> rows, // [(label, count)]
    String? logoUrl,
  }) async {
    final font = await PdfGoogleFonts.notoSansThaiRegular();
    final bold = await PdfGoogleFonts.notoSansThaiBold();
    final doc = pw.Document();
    final theme = pw.ThemeData.withFont(base: font, bold: bold);

    pw.Widget header;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      try {
        final img = await networkImage(logoUrl);
        header = pw.Row(children: [
          pw.SizedBox(width: 64, height: 64, child: pw.Image(img, fit: pw.BoxFit.contain)),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Text(title,
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
        ]);
      } catch (_) {
        header =
            pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold));
      }
    } else {
      header =
          pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold));
    }

    doc.addPage(
      pw.MultiPage(
        theme: theme,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => [
          header,
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: pdf.PdfColors.grey300),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: pdf.PdfColors.grey200),
                children: [
                  _cell('กิจวัตร', bold: true),
                  _cell('จำนวน', bold: true, alignRight: true),
                ],
              ),
              ...rows.map((e) => pw.TableRow(
                    children: [
                      _cell(e.key),
                      _cell(e.value.toString(), alignRight: true),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/care_summary.pdf';
    final bytes = await doc.save();
    final f = File(path);
    await f.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(path)], text: title);
  }

  static pw.Widget _cell(String t, {bool bold = false, bool alignRight = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Align(
          alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
          child: pw.Text(t,
              style: pw.TextStyle(
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
      );
}
