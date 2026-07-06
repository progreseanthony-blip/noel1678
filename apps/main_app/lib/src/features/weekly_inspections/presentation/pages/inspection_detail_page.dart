import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_data/noel_data.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';
import '../widgets/comparison_result_row.dart';

class InspectionDetailPage extends StatefulWidget {
  final String projectId;
  final String inspectionId;
  const InspectionDetailPage(
      {super.key, required this.projectId, required this.inspectionId});

  @override
  State<InspectionDetailPage> createState() => _InspectionDetailPageState();
}

class _InspectionDetailPageState extends State<InspectionDetailPage> {
  Map<String, dynamic>? _inspection;
  List<Map<String, dynamic>> _details = [];
  List<Map<String, dynamic>> _comparisons = [];
  List<Map<String, dynamic>> _adjustments = [];
  Map<String, dynamic>? _project;
  bool _isLoading = true;
  String? _error;
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    _loadData();
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

      final inspection =
          await service.getInspectionById(widget.inspectionId);
      final details =
          await service.getInspectionDetails(widget.inspectionId);
      final comparisons = await service
          .getComparisonsByInspection(widget.inspectionId);

      List<Map<String, dynamic>> adjustments = [];
      for (final comp in comparisons) {
        final compId = comp['id'] as String;
        final adj = await service.getAdjustmentsForComparison(compId);
        adjustments.addAll(adj);
      }

      if (mounted) {
        setState(() {
          _project = project;
          _inspection = inspection;
          _details = details;
          _comparisons = comparisons;
          _adjustments = adjustments;
          _isLoading = false;
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

  void _navigateToReconciliation(String comparisonId, String serviceId) {
    context.push(
      '/projects/${widget.projectId}/weekly-inspections/${widget.inspectionId}/reconcile?comparisonId=$comparisonId&serviceId=$serviceId',
    );
  }

  Future<void> _deleteInspection() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Delete Inspection',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this inspection? This action cannot be undone.',
          style: GoogleFonts.manrope(color: AppTheme.slate400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final service = InspectionService(Supabase.instance.client);
      await service.deleteInspection(widget.inspectionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inspection deleted.'),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
        context.pop();
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
                    '/projects/${widget.projectId}/weekly-inspections/${widget.inspectionId}',
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
                  '/projects/${widget.projectId}/weekly-inspections/${widget.inspectionId}',
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
                      'Detail'
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
            'Inspection Detail',
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
    final status = _inspection?['status'] as String? ?? 'draft';
    final method = _inspection?['method'] as String? ?? 'drone';
    final inspectorName =
        (_inspection?['profiles'] as Map?)?['name'] ?? 'Unknown';
    final date = _inspection?['inspection_date'] as String? ?? '';
    final notes = _inspection?['general_notes'] as String? ?? '';
    final evidenceFiles =
        List<Map<String, dynamic>>.from(_inspection?['evidence_files'] ?? []);

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
                  'Back to Inspections',
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

          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatusBadge(status),
                    const Spacer(),
                    _buildMethodBadge(method),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Inspection — ${_dateFormat.format(DateTime.tryParse(date) ?? DateTime.now())}',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Inspector: $inspectorName',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: AppTheme.slate400,
                  ),
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    notes,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppTheme.slate200,
                    ),
                  ),
                ],
                if (status == 'draft' || status == 'submitted') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (status == 'draft' || status == 'submitted')
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: OutlinedButton.icon(
                              onPressed: () => context.push(
                                '/projects/${widget.projectId}/weekly-inspections/${widget.inspectionId}/edit',
                              ),
                              icon: const Icon(Icons.edit, size: 16),
                              label: Text(
                                'Edit',
                                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                side: const BorderSide(color: Colors.blue),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                      if (status == 'draft') ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 36,
                            child: OutlinedButton.icon(
                              onPressed: () => _deleteInspection(),
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: Text(
                                'Delete',
                                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.errorRed,
                                side: const BorderSide(color: AppTheme.errorRed),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Evidence section
          if (evidenceFiles.isNotEmpty) ...[
            _buildSectionTitle('Evidence Files', Icons.photo_library_outlined),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                children: evidenceFiles.map((e) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          e['type'] == 'photo'
                              ? Icons.image
                              : Icons.insert_drive_file,
                          size: 16,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e['description'] ?? e['url'] ?? '',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppTheme.slate200,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Comparison results
          _buildSectionTitle('Comparison Results', Icons.compare_arrows),
          const SizedBox(height: 8),
          if (_comparisons.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'No comparison data available.\nRun comparison to see results.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        color: AppTheme.slate400,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        try {
                          final service = InspectionService(
                              Supabase.instance.client);
                          await service
                              .runComparison(widget.inspectionId);
                          await _loadData();
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppTheme.errorRed,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(
                        'Run Comparison',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: const Color(0xFF0F172A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_comparisons.map((comp) {
              final compId = comp['id'] as String;
              final serviceId = comp['quote_service_id'] as String;
              final exceeds = comp['exceeds_threshold'] == true;
              final status = comp['status'] as String? ?? 'pending';
              final canReconcile =
                  status == 'exceeds_threshold' && exceeds;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ComparisonResultRow(
                  comparison: comp,
                  onReconcile: canReconcile
                      ? () => _navigateToReconciliation(compId, serviceId)
                      : null,
                  onRetryComparison: () async {
                    final service = InspectionService(
                        Supabase.instance.client);
                    await service.runComparison(widget.inspectionId);
                    _loadData();
                  },
                ),
              );
            })),

          const SizedBox(height: 16),

          // Adjustments history
          if (_adjustments.isNotEmpty) ...[
            _buildSectionTitle(
                'Adjustment History', Icons.history),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                children: _adjustments.map((adj) {
                  final reportDate = adj['daily_reports'] != null
                      ? (adj['daily_reports'] as Map)['report_date']
                      : 'N/A';
                  final resourceType = adj['resource_type'] ?? '';
                  final original = (adj['original_value'] as num?)?.toDouble() ?? 0;
                  final adjusted = (adj['adjusted_value'] as num?)?.toDouble() ?? 0;
                  final reason = adj['adjustment_reason'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          resourceType == 'machinery'
                              ? Icons.precision_manufacturing
                              : resourceType == 'material'
                                  ? Icons.inventory
                                  : Icons.person,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$reportDate — ${resourceType.toUpperCase()}',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.orange,
                                ),
                              ),
                              Text(
                                'Adjusted: $original → $adjusted',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  color: AppTheme.slate200,
                                ),
                              ),
                              if (reason.isNotEmpty)
                                Text(
                                  reason,
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    color: AppTheme.slate500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 40),
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

  Widget _buildStatusBadge(String status) {
    final color = status == 'reconciled'
        ? AppTheme.primaryGreen
        : status == 'approved'
            ? Colors.blue
            : status == 'submitted'
                ? Colors.orange
                : AppTheme.slate400;
    final label = status.replaceAll('_', ' ').toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
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

  Widget _buildMethodBadge(String method) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.satellite_alt, size: 12, color: AppTheme.primaryGreen),
          const SizedBox(width: 4),
          Text(
            method.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryGreen,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
