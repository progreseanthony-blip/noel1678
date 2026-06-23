import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';

class ResourceRow extends StatelessWidget {
  final Map<String, dynamic> resource;
  final VoidCallback? onTap;

  const ResourceRow({super.key, required this.resource, this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = resource['type']?.toString() ?? '';
    final name = resource['name']?.toString() ?? '';
    final hasIssues = _hasIssues();

    Color indicatorColor;
    String statusLabel;
    String metricLine;

    if (type == 'machinery') {
      final prod = (resource['total_production'] as num?)?.toDouble() ?? 0;
      final hrs = (resource['total_hours'] as num?)?.toDouble() ?? 0;
      final devCount = (resource['deviation_count'] as int?) ?? 0;
      indicatorColor = devCount >= 2 ? Colors.redAccent : (prod > 0 ? AppTheme.primaryGreen : AppTheme.slate400);
      statusLabel = devCount >= 2 ? 'IRREGULAR' : (prod > 0 ? 'ACTIVE' : 'NO DATA');
      final odometerUnit = resource['odometer_unit']?.toString() == 'miles' ? 'mi' : 'hrs';
      metricLine = '${prod.toStringAsFixed(0)} prod · ${hrs.toStringAsFixed(1)} $odometerUnit · ${devCount} deviations';
    } else {
      final totalHrs = (resource['total_hours'] as num?)?.toDouble() ?? 0;
      final ot = (resource['total_ot'] as num?)?.toDouble() ?? 0;
      final devCount = (resource['deviation_count'] as int?) ?? 0;
      final unplanned = (resource['unplanned_count'] as int?) ?? 0;
      indicatorColor = devCount >= 3 || unplanned >= 2 ? Colors.redAccent : (totalHrs > 0 ? AppTheme.primaryGreen : AppTheme.slate400);
      statusLabel = devCount >= 3 ? 'IRREGULAR' : (totalHrs > 0 ? 'ACTIVE' : 'NO DATA');
      metricLine = '${totalHrs.toStringAsFixed(1)} hrs · OT: ${ot.toStringAsFixed(1)} · ${devCount} deviations';
      if (unplanned > 0) metricLine += ' · $unplanned reassigns';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: hasIssues ? Colors.red.withOpacity(0.04) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: hasIssues ? Border.all(color: Colors.red.withOpacity(0.1)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: indicatorColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: type == 'machinery'
                    ? AppTheme.primaryGreen.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                type == 'machinery' ? Icons.precision_manufacturing : Icons.person,
                size: 14,
                color: type == 'machinery' ? AppTheme.primaryGreen : Colors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    metricLine,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      color: AppTheme.slate400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: indicatorColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                statusLabel,
                style: GoogleFonts.manrope(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: indicatorColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasIssues() {
    final type = resource['type']?.toString() ?? '';
    final devCount = (resource['deviation_count'] as int?) ?? 0;
    if (type == 'machinery') {
      return devCount >= 2;
    }
    final unplannedCount = (resource['unplanned_count'] as int?) ?? 0;
    return devCount >= 3 || unplannedCount >= 2;
  }
}
