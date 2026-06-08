import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

class PayrollExcelGenerator {
  static Uint8List generate({
    required String projectTitle,
    required String periodName,
    required String startDate,
    required String endDate,
    required List<Map<String, dynamic>> entries,
    required num totalReg,
    required num totalOT,
    required num totalCost,
    required num totalWorkers,
  }) {
    final excel = Excel.createExcel();
    final sheet = excel['Labor Cost'];
    final fmt = NumberFormat('#,##0.00', 'en_US');
    final hrsFmt = NumberFormat('#,##0.0', 'en_US');

    sheet.setColumnWidth(0, 25);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 12);
    sheet.setColumnWidth(3, 12);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 14);
    sheet.setColumnWidth(6, 16);

    int r = 0;
    _cell(sheet, r++, 0, 'GLOBAL GOLF CONSTRUCTION LLC', bold: true, fontSize: 14);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r - 1), CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: r - 1));

    _cell(sheet, r++, 0, 'LABOR COST REPORT', bold: true, fontSize: 16);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r - 1), CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: r - 1));

    _cell(sheet, r++, 0, periodName, bold: true, fontSize: 11);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r - 1), CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: r - 1));

    _cell(sheet, r++, 0, '$startDate — $endDate', bold: false, fontSize: 10);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r - 1), CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: r - 1));

    _cell(sheet, r++, 0, projectTitle, bold: true, fontSize: 10);
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r - 1), CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: r - 1));

    r++; // blank

    // Summary
    _cell(sheet, r, 0, 'Workers', bold: true);
    _cell(sheet, r, 1, '$totalWorkers');
    _cell(sheet, r, 2, 'Reg Hrs', bold: true);
    _cell(sheet, r, 3, hrsFmt.format(totalReg));
    _cell(sheet, r, 4, 'OT Hrs', bold: true);
    _cell(sheet, r, 5, hrsFmt.format(totalOT));
    _cell(sheet, r, 6, 'Total Cost', bold: true);
    r++;

    _cell(sheet, r, 4, '');
    _cell(sheet, r, 6, '\$${fmt.format(totalCost)}', bold: true);
    r++;

    r++; // blank

    // Header
    final headers = ['WORKER', 'ROLE', 'RATE', 'REG HRS', 'OT HRS', 'TOTAL HRS', 'TOTAL COST'];
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = CellStyle(bold: true);
    }
    r++;

    // Data
    for (final e in entries) {
      final reg = (e['regular_hours'] ?? 0).toDouble();
      final ot = (e['overtime_hours'] ?? 0).toDouble();
      final totalHrs = reg + ot;
      final totalPay = (e['total_pay'] ?? 0).toDouble();

      _cell(sheet, r, 0, e['full_name'] ?? 'N/A');
      _cell(sheet, r, 1, (e['role_name'] ?? '').toString().toUpperCase());
      _cell(sheet, r, 2, '\$${fmt.format((e['hourly_rate'] ?? 0).toDouble())}');
      _cell(sheet, r, 3, hrsFmt.format(reg));
      _cell(sheet, r, 4, hrsFmt.format(ot));
      _cell(sheet, r, 5, hrsFmt.format(totalHrs));
      _cell(sheet, r, 6, '\$${fmt.format(totalPay)}');
      r++;
    }

    // Grand total
    _cell(sheet, r, 0, 'TOTAL', bold: true);
    _cell(sheet, r, 3, hrsFmt.format(totalReg), bold: true);
    _cell(sheet, r, 4, hrsFmt.format(totalOT), bold: true);
    _cell(sheet, r, 5, hrsFmt.format(totalReg + totalOT), bold: true);
    _cell(sheet, r, 6, '\$${fmt.format(totalCost)}', bold: true);

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
