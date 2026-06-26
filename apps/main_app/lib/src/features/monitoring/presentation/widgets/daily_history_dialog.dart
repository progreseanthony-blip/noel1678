import 'package:flutter/material.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

class DailyHistoryDialog extends StatefulWidget {
  final String projectId;
  final String resourceType;
  final String resourceId;
  final String resourceName;
  final String odometerUnit;

  const DailyHistoryDialog({
    super.key,
    required this.projectId,
    required this.resourceType,
    required this.resourceId,
    required this.resourceName,
    this.odometerUnit = 'hours',
  });

  @override
  State<DailyHistoryDialog> createState() => _DailyHistoryDialogState();
}

class _DailyHistoryDialogState extends State<DailyHistoryDialog> {
  List<Map<String, dynamic>>? _entries;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final service = ProjectMonitoringService(Supabase.instance.client);
      final entries = await service.getDailyHistory(
        widget.projectId, widget.resourceType, widget.resourceId,
      );
      if (mounted) {
        setState(() {
          _entries = entries;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily History',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.slate400,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          widget.resourceName,
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.slate200.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.close, color: AppTheme.slate400, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              )
            else if (_entries == null || _entries!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No entries found',
                  style: GoogleFonts.manrope(color: AppTheme.slate400),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _entries!.length,
                  itemBuilder: (context, i) {
                    final e = _entries![i];
                    final date = e['daily_reports']?['report_date']?.toString() ?? '';
                    final status = e['daily_reports']?['status']?.toString() ?? '';
                    final devReason = e['deviation_reasons']?['description']?.toString();

                    if (widget.resourceType == 'machinery') {
                      final prod = (e['production_value'] as num?)?.toDouble() ?? 0;
                      final hrs = (e['total_hours'] as num?)?.toDouble() ?? 0;
                      final unitLabel = widget.odometerUnit == 'miles' ? 'Miles' : 'Hours';
                      return _entryRow(date, status,
                        'Production: ${prod.toStringAsFixed(0)} · $unitLabel: ${hrs.toStringAsFixed(1)}',
                        devReason,
                      );
                    } else {
                      final reg = (e['regular_hours'] as num?)?.toDouble() ?? 0;
                      final ot = (e['overtime_hours'] as num?)?.toDouble() ?? 0;
                      return _entryRow(date, status,
                        'Regular: ${reg.toStringAsFixed(1)}h · OT: ${ot.toStringAsFixed(1)}h',
                        devReason,
                      );
                    }
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _entryRow(String date, String status, String info, String? deviation) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: status == 'approved' ? AppTheme.primaryGreen.withOpacity(0.15) : AppTheme.slate200.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: status == 'approved' ? AppTheme.primaryGreen : AppTheme.slate400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
                if (deviation != null)
                  Text(
                    deviation,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      color: Colors.orange.shade300,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
