import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class WorkerIndividualReportPdfGenerator {
  static Future<Uint8List> generate({
    required String projectTitle,
    required String periodName,
    required String startDate,
    required String endDate,
    required Map<String, dynamic> worker,
    required List<Map<String, dynamic>> dailyLogs,
    required num totalReg,
    required num totalOT,
    required num totalHours,
  }) async {
    final pdf = pw.Document();
    final hrsFmt = NumberFormat('#,##0.0', 'en_US');
    final dateFmt = DateFormat('MMM dd, yyyy');

    pw.MemoryImage? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/images/global_golf_logo.png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(logoImage, font, fontBold),
            pw.SizedBox(height: 20),
            pw.Text('INDIVIDUAL TIME REPORT', style: pw.TextStyle(font: fontBold, fontSize: 22, color: PdfColor.fromHex('#15803d'))),
            pw.SizedBox(height: 4),
            pw.Text(periodName, style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.grey800)),
            pw.SizedBox(height: 2),
            pw.Text('$startDate — $endDate', style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(projectTitle, style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColor.fromHex('#15803d'))),
            pw.SizedBox(height: 20),
            _buildWorkerInfo(worker, font, fontBold),
            pw.SizedBox(height: 20),
            _buildTable(dailyLogs, font, fontBold, hrsFmt, dateFmt),
            pw.SizedBox(height: 16),
            _buildGrandTotal(totalReg, totalOT, totalHours, font, fontBold, hrsFmt),
            pw.SizedBox(height: 40),
            _buildSignatureSection(font, fontBold),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(pw.MemoryImage? logoImage, pw.Font font, pw.Font fontBold) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoImage != null)
              pw.Container(
                height: 60,
                margin: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
            pw.Text('Global Golf Construction LLC', style: pw.TextStyle(font: fontBold, fontSize: 13)),
            pw.SizedBox(height: 2),
            pw.Text('31330 Sellers Terrace Dr', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey800)),
            pw.Text('Hockley, TX 77447-2328', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey800)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.SizedBox(height: 8),
            pw.Text('INDIVIDUAL TIME', style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColor.fromHex('#15803d'))),
            pw.SizedBox(height: 8),
            pw.Text('Date: ${DateFormat('MM/dd/yyyy').format(DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildWorkerInfo(Map<String, dynamic> worker, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#f8fafc'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(children: [
                  pw.Text('Worker: ', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
                  pw.Text(worker['full_name'] ?? '', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.grey900)),
                ]),
                pw.SizedBox(height: 4),
                pw.Row(children: [
                  pw.Text('ID No.: ', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
                  pw.Text(worker['id_number'] ?? '', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.grey900)),
                ]),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('ROLE', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
              pw.SizedBox(height: 2),
              pw.Text((worker['role_name'] ?? '').toString().toUpperCase(), style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColor.fromHex('#15803d'))),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(List<Map<String, dynamic>> dailyLogs, pw.Font font, pw.Font fontBold, NumberFormat hrsFmt, DateFormat dateFmt) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(1.2),
        6: const pw.FlexColumnWidth(1.2),
        7: const pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF0F172A),
          ),
          children: [
            _th('DATE', fontBold),
            _th('CHECK-IN', fontBold, align: pw.TextAlign.center),
            _th('CHECK-OUT', fontBold, align: pw.TextAlign.center),
            _th('REG HRS', fontBold, align: pw.TextAlign.right),
            _th('OT HRS', fontBold, align: pw.TextAlign.right),
            _th('BREAK', fontBold, align: pw.TextAlign.center),
            _th('NET HRS', fontBold, align: pw.TextAlign.right),
            _th('NOTES', fontBold),
          ],
        ),
        for (final log in dailyLogs) ...[
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            children: [
              _td(_formatDate(log['date'] as String, dateFmt), font),
              _td(_formatTime(log['check_in'] as String), font, align: pw.TextAlign.center),
              _td(_formatTime(log['check_out'] as String), font, align: pw.TextAlign.center),
              _td(hrsFmt.format((log['regular_hours'] as num).toDouble()), font, align: pw.TextAlign.right),
              _td(hrsFmt.format((log['overtime_hours'] as num).toDouble()), font, align: pw.TextAlign.right),
              _td('${log['break_minutes']}', font, align: pw.TextAlign.center),
              _td(hrsFmt.format((log['net_hours'] as num).toDouble()), fontBold, align: pw.TextAlign.right),
              _td(log['notes'] as String? ?? '', font),
            ],
          ),
        ],
      ],
    );
  }

  static String _formatDate(String dateStr, DateFormat dateFmt) {
    try {
      return dateFmt.format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  static String _formatTime(String time) {
    if (time.isEmpty) return '-';
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final h = int.parse(parts[0]);
        final m = parts[1];
        final ampm = h >= 12 ? 'PM' : 'AM';
        final hr = h > 12 ? h - 12 : (h == 0 ? 12 : h);
        return '${hr.toString().padLeft(2, '0')}:$m $ampm';
      }
      return time;
    } catch (_) {
      return time;
    }
  }

  static pw.Widget _th(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.white), textAlign: align),
    );
  }

  static pw.Widget _td(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8.5, color: PdfColors.grey900), textAlign: align),
    );
  }

  static pw.Widget _buildGrandTotal(num totalReg, num totalOT, num totalHours, pw.Font font, pw.Font fontBold, NumberFormat hrsFmt) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.SizedBox(width: 300, child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(flex: 4, child: pw.Text('TOTAL', style: pw.TextStyle(font: fontBold, fontSize: 12))),
              pw.Expanded(flex: 2, child: pw.Text(hrsFmt.format(totalReg), style: pw.TextStyle(font: fontBold, fontSize: 11), textAlign: pw.TextAlign.right)),
              pw.Expanded(flex: 2, child: pw.Text(hrsFmt.format(totalOT), style: pw.TextStyle(font: fontBold, fontSize: 11), textAlign: pw.TextAlign.right)),
              pw.Expanded(flex: 3, child: pw.Text(hrsFmt.format(totalHours), style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColor.fromHex('#15803d')), textAlign: pw.TextAlign.right)),
            ],
          )),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureSection(pw.Font font, pw.Font fontBold) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(thickness: 1, color: PdfColors.grey300),
        pw.SizedBox(height: 16),
        pw.Text('I confirm that the hours recorded above accurately reflect the time I worked.', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 32),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 200,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 1)),
                  ),
                  child: pw.SizedBox(height: 24),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Worker Signature', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 200,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 1)),
                  ),
                  child: pw.SizedBox(height: 24),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Date', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 32),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 200,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 1)),
                  ),
                  child: pw.SizedBox(height: 24),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Supervisor Signature', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 200,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 1)),
                  ),
                  child: pw.SizedBox(height: 24),
                ),
                pw.SizedBox(height: 4),
                pw.Text('Date', style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
