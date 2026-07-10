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
    List<Map<String, dynamic>> machineryDeductions = const [],
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

    final retainageRate = (invoice['retainage_rate'] as num?)?.toDouble() ?? 5.0;
    final orig = (invoice['original_contract'] as num?)?.toDouble() ?? 0;
    final cos = (invoice['approved_cos_total'] as num?)?.toDouble() ?? 0;
    final current = orig + cos;

    double totalScheduled = 0, totalThisPeriod = 0, totalPrev = 0, totalEq = 0;
    for (final l in lines) {
      totalScheduled += (l['scheduled_value'] as num?)?.toDouble() ?? 0;
      totalThisPeriod += (l['this_period_amount'] as num?)?.toDouble() ?? 0;
      totalPrev += (l['previous_completed'] as num?)?.toDouble() ?? 0;
      totalEq += (l['equipment_present'] as num?)?.toDouble() ?? 0;
    }
    final completed = totalPrev + totalThisPeriod + totalEq;
    final retainage = lines.fold(0.0, (s, l) {
      if (l['line_type']?.toString() == 'equipment') return s;
      final tp = (l['this_period_amount'] as num?)?.toDouble() ?? 0;
      final p = (l['previous_completed'] as num?)?.toDouble() ?? 0;
      return s + ((tp + p) * retainageRate / 100);
    });
    final due = totalThisPeriod - retainage;
    final balance = totalScheduled - completed;

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

            _contractSummary(font, fontBold, fmt, orig, cos, current, totalPrev, totalThisPeriod, completed, retainageRate, retainage, due, balance),
            pw.SizedBox(height: 20),

            _payAppTable(font, fontBold, fmt, lines, retainageRate),
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

    if (machineryDeductions.isNotEmpty) {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return _machinerySupportPage(font, fontBold, fmt, machineryDeductions, lines, projectTitle, periodStart, periodEnd);
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _contractSummary(
    pw.Font font, pw.Font fontBold, NumberFormat fmt,
    double orig, double cos, double current,
    double totalPrev, double totalThisPeriod, double completed,
    double retainageRate, double retainage, double due, double balance,
  ) {
    pw.Widget _line(String label, String value, {bool bold = false, bool green = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label, style: pw.TextStyle(font: bold ? fontBold : font, fontSize: 9)),
            pw.Text(value, style: pw.TextStyle(
              font: bold ? fontBold : font, fontSize: 9,
              color: green ? PdfColor.fromHex('#15803d') : null,
            )),
          ],
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('CONTRACT SUMMARY', style: pw.TextStyle(font: fontBold, fontSize: 12)),
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _line('Original Contract:', '\$${fmt.format(orig)}'),
                    _line('Approved COs:', '\$${fmt.format(cos)}'),
                    pw.Divider(thickness: 0.5),
                    _line('CURRENT CONTRACT:', '\$${fmt.format(current)}', bold: true),
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _line('Total Previous:', '\$${fmt.format(totalPrev)}'),
                    _line('Total This Period:', '\$${fmt.format(totalThisPeriod)}'),
                    _line('Total Completed:', '\$${fmt.format(completed)}'),
                  ],
                ),
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _line('Retainage ($retainageRate%):', '\$${fmt.format(retainage)}'),
                    _line('AMOUNT DUE:', '\$${fmt.format(due)}', bold: true, green: true),
                    _line('Balance to Finish:', '\$${fmt.format(balance)}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _payAppTable(
    pw.Font font, pw.Font fontBold, NumberFormat fmt,
    List<Map<String, dynamic>> lines,
    double retainageRate,
  ) {
    final tableRows = <pw.TableRow>[];

    tableRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 1)),
        ),
        children: [
          _hdr(fontBold, '#'),
          _hdr(fontBold, 'Description'),
          _hdr(fontBold, 'Scheduled\nValue'),
          _hdr(fontBold, 'Work Done\nThis Period'),
          _hdr(fontBold, 'Prev.\nCompleted'),
          _hdr(fontBold, 'Equip.\nPresent'),
          _hdr(fontBold, 'Total\nCompleted'),
          _hdr(fontBold, 'Balance to\nFinish'),
          _hdr(fontBold, 'Retainage\n$retainageRate%'),
          _hdr(fontBold, 'Total This\nPeriod'),
        ],
      ),
    );

    double tSv = 0, tTp = 0, tPrev = 0, tEq = 0, tTc = 0, tBal = 0, tRet = 0, tTtp = 0;

    for (int i = 0; i < lines.length; i++) {
      final l = lines[i];
      final sv = (l['scheduled_value'] as num?)?.toDouble() ?? 0;
      final tp = (l['this_period_amount'] as num?)?.toDouble() ?? 0;
      final prev = (l['previous_completed'] as num?)?.toDouble() ?? 0;
      final eq = (l['equipment_present'] as num?)?.toDouble() ?? 0;
      final tc = tp + prev + eq;
      final bal = sv - tc;
      final isEq = l['line_type']?.toString() == 'equipment';
      final ret = isEq ? 0.0 : (tp + prev) * retainageRate / 100;
      final ttp = isEq ? 0.0 : (tp + prev) - ret;

      tSv += sv;
      tTp += tp;
      tPrev += prev;
      tEq += eq;
      tTc += tc;
      tBal += bal;
      tRet += ret;
      tTtp += ttp;

      tableRows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          ),
          children: [
            _cell(font, '${i + 1}'),
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
        ),
      );
    }

    tableRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: PdfColors.grey600, width: 1.5)),
        ),
        children: [
          _cell(fontBold, 'Totals', align: pw.TextAlign.center),
          _cell(fontBold, ''),
          _cell(fontBold, '\$${fmt.format(tSv)}', align: pw.TextAlign.right),
          _cell(fontBold, '\$${fmt.format(tTp)}', align: pw.TextAlign.right),
          _cell(fontBold, '\$${fmt.format(tPrev)}', align: pw.TextAlign.right),
          _cell(fontBold, '\$${fmt.format(tEq)}', align: pw.TextAlign.right),
          _cell(fontBold, '\$${fmt.format(tTc)}', align: pw.TextAlign.right),
          _cell(fontBold, '\$${fmt.format(tBal)}', align: pw.TextAlign.right),
          _cell(fontBold, '\$${fmt.format(tRet)}', align: pw.TextAlign.right),
          _cell(fontBold, '\$${fmt.format(tTtp)}', align: pw.TextAlign.right),
        ],
      ),
    );

    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(0.5),
        1: const pw.FlexColumnWidth(2.0),
        2: const pw.FlexColumnWidth(1.3),
        3: const pw.FlexColumnWidth(1.05),
        4: const pw.FlexColumnWidth(1.05),
        5: const pw.FlexColumnWidth(1.05),
        6: const pw.FlexColumnWidth(1.1),
        7: const pw.FlexColumnWidth(1.05),
        8: const pw.FlexColumnWidth(1.05),
        9: const pw.FlexColumnWidth(1.05),
      },
      children: tableRows,
    );
  }

  static List<pw.Widget> _machinerySupportPage(
    pw.Font font, pw.Font fontBold, NumberFormat fmt,
    List<Map<String, dynamic>> deductions,
    List<Map<String, dynamic>> lines,
    String projectTitle,
    String periodStart,
    String periodEnd,
  ) {
    final serviceNames = <String, String>{};
    for (final l in lines) {
      final qsId = l['quote_service_id']?.toString();
      if (qsId != null) serviceNames[qsId] = l['service_name']?.toString() ?? '';
    }

    final byService = <String, List<Map<String, dynamic>>>{};
    for (final d in deductions) {
      if (d['selected'] == false) continue;
      final qsId = d['quote_service_id']?.toString();
      if (qsId == null) continue;
      byService.putIfAbsent(qsId, () => []).add(d);
    }

    final widgets = <pw.Widget>[];

    widgets.add(pw.Text('EQUIPMENT RENT DEDUCTION DETAILS', style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColor.fromHex('#15803d'))));
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(pw.Text('Project: $projectTitle', style: pw.TextStyle(font: font, fontSize: 11)));
    widgets.add(pw.Text('Period: $periodStart — $periodEnd', style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey800)));
    widgets.add(pw.SizedBox(height: 20));

    double grandTotal = 0;

    for (final entry in byService.entries) {
      final svcName = serviceNames[entry.key] ?? 'Service';
      final svcDeductions = entry.value;

      widgets.add(pw.Text(svcName, style: pw.TextStyle(font: fontBold, fontSize: 12)));
      widgets.add(pw.SizedBox(height: 6));

      final tableRows = <pw.TableRow>[];
      tableRows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey600, width: 1)),
          ),
          children: [
            _hdr(fontBold, 'Code'),
            _hdr(fontBold, 'Machine'),
            _hdr(fontBold, 'Model'),
            _hdr(fontBold, 'Monthly\nRent'),
            _hdr(fontBold, 'Daily\nRate'),
            _hdr(fontBold, 'Days'),
            _hdr(fontBold, 'Deduction'),
          ],
        ),
      );

      double subtotal = 0;
      for (final d in svcDeductions) {
        final code = d['internal_code']?.toString() ?? '';
        final name = d['machine_name']?.toString() ?? '';
        final brand = d['brand_model']?.toString() ?? '';
        final monthly = (d['monthly_rent_cost'] as num?)?.toDouble() ?? 0;
        final daily = (d['daily_rental_rate'] as num?)?.toDouble() ?? 0;
        final days = (d['days_in_period'] as num?)?.toDouble() ?? 0;
        final amount = (d['deduction_amount'] as num?)?.toDouble() ?? 0;

        tableRows.add(
          pw.TableRow(
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            children: [
              _cell(font, code),
              _cell(font, name),
              _cell(font, brand),
              _cell(font, '\$${fmt.format(monthly)}', align: pw.TextAlign.right),
              _cell(font, '\$${fmt.format(daily)}', align: pw.TextAlign.right),
              _cell(font, days.toStringAsFixed(0), align: pw.TextAlign.right),
              _cell(font, '\$${fmt.format(amount)}', align: pw.TextAlign.right),
            ],
          ),
        );

        subtotal += amount;
      }

      tableRows.add(
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey500)),
          ),
          children: [
            _cell(fontBold, '', align: pw.TextAlign.right),
            _cell(fontBold, '', align: pw.TextAlign.right),
            _cell(fontBold, '', align: pw.TextAlign.right),
            _cell(fontBold, '', align: pw.TextAlign.right),
            _cell(fontBold, '', align: pw.TextAlign.right),
            _cell(fontBold, 'Subtotal:', align: pw.TextAlign.right),
            _cell(fontBold, '\$${fmt.format(subtotal)}', align: pw.TextAlign.right),
          ],
        ),
      );

      grandTotal += subtotal;

      widgets.add(pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(2),
          2: const pw.FlexColumnWidth(1.5),
          3: const pw.FlexColumnWidth(1.2),
          4: const pw.FlexColumnWidth(1),
          5: const pw.FlexColumnWidth(0.8),
          6: const pw.FlexColumnWidth(1.2),
        },
        children: tableRows,
      ));

      widgets.add(pw.SizedBox(height: 16));
    }

    widgets.add(pw.Divider(thickness: 2));
    widgets.add(pw.SizedBox(height: 8));
    widgets.add(
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 250,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL DEDUCTIONS:', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                pw.Text('\$${fmt.format(grandTotal)}', style: pw.TextStyle(font: fontBold, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );

    return widgets;
  }

  static pw.Widget _hdr(pw.Font font, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 7), textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _cell(pw.Font font, String text, {pw.TextAlign align = pw.TextAlign.left, PdfColor? textColor}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      alignment: align == pw.TextAlign.right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 8, color: textColor), textAlign: align),
    );
  }
}
