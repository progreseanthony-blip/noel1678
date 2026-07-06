import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_data/noel_data.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';

class ReconciliationPage extends StatefulWidget {
  final String projectId;
  final String inspectionId;
  final String comparisonId;
  final String serviceId;
  const ReconciliationPage({
    super.key,
    required this.projectId,
    required this.inspectionId,
    required this.comparisonId,
    required this.serviceId,
  });

  @override
  State<ReconciliationPage> createState() => _ReconciliationPageState();
}

class _ReconciliationPageState extends State<ReconciliationPage> {
  final _notesController = TextEditingController();
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic>? _comparison;
  List<Map<String, dynamic>> _dailyLogs = [];
  List<Map<String, dynamic>> _existingAdjustments = [];
  Map<String, dynamic>? _project;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  // In-memory adjustments: key = "${resourceType}:${logId}", value = adjusted value
  final Map<String, double> _pendingAdjustments = {};
  final Map<String, String> _pendingReasons = {};

  double _totalOriginal = 0;
  double _totalAdjusted = 0;
  double _targetDeviation = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final service = InspectionService(supabase);

      final project = await supabase
          .from('projects')
          .select('id, title')
          .eq('id', widget.projectId)
          .maybeSingle();

      final comparisons =
          await service.getComparisonsByInspection(widget.inspectionId);
      final comp = comparisons.firstWhere(
        (c) => c['id'] == widget.comparisonId,
        orElse: () => <String, dynamic>{},
      );
      if (comp.isEmpty) throw 'Comparison not found';

      final periodStart = comp['period_start'] as String? ?? '';
      final periodEnd = comp['period_end'] as String? ?? '';
      final serviceQuoteId = comp['quote_service_id'] as String;

      final dailyLogs = await service.getDailyReportLogsForPeriod(
        widget.projectId, serviceQuoteId, periodStart, periodEnd);

      final adjustments = await service.getAdjustmentsForComparison(
          widget.comparisonId);

      final accumulatedDaily =
          (comp['accumulated_daily_quantity'] as num?)?.toDouble() ?? 0;
      final inspectionMeasured =
          (comp['inspection_measured_quantity'] as num?)?.toDouble() ?? 0;
      final targetDeviation = accumulatedDaily - inspectionMeasured;

      if (mounted) {
        setState(() {
          _project = project;
          _comparison = comp;
          _dailyLogs = dailyLogs;
          _existingAdjustments = adjustments;
          _targetDeviation = targetDeviation;
          _totalOriginal = accumulatedDaily;
          _isLoading = false;
          _recalcTotals();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _recalcTotals() {
    double total = 0;
    for (final day in _dailyLogs) {
      for (final log in day['machinery_logs'] ?? []) {
        final logId = log['id'] as String;
        final key = 'machinery:$logId';
        total += _pendingAdjustments.containsKey(key)
            ? (_pendingAdjustments[key] ?? 0)
            : ((log['production_value'] as num?)?.toDouble() ?? 0);
      }
      for (final log in day['material_usage'] ?? []) {
        final logId = log['id'] as String;
        final key = 'material:$logId';
        total += _pendingAdjustments.containsKey(key)
            ? (_pendingAdjustments[key] ?? 0)
            : ((log['quantity_used'] as num?)?.toDouble() ?? 0);
      }
    }
    setState(() => _totalAdjusted = total);
  }

  double _getOriginalValue(Map<String, dynamic> log, String resourceType) {
    if (resourceType == 'machinery') {
      return (log['production_value'] as num?)?.toDouble() ?? 0;
    } else if (resourceType == 'material') {
      return (log['quantity_used'] as num?)?.toDouble() ?? 0;
    }
    return 0;
  }

  String _getLogUnit(Map<String, dynamic> log, String resourceType) {
    if (resourceType == 'machinery') {
      return log['production_unit'] as String? ?? 'CY';
    }
    return log['unit'] as String? ?? 'CY';
  }

  void _showAdjustmentDialog(String resourceType, String logId,
      Map<String, dynamic> log) {
    final key = '$resourceType:$logId';
    final original = _getOriginalValue(log, resourceType);
    final currentAdjusted = _pendingAdjustments[key] ?? original;
    final reason = _pendingReasons[key] ?? '';
    final unit = _getLogUnit(log, resourceType);

    final adjustmentController =
        TextEditingController(text: currentAdjusted.toString());
    final reasonController = TextEditingController(text: reason);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Adjust ${resourceType == 'machinery' ? 'Production' : 'Quantity'}',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Original: $original $unit',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.slate400,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: adjustmentController,
              keyboardType:
                  TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Adjusted Value ($unit)',
                border: const OutlineInputBorder(),
              ),
              style:
                  GoogleFonts.manrope(fontSize: 13, color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for adjustment',
                hintText: 'e.g. Measured by drone shows less volume',
                border: OutlineInputBorder(),
              ),
              style:
                  GoogleFonts.manrope(fontSize: 13, color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          if (_pendingAdjustments.containsKey(key))
            TextButton(
              onPressed: () {
                _pendingAdjustments.remove(key);
                _pendingReasons.remove(key);
                Navigator.pop(ctx);
                _recalcTotals();
              },
              child: const Text('Reset', style: TextStyle(color: AppTheme.errorRed)),
            ),
          TextButton(
            onPressed: () {
              final newVal =
                  double.tryParse(adjustmentController.text.trim());
              if (newVal == null) return;
              _pendingAdjustments[key] = newVal;
              _pendingReasons[key] = reasonController.text.trim();
              Navigator.pop(ctx);
              _recalcTotals();
            },
            child: Text(
              'Apply',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitProposal() async {
    if (_pendingAdjustments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No adjustments to submit.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final supabase = Supabase.instance.client;
      final service = InspectionService(supabase);

      final adjustments = <Map<String, dynamic>>[];
      for (final entry in _pendingAdjustments.entries) {
        final parts = entry.key.split(':');
        final resourceType = parts[0];
        final logId = parts.sublist(1).join(':');

        double original = 0;
        for (final day in _dailyLogs) {
          final logs = resourceType == 'machinery'
              ? day['machinery_logs'] as List
              : day['material_usage'] as List;
          for (final log in logs) {
            if (log['id'] == logId) {
              original = _getOriginalValue(log, resourceType);
              break;
            }
          }
        }

        // Find which daily report this log belongs to
        String dailyReportId = '';
        for (final day in _dailyLogs) {
          final logs = resourceType == 'machinery'
              ? day['machinery_logs'] as List
              : day['material_usage'] as List;
          if (logs.any((l) => l['id'] == logId)) {
            dailyReportId = day['report_id'] as String;
            break;
          }
        }

        final fieldName = resourceType == 'machinery'
            ? 'production_value'
            : resourceType == 'material'
                ? 'quantity_used'
                : 'regular_hours';

        adjustments.add({
          'daily_report_id': dailyReportId,
          'resource_type': resourceType,
          'log_id': logId,
          'field_name': fieldName,
          'original_value': original,
          'adjusted_value': entry.value,
          'adjustment_reason': _pendingReasons[entry.key] ?? '',
        });
      }

      await service.proposeAdjustments(
        widget.comparisonId,
        adjustments,
        _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Adjustment proposal submitted for approval.'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _approveReconciliation() async {
    setState(() => _isSaving = true);
    try {
      final service = InspectionService(Supabase.instance.client);
      await service.approveReconciliation(widget.comparisonId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reconciliation approved. Values updated.'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _rejectReconciliation() async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Reject Reconciliation',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            border: OutlineInputBorder(),
          ),
          style: GoogleFonts.manrope(fontSize: 13, color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, reasonController.text.trim()),
            child: const Text('Reject',
                style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      setState(() => _isSaving = true);
      try {
        final service = InspectionService(Supabase.instance.client);
        await service.rejectReconciliation(widget.comparisonId, reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reconciliation rejected.'),
              backgroundColor: Colors.orange,
            ),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin User';
    final userEmail = currentUser?.email ?? '';
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      key: _mobileScaffoldKey,
      backgroundColor: const Color(0xFF0F172A),
      drawer: isMobile
          ? Drawer(
              backgroundColor: const Color(0xFF0F172A),
              child: Sidebar(
                userName: userName,
                userEmail: userEmail,
                currentPath:
                    '/projects/${widget.projectId}/weekly-inspections/${widget.inspectionId}/reconcile',
                onLogout: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) context.go('/signin');
                },
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            Sidebar(
              userName: userName,
              userEmail: userEmail,
              currentPath:
                  '/projects/${widget.projectId}/weekly-inspections/${widget.inspectionId}/reconcile',
              onLogout: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/signin');
              },
            ),
          Expanded(
            child: Column(
              children: [
                if (!isMobile)
                  TopHeader(
                    userName: userName,
                    breadcrumbs: [
                      'Operations',
                      'Projects',
                      _project?['title'] ?? 'Project',
                      'Weekly Inspections',
                      'Reconcile'
                    ],
                  ),
                if (isMobile) _buildMobileHeader(),
                Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.primaryGreen))
                        : _error != null
                            ? _buildError()
                            : _buildContent(isMobile)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      color: const Color(0xFF1E293B),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _mobileScaffoldKey.currentState?.openDrawer(),
            child: const Icon(Icons.menu, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Reconciliation',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isPendingApproval =
        _comparison?['status'] == 'pending_approval';
    final isProposedByCurrent =
        _comparison?['proposed_by'] == currentUserId;
    final serviceName =
        _comparison?['quote_services'] != null
            ? (_comparison!['quote_services'] as Map)['name'] ?? 'Unknown'
            : 'Unknown';
    final accumulatedDaily =
        (_comparison?['accumulated_daily_quantity'] as num?)?.toDouble() ?? 0;
    final inspectionMeasured =
        (_comparison?['inspection_measured_quantity'] as num?)?.toDouble() ?? 0;
    final currentStatus = _comparison?['status'] as String? ?? '';
    final reconciliationNotes =
        _comparison?['reconciliation_notes'] as String? ?? '';

    final remainingToAdjust = _totalAdjusted - inspectionMeasured;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back,
                    size: 16, color: AppTheme.slate400),
                const SizedBox(width: 6),
                Text(
                  'Back to Inspection',
                  style: GoogleFonts.manrope(
                    color: AppTheme.slate400,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Summary Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _targetDeviation.abs() > 0
                    ? Colors.orange.withOpacity(0.3)
                    : AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.compare_arrows,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reconciliation: $serviceName',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _summaryRow('Daily Report Accumulated',
                    accumulatedDaily.toStringAsFixed(2)),
                _summaryRow('Inspection Measured',
                    inspectionMeasured.toStringAsFixed(2)),
                const Divider(color: Color(0xFF334155), height: 24),
                _summaryRow('Deviation (to adjust)',
                    '${_targetDeviation.toStringAsFixed(2)}',
                    color: Colors.orange),
                const SizedBox(height: 4),
                _summaryRow('Total Adjusted (pending)',
                    '${_totalAdjusted.toStringAsFixed(2)}',
                    color: AppTheme.primaryGreen),
                _summaryRow('Remaining Deviation',
                    '${remainingToAdjust.toStringAsFixed(2)}',
                    color: remainingToAdjust.abs() < 0.01
                        ? AppTheme.primaryGreen
                        : Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (currentStatus == 'pending_approval') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.blue, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending Approval',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue,
                          ),
                        ),
                        if (reconciliationNotes.isNotEmpty)
                          Text(
                            reconciliationNotes,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: AppTheme.slate200,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isPendingApproval && !isProposedByCurrent) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _approveReconciliation,
                      child: Text(
                        'Approve',
                        style: GoogleFonts.manrope(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _rejectReconciliation,
                      child: Text(
                        'Reject',
                        style: GoogleFonts.manrope(
                          color: AppTheme.errorRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Day-by-day logs
          _buildSectionTitle('Daily Report Logs', Icons.list_alt),
          const SizedBox(height: 4),
          Text(
            'Review each day and adjust individual log entries.',
            style: GoogleFonts.manrope(
                fontSize: 11, color: AppTheme.slate500),
          ),
          const SizedBox(height: 12),

          if (_dailyLogs.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Center(
                child: Text(
                  'No daily report logs found in this period.',
                  style: GoogleFonts.manrope(
                    color: AppTheme.slate400,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...(_dailyLogs.map((day) => _buildDayCard(day))),

          const SizedBox(height: 24),

          // Reconciliation notes
          if (currentStatus != 'pending_approval') ...[
            _buildSectionTitle('Notes', Icons.notes),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Explain the reason for this reconciliation...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              style:
                  GoogleFonts.manrope(fontSize: 13, color: Colors.white),
            ),
            const SizedBox(height: 24),

            // Submit button
            Center(
              child: SizedBox(
                width: isMobile ? double.infinity : 360,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : _pendingAdjustments.isEmpty
                          ? null
                          : _submitProposal,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isSaving
                        ? 'Submitting...'
                        : 'Submit for Approval',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.slate400,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day) {
    final reportDate = day['report_date'] as String? ?? '';
    final reportId = day['report_id'] as String? ?? '';
    final machineryLogs =
        List<Map<String, dynamic>>.from(day['machinery_logs'] ?? []);
    final materialUsage =
        List<Map<String, dynamic>>.from(day['material_usage'] ?? []);

    final hasLogs = machineryLogs.isNotEmpty || materialUsage.isNotEmpty;
    if (!hasLogs) return const SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 768;

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
            const SizedBox(height: 10),

            // Machinery logs
            if (machineryLogs.isNotEmpty) ...[
              Text(
                'Machinery',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.slate400,
                ),
              ),
              const SizedBox(height: 6),
              ...(machineryLogs.map((log) =>
                  _buildLogRow('machinery', log, isMobile))),
              const Divider(color: Color(0xFF334155), height: 16),
            ],

            // Material usage
            if (materialUsage.isNotEmpty) ...[
              Text(
                'Materials',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.slate400,
                ),
              ),
              const SizedBox(height: 6),
              ...(materialUsage.map((log) =>
                  _buildLogRow('material', log, isMobile))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogRow(
      String resourceType, Map<String, dynamic> log, bool isMobile) {
    final logId = log['id'] as String;
    final key = '$resourceType:$logId';
    final original = _getOriginalValue(log, resourceType);
    final unit = _getLogUnit(log, resourceType);
    final hasAdjustment = _pendingAdjustments.containsKey(key);
    final adjustedValue = _pendingAdjustments[key] ?? original;

    String machineName = '';
    if (resourceType == 'machinery') {
      final pm = log['project_machinery'] as Map?;
      machineName = pm?['machinery_name'] as String? ?? '';
    } else {
      final pm = log['project_material'] as Map?;
      machineName = pm?['material_name'] as String? ?? '';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  machineName.isNotEmpty ? machineName : 'Unknown',
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
                    color: hasAdjustment
                        ? Colors.orange
                        : AppTheme.slate400,
                  ),
                ),
                if (hasAdjustment &&
                    _pendingReasons[key]?.isNotEmpty == true)
                  Text(
                    _pendingReasons[key]!,
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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () =>
                _showAdjustmentDialog(resourceType, logId, log),
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
