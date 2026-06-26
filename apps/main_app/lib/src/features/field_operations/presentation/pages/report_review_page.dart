import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';

class ReportReviewPage extends ConsumerStatefulWidget {
  final String projectId;
  final String reportId;
  const ReportReviewPage({super.key, required this.projectId, required this.reportId});

  @override
  ConsumerState<ReportReviewPage> createState() => _ReportReviewPageState();
}

class _ReportReviewPageState extends ConsumerState<ReportReviewPage> {
  Map<String, dynamic>? _report;
  List<Map<String, dynamic>> _laborLogs = [];
  List<Map<String, dynamic>> _machineryLogs = [];
  List<Map<String, dynamic>> _materialUsage = [];
  String _projectName = '';
  bool _isLoading = true;
  bool _isAdmin = false;
  final TextEditingController _rejectReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _rejectReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final service = ref.read(dailyReportServiceProvider);
      final report = await service.getReportById(widget.reportId);
      final labor = await service.getLaborLogsForReport(widget.reportId);
      final machinery = await service.getMachineryLogsForReport(widget.reportId);
      final material = await service.getMaterialUsageForReport(widget.reportId);

      final proj = await Supabase.instance.client
          .from('projects')
          .select('title')
          .eq('id', widget.projectId)
          .maybeSingle();
      final userId = Supabase.instance.client.auth.currentUser?.id;
      bool admin = false;
      if (userId != null) {
        final profile = await Supabase.instance.client
            .from('profiles').select('role').eq('id', userId).maybeSingle();
        admin = profile?['role'] == 'Admin';
      }

      if (mounted) {
        setState(() {
          _report = report;
          _laborLogs = labor;
          _machineryLogs = machinery;
          _materialUsage = material;
          _projectName = proj?['title'] ?? '';
          _isAdmin = admin;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approve() async {
    try {
      await ref.read(dailyReportServiceProvider).approveReport(widget.reportId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report approved'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Future<void> _reject() async {
    final reason = _rejectReasonController.text.trim();
    final confirm = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Report', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          reason.isNotEmpty
              ? 'Send report back with this reason:\n\n"$reason"'
              : 'Send report back for revisions without a reason?',
          style: GoogleFonts.manrope(color: const Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.manrope(color: AppTheme.slate400))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: Text('Reject', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(dailyReportServiceProvider).rejectReport(widget.reportId, reason: reason.isNotEmpty ? reason : null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report rejected'), backgroundColor: Colors.orange),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) { return dateStr; }
  }

  String _fmtCurrency(dynamic val) {
    if (val == null) return '-';
    final d = (val as num).toDouble();
    return '\$${d.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? 'Admin User';
    final userEmail = user?.email ?? '';
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: isMobile
          ? AppBar(
              backgroundColor: const Color(0xFF1E293B),
              title: Text('Report Review', style: GoogleFonts.manrope(fontWeight: FontWeight.w700, color: Colors.white)),
              leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            Sidebar(
              userName: userName, userEmail: userEmail, currentPath: '/daily-reports/pending',
              onLogout: () async { await Supabase.instance.client.auth.signOut(); if (context.mounted) context.go('/signin'); },
            ),
          Expanded(
            child: Column(
              children: [
                if (!isMobile) TopHeader(userName: userName, breadcrumbs: const ['Daily Reports', 'Pending Approvals', 'Review']),
                Expanded(child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                    : _buildContent(isMobile)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    final r = _report;
    if (r == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text('Could not load report', style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 15)),
        ]),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: () => context.pop(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back, size: 16, color: AppTheme.slate400),
                const SizedBox(width: 6),
                Text('Back to Pending Approvals', style: GoogleFonts.manrope(color: AppTheme.slate400, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text('DAILY REPORT REVIEW', style: GoogleFonts.manrope(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(_projectName, style: GoogleFonts.manrope(fontSize: 16, color: AppTheme.slate400, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),

          // Meta info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _metaRow('Date', _formatDate(r['report_date'])),
                const SizedBox(height: 6),
                _metaRow('Status', (r['status'] as String?)?.toUpperCase() ?? ''),
              ]),
              const SizedBox(width: 48),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _metaRow('Weather', r['weather_condition'] ?? '-'),
                const SizedBox(height: 6),
                _metaRow('Supervisor', r['supervisor_id']?.toString()?.substring(0, 8) ?? '-'),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // Notes
          if ((r['general_notes'] as String?)?.isNotEmpty == true) ...[
            _sectionHeader('Notes'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF334155))),
              child: Text(r['general_notes'] as String? ?? '', style: GoogleFonts.manrope(color: const Color(0xFFCBD5E1), fontSize: 13)),
            ),
            const SizedBox(height: 20),
          ],

          // Labor section
          if (_laborLogs.isNotEmpty) ...[
            _sectionHeader('Labor (${_laborLogs.length} workers)'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
              child: Column(children: [
                ..._laborLogs.map((l) {
                  final bm = l['break_minutes'] as int? ?? 0;
                  final tn = (l['total_net_hours'] as num?)?.toDouble() ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Expanded(flex: 3, child: Text(l['workers']?['full_name'] ?? 'Worker ${l['worker_id']?.toString().substring(0, 6)}', style: GoogleFonts.manrope(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                      Text('${tn.toStringAsFixed(1)}h', style: GoogleFonts.manrope(color: AppTheme.slate200, fontSize: 13)),
                      if (bm > 0) Text(' (-${bm}m)', style: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 11)),
                      if ((l['regular_hours'] as num?)?.toDouble() != 0 || (l['overtime_hours'] as num?)?.toDouble() != 0) ...[
                        const SizedBox(width: 8),
                        Text('${(l['regular_hours'] as num?)?.toDouble() ?? 0}h', style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13)),
                        if ((l['overtime_hours'] as num?)?.toDouble() != 0)
                          Text(' + ${(l['overtime_hours'] as num?)?.toDouble()}h OT', style: GoogleFonts.manrope(color: Colors.orange, fontSize: 13)),
                      ],
                    ]),
                  );
                }),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // Machinery section
          if (_machineryLogs.isNotEmpty) ...[
            _sectionHeader('Machinery (${_machineryLogs.length} units)'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
              child: Column(children: [
                ..._machineryLogs.map((m) {
                  final mach = m['machinery'] as Map<String, dynamic>?;
                  final op = m['workers'] as Map<String, dynamic>?;
                  final prod = (m['production_value'] as num?)?.toDouble() ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(flex: 2, child: Text(mach?['description'] ?? 'Machine', style: GoogleFonts.manrope(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                        Text('${(m['total_hours'] as num?)?.toDouble() ?? 0}h', style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13)),
                        if (prod > 0) ...[
                          const SizedBox(width: 12),
                          Text('${prod.toStringAsFixed(0)} trips', style: GoogleFonts.manrope(color: AppTheme.primaryGreen, fontSize: 13)),
                        ],
                      ]),
                      if (op != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('Operator: ${op['full_name'] ?? op['id_number'] ?? '-'}', style: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 11)),
                        ),
                    ]),
                  );
                }),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // Materials section
          if (_materialUsage.isNotEmpty) ...[
            _sectionHeader('Materials (${_materialUsage.length} items)'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF334155))),
              child: Column(children: [
                ..._materialUsage.map((u) {
                  final mat = u['materials'] as Map<String, dynamic>?;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Expanded(flex: 2, child: Text(mat?['description'] ?? 'Material', style: GoogleFonts.manrope(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
                      Text('${(u['quantity_used'] as num?)?.toDouble() ?? 0} ${mat?['unit'] ?? ''}', style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13)),
                    ]),
                  );
                }),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          if (_buildEvidencePhotos(r['evidence_photos']) case final photos?) photos,
          if (_isAdmin) _buildDecisionSection(r['status'] as String?),
        ],
      ),
    );
  }

  Widget? _buildEvidencePhotos(dynamic evidencePhotos) {
    final photos = evidencePhotos as List<dynamic>?;
    if (photos == null || photos.isEmpty) return null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Evidence Photos'),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ...photos.map((p) {
          final url = p is String ? p : (p as Map)['url'] as String?;
          if (url == null) return const SizedBox.shrink();
          return GestureDetector(
            onTap: () => showSafeDialog(
              context: context,
              builder: (_) => Dialog(
                backgroundColor: Colors.black,
                child: InteractiveViewer(
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
            ),
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
                image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
              ),
            ),
          );
        }),
      ]),
      const SizedBox(height: 24),
    ]);
  }

  Widget _buildDecisionSection(String? status) {
    if (status == 'submitted') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DECISION', style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 12),
          TextField(
            controller: _rejectReasonController, maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Rejection reason (optional)',
              hintStyle: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 13),
              filled: true, fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(14),
            ),
            style: GoogleFonts.manrope(color: Colors.white, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: _reject, icon: const Icon(Icons.close, size: 18),
              label: Text('REJECT', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14)),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            )),
            const SizedBox(width: 12),
            Expanded(child: FilledButton.icon(
              onPressed: _approve, icon: const Icon(Icons.check, size: 18),
              label: Text('APPROVE', style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 14)),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryGreen, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            )),
          ]),
        ]),
      );
    }
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status == 'approved' ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(status == 'approved' ? Icons.check_circle : Icons.cancel, color: status == 'approved' ? Colors.green : Colors.orange, size: 24),
        const SizedBox(width: 12),
        Text('This report was ${status ?? 'processed'}', style: GoogleFonts.manrope(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.slate400, letterSpacing: 0.5)),
    );
  }

  Widget _metaRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ', style: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(value, style: GoogleFonts.manrope(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
