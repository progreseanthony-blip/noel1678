import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class PayrollPdfGenerator {
  static Future<Uint8List> generate({
    required String projectTitle,
    required String periodName,
    required String startDate,
    required String endDate,
    required List<Map<String, dynamic>> entries,
    required num totalReg,
    required num totalOT,
    required num totalCost,
    required num totalWorkers,
  }) async {
    final pdf = pw.Document();
    final fmt = NumberFormat('#,##0.00', 'en_US');
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
            pw.Text('LABOR COST REPORT', style: pw.TextStyle(font: fontBold, fontSize: 22, color: PdfColor.fromHex('#15803d'))),
            pw.SizedBox(height: 4),
            pw.Text(periodName, style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColors.grey800)),
            pw.SizedBox(height: 2),
            pw.Text('$startDate — $endDate', style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(projectTitle, style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColor.fromHex('#15803d'))),
            pw.SizedBox(height: 24),
            _buildSummaryRow(totalWorkers, totalReg, totalOT, totalCost, font, fontBold, hrsFmt, fmt),
            pw.SizedBox(height: 20),
            _buildTable(entries, font, fontBold, fmt, hrsFmt),
            pw.SizedBox(height: 16),
            _buildGrandTotal(totalReg, totalOT, totalCost, font, fontBold, hrsFmt, fmt),
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
            pw.Text('LABOR COST', style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColor.fromHex('#15803d'))),
            pw.SizedBox(height: 8),
            pw.Text('Date: ${DateFormat('MM/dd/yyyy').format(DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 10)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(num workers, num reg, num ot, num cost, pw.Font font, pw.Font fontBold, NumberFormat hrsFmt, NumberFormat fmt) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        _summaryItem('Workers', '$workers', font, fontBold),
        _summaryItem('Regular Hrs', hrsFmt.format(reg), font, fontBold),
        _summaryItem('Overtime Hrs', hrsFmt.format(ot), font, fontBold),
        _summaryItem('Total Cost', '\$${fmt.format(cost)}', font, fontBold, isHighlight: true),
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

  static pw.Widget _buildTable(List<Map<String, dynamic>> entries, pw.Font font, pw.Font fontBold, NumberFormat fmt, NumberFormat hrsFmt) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
        5: const pw.FlexColumnWidth(1.5),
        6: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF0F172A),
          ),
          children: [
            _th('WORKER', fontBold),
            _th('ROLE', fontBold),
            _th('RATE', fontBold, align: pw.TextAlign.right),
            _th('REG HRS', fontBold, align: pw.TextAlign.right),
            _th('OT HRS', fontBold, align: pw.TextAlign.right),
            _th('TOTAL HRS', fontBold, align: pw.TextAlign.right),
            _th('TOTAL COST', fontBold, align: pw.TextAlign.right),
          ],
        ),
        for (final e in entries) ...[
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            children: [
              _td(e['full_name'] ?? 'N/A', font),
              _td((e['role_name'] ?? '').toString().toUpperCase(), font),
              _td('\$${fmt.format((e['hourly_rate'] ?? 0).toDouble())}', font, align: pw.TextAlign.right),
              _td(hrsFmt.format((e['regular_hours'] ?? 0).toDouble()), font, align: pw.TextAlign.right),
              _td(hrsFmt.format((e['overtime_hours'] ?? 0).toDouble()), font, align: pw.TextAlign.right),
              _td(hrsFmt.format(((e['regular_hours'] ?? 0).toDouble() + (e['overtime_hours'] ?? 0).toDouble())), font, align: pw.TextAlign.right),
              _td('\$${fmt.format((e['total_pay'] ?? 0).toDouble())}', fontBold, align: pw.TextAlign.right),
            ],
          ),
        ],
      ],
    );
  }

  static pw.Widget _th(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.white), textAlign: align),
    );
  }

  static pw.Widget _td(String text, pw.Font font, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8.5, color: PdfColors.grey900), textAlign: align),
    );
  }

  static pw.Widget _buildGrandTotal(num totalReg, num totalOT, num totalCost, pw.Font font, pw.Font fontBold, NumberFormat hrsFmt, NumberFormat fmt) {
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
              pw.Expanded(flex: 2, child: pw.Text('TOTAL', style: pw.TextStyle(font: fontBold, fontSize: 12))),
              pw.Expanded(flex: 1, child: pw.Text(hrsFmt.format(totalReg), style: pw.TextStyle(font: fontBold, fontSize: 11), textAlign: pw.TextAlign.right)),
              pw.Expanded(flex: 1, child: pw.Text(hrsFmt.format(totalOT), style: pw.TextStyle(font: fontBold, fontSize: 11), textAlign: pw.TextAlign.right)),
              pw.Expanded(flex: 1, child: pw.Text(hrsFmt.format(totalReg + totalOT), style: pw.TextStyle(font: fontBold, fontSize: 11), textAlign: pw.TextAlign.right)),
              pw.Expanded(flex: 2, child: pw.Text('\$${fmt.format(totalCost)}', style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColor.fromHex('#15803d')), textAlign: pw.TextAlign.right)),
            ],
          )),
        ],
      ),
    );
  }
}
