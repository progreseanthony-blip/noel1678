import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';

class ProjectDashboardPage extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDashboardPage({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDashboardPage> createState() => _ProjectDashboardPageState();
}

class _ProjectDashboardPageState extends ConsumerState<ProjectDashboardPage> {
  Map<String, dynamic>? _project;
  Map<String, dynamic>? _measurement;
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _recentReports = [];

  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final supabase = Supabase.instance.client;
    try {
      final pResult = await supabase
          .from('projects')
          .select('id, title, client_name, status, start_date, end_date, quote_id')
          .eq('id', widget.projectId)
          .maybeSingle();

      final reports = await supabase
          .from('daily_reports')
          .select('id, report_date, status')
          .eq('project_id', widget.projectId)
          .order('report_date', ascending: false)
          .limit(5);

      final service = ref.read(productionMeasurementServiceProvider);
      final measurement = await service.getProjectMeasurement(widget.projectId);

      if (mounted) {
        setState(() {
          _project = Map<String, dynamic>.from(pResult ?? {});
          _measurement = measurement;
          _recentReports = List<Map<String, dynamic>>.from(reports ?? []);
          _isLoading = false;
          _error = (measurement is Map && measurement['error'] != null) ? measurement['error'] as String : null;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _isLoading = false; });
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
      backgroundColor: AppTheme.backgroundLight,
      drawer: isMobile ? Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: Sidebar(
          userName: userName, userEmail: userEmail,
          currentPath: '/projects/${widget.projectId}/dashboard',
          onLogout: () async {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) context.go('/signin');
          },
        ),
      ) : null,
      body: Row(
        children: [
          if (!isMobile)
            Sidebar(
              userName: userName, userEmail: userEmail,
              currentPath: '/projects/${widget.projectId}/dashboard',
              onLogout: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/signin');
              },
            ),
          Expanded(
            child: Column(
              children: [
                if (!isMobile)
                  TopHeader(userName: userName, breadcrumbs: const ['Operations', 'Projects', 'Dashboard']),
                if (isMobile)
                  _buildMobileHeader(userName),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 3))
                      : _error != null
                          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                          : _buildContent(isMobile),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(String userName) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _mobileScaffoldKey.currentState?.openDrawer(),
            child: const Icon(Icons.menu, color: AppTheme.slate700, size: 24),
          ),
          const SizedBox(width: 12),
          Text('Dashboard', style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
        ],
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    final services = (_measurement?['services'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final overallProgress = (_measurement?['overall_progress'] as num?)?.toDouble() ?? 0;
    final cpi = (_measurement?['cpi'] as num?)?.toDouble() ?? 1;
    final spi = (_measurement?['spi'] as num?)?.toDouble() ?? 1;
    final totalPlannedCost = (_measurement?['total_planned_cost'] as num?)?.toDouble() ?? 0;
    final totalActualCost = (_measurement?['total_actual_cost'] as num?)?.toDouble() ?? 0;
    final totalEarnedValue = (_measurement?['total_earned_value'] as num?)?.toDouble() ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + Header
          GestureDetector(
            onTap: () => context.go('/projects'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back, size: 16, color: AppTheme.slate500),
                const SizedBox(width: 6),
                Text('Back to Portfolio', style: GoogleFonts.manrope(color: AppTheme.slate500, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(_project?['title'] ?? 'Unknown Project', style: GoogleFonts.manrope(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.w800, color: AppTheme.slate900, letterSpacing: -0.5)),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(_project?['status'] ?? 'active'),
            ],
          ),
          const SizedBox(height: 4),
          Text('Client: ${_project?['client_name'] ?? '-'}', style: GoogleFonts.manrope(fontSize: 15, color: AppTheme.slate600, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),

          // Overall Progress Card
          _buildProgressCard(overallProgress, cpi, spi, totalPlannedCost, totalActualCost, totalEarnedValue),
          const SizedBox(height: 20),

          // Quick Actions
          _buildQuickActions(),
          const SizedBox(height: 24),

          // Service Progress Table
          Text('Service Progress', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
          const SizedBox(height: 12),
          _buildServiceTable(services, isMobile),
          const SizedBox(height: 24),

          // Recent Daily Reports
          Text('Recent Daily Reports', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
          const SizedBox(height: 12),
          _buildRecentReports(isMobile),
        ],
      ),
    );
  }

  Widget _buildProgressCard(double progress, double cpi, double spi, double plannedCost, double actualCost, double earnedValue) {
    final color = progress >= 100 ? AppTheme.primaryGreen : (progress >= 50 ? Colors.orange : AppTheme.slate400);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Overall Progress', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
              const SizedBox(width: 12),
              Text('${progress.toStringAsFixed(1)}%', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: (progress / 100).clamp(0, 1)),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(value: v, backgroundColor: AppTheme.slate200, color: color, minHeight: 10),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetric('Planned', '\$${_fmt(plannedCost)}', AppTheme.slate700),
              _buildMetric('Earned', '\$${_fmt(earnedValue)}', AppTheme.primaryGreen),
              _buildMetric('Actual', '\$${_fmt(actualCost)}', cpi >= 1 ? AppTheme.primaryGreen : AppTheme.errorRed),
              _buildMetric('CPI', cpi.toStringAsFixed(2), cpi >= 1 ? AppTheme.primaryGreen : AppTheme.errorRed),
              _buildMetric('SPI', spi.toStringAsFixed(2), spi >= 1 ? AppTheme.primaryGreen : Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.slate500)),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final pid = widget.projectId;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _actionChip(Icons.speed, 'Production', () => context.push('/projects/$pid/production-measurement'), AppTheme.primaryGreen),
              _actionChip(Icons.dashboard, 'Monitoring', () => context.push('/projects/$pid/monitoring'), Colors.indigo),
              _actionChip(Icons.assignment, 'Reports', () => context.push('/projects/$pid/daily-reports'), Colors.orange),
              _actionChip(Icons.build_circle, 'Planning', () => context.push('/projects/$pid'), AppTheme.slate900),
              _actionChip(Icons.receipt_long, 'Billing', () => context.push('/projects/$pid/billing'), Colors.teal),
              _actionChip(Icons.warning_amber, 'Incidents', () => context.push('/projects/$pid/incidents'), AppTheme.errorRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap, Color color) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTable(List<Map<String, dynamic>> services, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        children: [
          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
              child: Row(
                children: [
                  Expanded(flex: 25, child: _th('SERVICE')),
                  Expanded(flex: 15, child: _th('PLANNED')),
                  Expanded(flex: 15, child: _th('ACTUAL')),
                  Expanded(flex: 15, child: _th('PROGRESS')),
                  Expanded(flex: 15, child: _th('COST')),
                  Expanded(flex: 15, child: _th('EARNED')),
                ],
              ),
            ),
          if (services.isEmpty)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No services data available.')))
          else
            ...services.map((s) => _buildServiceRow(s, isMobile)),
        ],
      ),
    );
  }

  Widget _th(String label) {
    return Text(label, style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppTheme.slate500));
  }

  Widget _buildServiceRow(Map<String, dynamic> s, bool isMobile) {
    final name = s['name'] ?? '';
    final planned = (s['planned_quantity'] as num?)?.toDouble() ?? 0;
    final actual = (s['actual_quantity'] as num?)?.toDouble() ?? 0;
    final progress = (s['progress'] as num?)?.toDouble() ?? 0;
    final plannedCost = (s['planned_cost'] as num?)?.toDouble() ?? 0;
    final earnedValue = (s['earned_value'] as num?)?.toDouble() ?? 0;
    final unit = s['unit'] ?? '';
    final color = progress >= 100 ? AppTheme.primaryGreen : (progress >= 50 ? Colors.orange : AppTheme.slate400);

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
            const SizedBox(height: 6),
            Row(children: [
              Text('${_fmt(planned)} $unit → ${_fmt(actual)} $unit', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500)),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(value: (progress / 100).clamp(0, 1), backgroundColor: AppTheme.slate200, color: color, minHeight: 6),
              )),
              const SizedBox(width: 8),
              Text('${progress.toStringAsFixed(0)}%', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            ]),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(
        children: [
          Expanded(flex: 25, child: Text(name, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.slate900))),
          Expanded(flex: 15, child: Text('${_fmt(planned)} ${unit}', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500))),
          Expanded(flex: 15, child: Text('${_fmt(actual)} ${unit}', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500))),
          Expanded(flex: 15, child: Row(
            children: [
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(value: (progress / 100).clamp(0, 1), backgroundColor: AppTheme.slate200, color: color, minHeight: 6),
              )),
              const SizedBox(width: 8),
              SizedBox(width: 36, child: Text('${progress.toStringAsFixed(0)}%', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: color))),
            ],
          )),
          Expanded(flex: 15, child: Text('\$${_fmt(plannedCost)}', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate700))),
          Expanded(flex: 15, child: Text('\$${_fmt(earnedValue)}', style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen))),
        ],
      ),
    );
  }

  Widget _buildRecentReports(bool isMobile) {
    if (_recentReports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.slate200)),
        child: Center(child: Text('No daily reports yet.', style: GoogleFonts.manrope(color: AppTheme.slate500))),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.slate200)),
      child: Column(
        children: _recentReports.map((r) {
          final date = r['report_date'] != null
              ? DateFormat('MMM dd, yyyy').format(DateTime.parse(r['report_date']))
              : '-';
          final status = r['status'] ?? 'draft';
          final statusIcon = status == 'approved' ? Icons.check_circle : (status == 'submitted' ? Icons.hourglass_bottom : Icons.edit_note);
          final statusColor = status == 'approved' ? AppTheme.primaryGreen : (status == 'submitted' ? Colors.orange : AppTheme.slate400);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
            child: Row(
              children: [
                Icon(statusIcon, size: 18, color: statusColor),
                const SizedBox(width: 12),
                Text(date, style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.slate900)),
                const Spacer(),
                Text(status.toUpperCase(), style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.5)),
                const SizedBox(width: 12),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg; Color text;
    switch(status.toLowerCase()) {
      case 'active': bg = AppTheme.primaryGreen.withOpacity(0.1); text = AppTheme.primaryGreen; break;
      case 'completed': bg = Colors.blue.withOpacity(0.1); text = Colors.blue; break;
      case 'on_hold': bg = Colors.orange.withOpacity(0.1); text = Colors.orange; break;
      default: bg = AppTheme.slate200; text = AppTheme.slate700; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: text, letterSpacing: 0.5)),
    );
  }
}
