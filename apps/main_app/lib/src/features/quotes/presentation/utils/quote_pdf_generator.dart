import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class QuotePdfGenerator {
  static Future<Uint8List> generate({
    required Map<String, dynamic> quote,
    required List<Map<String, dynamic>> services,
    required Map<String, Map<String, double>> serviceTotals,
    required double grandTotal,
  }) async {
    final pdf = pw.Document();
    final fmt = NumberFormat('#,##0.00', 'en_US');

    // Attempt to load logo from assets
    pw.MemoryImage? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/images/global_golf_logo.png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      // If logo not found, continue without it
    }

    // Attempt to load fonts if needed, else use default
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    final String title = quote['title'] ?? 'ESTIMATE';
    final String quoteId = quote['id'] != null ? quote['id'].toString().substring(0, 8).toUpperCase() : '0000';
    final String date = quote['created_at'] != null 
        ? DateFormat('MM/dd/yyyy').format(DateTime.parse(quote['created_at']).toLocal())
        : DateFormat('MM/dd/yyyy').format(DateTime.now());

    // Client info
    final String clientName = quote['client_name'] ?? 'Client Name';
    final String clientAddress = quote['client_address'] ?? '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        height: 50,
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
                    pw.Text('ESTIMATE', style: pw.TextStyle(font: fontBold, fontSize: 32, color: PdfColor.fromHex('#15803d'))),
                    pw.SizedBox(height: 12),
                    pw.Text('Estimate no.: $quoteId', style: pw.TextStyle(font: font, fontSize: 11)),
                    pw.SizedBox(height: 2),
                    pw.Text('Estimate date: $date', style: pw.TextStyle(font: font, fontSize: 11)),
                  ],
                )
              ],
            ),
            pw.SizedBox(height: 20),
            
            // Bill To
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Bill to', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                pw.SizedBox(height: 4),
                pw.Text(clientName, style: pw.TextStyle(font: fontBold, fontSize: 10)),
                if (clientAddress.isNotEmpty)
                  pw.Text(clientAddress, style: pw.TextStyle(font: font, fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 24),

            // Table Header
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400, width: 1)),
                  ),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('#', style: pw.TextStyle(font: fontBold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('Product or service / Description', style: pw.TextStyle(font: fontBold, fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('Qty / Unit', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.center)),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('Rate', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.right)),
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text('Amount', style: pw.TextStyle(font: fontBold, fontSize: 10), textAlign: pw.TextAlign.right)),
                  ],
                ),
                // Table Rows
                for (int i = 0; i < services.length; i++) ...[
                  () {
                    final svc = services[i];
                    final svcId = svc['id'] as String;
                    final totals = serviceTotals[svcId]!;
                    final name = svc['name'] ?? 'Service ${i + 1}';
                    final qty = (svc['quantity'] as num?)?.toDouble() ?? 0;
                    final unit = (svc['unit_of_measure'] ?? svc['unit'] ?? '').toString();
                    
                    final rate = totals['unitP'] ?? 0.0;
                    final amount = totals['sale'] ?? 0.0;

                    return pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                      ),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text('${i + 1}.', style: pw.TextStyle(font: font, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text(name, style: pw.TextStyle(font: font, fontSize: 10))),
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text('${qty.toStringAsFixed(0)} $unit', style: pw.TextStyle(font: font, fontSize: 10), textAlign: pw.TextAlign.center)),
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text('\$${fmt.format(rate)}', style: pw.TextStyle(font: font, fontSize: 10), textAlign: pw.TextAlign.right)),
                        pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 6), child: pw.Text('\$${fmt.format(amount)}', style: pw.TextStyle(font: font, fontSize: 10), textAlign: pw.TextAlign.right)),
                      ],
                    );
                  }()
                ],
              ],
            ),
            pw.SizedBox(height: 16),

            // Total
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 200,
                  padding: const pw.EdgeInsets.only(top: 8),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfColors.black, width: 2)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                      pw.Text('\$${fmt.format(grandTotal)}', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 40),

            // Footer / Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Accepted date: _________________', style: pw.TextStyle(font: font, fontSize: 10)),
                  ]
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Accepted by: _________________', style: pw.TextStyle(font: font, fontSize: 10)),
                  ]
                ),
              ]
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
