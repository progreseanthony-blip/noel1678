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

    Map<String, List<Map<String, dynamic>>> months = {};
    for (var day in widget.dailySchedule) {
      final d = day['date'];
      if (d is DateTime) {
        final monthName = DateFormat('MMMM yyyy').format(d);
        months.putIfAbsent(monthName, () => []).add(day);
      }
    }

    return ScrollConfiguration(
      behavior: AppScrollBehavior(),
      child: SingleChildScrollView(
        child: Column(
          children: months.entries.map((entry) {
            return _buildMonthTable(entry.key, entry.value);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMonthTable(String monthName, List<Map<String, dynamic>> days) {
    final controller = _getController(monthName);

    // Calculate production averages for display
    double theoNormalProd = 0;
    for (var res in widget.resources) {
      final qty = (res['quantity'] as num?)?.toDouble() ?? 0;
      final trips = (res['trips_per_day'] as num?)?.toDouble() ?? 0;
      final cap = (res['capacity_per_trip'] as num?)?.toDouble() ?? 0;
      theoNormalProd += (qty * trips * cap);
    }
    double theoSatProd = theoNormalProd * 0.5;

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    fontSize: 15,
                    letterSpacing: 0.5,
                  )
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
                          padding: const EdgeInsets.only(bottom: 28),
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
          // Avg Production Row
          Container(
            height: 40,
            padding: const EdgeInsets.only(left: 16),
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AVG. PRODUCTION', 
                  style: GoogleFonts.manrope(
                    fontSize: 8, 
                    fontWeight: FontWeight.w800, 
                    color: AppTheme.slate400
                  )
                ),
                const SizedBox(height: 1),
                Text(
                  'N ${theoNormal.toStringAsFixed(0)} | S ${theoSat.toStringAsFixed(0)}',
                  style: GoogleFonts.manrope(
                    fontSize: 11, 
                    fontWeight: FontWeight.w800, 
                    color: AppTheme.primaryGreen
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30), // Match scrollbar
        ],
      ),
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> days, BuildContext context) {
    return DataTable(
      columnSpacing: 0,
      headingRowHeight: 40,
      dataRowMinHeight: 40,
      dataRowMaxHeight: 40,
      horizontalMargin: 0,
      columns: [
        // No Resource Column here anymore
        ...days.map((day) {
          final date = day['date'] as DateTime;
          final isSun = day['isSunday'] == true;
          final isSat = day['isSaturday'] == true;
          return DataColumn(
            label: Container(
              width: 40,
              alignment: Alignment.center,
              color: (isSun || isSat) ? const Color(0xFFF1F5F9) : null,
              child: Text(DateFormat('dd').format(date),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSat ? FontWeight.bold : FontWeight.normal,
                    color: isSun ? Colors.red[300] : Colors.black,
                  )),
            ),
          );
        }),
        DataColumn(
          label: Container(
            width: 70,
            alignment: Alignment.center,
            child: const Text('TOTAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
      rows: [
        // Resource Rows
        ...widget.resources.map((res) {
          final qty = (res['quantity'] as num?)?.toDouble() ?? 1;
          final trips = (res['trips_per_day'] as num?)?.toDouble() ?? 0;
          double rowTotal = 0;
          return DataRow(cells: [
            ...days.map((day) {
              final isSun = day['isSunday'] == true;
              final isSat = day['isSaturday'] == true;
              final f = isSun ? 0.0 : (isSat ? 0.5 : 1.0);
              final val = trips * qty * f;
              rowTotal += val;
              return DataCell(Container(
                width: 40,
                alignment: Alignment.center,
                color: (isSun || isSat) ? const Color(0xFFF8FAFC) : null,
                child: Text(
                  val > 0 ? val.toStringAsFixed(0) : '-',
                  style: TextStyle(fontSize: 10, color: isSun ? Colors.grey[300] : Colors.black),
                ),
              ));
            }),
            DataCell(Center(
              child: Text(rowTotal.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF11D411))),
            )),
          ]);
        }),

        // Total Trips Row
        DataRow(
          color: WidgetStateProperty.all(Colors.grey[50]),
          cells: [
            ...days.map((day) {
              final isSun = day['isSunday'] == true;
              final isSat = day['isSaturday'] == true;
              final f = isSun ? 0.0 : (isSat ? 0.5 : 1.0);
              double dailyTotalTrips = 0;
              for (var res in widget.resources) {
                final qty = (res['quantity'] as num?)?.toDouble() ?? 1;
                final trips = (res['trips_per_day'] as num?)?.toDouble() ?? 0;
                dailyTotalTrips += trips * qty * f;
              }
              return DataCell(Container(
                width: 40,
                alignment: Alignment.center,
                color: (isSun || isSat) ? const Color(0xFFF1F5F9) : null,
                child: Text(
                  dailyTotalTrips > 0 ? dailyTotalTrips.toStringAsFixed(0) : '-',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ));
            }),
            DataCell(Center(
              child: Text(
                days.fold<double>(0, (sum, d) {
                  final f = d['isSunday'] == true ? 0.0 : (d['isSaturday'] == true ? 0.5 : 1.0);
                  double daily = 0;
                  for (var res in widget.resources) {
                    daily += ((res['trips_per_day'] as num?)?.toDouble() ?? 0) * ((res['quantity'] as num?)?.toDouble() ?? 1) * f;
                  }
                  return sum + daily;
                }).toStringAsFixed(0),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            )),
          ],
        ),

        // Production Averages Row
        DataRow(
          cells: [
            ...days.map((day) {
              final isSun = day['isSunday'] == true;
              final isSat = day['isSaturday'] == true;
              return DataCell(Container(
                width: 40,
                alignment: Alignment.center,
                color: (isSun || isSat) ? const Color(0xFFF1F5F9) : null,
                child: const Text('-', style: TextStyle(fontSize: 10, color: Colors.black26)),
              ));
            }),
            DataCell(Center(
              child: Text(
                days.fold<double>(0.0, (sum, d) => sum + ((d['production'] as num?)?.toDouble() ?? 0)).toStringAsFixed(0),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF11D411)),
              ),
            )),
          ],
        ),
      ],
    );
  }
}
