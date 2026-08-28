import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';

class PdfReportService {
  static Future<void> generateAndShare({
    required Project project,
    required Map<String, dynamic> stats,
  }) async {
    final regularFontData =
        await rootBundle.load('assets/fonts/Tajawal-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Tajawal-Bold.ttf');

    final regularFont = pw.Font.ttf(regularFontData);
    final boldFont = pw.Font.ttf(boldFontData);

    final total = stats['total'] ?? 0;
    final done = stats['done'] ?? 0;
    final inProgress = stats['inProgress'] ?? 0;
    final todo = stats['todo'] ?? 0;
    final overdue = stats['overdue'] ?? 0;
    final progress = stats['progress'] ?? 0;

    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  project.name,
                  style: pw.TextStyle(font: boldFont, fontSize: 24),
                ),
                pw.SizedBox(height: 8),
                if (project.description.isNotEmpty)
                  pw.Text(
                    project.description,
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 14,
                      color: PdfColors.grey700,
                    ),
                  ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Text(
                  'إحصائيات المشروع',
                  style: pw.TextStyle(font: boldFont, fontSize: 18),
                ),
                pw.SizedBox(height: 12),
                _statRow(regularFont, boldFont, 'إجمالي المهام', '$total'),
                _statRow(regularFont, boldFont, 'المهام المنجزة', '$done'),
                _statRow(regularFont, boldFont, 'قيد التنفيذ', '$inProgress'),
                _statRow(regularFont, boldFont, 'لم تبدأ', '$todo'),
                _statRow(regularFont, boldFont, 'المهام المتأخرة', '$overdue'),
                _statRow(regularFont, boldFont, 'نسبة الإنجاز', '$progress%'),
                pw.SizedBox(height: 24),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text(
                  'تم إنشاء هذا التقرير بواسطة تطبيق مُنجز',
                  style: pw.TextStyle(
                    font: regularFont,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await doc.save();

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/munjiz_report.pdf');
    await file.writeAsBytes(bytes, flush: true);

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'munjiz_report.pdf',
    );
  }

  static pw.Widget _statRow(
    pw.Font regular,
    pw.Font bold,
    String title,
    String value,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(font: regular, fontSize: 14)),
          pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 14)),
        ],
      ),
    );
  }
}
