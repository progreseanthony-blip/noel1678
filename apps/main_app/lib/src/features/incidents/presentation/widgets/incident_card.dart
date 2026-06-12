import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';
import 'incident_status_badge.dart';
import 'incident_priority_badge.dart';

class IncidentCard extends StatelessWidget {
  final Map<String, dynamic> incident;
  final VoidCallback onTap;

  const IncidentCard({super.key, required this.incident, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final category = incident['incident_categories'] as Map<String, dynamic>?;
    final catName = category?['name'] as String? ?? 'General';
    final catColorHex = category?['color'] as String? ?? '#EF4444';
    final catColor = Color(int.parse(catColorHex.replaceFirst('#', '0xFF')));
    final title = incident['title'] as String? ?? '';
    final priority = incident['priority'] as String? ?? 'medium';
    final status = incident['status'] as String? ?? 'open';
    final timeImpact = incident['time_impact_hours'];
    final costImpact = incident['cost_impact'];
    final expenses = incident['actual_expenses'];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppTheme.slate200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: catColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: AppTheme.slate900,
                        ),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        catName,
                        style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate400),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                IncidentStatusBadge(status: status),
                const SizedBox(width: 8),
                IncidentPriorityBadge(priority: priority),
              ]),
              if (timeImpact != null || costImpact != null || (expenses != null && expenses > 0)) ...[
                const SizedBox(height: 8),
                Row(children: [
                  if (timeImpact != null)
                    _metricChip('${timeImpact.toStringAsFixed(1)}h', AppTheme.accentCyan),
                  if (costImpact != null) ...[
                    const SizedBox(width: 8),
                    _metricChip('\$${costImpact.toStringAsFixed(0)}', AppTheme.errorRed),
                  ],
                  if (expenses != null && expenses > 0) ...[
                    const SizedBox(width: 8),
                    _metricChip('Exp: \$${expenses.toStringAsFixed(0)}', AppTheme.slate600),
                  ],
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 10, fontWeight: FontWeight.w700, color: color,
        ),
      ),
    );
  }
}
