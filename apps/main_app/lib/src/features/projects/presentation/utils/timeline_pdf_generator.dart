import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class TimelinePdfGenerator {
  static const _leftPanelWidth = 170.0;
  static const _dayWidthPdf = 7.0;
  static const _margin = 24.0;

  static final _machineryColors = [PdfColor.fromHex('#11D411'), PdfColor.fromHex('#10B981')];
  static final _laborColors = [PdfColor.fromHex('#3B82F6'), PdfColor.fromHex('#3B82F6')];
  static final _instrumentColors = [PdfColor.fromHex('#8B5CF6'), PdfColor.fromHex('#8B5CF6')];
  static final _extraColors = [PdfColor.fromHex('#F59E0B'), PdfColor.fromHex('#F59E0B')];
  static final _sundayBg = PdfColor.fromHex('#FEF2F2');
  static final _sundayText = PdfColor.fromHex('#B91C1C');
  static final _gridColor = PdfColor.fromHex('#E2E8F0');
  static final _sundayGridBg = PdfColor.fromHex('#FEF2F2');
  static final _headerBg = PdfColor.fromHex('#0F172A');
  static final _headerBorder = PdfColor.fromHex('#1E293B');
  static final _headerText = PdfColor.fromHex('#94A3B8');
  static final _monthBg = PdfColor.fromHex('#1E293B');
  static final _greenTitle = PdfColor.fromHex('#15803d');
  static final _ghostColor = PdfColor.fromHex('#64748B');
  static final _currencyFmt = NumberFormat('#,##0', 'en_US');

  static Future<Uint8List> generate({
    required String projectTitle,
    required String projectId,
    required List<Map<String, dynamic>> items,
    required DateTime minVal,
    required int totalDays,
    required Map<String, bool> expandedServices,
    required String selectedServiceFilter,
    required Map<String, DateTime> serviceOriginalMax,
    required Map<String, double> serviceDaysSaved,
    DateTime? compressedMaxDate,
    double baselineOriginalTotalDays = 0,
    double baselineTotalDaysSaved = 0,
    double baselineDeviationCost = 0,
    double baselineTotalCompressionSavings = 0,
    int plannedCount = 0,
    int extraCount = 0,
  }) async {
    final pdf = pw.Document();
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();
    final dateFmt = DateFormat('MMM dd, yyyy');

    pw.MemoryImage? logoImage;
    try {
      final ByteData data = await rootBundle.load('assets/images/global_golf_logo.png');
      logoImage = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    final ganttWidth = PdfPageFormat.a4.landscape.width - _margin * 2 - _leftPanelWidth;
    final daysPerPage = _maxInt(1, (ganttWidth / _dayWidthPdf).floor());
    final totalHorizontalPages = (totalDays / daysPerPage).ceil();

    final grouped = _groupByService(items, expandedServices, selectedServiceFilter, serviceOriginalMax, serviceDaysSaved);
    final maxVal = minVal.add(Duration(days: totalDays - 1));

    final pages = <List<pw.Widget>>[];
    for (int hPage = 0; hPage < totalHorizontalPages; hPage++) {
      final dayStart = hPage * daysPerPage;
      final dayEnd = _minInt(dayStart + daysPerPage, totalDays);
      final sliceDays = dayEnd - dayStart;

      final pageWidgets = <pw.Widget>[];

      pageWidgets.add(_buildHeader(
        logoImage, projectTitle, font, fontBold, dateFmt,
        minVal, maxVal, totalDays, items.length, hPage, totalHorizontalPages,
        baselineOriginalTotalDays, baselineTotalDaysSaved,
        baselineDeviationCost, baselineTotalCompressionSavings,
        plannedCount, extraCount, compressedMaxDate, maxVal,
      ));
      pageWidgets.add(pw.SizedBox(height: 8));
      pageWidgets.add(_buildTimelineMonthRow(minVal, dayStart, sliceDays, fontBold));
      pageWidgets.add(_buildTimelineDayRow(minVal, dayStart, sliceDays, fontBold));

      for (final svc in grouped) {
        pageWidgets.add(_buildServiceRow(svc, fontBold, font, minVal, dayStart, sliceDays));
        for (final item in svc['items'] as List) {
          pageWidgets.add(_buildResourceRow(item as Map<String, dynamic>, font, fontBold, minVal, dayStart, sliceDays));
        }
      }

      pages.add(pageWidgets);
    }

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: pw.EdgeInsets.all(_margin),
      footer: (context) {
        return pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${context.pageNumber}',
            style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600),
          ),
        );
      },
      build: (pw.Context context) {
        final allWidgets = <pw.Widget>[];
        for (final page in pages) {
          allWidgets.addAll(page);
          allWidgets.add(pw.SizedBox(height: 16));
        }
        return allWidgets;
      },
    ));

    return pdf.save();
  }

  static int _maxInt(int a, int b) => a > b ? a : b;
  static int _minInt(int a, int b) => a < b ? a : b;

  static List<Map<String, dynamic>> _groupByService(
    List<Map<String, dynamic>> items,
    Map<String, bool> expandedServices,
    String selectedServiceFilter,
    Map<String, DateTime> serviceOriginalMax,
    Map<String, double> serviceDaysSaved,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      final svc = (item['service'] ?? 'No Service').toString();
      if (selectedServiceFilter != 'All Services' && svc != selectedServiceFilter) continue;
      grouped.putIfAbsent(svc, () => []);
      grouped[svc]!.add(item);
    }
    return grouped.entries.map((e) {
      final sName = e.key;
      final sItems = e.value;

      DateTime? sMin;
      DateTime? sMax;
      for (final item in sItems) {
        final s = item['plannedStart'] as DateTime?;
        final ed = item['plannedEnd'] as DateTime?;
        if (s != null && (sMin == null || s.isBefore(sMin))) sMin = s;
        if (ed != null && (sMax == null || ed.isAfter(sMax))) sMax = ed;
      }

      final saved = serviceDaysSaved[sName] ?? 0.0;
      final origSMax = serviceOriginalMax[sName];
      final hasCompression = sMax != null && saved > 0 && sMin != null;

      Map<String, dynamic>? compressionInfo;
      if (hasCompression && sMax != null && sMin != null) {
        final originalEnd = origSMax ?? sMax;
        compressionInfo = {
          'savedDays': saved,
          'originalSMax': originalEnd,
          'sMin': sMin,
          'sMax': sMax,
          'originalSDuration': originalEnd.difference(sMin).inDays + 1,
        };
      }

      return {
        'name': sName,
        'items': sItems,
        'expanded': expandedServices[sName] ?? true,
        'compressionInfo': compressionInfo,
      };
    }).toList();
  }

  static pw.Widget _buildHeader(
    pw.MemoryImage? logo,
    String title,
    pw.Font fontBold,
    pw.Font font,
    DateFormat dateFmt,
    DateTime minVal,
    DateTime maxVal,
    int totalDays,
    int resourceCount,
    int pageNum,
    int totalPages,
    double baselineOriginalTotalDays,
    double baselineTotalDaysSaved,
    double baselineDeviationCost,
    double baselineTotalCompressionSavings,
    int plannedCount,
    int extraCount,
    DateTime? compressedMaxDate,
    DateTime viewMaxVal,
  ) {
    final int originalDays = baselineOriginalTotalDays > 0 ? baselineOriginalTotalDays.toInt() : totalDays;
    final int savedDays = baselineTotalDaysSaved > 0 ? baselineTotalDaysSaved.toInt() : 0;
    final int compressedWorkDays = originalDays - savedDays;
    final double roi = baselineDeviationCost > 0 && baselineTotalCompressionSavings > 0
        ? (baselineTotalCompressionSavings / baselineDeviationCost) * 100
        : 0.0;
    final bool hasBaseline = baselineTotalDaysSaved > 0 || baselineTotalCompressionSavings > 0;
    final DateFormat dateShort = DateFormat('MMM dd');

    final dateDisplay = savedDays > 0 && compressedMaxDate != null && compressedMaxDate.isBefore(maxVal)
        ? '${dateShort.format(minVal)} - ${dateShort.format(compressedMaxDate)}  <- ${dateShort.format(maxVal)}'
        : '${dateShort.format(minVal)} - ${dateShort.format(maxVal)}';

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null)
          pw.Container(
            height: 48,
            margin: const pw.EdgeInsets.only(right: 16),
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 13, color: _greenTitle)),
              pw.SizedBox(height: 2),
              pw.Text(
                'Complete Resource Timeline',
                style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '$plannedCount${extraCount > 0 ? " +$extraCount extra" : ""} resources  |  $dateDisplay  |  $totalDays days',
                style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey700),
              ),
              if (hasBaseline) ...[
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    if (savedDays > 0)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#F0FDF4'),
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColor.fromHex('#BBF7D0'), width: 0.5),
                        ),
                        child: pw.Text(
                          '${originalDays}d -> ${compressedWorkDays}d  ($savedDays saved)',
                          style: pw.TextStyle(font: fontBold, fontSize: 7, color: _greenTitle),
                        ),
                      ),
                    if (savedDays > 0 && baselineTotalCompressionSavings > 0)
                      pw.SizedBox(width: 6),
                    if (baselineTotalCompressionSavings > 0)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#ECFEFF'),
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColor.fromHex('#A5F3FC'), width: 0.5),
                        ),
                        child: pw.Row(
                          children: [
                            pw.Text(
                              '\$${_currencyFmt.format(baselineTotalCompressionSavings)} saved',
                              style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfColor.fromHex('#0891B2')),
                            ),
                            if (roi > 0) ...[
                              pw.Text(
                                '  |  ROI ${roi.toStringAsFixed(1)}%',
                                style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfColor.fromHex('#0891B2')),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              totalPages > 1 ? 'Page ${pageNum + 1}/$totalPages' : '',
              style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey500),
            ),
            pw.SizedBox(height: 12),
            _buildLegend(font),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildLegend(pw.Font font) {
    return pw.Row(
      children: [
        _legendItem('Machinery', _machineryColors[0], font),
        pw.SizedBox(width: 8),
        _legendItem('Labor', _laborColors[0], font),
        pw.SizedBox(width: 8),
        _legendItem('Instruments', _instrumentColors[0], font),
        pw.SizedBox(width: 8),
        _legendItem('Extra', _extraColors[0], font),
      ],
    );
  }

  static pw.Widget _legendItem(String label, PdfColor color, pw.Font font) {
    return pw.Row(
      children: [
        pw.Container(width: 8, height: 8, decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(2))),
        pw.SizedBox(width: 3),
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 6, color: PdfColors.grey700)),
      ],
    );
  }

  static pw.Widget _buildTimelineMonthRow(DateTime minVal, int dayStart, int sliceDays, pw.Font fontBold) {
    final monthHeaders = <pw.Widget>[];
    final headerWidth = sliceDays * _dayWidthPdf;

    int currentMonthDays = 0;
    String? currentMonthStr;

    for (int i = 0; i < sliceDays; i++) {
      final day = minVal.add(Duration(days: dayStart + i));
      final monthStr = DateFormat('MMM yyyy').format(day);

      if (i == 0) {
        currentMonthStr = monthStr;
        currentMonthDays = 1;
      } else if (monthStr == currentMonthStr) {
        currentMonthDays++;
      } else {
        monthHeaders.add(
          pw.Container(
            width: currentMonthDays * _dayWidthPdf,
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: _monthBg,
              border: pw.Border(right: pw.BorderSide(color: _headerBorder, width: 0.5)),
            ),
            child: pw.Text(currentMonthStr!, style: pw.TextStyle(font: fontBold, fontSize: 6, color: PdfColors.white)),
          ),
        );
        currentMonthStr = monthStr;
        currentMonthDays = 1;
      }
    }
    if (currentMonthStr != null) {
      monthHeaders.add(
        pw.Container(
          width: currentMonthDays * _dayWidthPdf,
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(color: _monthBg),
          child: pw.Text(currentMonthStr, style: pw.TextStyle(font: fontBold, fontSize: 6, color: PdfColors.white)),
        ),
      );
    }

    return pw.Row(
      children: [
        pw.Container(
          width: _leftPanelWidth,
          padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          color: _headerBg,
          child: pw.Text('SERVICES & RESOURCES', style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfColors.white)),
        ),
        pw.Container(width: headerWidth, child: pw.Row(children: monthHeaders)),
      ],
    );
  }

  static pw.Widget _buildTimelineDayRow(DateTime minVal, int dayStart, int sliceDays, pw.Font fontBold) {
    final dayHeaders = <pw.Widget>[];
    for (int i = 0; i < sliceDays; i++) {
      final day = minVal.add(Duration(days: dayStart + i));
      final isSunday = day.weekday == DateTime.sunday;
      dayHeaders.add(
        pw.Container(
          width: _dayWidthPdf,
          padding: const pw.EdgeInsets.symmetric(vertical: 1),
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: isSunday ? _sundayBg : _headerBg,
            border: pw.Border(right: pw.BorderSide(color: _headerBorder, width: 0.5)),
          ),
          child: pw.Text(
            day.day.toString(),
            style: pw.TextStyle(font: fontBold, fontSize: 5, color: isSunday ? _sundayText : _headerText),
          ),
        ),
      );
    }
    return pw.Row(
      children: [
        pw.SizedBox(width: _leftPanelWidth),
        pw.Row(children: dayHeaders),
      ],
    );
  }

  static pw.Widget _buildServiceRow(Map<String, dynamic> svc, pw.Font fontBold, pw.Font font, DateTime minVal, int dayStart, int sliceDays) {
    final name = svc['name'] as String;
    final serviceItems = svc['items'] as List;
    final isExpanded = svc['expanded'] as bool? ?? true;
    final compressionInfo = svc['compressionInfo'] as Map<String, dynamic>?;

    DateTime? svcStart;
    DateTime? svcEnd;
    for (final item in serviceItems) {
      final s = item['plannedStart'] as DateTime?;
      final e = item['plannedEnd'] as DateTime?;
      if (s != null && (svcStart == null || s.isBefore(svcStart))) svcStart = s;
      if (e != null && (svcEnd == null || e.isAfter(svcEnd))) svcEnd = e;
    }

    final rowHeight = 20.0;
    final stackChildren = <pw.Widget>[_buildGrid(sliceDays, minVal, dayStart)];

    if (svcStart != null && svcEnd != null) {
      final barStart = _dayOffset(svcStart, minVal, dayStart);
      final barWidth = _clampedBarWidth(svcStart, svcEnd, minVal, dayStart, sliceDays);
      stackChildren.add(
        pw.Positioned(
          left: barStart * _dayWidthPdf,
          top: 4,
          child: pw.Container(
            width: barWidth * _dayWidthPdf,
            height: 12,
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#334155'),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              '${svcEnd.difference(svcStart).inDays + 1}d',
              style: pw.TextStyle(font: fontBold, fontSize: 6, color: PdfColors.white),
            ),
          ),
        ),
      );
    }

    // Ghost bar for compressed services
    if (compressionInfo != null && svcStart != null && svcEnd != null) {
      final originalEnd = compressionInfo['originalSMax'] as DateTime;
      if (originalEnd.isAfter(svcEnd)) {
        final ghostStart = _dayOffset(svcEnd, minVal, dayStart);
        final ghostWidth = _clampedBarWidth(svcEnd, originalEnd, minVal, dayStart, sliceDays);
        final savedDays = (compressionInfo['savedDays'] as num?)?.toDouble() ?? 0;
        if (ghostWidth > 0) {
          stackChildren.add(
            pw.Positioned(
              left: ghostStart * _dayWidthPdf,
              top: 4,
              child: pw.Container(
                width: ghostWidth * _dayWidthPdf,
                height: 12,
                decoration: pw.BoxDecoration(
                  color: _ghostColor.withAlpha(0.12),
                  borderRadius: const pw.BorderRadius.only(
                    topRight: pw.Radius.circular(3),
                    bottomRight: pw.Radius.circular(3),
                  ),
                ),
                alignment: pw.Alignment.center,
                child: ghostWidth * _dayWidthPdf > 18
                    ? pw.Text(
                        '-${savedDays.toStringAsFixed(0)}d',
                        style: pw.TextStyle(font: font, fontSize: 5, color: PdfColor.fromHex('#A8A29E')),
                      )
                    : null,
              ),
            ),
          );
        }
      }
    }

    return pw.Container(
      height: rowHeight,
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8FAFC'),
        border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#F1F5F9'), width: 0.5)),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: _leftPanelWidth,
            padding: const pw.EdgeInsets.symmetric(horizontal: 4),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              '${isExpanded ? "v" : ">"} $name',
              style: pw.TextStyle(font: fontBold, fontSize: 7, color: PdfColors.grey900),
            ),
          ),
          pw.Expanded(
            child: pw.Stack(children: stackChildren),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildResourceRow(Map<String, dynamic> item, pw.Font font, pw.Font fontBold, DateTime minVal, int dayStart, int sliceDays) {
    final name = (item['name'] ?? '').toString();
    final type = (item['type'] ?? '').toString();
    final isExtra = item['isUnplanned'] == true;
    final plannedStart = item['plannedStart'] as DateTime?;
    final plannedEnd = item['plannedEnd'] as DateTime?;
    final originalPlannedEnd = item['originalPlannedEnd'] as DateTime?;

    List<PdfColor> barColors;
    switch (type) {
      case 'machinery':
        barColors = _machineryColors;
        break;
      case 'labor':
        barColors = _laborColors;
        break;
      case 'instrument':
        barColors = _instrumentColors;
        break;
      default:
        barColors = _machineryColors;
    }
    if (isExtra) barColors = _extraColors;

    final stackChildren = <pw.Widget>[_buildGrid(sliceDays, minVal, dayStart)];

    if (plannedStart != null && plannedEnd != null) {
      final barStart = _dayOffset(plannedStart, minVal, dayStart);
      final barWidth = _clampedBarWidth(plannedStart, plannedEnd, minVal, dayStart, sliceDays);
      final barDuration = plannedEnd.difference(plannedStart).inDays + 1;

      if (barWidth > 0) {
        stackChildren.add(
          pw.Positioned(
            left: barStart * _dayWidthPdf,
            top: 3,
            child: pw.Container(
              width: barWidth * _dayWidthPdf,
              height: 12,
              decoration: pw.BoxDecoration(
                color: barColors[0],
                borderRadius: pw.BorderRadius.circular(3),
              ),
              alignment: pw.Alignment.center,
              child: barWidth * _dayWidthPdf > 18
                  ? pw.Text(
                      '$barDuration d',
                      style: pw.TextStyle(font: fontBold, fontSize: 5, color: PdfColors.white),
                    )
                  : null,
            ),
          ),
        );
      }

      // Ghost bar for compressed resources
      if (originalPlannedEnd != null && originalPlannedEnd.isAfter(plannedEnd)) {
        final ghostStart = _dayOffset(plannedEnd, minVal, dayStart);
        final ghostWidth = _clampedBarWidth(plannedEnd, originalPlannedEnd, minVal, dayStart, sliceDays);
        if (ghostWidth > 0) {
          final savedAmount = originalPlannedEnd.difference(plannedEnd).inDays;
          stackChildren.add(
            pw.Positioned(
              left: ghostStart * _dayWidthPdf,
              top: 3,
              child: pw.Container(
                width: ghostWidth * _dayWidthPdf,
                height: 12,
                decoration: pw.BoxDecoration(
                  color: _ghostColor.withAlpha(0.12),
                  borderRadius: const pw.BorderRadius.only(
                    topRight: pw.Radius.circular(3),
                    bottomRight: pw.Radius.circular(3),
                  ),
                ),
                alignment: pw.Alignment.center,
                child: ghostWidth * _dayWidthPdf > 18
                    ? pw.Text(
                        '-$savedAmount d',
                        style: pw.TextStyle(font: font, fontSize: 5, color: PdfColor.fromHex('#94A3B8')),
                      )
                    : null,
              ),
            ),
          );
        }
      }
    } else {
      stackChildren.add(
        pw.Positioned(
          left: 0,
          top: 3,
          child: pw.Text(
            'Pending',
            style: pw.TextStyle(font: font, fontSize: 6, color: PdfColors.grey500),
          ),
        ),
      );
    }

    final rowHeight = 16.0;
    return pw.Container(
      height: rowHeight,
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex('#F8FAFC'), width: 0.5)),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: _leftPanelWidth,
            padding: const pw.EdgeInsets.only(left: 16, right: 4),
            alignment: pw.Alignment.centerLeft,
            child: pw.Text(
              '- $name${isExtra ? " (EXTRA)" : ""}',
              style: pw.TextStyle(font: font, fontSize: 6, color: isExtra ? PdfColors.orange700 : PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Stack(children: stackChildren),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildGrid(int sliceDays, DateTime minVal, int dayStart) {
    return pw.Row(
      children: List.generate(sliceDays, (index) {
        final day = minVal.add(Duration(days: dayStart + index));
        final isSunday = day.weekday == DateTime.sunday;
        return pw.Container(
          width: _dayWidthPdf,
          decoration: pw.BoxDecoration(
            color: isSunday ? _sundayGridBg : null,
            border: pw.Border(right: pw.BorderSide(color: isSunday ? _sundayGridBg : _gridColor, width: 0.3)),
          ),
        );
      }),
    );
  }

  static int _dayOffset(DateTime date, DateTime minVal, int dayStart) {
    final offset = date.difference(minVal).inDays - dayStart;
    if (offset < 0) return 0;
    return offset;
  }

  static double _clampedBarWidth(DateTime start, DateTime end, DateTime minVal, int dayStart, int sliceDays) {
    final sliceEnd = minVal.add(Duration(days: dayStart + sliceDays - 1));
    final visibleEnd = end.isBefore(sliceEnd) ? end : sliceEnd;
    final sliceStart = minVal.add(Duration(days: dayStart));
    final visibleStart = start.isAfter(sliceStart) ? start : sliceStart;
    if (visibleEnd.isBefore(visibleStart)) return 0;
    return (visibleEnd.difference(visibleStart).inDays + 1).toDouble();
  }
}
