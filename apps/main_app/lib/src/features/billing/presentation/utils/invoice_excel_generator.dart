import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

class InvoiceExcelGenerator {
  static Uint8List generate({
    required Map<String, dynamic> invoice,
    required List<Map<String, dynamic>> lines,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel['Pay Application'];
    final fmt = NumberFormat('#,##0.00', 'en_US');

    sheet.setColumnWidth(0, 6);
    sheet.setColumnWidth(1, 40);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 14);
    sheet.setColumnWidth(4, 14);
    sheet.setColumnWidth(5, 14);
    sheet.setColumnWidth(6, 16);
    sheet.setColumnWidth(7, 16);
    sheet.setColumnWidth(8, 14);
    sheet.setColumnWidth(9, 16);

    int r = 0;
    _cell(sheet, r++, 0, 'GLOBAL GOLF CONSTRUCTION LLC', bold: true, fontSize: 14);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r - 1),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: r - 1),
    );

    _cell(sheet, r++, 0, 'PAY APPLICATION', bold: true, fontSize: 16);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r - 1),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: r - 1),
    );

    _cell(sheet, r++, 0, 'App No: ${invoice['invoice_number'] ?? ''}', bold: false, fontSize: 11);
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r - 1),
      CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: r - 1),
    );

    r++;

    final headers = [
      'ITEM NO.', 'DESCRIPTION OF WORK', 'SCHEDULED\nVALUE',
      'WORK COMPLETED\n(this period)', 'WORK COMPLETED\n(previous)',
      'EQUIPMENT\nPRESENT', 'TOTAL\nMATERIALS', 'BALANCE TO\nFINISH',
      'RETAINAGE\n5%', 'TOTAL THIS\nPERIOD',
    ];
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = CellStyle(bold: true, textWrapping: TextWrapping.WrapText);
    }
    r++;

    double totalSv = 0, totalTp = 0, totalPrev = 0, totalEq = 0;
    double totalTc = 0, totalBal = 0, totalRet = 0, totalTtp = 0;

    for (int i = 0; i < lines.length; i++) {
      final l = lines[i];
      final sv = (l['scheduled_value'] as num?)?.toDouble() ?? 0;
      final tp = (l['this_period_amount'] as num?)?.toDouble() ?? 0;
      final prev = (l['previous_completed'] as num?)?.toDouble() ?? 0;
      final eq = (l['equipment_present'] as num?)?.toDouble() ?? 0;
      final tc = tp + prev + eq;
      final bal = sv - tc;
      final ret = l['line_type'] == 'equipment' ? 0.0 : (tp + prev) * 0.05;
      final ttp = l['line_type'] == 'equipment' ? 0.0 : (tp + prev) - ret;

      totalSv += sv;
      totalTp += tp;
      totalPrev += prev;
      totalEq += eq;
      totalTc += tc;
      totalBal += bal;
      totalRet += ret;
      totalTtp += ttp;

      _cell(sheet, r, 0, '${i + 1}');
      _cell(sheet, r, 1, l['service_name'] ?? '');
      _cell(sheet, r, 2, '\$${fmt.format(sv)}');
      _cell(sheet, r, 3, '\$${fmt.format(tp)}');
      _cell(sheet, r, 4, '\$${fmt.format(prev)}');
      _cell(sheet, r, 5, '\$${fmt.format(eq)}');
      _cell(sheet, r, 6, '\$${fmt.format(tc)}');
      _cell(sheet, r, 7, '\$${fmt.format(bal)}');
      _cell(sheet, r, 8, '\$${fmt.format(ret)}');
      _cell(sheet, r, 9, '\$${fmt.format(ttp)}');
      r++;
    }

    _cell(sheet, r, 0, 'TOTALS', bold: true);
    _cell(sheet, r, 2, '\$${fmt.format(totalSv)}', bold: true);
    _cell(sheet, r, 3, '\$${fmt.format(totalTp)}', bold: true);
    _cell(sheet, r, 4, '\$${fmt.format(totalPrev)}', bold: true);
    _cell(sheet, r, 5, '\$${fmt.format(totalEq)}', bold: true);
    _cell(sheet, r, 6, '\$${fmt.format(totalTc)}', bold: true);
    _cell(sheet, r, 7, '\$${fmt.format(totalBal)}', bold: true);
    _cell(sheet, r, 8, '\$${fmt.format(totalRet)}', bold: true);
    _cell(sheet, r, 9, '\$${fmt.format(totalTtp)}', bold: true);

    final saved = excel.save();
    if (saved == null) return Uint8List(0);
    return Uint8List.fromList(saved);
  }

  static void _cell(Sheet sheet, int row, int col, String value, {bool bold = false, double fontSize = 10}) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    cell.value = TextCellValue(value);
    if (bold || fontSize != 10) {
      cell.cellStyle = CellStyle(bold: bold, fontSize: fontSize != 10 ? fontSize.toInt() : null);
    }
  }
}
