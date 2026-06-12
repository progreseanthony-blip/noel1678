import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';
import '../widgets/incident_card.dart';

class IncidentsDashboardPage extends ConsumerStatefulWidget {
  const IncidentsDashboardPage({super.key});

  @override
  ConsumerState<IncidentsDashboardPage> createState() => _IncidentsDashboardPageState();
}

class _IncidentsDashboardPageState extends ConsumerState<IncidentsDashboardPage> {
  List<Map<String, dynamic>> _incidents = [];
  bool _isLoading = true;
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(incidentsServiceProvider);
      _incidents = await service.getAllOpen();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
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
      body: Row(children: [
        Sidebar(
          userName: userName, userEmail: userEmail,
          currentPath: '/incidents',
          onLogout: () async {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) context.go('/signin');
          },
        ),
        Expanded(
          child: Column(children: [
            TopHeader(userName: userName, breadcrumbs: const ['Operations', 'Incidents Dashboard']),
            Expanded(child: _buildContent()),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMobileLayout(String userName, String userEmail) {
    return Scaffold(
      key: _mobileScaffoldKey,
      backgroundColor: AppTheme.backgroundLight,
      drawer: Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: Sidebar(
          userName: userName, userEmail: userEmail,
          currentPath: '/incidents',
          onLogout: () async {
            await Supabase.instance.client.auth.signOut();
            if (context.mounted) context.go('/signin');
          },
        ),
      ),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Incidents Dashboard', style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }

    final totalTime = _incidents.fold<double>(0, (sum, i) {
      final t = i['time_impact_hours'];
      return sum + (t != null ? (t as num).toDouble() : 0);
    });
    final totalCost = _incidents.fold<double>(0, (sum, i) {
      final t = i['cost_impact'];
      return sum + (t != null ? (t as num).toDouble() : 0);
    });
    final totalExpenses = _incidents.fold<double>(0, (sum, i) {
      final t = i['actual_expenses'];
      return sum + (t != null ? (t as num).toDouble() : 0);
    });
    final criticalCount = _incidents.where((i) => i['priority'] == 'critical').length;

    return Column(children: [
      _buildSummaryBar(totalTime, totalCost, totalExpenses, criticalCount),
      Expanded(
        child: _incidents.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_outline, size: 64, color: AppTheme.primaryGreen.withAlpha(60)),
                  const SizedBox(height: 16),
                  Text('No open incidents', style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.slate600)),
                ]),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(32),
                itemCount: _incidents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final inc = _incidents[i];
                  final project = inc['projects'] as Map<String, dynamic>?;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (project != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            project['title'] as String? ?? '',
                            style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate400, letterSpacing: 0.5),
                          ),
                        ),
                      IncidentCard(
                        incident: inc,
                        onTap: () {
                          context.push('/projects/${inc['project_id']}/incidents/${inc['id']}');
                        },
                      ),
                    ],
                  );
                },
              ),
      ),
    ]);
  }

  Widget _buildSummaryBar(double totalTime, double totalCost, double totalExpenses, int criticalCount) {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Row(children: [
        _summaryItem(Icons.access_time, '${totalTime.toStringAsFixed(1)}h', 'Time Lost', AppTheme.accentCyan),
        _summaryItem(Icons.attach_money, '\$${(totalCost + totalExpenses).toStringAsFixed(0)}', 'Budget Impact', AppTheme.errorRed),
        _summaryItem(Icons.warning, '$criticalCount', 'Critical', AppTheme.errorRed),
        _summaryItem(Icons.list_alt, '${_incidents.length}', 'Open Incidents', AppTheme.slate600),
      ]),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.manrope(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.slate900)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate400, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
