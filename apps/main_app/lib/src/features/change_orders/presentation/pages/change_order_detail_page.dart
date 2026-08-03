import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../providers/change_order_providers.dart';
import '../providers/change_order_controller.dart';
import '../utils/change_order_pdf_generator.dart';
import '../widgets/resource_conflict_dialog.dart';
import '../../../../shared/widgets/sidebar.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

class ChangeOrderDetailPage extends ConsumerStatefulWidget {
  final String projectId;
  final String coId;

  const ChangeOrderDetailPage({
    super.key,
    required this.projectId,
    required this.coId,
  });

  @override
  ConsumerState<ChangeOrderDetailPage> createState() =>
      _ChangeOrderDetailPageState();
}

class _ChangeOrderDetailPageState extends ConsumerState<ChangeOrderDetailPage> {
  final _fmt = NumberFormat('#,##0.00', 'en_US');
  String _projectTitle = '';
  String? _rejectionReason;

  @override
  void initState() {
    super.initState();
    _loadProjectName();
  }

  Future<void> _loadProjectName() async {
    try {
      final data = await Supabase.instance.client
          .from('projects')
          .select('title')
          .eq('id', widget.projectId)
          .maybeSingle();
      if (mounted && data != null) {
        setState(() => _projectTitle = data['title']?.toString() ?? '');
      }
    } catch (_) {}
  }
  Map<String, dynamic>? _cachedCo;
  List<Map<String, dynamic>> _cachedDetails = [];
  List<Map<String, dynamic>> _cachedDisruptions = [];
  List<Map<String, dynamic>> _cachedDisruptionServices = [];
  final Map<String, String?> _reasonMap = {};
  bool _reapplyingSchedule = false;

  Future<void> _printPdf(
    Map<String, dynamic> co,
    List<Map<String, dynamic>> details,
  ) async {
    final project = await Supabase.instance.client
        .from('projects')
        .select('title, client_name')
        .eq('id', widget.projectId)
        .single();

    final pdfBytes = await ChangeOrderPdfGenerator.generate(
      changeOrder: co,
      details: details,
      projectTitle: project['title'] ?? '',
      clientName: project['client_name'] ?? '',
      projectAddress: '',
      disruptionRecords: _cachedDisruptions,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'CO_${co['co_number'] ?? widget.coId}',
    );
  }

  Future<void> _loadDisruptions() async {
    final svc = ref.read(billingServiceProvider);
    final records = await svc.getDisruptionRecords(widget.coId);
    final services = await svc.getDisruptionServices(widget.coId);
    if (mounted) {
      final reasons = await ref.read(disruptionReasonListProvider.future);
      _reasonMap
        ..clear()
        ..addAll({for (final r in reasons) r['code'] as String: r['description'] as String?});
      setState(() {
        _cachedDisruptions = records;
        _cachedDisruptionServices = services;
      });
    }
  }

  Future<void> _approve() async {
    try {
      final result = await ref
          .read(changeOrderControllerProvider.notifier)
          .approveChangeOrder(widget.coId);

      if (result != null && mounted) {
        final conflicts = List<Map<String, dynamic>>.from(result['conflicts'] as List? ?? []);
        if (conflicts.isNotEmpty) {
          final resolved = await showSafeDialog(
            context: context,
            barrierColor: Colors.black.withOpacity(0.5),
            builder: (_) => ResourceConflictDialog(
              projectId: widget.projectId,
              conflicts: conflicts,
              onResolve: (conflict, strategy) async {
                try {
                  final svc = ref.read(billingServiceProvider);
                  await svc.resolveResourceConflict(widget.projectId, conflict, strategy);
                  return null;
                } catch (e) {
                  return e.toString();
                }
              },
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Change Order approved',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e', style: GoogleFonts.manrope()),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _reject() async {
    final reason = await showSafeDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reject Change Order',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Rejection Reason'),
          onChanged: (v) => _rejectionReason = v,
          style: GoogleFonts.manrope(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(ctx).pop(_rejectionReason ?? 'No reason provided'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: Text(
              'Reject',
              style: GoogleFonts.manrope(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (reason != null && mounted) {
      try {
        await ref
            .read(changeOrderControllerProvider.notifier)
            .rejectChangeOrder(widget.coId, reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Change Order rejected',
                style: GoogleFonts.manrope(color: Colors.white),
              ),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e', style: GoogleFonts.manrope()),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _reapplyScheduleImpact() async {
    setState(() => _reapplyingSchedule = true);
    try {
      final svc = ref.read(billingServiceProvider);
      // Reset applied_at flag so applyScheduleImpact can run again
      await Supabase.instance.client
          .from('change_order_disruptions')
          .update({'schedule_impact_applied_at': null})
          .eq('change_order_id', widget.coId);
      await svc.applyScheduleImpact(widget.coId);
      await _loadDisruptions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schedule impact re-applied', style: GoogleFonts.manrope(color: Colors.white)),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.manrope()), backgroundColor: AppTheme.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _reapplyingSchedule = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin';
    final userEmail = currentUser?.email ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1250;

    final coAsync = ref.watch(changeOrderDetailProvider(widget.coId));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      drawer: isMobile
          ? Sidebar(
              userName: userName,
              userEmail: userEmail,
              currentPath: '/projects/${widget.projectId}/change-orders',
              onLogout: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/signin');
              },
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            Sidebar(
              userName: userName,
              userEmail: userEmail,
              currentPath: '/projects/${widget.projectId}/change-orders',
              onLogout: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/signin');
              },
            ),
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(userName, isMobile),
                Expanded(
                  child: coAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        'Error: $e',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    data: (co) {
                      _cachedCo = co;
                      _cachedDetails =
                          (co['details'] as List<dynamic>?)
                              ?.cast<Map<String, dynamic>>() ??
                          [];
                      if (co['co_type'] == 'disruption' &&
                          _cachedDisruptions.isEmpty) {
                        _loadDisruptions();
                      }
                      return _buildContent(co, isMobile);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(String userName, bool isMobile) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.slate200)),
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: AppTheme.slate700),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () =>
                  context.go('/projects/${widget.projectId}/change-orders'),
              child: const Icon(
                Icons.arrow_back,
                size: 18,
                color: AppTheme.slate500,
              ),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 8),
            Text(
              _projectTitle.isNotEmpty ? _projectTitle : 'Project',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.slate500,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: AppTheme.slate400,
              ),
            ),
            Text(
              'Change Orders',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppTheme.slate500,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: AppTheme.slate400,
              ),
            ),
            Text(
              'Detail',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate900,
              ),
            ),
          ],
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {
              if (_cachedCo != null) _printPdf(_cachedCo!, _cachedDetails);
            },
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
            label: Text(
              'PDF',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> co, bool isMobile) {
    final details =
        (co['details'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final status = co['status']?.toString() ?? 'draft';
    final coType = co['co_type']?.toString() ?? 'scope_change';
    final adj = (co['adjustment_amount'] as num?)?.toDouble() ?? 0;
    final orig = (co['original_contract_amount'] as num?)?.toDouble() ?? 0;
    final newCt = (co['new_contract_amount'] as num?)?.toDouble() ?? 0;
    final sched = (co['schedule_days_change'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 20 : 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      co['co_number'] ?? '',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.slate900,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _coTypeBadge(coType),
                    const SizedBox(width: 8),
                    _statusBadge(status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  co['title'] ?? '',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate700,
                  ),
                ),
                const SizedBox(height: 8),
                if (co['description'] != null &&
                    (co['description'] as String).isNotEmpty)
                  Text(
                    co['description'],
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppTheme.slate500,
                    ),
                  ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFFE2E8F0)),
                  ),
                  child: isMobile
                      ? Column(
                          children: [
                            if (coType == 'disruption') ...[
                              _infoRow('Type', 'Disruption / Standby'),
                              if (_cachedDisruptions.isNotEmpty) ...[
                                _infoRow(
                                  'Reason',
                                  _reasonMap[
                                        _cachedDisruptions.first['disruption_type']
                                            as String?] ??
                                      '',
                                ),
                                _infoRow(
                                  'Start',
                                  _cachedDisruptions.first['start_date']
                                          ?.toString() ??
                                      '',
                                ),
                                _infoRow(
                                  'End',
                                  _cachedDisruptions.first['end_date']
                                          ?.toString() ??
                                      '',
                                ),
                              ],
                              const Divider(height: 16),
                            ],
                            _infoRow(
                              'Original Contract',
                              '\$${_fmt.format(orig)}',
                            ),
                            _infoRow(
                              'Adjustment',
                              '\$${_fmt.format(adj)}',
                              valueColor: adj >= 0
                                  ? AppTheme.primaryGreen
                                  : AppTheme.errorRed,
                            ),
                            const Divider(height: 16),
                            _infoRow(
                              'New Contract',
                              '\$${_fmt.format(newCt)}',
                              bold: true,
                            ),
                            if (coType == 'scope_change')
                              _infoRow(
                                'Schedule Change',
                                sched >= 0 ? '+$sched days' : '$sched days',
                              ),
                          ],
                        )
                      : Row(
                          children: [
                            if (coType == 'disruption') ...[
                              Expanded(
                                child: _infoRow('Type', 'Disruption / Standby'),
                              ),
                              const SizedBox(width: 24),
                              if (_cachedDisruptions.isNotEmpty) ...[
                                Expanded(
                                  child: _infoRow(
                                    'Reason',
                                    _reasonMap[
                                          _cachedDisruptions
                                              .first['disruption_type']
                                              as String?] ??
                                        '',
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _infoRow(
                                    'Period',
                                    '${_cachedDisruptions.first['start_date'] ?? ''} to ${_cachedDisruptions.first['end_date'] ?? ''}',
                                  ),
                                ),
                                const SizedBox(width: 24),
                              ],
                            ],
                            Expanded(
                              child: _infoRow(
                                'Original Contract',
                                '\$${_fmt.format(orig)}',
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _infoRow(
                                'Adjustment',
                                '\$${_fmt.format(adj)}',
                                valueColor: adj >= 0
                                    ? AppTheme.primaryGreen
                                    : AppTheme.errorRed,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: _infoRow(
                                'New Contract',
                                '\$${_fmt.format(newCt)}',
                                bold: true,
                              ),
                            ),
                            if (coType == 'scope_change') ...[
                              const SizedBox(width: 24),
                              Expanded(
                                child: _infoRow(
                                  'Schedule',
                                  sched >= 0 ? '+$sched days' : '$sched days',
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (details.isNotEmpty)
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isMobile)
                    Column(
                      children: details
                          .asMap()
                          .entries
                          .map((e) => _detailCard(e.key, e.value))
                          .toList(),
                    )
                  else
                    _detailsTable(details),
                  const SizedBox(height: 24),
                  _buildResourcePlans(details, isMobile),
                ],
              ),
            ),
          if (coType == 'disruption' && _cachedDisruptionServices.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.build_circle, size: 20, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Affected Services / Tasks',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ..._cachedDisruptionServices.map((s) {
                    final task = s['project_tasks'] as Map<String, dynamic>?;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withOpacity(0.15)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task?['name'] as String? ?? 'Unknown',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    (s['affectation_type'] as String? ?? '')
                                        .replaceAll('_', ' '),
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (s['notes'] != null && (s['notes'] as String).isNotEmpty)
                            Flexible(
                              child: Text(
                                s['notes'],
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: AppTheme.slate500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            // Schedule Impact section
            if (coType == 'disruption' && _hasScheduleImpact) ...[
              const SizedBox(height: 24),
              _buildScheduleImpact(),
            ],
          ],
          if (status == 'draft') ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(
                      '/projects/${widget.projectId}/change-orders/${widget.coId}/edit',
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(
                      'Edit',
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: BorderSide(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(
                            'Delete Change Order',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          content: Text(
                            'Are you sure? This action cannot be undone.',
                            style: GoogleFonts.manrope(),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.errorRed,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                'Delete',
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        await ref
                            .read(changeOrderControllerProvider.notifier)
                            .deleteChangeOrder(widget.coId);
                        if (mounted) {
                          context.go(
                            '/projects/${widget.projectId}/change-orders',
                          );
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: AppTheme.errorRed,
                    ),
                    label: Text(
                      'Delete',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.errorRed,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorRed,
                      side: BorderSide(
                        color: AppTheme.errorRed.withOpacity(0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await ref
                            .read(changeOrderControllerProvider.notifier)
                            .submitChangeOrder(widget.coId);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Change Order submitted',
                                style: GoogleFonts.manrope(
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: AppTheme.primaryGreen,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error: $e',
                                style: GoogleFonts.manrope(),
                              ),
                              backgroundColor: AppTheme.errorRed,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: Text(
                      'Submit for Approval',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (status == 'submitted') ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _approve,
                    icon: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Approve',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _reject,
                    icon: const Icon(
                      Icons.cancel_outlined,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Reject',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorRed,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (status == 'rejected' && co['rejection_reason'] != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.errorRed.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rejection Reason',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppTheme.errorRed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    co['rejection_reason'],
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: AppTheme.slate700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.slate500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? AppTheme.slate900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsTable(List<Map<String, dynamic>> details) {
    final hasStandby = details.any((d) {
      final lt = d['line_type'] as String?;
      return lt == 'standby_machinery' ||
          lt == 'standby_labor' ||
          lt == 'standby_material';
    });

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(
            label: Text(
              '#',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          const DataColumn(
            label: Text(
              'Service',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          const DataColumn(
            label: Text(
              'Type',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          if (hasStandby)
            const DataColumn(
              label: Text(
                'Hours/Units',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              numeric: true,
            )
          else
            const DataColumn(
              label: Text(
                'Qty',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              numeric: true,
            ),
          const DataColumn(
            label: Text(
              'Rate/Price',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            numeric: true,
          ),
          const DataColumn(
            label: Text(
              'Total',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            numeric: true,
          ),
        ],
        rows: details.asMap().entries.map((e) {
          final i = e.key + 1;
          final d = e.value;
          final lt = d['line_type'] as String?;
          final qty = (d['quantity_change'] as num?)?.toDouble() ?? 0;
          final up = (d['unit_price'] as num?)?.toDouble() ?? 0;

          double qtyDisplay;
          double rate;
          double total;
          if (lt == 'standby_machinery' || lt == 'standby_labor') {
            qtyDisplay = (d['standby_hours'] as num?)?.toDouble() ?? 0;
            rate = (d['standby_rate'] as num?)?.toDouble() ?? 0;
            total = qtyDisplay * rate;
          } else if (lt == 'standby_material') {
            qtyDisplay = (d['quantity_lost'] as num?)?.toDouble() ?? 0;
            rate = (d['replacement_unit_cost'] as num?)?.toDouble() ?? 0;
            total = qtyDisplay * rate;
          } else {
            qtyDisplay = qty;
            rate = up;
            total = qty * up;
          }

          return DataRow(
            cells: [
              DataCell(Text('$i', style: GoogleFonts.manrope(fontSize: 12))),
              DataCell(
                Text(
                  d['service_name'] ?? '',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  lt?.replaceAll('_', ' ') ?? '',
                  style: GoogleFonts.manrope(fontSize: 11),
                ),
              ),
              DataCell(
                Text(
                  qtyDisplay.toString(),
                  style: GoogleFonts.manrope(fontSize: 12),
                ),
              ),
              DataCell(
                Text(
                  '\$${_fmt.format(rate)}',
                  style: GoogleFonts.manrope(fontSize: 12),
                ),
              ),
              DataCell(
                Text(
                  '\$${_fmt.format(total)}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _detailCard(int i, Map<String, dynamic> d) {
    final lt = d['line_type'] as String?;
    final qty = (d['quantity_change'] as num?)?.toDouble() ?? 0;
    final up = (d['unit_price'] as num?)?.toDouble() ?? 0;

    double qtyDisplay;
    double rate;
    double total;
    if (lt == 'standby_machinery' || lt == 'standby_labor') {
      qtyDisplay = (d['standby_hours'] as num?)?.toDouble() ?? 0;
      rate = (d['standby_rate'] as num?)?.toDouble() ?? 0;
      total = qtyDisplay * rate;
    } else if (lt == 'standby_material') {
      qtyDisplay = (d['quantity_lost'] as num?)?.toDouble() ?? 0;
      rate = (d['replacement_unit_cost'] as num?)?.toDouble() ?? 0;
      total = qtyDisplay * rate;
    } else {
      qtyDisplay = qty;
      rate = up;
      total = qty * up;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.slate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${i + 1}. ${d['service_name'] ?? ''}',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
          ),
          if (lt == 'standby_machinery' || lt == 'standby_labor')
            Text(
              '${lt?.replaceAll('_', ' ') ?? ''} | Hours: $qtyDisplay @ \$${_fmt.format(rate)}/hr | Total: \$${_fmt.format(total)}',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: AppTheme.slate500,
              ),
            )
          else if (lt == 'standby_material')
            Text(
              '${lt?.replaceAll('_', ' ') ?? ''} | Lost: $qtyDisplay @ \$${_fmt.format(rate)}/ea | Total: \$${_fmt.format(total)}',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: AppTheme.slate500,
              ),
            )
          else
            Text(
              '${lt?.replaceAll('_', ' ') ?? ''} | Qty: $qtyDisplay | \$${_fmt.format(rate)} ea. | Total: \$${_fmt.format(total)}',
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: AppTheme.slate500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = AppTheme.primaryGreen;
        break;
      case 'rejected':
        color = AppTheme.errorRed;
        break;
      case 'submitted':
        color = const Color(0xFFF59E0B);
        break;
      default:
        color = AppTheme.slate400;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _coTypeBadge(String coType) {
    final isDisruption = coType == 'disruption';
    final color = isDisruption
        ? const Color(0xFF8B5CF6)
        : AppTheme.primaryGreen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        isDisruption ? 'STANDBY' : 'SCOPE',
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildResourcePlans(
      List<Map<String, dynamic>> details, bool isMobile) {
    final hasPlans = details.any((d) {
      final plans = d['resource_plans'] as List<dynamic>? ?? [];
      return plans.isNotEmpty;
    });
    if (!hasPlans) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, size: 18, color: Colors.indigo.shade600),
              const SizedBox(width: 8),
              Text(
                'Baseline Impact (Resource Plans)',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.indigo.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...details
              .where((d) =>
                  (d['resource_plans'] as List<dynamic>?)?.isNotEmpty ?? false)
              .map((d) {
            final plans = d['resource_plans'] as List<dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d['service_name'] as String? ?? '',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...plans.map((p) {
                    final plan = p as Map<String, dynamic>;
                    final factor =
                        (plan['proportional_factor'] as num?)?.toDouble();
                    if (factor != null) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                plan['resource_type'] as String? ?? '',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.indigo,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${factor}x proportional',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.indigo.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              plan['resource_type'] as String? ?? '',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${plan['resource_name'] ?? 'Resource'} x${plan['quantity'] ?? 1}',
                            style: GoogleFonts.manrope(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  bool get _hasScheduleImpact {
    if (_cachedDisruptions.isNotEmpty) return true;
    for (final s in _cachedDisruptionServices) {
      final delayDays = (s['delay_days'] as num?)?.toInt() ?? 0;
      if (delayDays > 0) return true;
    }
    return false;
  }

  Widget _buildScheduleImpact() {
    if (_cachedDisruptions.isEmpty) return const SizedBox.shrink();

    final disruption = _cachedDisruptions.first;
    final startDate = disruption['start_date']?.toString() ?? '';
    final endDate = disruption['end_date']?.toString() ?? '';
    int totalDelay = 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 20, color: Colors.indigo.shade700),
              const SizedBox(width: 8),
              Text(
                'Schedule Impact',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.indigo.shade900,
                ),
              ),
              const Spacer(),
              if (_cachedCo?['status'] == 'approved')
                Row(mainAxisSize: MainAxisSize.min, children: [
                  if (totalDelay > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 12, color: AppTheme.primaryGreen),
                          const SizedBox(width: 4),
                          Text('Applied', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryGreen)),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 28,
                    child: OutlinedButton.icon(
                      onPressed: _reapplyingSchedule ? null : _reapplyScheduleImpact,
                      icon: _reapplyingSchedule
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo))
                          : const Icon(Icons.refresh, size: 12),
                      label: Text(_reapplyingSchedule ? 'Applying...' : 'Re-apply', style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.indigo.shade700)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        side: BorderSide(color: Colors.indigo.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ),
                ]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _impactMetric('Disruption Period', '$startDate — $endDate', Colors.indigo),
              const SizedBox(width: 24),
              _impactMetric('Type', (disruption['disruption_type'] as String? ?? '').replaceAll('_', ' '), Colors.indigo),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Affected Services',
            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.slate500),
          ),
          const SizedBox(height: 8),
          ..._cachedDisruptionServices.map((s) {
            final delayDays = (s['delay_days'] as num?)?.toInt() ?? 0;
            totalDelay += delayDays;
            final originalEnd = s['original_end_date']?.toString() ?? '';
            final extendedEnd = s['extended_end_date']?.toString() ?? '';
            final task = s['project_tasks'] as Map<String, dynamic>?;
            final taskName = task?['name'] as String? ?? 'Unknown';

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          taskName,
                          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900),
                        ),
                        if (originalEnd.isNotEmpty && extendedEnd.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Text(
                                  originalEnd,
                                  style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate400, decoration: TextDecoration.lineThrough),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(Icons.arrow_forward, size: 12, color: Colors.indigo.shade400),
                                ),
                                Text(
                                  extendedEnd,
                                  style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.indigo.shade600),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (delayDays > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+$delayDays day(s)',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          if (totalDelay > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.indigo.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Total schedule extension: +$totalDelay working day(s). Project end date extended accordingly. SPI is calculated against the baseline end date.',
                      style: GoogleFonts.manrope(fontSize: 11, color: Colors.indigo.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _impactMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.slate500)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
