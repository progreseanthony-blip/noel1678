import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';
import 'package:google_fonts/google_fonts.dart';

class ComparisonResultRow extends StatelessWidget {
  final Map<String, dynamic> comparison;
  final VoidCallback? onReconcile;
  final VoidCallback? onRetryComparison;

  const ComparisonResultRow({
    super.key,
    required this.comparison,
    this.onReconcile,
    this.onRetryComparison,
  });

  @override
  Widget build(BuildContext context) {
    final serviceName = comparison['quote_services'] != null
        ? (comparison['quote_services'] as Map)['name'] ?? 'Unknown'
        : 'Unknown';
    final unit = comparison['quote_services'] != null
        ? (comparison['quote_services'] as Map)['unit_of_measure'] ?? 'CY'
        : 'CY';
    final accumulatedDaily =
        (comparison['accumulated_daily_quantity'] as num?)?.toDouble() ?? 0;
    final inspectionMeasured =
        (comparison['inspection_measured_quantity'] as num?)?.toDouble() ?? 0;
    final deviationPct =
        (comparison['deviation_percentage'] as num?)?.toDouble() ?? 0;
    final threshold =
        (comparison['threshold_configured'] as num?)?.toDouble() ?? 5.0;
    final exceeds = comparison['exceeds_threshold'] == true;
    final status = comparison['status'] as String? ?? 'pending';

    final totalPlanned = comparison['weekly_inspection_details'] != null
        ? (comparison['weekly_inspection_details'] as Map)['total_planned_quantity'] ?? 0
        : 0;
    final plannedNum = (totalPlanned as num?)?.toDouble() ?? 0;
    final dailyPct = plannedNum > 0 ? (accumulatedDaily / plannedNum * 100) : 0;
    final inspectionPct = plannedNum > 0
        ? (inspectionMeasured / plannedNum * 100)
        : 0;

    final periodStart = comparison['period_start']?.toString() ?? '';
    final periodEnd = comparison['period_end']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: exceeds
              ? Colors.orange.withOpacity(0.3)
              : const Color(0xFF334155),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  serviceName,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              _statusBadge(status, exceeds),
            ],
          ),
          if (periodStart.isNotEmpty || periodEnd.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.date_range, size: 12, color: AppTheme.slate500),
                const SizedBox(width: 4),
                Text(
                  'Period: $periodStart — $periodEnd',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    color: AppTheme.slate500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // Progress bars
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Reports: ${accumulatedDaily.toStringAsFixed(1)} $unit (${dailyPct.toStringAsFixed(1)}%)',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppTheme.slate400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (dailyPct / 100).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFF334155),
                      color: Colors.blue,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inspection: ${inspectionMeasured.toStringAsFixed(1)} $unit (${inspectionPct.toStringAsFixed(1)}%)',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppTheme.slate400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (inspectionPct / 100).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFF334155),
                      color: AppTheme.primaryGreen,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _metricChip(
                'Deviation',
                '${deviationPct.toStringAsFixed(1)}%',
                exceeds ? Colors.orange : AppTheme.primaryGreen,
              ),
              const SizedBox(width: 8),
              _metricChip(
                'Threshold',
                '${threshold.toStringAsFixed(1)}%',
                AppTheme.slate400,
              ),
              const SizedBox(width: 8),
              _metricChip(
                'Abs Diff',
                '${(accumulatedDaily - inspectionMeasured).abs().toStringAsFixed(1)} $unit',
                AppTheme.slate400,
              ),
            ],
          ),

          if (exceeds && status != 'reconciled') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onReconcile != null)
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: onReconcile,
                        icon: const Icon(Icons.compare_arrows, size: 16),
                        label: Text(
                          'Reconcile',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (onRetryComparison != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onRetryComparison,
                    icon: const Icon(Icons.refresh, size: 14),
                    label: Text(
                      'Retry',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.slate400,
                      side: const BorderSide(color: AppTheme.slate600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status, bool exceeds) {
    Color color;
    String label;

    switch (status) {
      case 'reconciled':
        color = AppTheme.primaryGreen;
        label = 'RECONCILED';
        break;
      case 'pending_approval':
        color = Colors.blue;
        label = 'PENDING APPROVAL';
        break;
      case 'exceeds_threshold':
        color = Colors.orange;
        label = 'DEVIATION';
        break;
      case 'comparison_done':
        color = exceeds ? Colors.orange : AppTheme.primaryGreen;
        label = exceeds ? 'DEVIATION' : 'OK';
        break;
      default:
        color = AppTheme.slate400;
        label = 'PENDING';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _metricChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 9,
              color: AppTheme.slate500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
