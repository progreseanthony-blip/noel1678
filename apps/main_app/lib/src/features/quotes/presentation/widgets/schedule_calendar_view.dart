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
  final String unit;

  const ScheduleCalendarView({
    super.key,
    required this.dailySchedule,
    required this.resources,
    this.unit = 'CY',
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

    final bool isMobile = MediaQuery.of(context).size.width < 720;

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
      final perf = (res['performance_per_day'] as num?)?.toDouble() ?? 0;
      if (perf > 0) {
        theoNormalProd += (qty * perf);
      } else {
        final trips = (res['trips_per_day'] as num?)?.toDouble() ?? 0;
        final cap = (res['capacity_per_trip'] as num?)?.toDouble() ?? 0;
        theoNormalProd += (qty * trips * cap);
      }
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
      
      if (isMobile) {
        monthWidgets.add(_MobileMonthView(
          monthName: monthName,
          days: monthDays,
          monthProd: monthProduction,
          unit: widget.unit,
          remainingBalance: currentBalance < 0.1 ? 0 : currentBalance,
          theoNormalProd: theoNormalProd,
          theoSatProd: theoSatProd,
          cumulativePct: cumulativePct,
          resources: widget.resources,
        ));
      } else {
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
    }

    return ScrollConfiguration(
      behavior: AppScrollBehavior(),
      child: SingleChildScrollView(
        padding: isMobile ? const EdgeInsets.all(16) : EdgeInsets.zero,
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
                        thickness: WidgetStateProperty.all(14),
                        radius: const Radius.circular(7),
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
                          padding: const EdgeInsets.only(bottom: 14), // Added space for scrollbar to not overlap row
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
      width: 170, // Fixed Width
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.slate200, width: 1.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(2, 0)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row Match
          Container(
            height: 60, // Match DataTable headingRowHeight
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
          // Grouping Resources by Type
          ..._buildGroupedRows(widget.resources, days),
          // Grand Total Row
          _buildTotalTripsSeparator(),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 14), // Match horizontal scrollbar thickness
        ],
      ),
    );
  }

  List<Widget> _buildGroupedRows(List<Map<String, dynamic>> resources, List<Map<String, dynamic>> days) {
    final List<Widget> items = [];

    // Rows for all resources
    for (var res in resources) {
      items.add(_buildResourceRow(res));
    }

    return items;
  }

  Widget _buildResourceRow(Map<String, dynamic> res) {
    final name = res['machine_name'] ?? '';
    final String? photoUrl = res['photo_url'];
    final qty = (res['quantity'] as num?)?.toDouble() ?? 1;

    return Container(
      height: 44, // Fixed height for consistency
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
              borderRadius: BorderRadius.circular(4), color: AppTheme.slate50, border: Border.all(color: AppTheme.slate200),
            ),
            clipBehavior: Clip.antiAlias,
            child: (photoUrl != null && photoUrl.isNotEmpty) ? Image.network(
                  photoUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.precision_manufacturing, size: 14, color: AppTheme.slate400),
                ) : const Icon(Icons.precision_manufacturing, size: 14, color: AppTheme.slate400),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$name (x${qty.toInt()})', 
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.slate700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalTripsSeparator() {
    return Container(
      height: 60, // Match Grand Total height
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.only(left: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        'TOTAL PERIOD', 
        style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.slate500)
      ),
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> days, BuildContext context) {
    // 1. Build Columns
    final List<DataColumn> cols = [];
    final List<Widget> columnWidgets = [];
    
    // 1. Header Row
    columnWidgets.add(Row(
      children: [
        ...days.map((day) {
          final date = day['date'] as DateTime;
          final isSun = day['isSunday'] == true;
          final isSat = day['isSaturday'] == true;
          return Container(
            width: 40, height: 60,
            alignment: Alignment.center,
            color: (isSun || isSat) ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('E').format(date).substring(0, 1).toUpperCase(), style: TextStyle(fontSize: 9, color: isSun ? Colors.red[300] : AppTheme.slate400, fontWeight: FontWeight.bold)),
                Text(DateFormat('dd').format(date), style: TextStyle(fontSize: 10, fontWeight: isSat ? FontWeight.bold : FontWeight.w700, color: isSun ? Colors.red[300] : Colors.black)),
              ],
            ),
          );
        }),
        Container(width: 70, height: 60, alignment: Alignment.center, color: const Color(0xFFF8FAFC), child: const Text('TOTAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
      ],
    ));

    // Data Rows
    for (var res in widget.resources) {
      final qty = (res['quantity'] as num?)?.toDouble() ?? 1;
      final trips = (res['trips_per_day'] as num?)?.toDouble() ?? 0;
      final cap = (res['capacity_per_trip'] as num?)?.toDouble() ?? 0;
      double rowTotalCY = 0;
      double rowTotalTrips = 0;
      
      columnWidgets.add(Row(
        children: [
          ...days.map((day) {
            final isSun = day['isSunday'] == true;
            final isSat = day['isSaturday'] == true;
            final f = isSun ? 0.0 : (isSat ? 0.5 : 1.0);
            
            final dTrips = trips * qty * f;
            final dCY = trips * qty * cap * f;
            
            rowTotalTrips += dTrips;
            rowTotalCY += dCY;
            
            return Container(
              width: 40, height: 44, // Match Resource Row height
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (isSun || isSat) ? const Color(0xFFF8FAFC) : null,
                border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Text(dTrips > 0 ? dTrips.toStringAsFixed(0) : '-', style: TextStyle(fontSize: 10, color: isSun ? Colors.grey[300] : Colors.black)),
            );
          }),
          Container(
            width: 70, height: 44, alignment: Alignment.center,
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(rowTotalTrips.toStringAsFixed(0), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate500)),
                Text(NumberFormat.compact().format(rowTotalCY), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              ],
            ),
          ),
        ],
      ));
    }
    
    // Grand Total Row
    double totalTrips = 0;
    double totalCY = 0;
    columnWidgets.add(Row(
      children: [
        ...days.map((day) {
          final isSun = day['isSunday'] == true;
          final isSat = day['isSaturday'] == true;
          final f = isSun ? 0.0 : (isSat ? 0.5 : 1.0);
          double dCY = 0;
          double dTrips = 0;
          for (var res in widget.resources) {
            final q = (res['quantity'] as num?)?.toDouble() ?? 1;
            final t = (res['trips_per_day'] as num?)?.toDouble() ?? 0;
            final c = (res['capacity_per_trip'] as num?)?.toDouble() ?? 0;
            dTrips += (t * q * f);
            dCY += (t * q * c * f);
          }
          totalTrips += dTrips;
          totalCY += dCY;
          return Container(
            width: 40, height: 60, // Grand Total row height
            alignment: Alignment.center,
            color: Colors.grey[100],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(dTrips > 0 ? dTrips.toStringAsFixed(0) : '-', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.slate500)),
                Text(dCY > 0 ? NumberFormat.compact().format(dCY) : '-', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate900)),
              ],
            ),
          );
        }),
        Container(
          width: 70, height: 60, alignment: Alignment.center,
          color: Colors.grey[100],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(totalTrips.toStringAsFixed(0), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.slate500)),
              Text(NumberFormat.compact().format(totalCY), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.slate900)),
            ],
          ),
        ),
      ],
    ));

    // Add spacer for scrollbar
    columnWidgets.add(const SizedBox(height: 24));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columnWidgets,
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
          _buildSubValue('${NumberFormat('#,###').format(monthlyProd)} ${widget.unit} (${cumulativePct.toStringAsFixed(1)}%)', const Color(0xFF11D411)),
          const SizedBox(width: 12),
          Container(width: 1, height: 14, color: Colors.white10),
          const SizedBox(width: 12),
          _buildSubLabel('ENDING BALANCE'),
          const SizedBox(width: 8),
          _buildSubValue('${NumberFormat('#,###').format(balance)} ${widget.unit}', Colors.orange),
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

class _MobileMonthView extends StatelessWidget {
  final String monthName;
  final List<Map<String, dynamic>> days;
  final double monthProd;
  final double remainingBalance;
  final double theoNormalProd;
  final double theoSatProd;
  final double cumulativePct;
  final List<Map<String, dynamic>> resources;
  final String unit;

  const _MobileMonthView({
    required this.monthName,
    required this.days,
    required this.monthProd,
    required this.unit,
    required this.remainingBalance,
    required this.theoNormalProd,
    required this.theoSatProd,
    required this.cumulativePct,
    required this.resources,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month Selector card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F3), // surface-container-low
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.chevron_left, color: AppTheme.slate500),
              Column(
                children: [
                  Text(
                    monthName.toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: -0.5,
                      color: AppTheme.slate900,
                    ),
                  ),
                  Text(
                    'PRODUCTION PERIOD',
                    style: GoogleFonts.manrope(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: AppTheme.slate500,
                    ),
                  ),
                ],
              ),
              const Icon(Icons.chevron_right, color: AppTheme.slate500),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Metrics Bar
        Row(
          children: [
            Expanded(
              child: _MetricsCard(
                label: 'AVG DAILY PROD',
                value: NumberFormat.compact().format(theoNormalProd),
                unit: unit,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricsCard(
                label: 'MONTHLY PROD',
                value: NumberFormat.compact().format(monthProd),
                unit: unit,
                highlightColor: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricsCard(
                label: 'END BALANCE',
                value: NumberFormat.compact().format(remainingBalance),
                unit: 'TON',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Active Resources Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVE RESOURCES',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppTheme.slate500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3FFF8B).withOpacity(0.2), // tertiary-container
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${resources.length} MACHINES',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF005D2C),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Resource List
        ...resources.map((res) => _MobileResourceItem(
          resource: res,
          days: days,
        )),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _MetricsCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? highlightColor;

  const _MetricsCard({
    required this.label,
    required this.value,
    required this.unit,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: highlightColor != null ? Border(bottom: BorderSide(color: highlightColor!, width: 4)) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: AppTheme.slate500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Text(
                value,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.slate900,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: GoogleFonts.manrope(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.slate500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobileResourceItem extends StatefulWidget {
  final Map<String, dynamic> resource;
  final List<Map<String, dynamic>> days;

  const _MobileResourceItem({
    required this.resource,
    required this.days,
  });

  @override
  State<_MobileResourceItem> createState() => _MobileResourceItemState();
}

class _MobileResourceItemState extends State<_MobileResourceItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.resource['machine_name'] ?? '';
    final qty = (widget.resource['quantity'] as num?)?.toDouble() ?? 1;
    final trips = (widget.resource['trips_per_day'] as num?)?.toDouble() ?? 0;
    final cap = (widget.resource['capacity_per_trip'] as num?)?.toDouble() ?? 0;
    
    double weeklyTotalCY = 0;
    double weeklyTotalTrips = 0;
    for (var i = 0; i < widget.days.length && i < 7; i++) {
      final day = widget.days[i];
      final isSun = day['isSunday'] == true;
      final isSat = day['isSaturday'] == true;
      final f = isSun ? 0.0 : (isSat ? 0.5 : 1.0);
      weeklyTotalTrips += (trips * qty * f);
      weeklyTotalCY += (trips * qty * cap * f);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7E8EB), // surface-container
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.precision_manufacturing, color: AppTheme.primaryGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$name (x${qty.toInt()})',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.slate900,
                          ),
                        ),
                        Text(
                          'Excavator • Bulk Earthwork', // Placeholder or use category if available
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: AppTheme.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.slate400,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              color: const Color(0xFFF0F0F3), // surface-container-low
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.days.map((day) {
                        final date = day['date'] as DateTime;
                        final isSun = day['isSunday'] == true;
                        final isSat = day['isSaturday'] == true;
                        final f = isSun ? 0.0 : (isSat ? 0.5 : 1.0);
                        final dailyTrips = trips * qty * f;

                        return Container(
                          width: 64,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: (date.day == DateTime.now().day && date.month == DateTime.now().month) 
                              ? Border.all(color: AppTheme.primaryGreen, width: 1.5) 
                              : null,
                          ),
                          child: Column(
                            children: [
                              Text(
                                DateFormat('E d').format(date).toUpperCase(),
                                style: GoogleFonts.manrope(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.slate500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dailyTrips > 0 ? dailyTrips.toStringAsFixed(0) : '-',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.slate900,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'WEEKLY TOTAL',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.slate500,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${weeklyTotalTrips.toStringAsFixed(0)} TRIPS',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.slate500,
                            ),
                          ),
                          Text(
                            '${NumberFormat('#,###').format(weeklyTotalCY)} CY',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
