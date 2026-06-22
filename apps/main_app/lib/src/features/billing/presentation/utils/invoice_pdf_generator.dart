import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class InvoicePdfGenerator {
  static Future<Uint8List> generate({
    required Map<String, dynamic> invoice,
    required List<Map<String, dynamic>> lines,
    required String projectTitle,
    required String clientName,
  }) async {
    final pdf = pw.Document();
    final fmt = NumberFormat('#,##0.00', 'en_US');

    pw.MemoryImage? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/images/global_golf_logo.png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    final invNum = invoice['invoice_number'] ?? '';
    final appDate = invoice['application_date'] != null
        ? DateFormat('MM/dd/yyyy').format(DateTime.parse(invoice['application_date']).toLocal())
        : '';
    final periodStart = invoice['period_start'] != null
        ? DateFormat('MM/dd/yyyy').format(DateTime.parse(invoice['period_start']).toLocal())
        : '';
    final periodEnd = invoice['period_end'] != null
        ? DateFormat('MM/dd/yyyy').format(DateTime.parse(invoice['period_end']).toLocal())
        : '';

    final orig = (invoice['original_contract'] as num?)?.toDouble() ?? 0;
    final cos = (invoice['approved_cos_total'] as num?)?.toDouble() ?? 0;
    final current = (invoice['current_contract'] as num?)?.toDouble() ?? 0;
    final prev = (invoice['total_previous_billed'] as num?)?.toDouble() ?? 0;
    final thisPd = (invoice['total_this_period'] as num?)?.toDouble() ?? 0;
    final completed = (invoice['total_completed'] as num?)?.toDouble() ?? 0;
    final retainage = (invoice['total_retainage'] as num?)?.toDouble() ?? 0;
    final due = (invoice['total_due'] as num?)?.toDouble() ?? 0;
    final balance = (invoice['balance_to_finish'] as num?)?.toDouble() ?? 0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        height: 75,
                        margin: const pw.EdgeInsets.only(bottom: 12),
                        child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                      ),
                    pw.Text('Global Golf Construction LLC', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                    pw.SizedBox(height: 4),
                    pw.Text('31330 Sellers Terrace Dr', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey800)),
                    pw.Text('Hockley, TX 77447-2328', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey800)),
                    pw.Text('noel.a@globalgolfc.com', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey800)),
                    pw.Text('+1 (281) 979-7906', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey800)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.SizedBox(height: 8),
                    pw.Text('PAY APPLICATION', style: pw.TextStyle(font: fontBold, fontSize: 26, color: PdfColor.fromHex('#15803d'))),
                    pw.SizedBox(height: 8),
                    pw.Text('App. No.: $invNum', style: pw.TextStyle(font: font, fontSize: 11)),
                    pw.SizedBox(height: 2),
                    pw.Text('Date: $appDate', style: pw.TextStyle(font: font, fontSize: 11)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            pw.Text(projectTitle, style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColor.fromHex('#15803d'))),
            pw.SizedBox(height: 4),
            pw.Text('Period: $periodStart — $periodEnd', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey800)),
            pw.SizedBox(height: 4),
            pw.Text('Client: $clientName', style: pw.TextStyle(font: font, fontSize: 10)),
            pw.SizedBox(height: 16),

            _contractSummary(font, fontBold, fmt, orig, cos, current, prev, thisPd, completed, retainage, due, balance),
            pw.SizedBox(height: 20),

            _payAppTable(font, fontBold, fmt, lines),
            pw.SizedBox(height: 20),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 250,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _summaryLine(fontBold, font, 'Total Completed:', '\$${fmt.format(completed)}'),
                      _summaryLine(fontBold, font, 'Retainage (${invoice['retainage_rate'] ?? 5}%):', '-\$${fmt.format(retainage)}'),
                      pw.Divider(thickness: 1),
                      _summaryLine(fontBold, fontBold, 'AMOUNT DUE:', '\$${fmt.format(due)}', bold: true),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 40),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Accepted date: _________________', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text('Accepted by: _________________', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Title: _________________', style: pw.TextStyle(font: font, fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text('Date: _________________', style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _contractSummary(
    pw.Font font, pw.Font fontBold, NumberFormat fmt,
    double orig, double cos, double current,
    double prev, double thisPd, double completed,
    double retainage, double due, double balance,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('CONTRACT SUMMARY', style: pw.TextStyle(font: fontBold, fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Original Contract:', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Text('\$${fmt.format(orig)}', style: pw.TextStyle(font: font, fontSize: 10)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Approved Change Orders:', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Text('\$${fmt.format(cos)}', style: pw.TextStyle(font: font, fontSize: 10)),
            ],
          ),
          pw.Divider(thickness: 1),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('CURRENT CONTRACT:', style: pw.TextStyle(font: fontBold, fontSize: 11)),
              pw.Text('\$${fmt.format(current)}', style: pw.TextStyle(font: fontBold, fontSize: 11)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Completed to Date:', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Text('\$${fmt.format(completed)}', style: pw.TextStyle(font: font, fontSize: 10)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Balance to Finish:', style: pw.TextStyle(font: font, fontSize: 10)),
              pw.Text('\$${fmt.format(balance)}', style: pw.TextStyle(font: font, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _payAppTable(
    pw.Font font, pw.Font fontBold, NumberFormat fmt,
    List<Map<String, dynamic>> lines,
  ) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(3.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(1),
        6: const pw.FlexColumnWidth(1.2),
        7: const pw.FlexColumnWidth(1.2),
        8: const pw.FlexColumnWidth(1.2),
        9: const pw.FlexColumnWidth(1.2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 1)),
          ),
          children: [
            _hdr(fontBold, '#'),
            _hdr(fontBold, 'Description'),
            _hdr(fontBold, 'Scheduled\nValue'),
            _hdr(fontBold, 'This\nPeriod'),
            _hdr(fontBold, 'Previous'),
            _hdr(fontBold, 'Equip.\nPresent'),
            _hdr(fontBold, 'Total\nCompleted'),
            _hdr(fontBold, 'Balance'),
            _hdr(fontBold, 'Retainage'),
            _hdr(fontBold, 'Total This\nPeriod'),
          ],
        ),
        ...lines.asMap().entries.map((e) {
          final i = e.key + 1;
          final l = e.value;
          final sv = (l['scheduled_value'] as num?)?.toDouble() ?? 0;
          final tp = (l['this_period_amount'] as num?)?.toDouble() ?? 0;
          final prev = (l['previous_completed'] as num?)?.toDouble() ?? 0;
          final eq = (l['equipment_present'] as num?)?.toDouble() ?? 0;
          final tc = tp + prev + eq;
          final bal = sv - tc;
          final ret = l['line_type'] == 'equipment' ? 0.0 : (tp + prev) * 0.05;
          final ttp = l['line_type'] == 'equipment' ? 0.0 : (tp + prev) - ret;

          return pw.TableRow(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            children: [
              _cell(font, '$i'),
              _cell(font, l['service_name'] ?? ''),
              _cell(font, '\$${fmt.format(sv)}', align: pw.TextAlign.right),
              _cell(font, '\$${fmt.format(tp)}', align: pw.TextAlign.right),
              _cell(font, '\$${fmt.format(prev)}', align: pw.TextAlign.right),
              _cell(font, '\$${fmt.format(eq)}', align: pw.TextAlign.right),
              _cell(font, '\$${fmt.format(tc)}', align: pw.TextAlign.right),
              _cell(font, '\$${fmt.format(bal)}', align: pw.TextAlign.right),
              _cell(font, '\$${fmt.format(ret)}', align: pw.TextAlign.right),
              _cell(font, '\$${fmt.format(ttp)}', align: pw.TextAlign.right),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _hdr(pw.Font font, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 7), textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _cell(pw.Font font, String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8), textAlign: align),
    );
  }

  static pw.Widget _summaryLine(pw.Font fontBold, pw.Font font, String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: bold ? fontBold : font, fontSize: 10)),
          pw.Text(value, style: pw.TextStyle(font: bold ? fontBold : font, fontSize: 10)),
        ],
      ),
    );
  }
}
