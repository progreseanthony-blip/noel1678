import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyLogAdjustmentList extends StatelessWidget {
  final List<Map<String, dynamic>> dailyLogs;
  final Map<String, double> pendingAdjustments;
  final Map<String, String> pendingReasons;
  final void Function(String resourceType, String logId, Map<String, dynamic> log)
      onAdjust;

  const DailyLogAdjustmentList({
    super.key,
    required this.dailyLogs,
    required this.pendingAdjustments,
    required this.pendingReasons,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: dailyLogs.map((day) => _buildDayCard(day)).toList(),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day) {
    final reportDate = day['report_date'] as String? ?? '';
    final machineryLogs =
        List<Map<String, dynamic>>.from(day['machinery_logs'] ?? []);
    final materialUsage =
        List<Map<String, dynamic>>.from(day['material_usage'] ?? []);

    final hasLogs = machineryLogs.isNotEmpty || materialUsage.isNotEmpty;
    if (!hasLogs) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Text(
                  reportDate,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            if (machineryLogs.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Machinery',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.slate400,
                ),
              ),
              ...(machineryLogs
                  .map((log) => _buildLogRow('machinery', log))),
            ],
            if (materialUsage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Materials',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.slate400,
                ),
              ),
              ...(materialUsage
                  .map((log) => _buildLogRow('material', log))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogRow(String resourceType, Map<String, dynamic> log) {
    final logId = log['id'] as String;
    final key = '$resourceType:$logId';
    final hasAdjustment = pendingAdjustments.containsKey(key);

    double original;
    String unit;
    String machineName;

    if (resourceType == 'machinery') {
      original = (log['production_value'] as num?)?.toDouble() ?? 0;
      unit = log['production_unit'] as String? ?? 'CY';
      final pm = log['project_machinery'] as Map?;
      machineName = pm?['machinery_name'] as String? ?? 'Unknown';
    } else {
      original = (log['quantity_used'] as num?)?.toDouble() ?? 0;
      unit = log['unit'] as String? ?? 'CY';
      final pm = log['project_material'] as Map?;
      machineName = pm?['material_name'] as String? ?? 'Unknown';
    }

    final adjustedValue = pendingAdjustments[key] ?? original;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  machineName,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.slate200,
                  ),
                ),
                Text(
                  hasAdjustment
                      ? '$original $unit → $adjustedValue $unit'
                      : '${original.toStringAsFixed(2)} $unit',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color:
                        hasAdjustment ? Colors.orange : AppTheme.slate400,
                  ),
                ),
                if (hasAdjustment &&
                    pendingReasons[key]?.isNotEmpty == true)
                  Text(
                    pendingReasons[key]!,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      color: AppTheme.slate500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onAdjust(resourceType, logId, log),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: hasAdjustment
                    ? Colors.orange.withOpacity(0.15)
                    : AppTheme.slate700.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasAdjustment ? Icons.edit : Icons.edit_outlined,
                    size: 12,
                    color: hasAdjustment
                        ? Colors.orange
                        : AppTheme.slate400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasAdjustment ? 'ADJUSTED' : 'ADJUST',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: hasAdjustment
                          ? Colors.orange
                          : AppTheme.slate400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
