import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

class PendingApprovalsPage extends ConsumerStatefulWidget {
  const PendingApprovalsPage({super.key});

  @override
  ConsumerState<PendingApprovalsPage> createState() => _PendingApprovalsPageState();
}

class _PendingApprovalsPageState extends ConsumerState<PendingApprovalsPage> {
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(dailyReportServiceProvider);
      _reports = await service.getSubmittedReports();

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .single();
        _isAdmin = profile['role'] == 'Admin';
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _approve(String id) async {
    try {
      await ref.read(dailyReportServiceProvider).approveReport(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report approved'), backgroundColor: AppTheme.primaryGreen),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
        );
      }
    }
  }

  Future<void> _reject(String id) async {
    final reason = await showSafeDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Report'),
        content: const Text('Send the report back for revisions. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'reject'),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null) return;
    try {
      await ref.read(dailyReportServiceProvider).rejectReport(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report rejected'), backgroundColor: AppTheme.errorRed),
        );
        _loadData();
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
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? 'Admin User';
    final userEmail = user?.email ?? '';
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) return _buildMobileLayout(userName, userEmail);
    return _buildDesktopLayout(userName, userEmail);
  }

  Widget _buildDesktopLayout(String userName, String userEmail) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Row(
        children: [
          Sidebar(
            userName: userName,
            userEmail: userEmail,
            currentPath: '/daily-reports/pending',
            onLogout: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/signin');
            },
          ),
          Expanded(
            child: Column(
              children: [
                TopHeader(userName: userName, breadcrumbs: const ['Operations', 'Daily Reports', 'Pending Approvals']),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(String userName, String userEmail) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Pending Approvals', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }

    if (!_isAdmin) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock_outline, size: 48, color: AppTheme.slate400),
          const SizedBox(height: 16),
          Text('Admin access required', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.slate600)),
          const SizedBox(height: 8),
          Text('Only Admins can approve or reject reports.', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate400)),
        ]),
      );
    }

    if (_reports.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline, size: 64, color: AppTheme.primaryGreen.withAlpha(60)),
          const SizedBox(height: 16),
          Text('No pending approvals', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.slate600)),
          const SizedBox(height: 8),
          Text('All reports have been reviewed.', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate400)),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(32),
      itemCount: _reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final r = _reports[i];
        final project = r['projects'] as Map<String, dynamic>?;
        final projectTitle = project?['title'] ?? 'N/A';

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.slate200)),
          child: InkWell(
            onTap: () => context.push('/projects/${r['project_id']}/daily-report/${r['id']}/review'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.assignment, color: Colors.blue, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(projectTitle, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
                    const SizedBox(height: 4),
                    Text(
                      'Report: ${_formatDate(r['report_date'])}',
                      style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500),
                    ),
                    if (r['weather_condition'] != null)
                      Text(
                        'Weather: ${r['weather_condition']}',
                        style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate400),
                      ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _approve(r['id'] as String),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Approve'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _reject(r['id'] as String),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorRed,
                  side: const BorderSide(color: AppTheme.errorRed),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ]),
          ),
          ),
        );
      },
    );
  }
}
