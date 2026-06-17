import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';
import 'resource_row.dart';
import 'daily_history_dialog.dart';

class ServiceAccordion extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic> service;
  final List<Map<String, dynamic>> resources;
  final bool initiallyExpanded;

  const ServiceAccordion({
    super.key,
    required this.projectId,
    required this.service,
    required this.resources,
    this.initiallyExpanded = false,
  });

  @override
  State<ServiceAccordion> createState() => _ServiceAccordionState();
}

class _ServiceAccordionState extends State<ServiceAccordion> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final svc = widget.service;
    final name = svc['name']?.toString() ?? '';
    final progress = (svc['progress'] as num?)?.toDouble() ?? 0;
    final cpi = (svc['cpi'] as num?)?.toDouble() ?? 1;
    final plannedQty = (svc['planned_quantity'] as num?)?.toDouble() ?? 0;
    final actualQty = (svc['actual_quantity'] as num?)?.toDouble() ?? 0;
    final unit = svc['unit']?.toString() ?? '';
    final plannedCost = (svc['planned_cost'] as num?)?.toDouble() ?? 0;
    final actualCost = (svc['actual_cost'] as num?)?.toDouble() ?? 0;

    final pct = progress.toInt();
    final isBehind = progress < 50;
    final isOverBudget = cpi < 0.95;
    final hasIssues = isBehind || isOverBudget;
    final resourcesWithIssues = widget.resources.where((r) {
      final type = r['type']?.toString() ?? '';
      final devCount = (r['deviation_count'] as int?) ?? 0;
      if (type == 'machinery') return devCount >= 2;
      final unplannedCount = (r['unplanned_count'] as int?) ?? 0;
      return devCount >= 3 || unplannedCount >= 2;
    }).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasIssues ? Colors.orange.withOpacity(0.3) : const Color(0xFF334155),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: hasIssues ? Colors.orange.withOpacity(0.15) : AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          hasIssues ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                          size: 16,
                          color: hasIssues ? Colors.orange : AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${actualQty.toStringAsFixed(0)} / ${plannedQty.toStringAsFixed(0)} $unit',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                color: AppTheme.slate400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (resourcesWithIssues > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$resourcesWithIssues issues',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      Text(
                        '$pct%',
                        style: GoogleFonts.manrope(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: pct >= 80 ? AppTheme.primaryGreen : (pct >= 50 ? Colors.orange : Colors.redAccent),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppTheme.slate400,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (progress / 100).clamp(0.0, 1.0),
                      backgroundColor: AppTheme.slate200.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        pct >= 80 ? AppTheme.primaryGreen : (pct >= 50 ? Colors.orange : Colors.redAccent),
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _miniChip('CPI: ${cpi.toStringAsFixed(2)}', cpi >= 0.95 ? AppTheme.primaryGreen : Colors.redAccent),
                      const SizedBox(width: 8),
                      _miniChip('Budget: \$${actualCost.toStringAsFixed(0)} / \$${plannedCost.toStringAsFixed(0)}', AppTheme.slate400),
                      const Spacer(),
                      _miniChip('${widget.resources.length} resources', AppTheme.slate500),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && widget.resources.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  const Divider(color: Color(0xFF334155), height: 1),
                  const SizedBox(height: 8),
                  for (final r in widget.resources)
                    ResourceRow(
                      resource: r,
                      onTap: () => _showDailyHistory(context, r),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _showDailyHistory(BuildContext context, Map<String, dynamic> resource) {
    final type = resource['type']?.toString() ?? '';
    showDialog(
      context: context,
      builder: (_) => DailyHistoryDialog(
        projectId: widget.projectId, resourceType: type, resourceId: resource['id']?.toString() ?? '',
        resourceName: resource['name']?.toString() ?? '',
      ),
    );
  }
}
