import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class ScheduleCalendarView extends StatefulWidget {
  final List<Map<String, dynamic>> dailySchedule;
  final List<Map<String, dynamic>> resources;

  const ScheduleCalendarView({
    super.key,
    required this.dailySchedule,
    required this.resources,
  });

  @override
  State<ScheduleCalendarView> createState() => _ScheduleCalendarViewState();
}

class _ScheduleCalendarViewState extends State<ScheduleCalendarView> {
  final Map<String, ScrollController> _controllers = {};

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  ScrollController _getController(String key) {
    return _controllers.putIfAbsent(key, () => ScrollController());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dailySchedule.isEmpty) return const SizedBox.shrink();

    // 1. Calculate total initial volume to work with
    double initialTotal = 0;
    for (var day in widget.dailySchedule) {
      initialTotal += (day['production'] as num?)?.toDouble() ?? 0;
    }

    // 2. Group by month key for ordered processing
    Map<String, List<Map<String, dynamic>>> groupedMonths = {};
    for (var day in widget.dailySchedule) {
      final d = day['date'];
      if (d is DateTime) {
        final monthKey = DateFormat('yyyy-MM').format(d);
        groupedMonths.putIfAbsent(monthKey, () => []).add(day);
      }
    }

    // 3. Calculate production averages once for all months
    double theoNormalProd = 0;
    for (var res in widget.resources) {
      final qty = (res['quantity'] as num?)?.toDouble() ?? 0;
      final trips = (res['trips_per_day'] as num?)?.toDouble() ?? 0;
      final cap = (res['capacity_per_trip'] as num?)?.toDouble() ?? 0;
      theoNormalProd += (qty * trips * cap);
    }
    double theoSatProd = theoNormalProd * 0.5;

    // 4. Process months and track running balance
    double currentBalance = initialTotal;
    double accumulatedProd = 0;
    final sortedKeys = groupedMonths.keys.toList()..sort();
    List<Widget> monthWidgets = [];

    for (var key in sortedKeys) {
      final monthDays = groupedMonths[key]!;
      final monthName = DateFormat('MMMM yyyy').format(monthDays.first['date']);
      
      double monthProduction = 0;
      for (var day in monthDays) {
        monthProduction += (day['production'] as num?)?.toDouble() ?? 0;
      }
      
      accumulatedProd += monthProduction;
      currentBalance -= monthProduction;
      
      final double cumulativePct = initialTotal > 0 
          ? (accumulatedProd / initialTotal) * 100 
          : 0;
      
      monthWidgets.add(_buildMonthTable(
        monthName, 
        monthDays, 
        monthProduction, 
        currentBalance < 0.1 ? 0 : currentBalance,
        theoNormalProd,
        theoSatProd,
        cumulativePct,
      ));
    }

    return ScrollConfiguration(
      behavior: AppScrollBehavior(),
      child: SingleChildScrollView(
        child: Column(
          children: monthWidgets,
        ),
      ),
    );
  }

  Widget _buildMonthTable(
    String monthName, 
    List<Map<String, dynamic>> days, 
    double monthProd, 
    double remainingBalance,
    double theoNormalProd,
    double theoSatProd,
    double cumulativePct,
  ) {
    final controller = _getController(monthName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16), // Reduced margin between months
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), // Reduced vertical padding
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11D411).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month, color: Color(0xFF11D411), size: 18),
                ),
                const SizedBox(width: 14),
                Text(
                  monthName.toUpperCase(), 
                  style: GoogleFonts.manrope(
                    color: Colors.white, 
                    fontWeight: FontWeight.w800, 
                    fontSize: 14,
                    letterSpacing: 0.5,
                  )
                ),
                const Spacer(),
                _buildHeaderBadge(
                  'AVG DAILY PROD', 
                  'Normal: ${theoNormalProd.toStringAsFixed(0)} | Sat: ${theoSatProd.toStringAsFixed(0)}', 
                  AppTheme.primaryGreen
                ),
                const SizedBox(width: 12),
                _buildHeaderGroupBadge(
                  monthProd, 
                  remainingBalance,
                  cumulativePct,
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. FIXED RESOURCE COLUMN
              _buildFixedResourceColumn(days, theoNormalProd, theoSatProd),
              
              // 2. SCROLLABLE DATA PART
              Expanded(
                child: Listener(
                  onPointerSignal: (pointerSignal) {
                    if (pointerSignal is PointerScrollEvent) {
                      if (pointerSignal.scrollDelta.dy != 0) {
                        final newOffset = controller.offset + pointerSignal.scrollDelta.dy;
                        if (controller.hasClients) {
                          controller.jumpTo(newOffset.clamp(0.0, controller.position.maxScrollExtent));
                        }
                      }
                    }
                  },
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      scrollbarTheme: ScrollbarThemeData(
                        thumbColor: WidgetStateProperty.all(const Color(0xFF11D411)),
                        trackColor: WidgetStateProperty.all(Colors.grey[200]),
                        thickness: WidgetStateProperty.all(18),
                        radius: const Radius.circular(9),
                        thumbVisibility: WidgetStateProperty.all(true),
                        trackVisibility: WidgetStateProperty.all(true),
                        interactive: true,
                      ),
                    ),
                    child: Scrollbar(
                      controller: controller,
                      thumbVisibility: true,
                      trackVisibility: true,
                      child: SingleChildScrollView(
                        controller: controller,
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 0), // Removed 28px bottom space
                          child: _buildDataTable(days, context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFixedResourceColumn(List<Map<String, dynamic>> days, double theoNormal, double theoSat) {
    return Container(
      width: 170, // Slightly wider
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.slate200, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            height: 40,
            padding: const EdgeInsets.only(left: 16),
            alignment: Alignment.centerLeft,
            color: const Color(0xFFF8FAFC),
            child: Text(
              'RESOURCE', 
              style: GoogleFonts.manrope(
                fontSize: 10, 
                fontWeight: FontWeight.w800, 
                color: AppTheme.slate500,
                letterSpacing: 0.5,
              )
            ),
          ),
          // Resource Rows
          ...widget.resources.map((res) {
            final name = res['machine_name'] ?? '';
            final String? photoUrl = res['photo_url'];

            return Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: AppTheme.slate50,
                      border: Border.all(color: AppTheme.slate200),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (photoUrl != null && photoUrl.isNotEmpty)
                      ? Image.network(
                          photoUrl, 
                          fit: BoxFit.cover, 
                          errorBuilder: (c, e, s) => const Center(child: Icon(Icons.precision_manufacturing, size: 14, color: AppTheme.slate400)),
                        )
                      : const Center(child: Icon(Icons.precision_manufacturing, size: 14, color: AppTheme.slate400)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name, 
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 11, 
                        fontWeight: FontWeight.w600,
                        color: AppTheme.slate700, 
                      )
                    ),
                  ),
                ],
              ),
            );
          }),
          // Total Trips Row
          Container(
            height: 40,
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.only(left: 16),
            alignment: Alignment.centerLeft,
            child: Text(
              'TOTAL TRIPS', 
              style: GoogleFonts.manrope(
                fontSize: 10, 
                fontWeight: FontWeight.w800, 
                color: AppTheme.slate500
              )
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 18), // Match scrollbar thickness
        ],
      ),
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> days, BuildContext context) {
    // 1. Build Columns
    final List<DataColumn> cols = [];
    for (var day in days) {
      final date = day['date'] as DateTime;
      final isSun = day['isSunday'] == true;
      final isSat = day['isSaturday'] == true;
      cols.add(DataColumn(
        label: Container(
          width: 40,
          alignment: Alignment.center,
          color: (isSun || isSat) ? const Color(0xFFF1F5F9) : null,
          child: Text(
            DateFormat('dd').format(date),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSat ? FontWeight.bold : FontWeight.normal,
              color: isSun ? Colors.red[300] : Colors.black,
            ),
          ),
        ),
      ));
    }
    cols.add(const DataColumn(
      label: SizedBox(
        width: 70,
        child: Center(
          child: Text('TOTAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    ));

    // 2. Build Rows
    final List<DataRow> tableRows = [];

    // Resource rows
    for (var res in widget.resources) {
      final qty = (res['quantity'] as num?)?.toDouble() ?? 1;
      final trips = (res['trips_per_day'] as num?)?.toDouble() ?? 0;
      double rowTotal = 0;
      
      final List<DataCell> cells = [];
      for (var day in days) {
        final isSun = day['isSunday'] == true;
        final isSat = day['isSaturday'] == true;
        final f = isSun ? 0.0 : (isSat ? 0.5 : 1.0);
        final val = trips * qty * f;
        rowTotal += val;
        
        cells.add(DataCell(
          Container(
            width: 40,
            alignment: Alignment.center,
            color: (isSun || isSat) ? const Color(0xFFF8FAFC) : null,
            child: Text(
              val > 0 ? val.toStringAsFixed(0) : '-',
              style: TextStyle(fontSize: 10, color: isSun ? Colors.grey[300] : Colors.black),
            ),
          ),
        ));
      }
      
      // Total cell for the resource
      cells.add(DataCell(
        Center(
          child: Text(
            rowTotal.toStringAsFixed(0),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF11D411)),
          ),
        ),
      ));
      
      tableRows.add(DataRow(cells: cells));
    }

    // Total Trips Row
    final List<DataCell> totalTripsCells = [];
    for (var day in days) {
      final isSun = day['isSunday'] == true;
      final isSat = day['isSaturday'] == true;
      final f = isSun ? 0.0 : (isSat ? 0.5 : 1.0);
      double dailyTotalTrips = 0;
      for (var res in widget.resources) {
        final qty = (res['quantity'] as num?)?.toDouble() ?? 1;
        final trips = (res['trips_per_day'] as num?)?.toDouble() ?? 0;
        dailyTotalTrips += trips * qty * f;
      }
      totalTripsCells.add(DataCell(
        Container(
          width: 40,
          alignment: Alignment.center,
          color: (isSun || isSat) ? const Color(0xFFF1F5F9) : null,
          child: Text(
            dailyTotalTrips > 0 ? dailyTotalTrips.toStringAsFixed(0) : '-',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ));
    }

    // Grand total trips
    double grandTotalTrips = 0;
    for (var d in days) {
      final f = d['isSunday'] == true ? 0.0 : (d['isSaturday'] == true ? 0.5 : 1.0);
      for (var res in widget.resources) {
        grandTotalTrips += ((res['trips_per_day'] as num?)?.toDouble() ?? 0) * ((res['quantity'] as num?)?.toDouble() ?? 1) * f;
      }
    }
    totalTripsCells.add(DataCell(
      Center(
        child: Text(
          grandTotalTrips.toStringAsFixed(0),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    ));

    tableRows.add(DataRow(
      color: WidgetStateProperty.all(Colors.grey[50]),
      cells: totalTripsCells,
    ));

    return DataTable(
      columnSpacing: 0,
      headingRowHeight: 40,
      dataRowMinHeight: 40,
      dataRowMaxHeight: 40,
      horizontalMargin: 0,
      columns: cols,
      rows: tableRows,
    );
  }

  Widget _buildHeaderGroupBadge(double monthlyProd, double balance, double cumulativePct) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSubLabel('MONTHLY PROD'),
          const SizedBox(width: 8),
          _buildSubValue('${NumberFormat('#,###').format(monthlyProd)} CY (${cumulativePct.toStringAsFixed(1)}%)', const Color(0xFF11D411)),
          const SizedBox(width: 12),
          Container(width: 1, height: 14, color: Colors.white10),
          const SizedBox(width: 12),
          _buildSubLabel('ENDING BALANCE'),
          const SizedBox(width: 8),
          _buildSubValue('${NumberFormat('#,###').format(balance)} CY', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildSubLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        color: AppTheme.slate400,
        fontSize: 8,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSubValue(String value, Color color) {
    return Text(
      value,
      style: GoogleFonts.manrope(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildHeaderBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSubLabel(label),
          const SizedBox(width: 8),
          _buildSubValue(value, color),
        ],
      ),
    );
  }
}
