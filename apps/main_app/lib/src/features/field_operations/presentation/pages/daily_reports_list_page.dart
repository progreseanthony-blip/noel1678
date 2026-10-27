import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

class DailyReportsListPage extends ConsumerStatefulWidget {
  final String projectId;

  const DailyReportsListPage({super.key, required this.projectId});

  @override
  ConsumerState<DailyReportsListPage> createState() =>
      _DailyReportsListPageState();
}

class _DailyReportsListPageState extends ConsumerState<DailyReportsListPage> {
  List<Map<String, dynamic>> _reports = [];
  Map<String, dynamic>? _project;
  bool _isLoading = true;
  bool _isAdmin = false;
  bool _isForeman = false;
  bool _canDelete = false;
  Map<String, List<String>> _crewStatuses = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final service = DailyExecutionService(Supabase.instance.client);
      final access = await AccessService(Supabase.instance.client).load();
      final reports = await service.reports(widget.projectId);
      final crewStatuses = <String, List<String>>{};
      if ((access.isAdmin || access.isSupervisor) && reports.isNotEmpty) {
        final sections = await Supabase.instance.client
            .from('daily_report_sections')
            .select('daily_report_id,status')
            .in_(
              'daily_report_id',
              reports.map((r) => r['id'] as String).toList(),
            );
        for (final section in sections) {
          final report = section['daily_report_id'] as String;
          crewStatuses
              .putIfAbsent(report, () => [])
              .add(section['status'] as String);
        }
      }
      final entry = await service.entry(
        widget.projectId,
        DateTime.now().toIso8601String().split('T')[0],
      );

      if (!mounted) return;
      setState(() {
        _reports = reports;
        _crewStatuses = crewStatuses;
        _project = Map<String, dynamic>.from(entry['project'] as Map);
        _isAdmin = access.isAdmin || access.isSupervisor;
        _isForeman = access.isForeman;
        _canDelete = access.isAdmin;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReport(String id) async {
    final confirm = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(dailyReportServiceProvider).deleteReport(id);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting: $e', style: GoogleFonts.manrope()),
        ),
      );
    }
  }

  Future<void> _approveReport(String id) async {
    try {
      await ref.read(dailyReportServiceProvider).approveReport(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report approved'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _rejectReport(String id) async {
    final confirm = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Report'),
        content: const Text('Send back for revisions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(dailyReportServiceProvider).rejectReport(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report rejected'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'draft':
        return Colors.orange;
      case 'submitted':
        return Colors.blue;
      case 'approved':
        return AppTheme.primaryGreen;
      case 'rejected':
        return AppTheme.errorRed;
      default:
        return AppTheme.slate400;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'submitted':
        return 'Submitted';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectName = _project?['title'] as String? ?? 'Project';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Daily Reports — $projectName',
          style: GoogleFonts.manrope(fontSize: 14),
        ),
        actions: [
          if (!_isForeman)
            TextButton.icon(
              onPressed: () async {
                await context.push('/projects/${widget.projectId}/incidents');
                if (mounted) _loadData();
              },
              icon: const Icon(Icons.warning_amber_rounded, size: 18),
              label: Text(
                'Incidents',
                style: GoogleFonts.manrope(fontSize: 13),
              ),
              style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                'Error: $_error',
                style: GoogleFonts.manrope(color: AppTheme.errorRed),
              ),
            )
          : _reports.isEmpty
          ? _emptyState()
          : _buildReportList(),
      floatingActionButton: _project?['status'] != 'active'
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await context.push(
                  '/projects/${widget.projectId}/daily-report',
                );
                if (mounted) _loadData();
              },
              icon: const Icon(Icons.add),
              label: const Text('New Report'),
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
    );
  }

  Widget _compactAction({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      onPressed: onPressed,
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: AppTheme.slate400),
          const SizedBox(height: 16),
          Text(
            'No daily reports yet',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to create your first report',
            style: GoogleFonts.manrope(color: AppTheme.slate400),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final r = _reports[i];
        final status = r['status'] as String?;
        final isDraft = status == 'draft';
        final crewStatuses = _crewStatuses[r['id']] ?? const <String>[];
        final pendingCrews = crewStatuses.where((s) => s == 'submitted').length;
        final approvedCrews = crewStatuses.where((s) => s == 'approved').length;
        final allRecordedCrewsApproved =
            crewStatuses.isNotEmpty && approvedCrews == crewStatuses.length;

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: AppTheme.slate200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _statusColor(status).withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDraft ? Icons.edit_note : Icons.check_circle_outline,
                color: _statusColor(status),
                size: 22,
              ),
            ),
            title: Text(
              _formatDate(r['report_date']),
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate900,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        r['has_sections'] == true
                            ? 'Consolidated: ${_statusLabel(status)}'
                            : _statusLabel(status),
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(status),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (r['weather_condition'] != null)
                      Flexible(
                        child: Text(
                          r['weather_condition'] as String,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: AppTheme.slate400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                if (crewStatuses.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${_isForeman ? 'Your crew reports' : 'Crew reports'}: $approvedCrews/${crewStatuses.length} approved',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: allRecordedCrewsApproved
                            ? AppTheme.primaryGreen
                            : AppTheme.slate500,
                      ),
                    ),
                  ),
                if (_isAdmin &&
                    allRecordedCrewsApproved &&
                    (isDraft || status == 'rejected'))
                  TextButton.icon(
                    onPressed: () async {
                      await context.push(
                        '/projects/${widget.projectId}/daily-report?reportId=${r['id']}',
                      );
                      if (mounted) _loadData();
                    },
                    icon: const Icon(Icons.assignment_outlined, size: 18),
                    label: const Text('Complete consolidated report'),
                  ),
                if (_isAdmin &&
                    pendingCrews > 0 &&
                    (isDraft || status == 'rejected'))
                  TextButton.icon(
                    onPressed: () async {
                      await context.push(
                        '/projects/${widget.projectId}/daily-report?reportId=${r['id']}',
                      );
                      if (mounted) _loadData();
                    },
                    icon: const Icon(Icons.fact_check_outlined, size: 18),
                    label: Text(
                      '$pendingCrews crew report${pendingCrews == 1 ? '' : 's'} awaiting review',
                    ),
                  ),
              ],
            ),
            trailing: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status == 'submitted' &&
                      _isAdmin &&
                      r['supervisor_id'] !=
                          Supabase.instance.client.auth.currentUser?.id &&
                      r['submitted_by'] !=
                          Supabase.instance.client.auth.currentUser?.id) ...[
                    _compactAction(
                      icon: Icons.check_circle,
                      tooltip: 'Approve',
                      color: AppTheme.primaryGreen,
                      onPressed: () => _approveReport(r['id'] as String),
                    ),
                    _compactAction(
                      icon: Icons.cancel,
                      tooltip: 'Reject',
                      color: AppTheme.errorRed,
                      onPressed: () => _rejectReport(r['id'] as String),
                    ),
                  ],
                  if (isDraft || status == 'rejected')
                    _compactAction(
                      icon: Icons.edit,
                      tooltip: 'Edit',
                      color: AppTheme.primaryGreen,
                      onPressed: () async {
                        await context.push(
                          '/projects/${widget.projectId}/daily-report?reportId=${r['id']}',
                        );
                        if (mounted) _loadData();
                      },
                    ),
                  if (status == 'submitted' || status == 'approved')
                    _compactAction(
                      icon: Icons.visibility,
                      tooltip: 'View',
                      color: AppTheme.slate500,
                      onPressed: () async {
                        await context.push(
                          '/projects/${widget.projectId}/daily-report?reportId=${r['id']}',
                        );
                        if (mounted) _loadData();
                      },
                    ),
                  if (isDraft && _canDelete && r['has_sections'] != true)
                    _compactAction(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete',
                      color: AppTheme.errorRed,
                      onPressed: () => _deleteReport(r['id'] as String),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
