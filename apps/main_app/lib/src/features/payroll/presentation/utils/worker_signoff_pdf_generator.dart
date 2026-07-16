import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class WorkerSignoffPdfGenerator {
  static Future<Uint8List> generate({
    required String projectTitle,
    required String periodName,
    required String startDate,
    required String endDate,
    required List<Map<String, dynamic>> workers,
    required num totalReg,
    required num totalOT,
    required num totalHours,
    required num totalWorkers,
  }) async {
    final pdf = pw.Document();
    final hrsFmt = NumberFormat('#,##0.0', 'en_US');

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
            pw.Text('WORKER TIME SIGN-OFF REPORT', style: pw.TextStyle(font: fontBold, fontSize: 22, color: PdfColor.fromHex('#15803d'))),
            pw.SizedBox(height: 4),
            pw.Text(periodName, style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.grey800)),
            pw.SizedBox(height: 2),
            pw.Text('$startDate — $endDate', style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(projectTitle, style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColor.fromHex('#15803d'))),
            pw.SizedBox(height: 24),
            _buildSummaryRow(totalWorkers, totalReg, totalOT, totalHours, font, fontBold, hrsFmt),
            pw.SizedBox(height: 20),
            _buildTable(workers, font, fontBold, hrsFmt),
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
            pw.Text('TIME SIGN-OFF', style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColor.fromHex('#15803d'))),
            pw.SizedBox(height: 8),
            pw.Text('Date: ${DateFormat('MM/dd/yyyy').format(DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(num workers, num reg, num ot, num total, pw.Font font, pw.Font fontBold, NumberFormat hrsFmt) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        _summaryItem('Workers', '$workers', font, fontBold),
        _summaryItem('Regular Hrs', hrsFmt.format(reg), font, fontBold),
        _summaryItem('Overtime Hrs', hrsFmt.format(ot), font, fontBold),
        _summaryItem('Total Hours', hrsFmt.format(total), font, fontBold, isHighlight: true),
      ],
    );
  }

  static pw.Widget _summaryItem(String label, String value, pw.Font font, pw.Font fontBold, {bool isHighlight = false}) {
    return pw.Container(
      width: 110,
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: pw.BoxDecoration(
        color: isHighlight ? PdfColor.fromHex('#f0fdf4') : PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600)),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 14, color: isHighlight ? PdfColor.fromHex('#15803d') : PdfColors.grey900)),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(List<Map<String, dynamic>> workers, pw.Font font, pw.Font fontBold, NumberFormat hrsFmt) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.8),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
        6: const pw.FlexColumnWidth(1.5),
        7: const pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF0F172A),
          ),
          children: [
            _th('#', fontBold),
            _th('WORKER', fontBold),
            _th('ID No.', fontBold),
            _th('ROLE', fontBold),
            _th('REG HRS', fontBold, align: pw.TextAlign.right),
            _th('OT HRS', fontBold, align: pw.TextAlign.right),
            _th('TOTAL HRS', fontBold, align: pw.TextAlign.right),
            _th('SIGNATURE', fontBold, align: pw.TextAlign.center),
          ],
        ),
        for (int i = 0; i < workers.length; i++) ...[
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            children: [
              _td('${i + 1}', font),
              _td(workers[i]['full_name'] ?? 'N/A', font),
              _td(workers[i]['id_number'] ?? '', font),
              _td((workers[i]['role_name'] ?? '').toString().toUpperCase(), font),
              _td(hrsFmt.format((workers[i]['regular_hours'] ?? 0).toDouble()), font, align: pw.TextAlign.right),
              _td(hrsFmt.format((workers[i]['overtime_hours'] ?? 0).toDouble()), font, align: pw.TextAlign.right),
              _td(hrsFmt.format((workers[i]['total_hours'] ?? 0).toDouble()), fontBold, align: pw.TextAlign.right),
              _signatureCell(font),
            ],
          ),
        ],
      ],
    );
  }

  static pw.Widget _signatureCell(pw.Font font) {
    return pw.Container(
      height: 24,
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5)),
      ),
      child: pw.SizedBox.shrink(),
    );
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
          pw.SizedBox(width: 320, child: pw.Row(
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
        pw.Text('I confirm that the hours recorded above accurately reflect the time worked.', style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey700)),
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
