import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class ChangeOrderPdfGenerator {
  static Future<Uint8List> generate({
    required Map<String, dynamic> changeOrder,
    required List<Map<String, dynamic>> details,
    required String projectTitle,
    required String clientName,
    required String projectAddress,
    String? approvedByName,
    String? approvedByTitle,
    List<Map<String, dynamic>> disruptionRecords = const [],
  }) async {
    final pdf = pw.Document();
    final fmt = NumberFormat('#,##0.00', 'en_US');

    pw.MemoryImage? logoImage;
    try {
      final ByteData data = await rootBundle.load(
        'assets/images/global_golf_logo.png',
      );
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    final coNum = changeOrder['co_number'] ?? '';
    final title = changeOrder['title'] ?? '';
    final description = changeOrder['description'] ?? '';
    final coType = changeOrder['co_type']?.toString() ?? 'scope_change';
    final date = changeOrder['executed_date'] != null
        ? DateFormat(
            'MM/dd/yyyy',
          ).format(DateTime.parse(changeOrder['executed_date']).toLocal())
        : DateFormat('MM/dd/yyyy').format(DateTime.now());
    final orig =
        (changeOrder['original_contract_amount'] as num?)?.toDouble() ?? 0;
    final adj = (changeOrder['adjustment_amount'] as num?)?.toDouble() ?? 0;
    final newContract =
        (changeOrder['new_contract_amount'] as num?)?.toDouble() ?? 0;
    final schedDays =
        (changeOrder['schedule_days_change'] as num?)?.toInt() ?? 0;
    final status = (changeOrder['status'] as String?) ?? 'draft';
    final isDisruption = coType == 'disruption';

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
                    pw.Text(
                      'Global Golf Construction LLC',
                      style: pw.TextStyle(font: fontBold, fontSize: 14),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '31330 Sellers Terrace Dr',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.Text(
                      'Hockley, TX 77447-2328',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(
                          'CHANGE ORDER',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 26,
                            color: PdfColor.fromHex('#15803d'),
                          ),
                        ),
                        if (isDisruption)
                          pw.Container(
                            margin: const pw.EdgeInsets.only(left: 8),
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromHex('#8B5CF626'),
                              borderRadius: pw.BorderRadius.all(
                                pw.Radius.circular(3),
                              ),
                            ),
                            child: pw.Text(
                              'STANDBY',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 10,
                                color: PdfColor.fromHex('#8B5CF6'),
                              ),
                            ),
                          ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'CO No.: $coNum',
                      style: pw.TextStyle(font: font, fontSize: 11),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Date: $date',
                      style: pw.TextStyle(font: font, fontSize: 11),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Status: ${status.toUpperCase()}',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            pw.Text(
              'PROJECT',
              style: pw.TextStyle(font: fontBold, fontSize: 12),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              projectTitle,
              style: pw.TextStyle(font: fontBold, fontSize: 11),
            ),
            if (projectAddress.isNotEmpty)
              pw.Text(
                projectAddress,
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Client: $clientName',
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
            pw.SizedBox(height: 16),

            pw.Text(
              'TITLE: $title',
              style: pw.TextStyle(font: fontBold, fontSize: 12),
            ),
            pw.SizedBox(height: 12),

            pw.Text(
              'DESCRIPTION OF CHANGE:',
              style: pw.TextStyle(font: fontBold, fontSize: 11),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              description.isNotEmpty ? description : 'See attached details.',
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
            pw.SizedBox(height: 16),

            if (isDisruption && disruptionRecords.isNotEmpty) ...[
              pw.Text(
                'DISRUPTION DETAILS:',
                style: pw.TextStyle(font: fontBold, fontSize: 11),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Reason: ${disruptionRecords.first['disruption_reason'] ?? disruptionRecords.first['disruption_type'] ?? ''}',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.Text(
                'Period: ${disruptionRecords.first['start_date'] ?? ''} to ${disruptionRecords.first['end_date'] ?? ''}',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.SizedBox(height: 16),
            ],

            if (details.isNotEmpty) ...[
              pw.Text(
                isDisruption ? 'STANDBY LINE ITEMS:' : 'DETAILS OF CHANGE:',
                style: pw.TextStyle(font: fontBold, fontSize: 11),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.5),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(isDisruption ? 1 : 1.2),
                  4: pw.FlexColumnWidth(isDisruption ? 1 : 1.2),
                  5: const pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey600,
                          width: 1,
                        ),
                      ),
                    ),
                    children: [
                      _hdr(fontBold, '#'),
                      _hdr(fontBold, 'Item'),
                      _hdr(fontBold, 'Type'),
                      _hdr(fontBold, isDisruption ? 'Hrs/Lost' : 'Qty Change'),
                      _hdr(fontBold, isDisruption ? 'Rate' : 'Unit Price'),
                      _hdr(fontBold, 'Total'),
                    ],
                  ),
                  ...details.asMap().entries.map((e) {
                    final i = e.key + 1;
                    final d = e.value;
                    final lt = d['line_type'] as String?;
                    final qty = (d['quantity_change'] as num?)?.toDouble() ?? 0;
                    final up = (d['unit_price'] as num?)?.toDouble() ?? 0;

                    double qtyDisplay;
                    double rate;
                    double total;
                    if (lt == 'standby_machinery' || lt == 'standby_labor') {
                      qtyDisplay =
                          (d['standby_hours'] as num?)?.toDouble() ?? 0;
                      rate = (d['standby_rate'] as num?)?.toDouble() ?? 0;
                      total = qtyDisplay * rate;
                    } else if (lt == 'standby_material') {
                      qtyDisplay =
                          (d['quantity_lost'] as num?)?.toDouble() ?? 0;
                      rate =
                          (d['replacement_unit_cost'] as num?)?.toDouble() ?? 0;
                      total = qtyDisplay * rate;
                    } else {
                      qtyDisplay = qty;
                      rate = up;
                      total = qty * up;
                    }

                    return pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(
                            color: PdfColors.grey300,
                            width: 0.5,
                          ),
                        ),
                      ),
                      children: [
                        _cell(font, '$i'),
                        _cell(font, d['service_name'] ?? ''),
                        _cell(font, lt?.replaceAll('_', ' ') ?? ''),
                        _cell(
                          font,
                          qtyDisplay.toString(),
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          font,
                          '\$${fmt.format(rate)}',
                          align: pw.TextAlign.right,
                        ),
                        _cell(
                          font,
                          '\$${fmt.format(total)}',
                          align: pw.TextAlign.right,
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 16),
            ],

            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'CHANGE ORDER SUMMARY',
                    style: pw.TextStyle(font: fontBold, fontSize: 12),
                  ),
                  pw.SizedBox(height: 8),
                  _summaryLine(
                    font,
                    fontBold,
                    'Original Contract:',
                    '\$${fmt.format(orig)}',
                  ),
                  _summaryLine(
                    font,
                    fontBold,
                    'Net Change by this CO:',
                    '\$${fmt.format(adj)}',
                  ),
                  pw.Divider(thickness: 1),
                  _summaryLine(
                    font,
                    fontBold,
                    'NEW CONTRACT VALUE:',
                    '\$${fmt.format(newContract)}',
                    bold: true,
                  ),
                  pw.SizedBox(height: 8),
                  if (isDisruption) ...[
                    if (disruptionRecords.isNotEmpty) ...[
                      _summaryLine(
                        font,
                        fontBold,
                        'Disruption Reason:',
                        disruptionRecords.first['disruption_reason']
                                ?.toString() ??
                            '',
                      ),
                      _summaryLine(
                        font,
                        fontBold,
                        'Period:',
                        '${disruptionRecords.first['start_date'] ?? ''} to ${disruptionRecords.first['end_date'] ?? ''}',
                      ),
                    ],
                  ] else
                    _summaryLine(
                      font,
                      fontBold,
                      'Schedule days change:',
                      schedDays >= 0 ? '+$schedDays days' : '$schedDays days',
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 40),

            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'APPROVED BY SUBCONTRACTOR:',
                      style: pw.TextStyle(font: fontBold, fontSize: 10),
                    ),
                    pw.SizedBox(height: 24),
                    pw.Text(
                      'Signature: _________________',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Date: _________________',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'APPROVED BY CONTRACTOR:',
                      style: pw.TextStyle(font: fontBold, fontSize: 10),
                    ),
                    pw.SizedBox(height: 24),
                    pw.Text(
                      'Signature: _________________',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Date: _________________',
                      style: pw.TextStyle(font: font, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            pw.Text(
              'This Change Order is not valid until signed by all parties: Architect, Contractor, Subcontractor, and Owner.',
              style: pw.TextStyle(
                font: font,
                fontSize: 8,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _hdr(pw.Font font, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 8),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _cell(
    pw.Font font,
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 9),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _summaryLine(
    pw.Font font,
    pw.Font fontBold,
    String label,
    String value, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: bold ? fontBold : font, fontSize: 10),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: bold ? fontBold : font, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
