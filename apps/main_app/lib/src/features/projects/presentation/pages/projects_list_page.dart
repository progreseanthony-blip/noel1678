import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';
import '../../../../shared/widgets/kpi_card.dart';

class ProjectsListPage extends ConsumerStatefulWidget {
  const ProjectsListPage({super.key});

  @override
  ConsumerState<ProjectsListPage> createState() => _ProjectsListPageState();
}

class _ProjectsListPageState extends ConsumerState<ProjectsListPage> {
  List<Map<String, dynamic>>? _projects;
  Map<String, Map<String, dynamic>> _allServiceCompletions = {};
  Map<String, dynamic>? _portfolioSummary;
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _statusFilter = 'all';
  int _currentPage = 1;
  static const int _pageSize = 10;

  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('projects')
          .select()
          .order('created_at', ascending: false);

      final projects = List<Map<String, dynamic>>.from(response ?? []);

      final service = ref.read(productionMeasurementServiceProvider);
      Map<String, dynamic>? portfolioSummary;
      final Map<String, Map<String, dynamic>> allCompletions = {};

      try {
        portfolioSummary = await service.getPortfolioSummary();
        final summaries = List<Map<String, dynamic>>.from(
          portfolioSummary['project_summaries'] ?? [],
        );
        for (final s in summaries) {
          allCompletions[s['project_id'] as String] = {
            'pct': (s['progress'] as num?)?.toDouble() ?? 0,
            'totalServices': (s['total_services'] as int?) ?? 0,
            'completedServices': (s['completed_services'] as int?) ?? 0,
          };
        }
      } catch (_) {}

      for (final p in projects) {
        final pid = p['id'] as String;
        if (!allCompletions.containsKey(pid)) {
          allCompletions[pid] = {'pct': 0.0, 'totalServices': 0, 'completedServices': 0};
        }
      }

      if (mounted) {
        setState(() {
          _projects = projects;
          _allServiceCompletions = allCompletions;
          _portfolioSummary = portfolioSummary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load projects: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  int get _totalActive => _projects?.where((p) => p['status'] == 'active').length ?? 0;
  int get _totalCompleted => _projects?.where((p) => p['status'] == 'completed').length ?? 0;
  int get _totalOnHold => _projects?.where((p) => p['status'] == 'on_hold').length ?? 0;

  List<Map<String, dynamic>> get _filteredProjects {
    final base = _projects ?? [];
    var filtered = base;
    if (_statusFilter != 'all') {
      filtered = filtered.where((p) => p['status'] == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((u) {
        final title = (u['title'] ?? '').toString().toLowerCase();
        final client = (u['client_name'] ?? '').toString().toLowerCase();
        return title.contains(q) || client.contains(q);
      }).toList();
    }
    return filtered;
  }

  List<Map<String, dynamic>> get _paginatedProjects {
    final filtered = _filteredProjects;
    final start = (_currentPage - 1) * _pageSize;
    if (start >= filtered.length) return [];
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _totalPages => (_filteredProjects.length / _pageSize).ceil().clamp(1, 9999);

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Admin User';
    final userEmail = currentUser?.email ?? '';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      key: _mobileScaffoldKey,
      backgroundColor: AppTheme.backgroundLight,
      drawer: isMobile ? Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: Sidebar(
          userName: userName,
          userEmail: userEmail,
          currentPath: '/projects',
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
              userName: userName,
              userEmail: userEmail,
              currentPath: '/projects',
              onLogout: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/signin');
              },
            ),
          Expanded(
            child: Column(
              children: [
                if (!isMobile)
                  TopHeader(userName: userName, breadcrumbs: const ['Operations', 'Dashboard']),
                if (isMobile)
                  _buildMobileHeader(userName),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 3))
                      : _error != null
                          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                          : _buildMainContent(isMobile),
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
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16, right: 16, bottom: 12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _mobileScaffoldKey.currentState?.openDrawer(),
            child: const Icon(Icons.menu, color: AppTheme.slate700, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Dashboard',
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isMobile) {
    return RefreshIndicator(
      onRefresh: _loadProjects,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Portfolio Dashboard',
              style: GoogleFonts.manrope(
                fontSize: isMobile ? 24 : 30,
                fontWeight: FontWeight.w800,
                color: AppTheme.slate900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Overview of all operational projects, progress, and status.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: AppTheme.slate500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildStatsRow(isMobile),
            const SizedBox(height: 24),
            if (_portfolioSummary != null) ...[
              _buildPortfolioOverview(isMobile),
              const SizedBox(height: 24),
            ],
            _buildSearchFilters(),
            const SizedBox(height: 24),
            _buildTable(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isMobile) {
    final total = _projects?.length ?? 0;
    return Row(
      children: [
        _buildStatCard('Total Projects', total.toString(), AppTheme.slate900, Icons.folder_outlined, const Color(0xFFF1F5F9), isMobile),
        const SizedBox(width: 12),
        _buildStatCard('Active', _totalActive.toString(), AppTheme.primaryGreen, Icons.play_circle_outline, AppTheme.primaryGreen.withOpacity(0.1), isMobile),
        const SizedBox(width: 12),
        _buildStatCard('Completed', _totalCompleted.toString(), Colors.blue, Icons.check_circle_outline, Colors.blue.withOpacity(0.1), isMobile),
        const SizedBox(width: 12),
        _buildStatCard('On Hold', _totalOnHold.toString(), Colors.orange, Icons.pause_circle_outline, Colors.orange.withOpacity(0.1), isMobile),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon, Color bgColor, bool isMobile) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: isMobile ? 10 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.slate200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: GoogleFonts.manrope(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioOverview(bool isMobile) {
    final ps = _portfolioSummary!;
    final totalPlanned = (ps['total_planned_cost'] as num?)?.toDouble() ?? 0;
    final totalActual = (ps['total_actual_cost'] as num?)?.toDouble() ?? 0;
    final portfolioCPI = (ps['portfolio_cpi'] as num?)?.toDouble() ?? 1;
    final portfolioProgress = (ps['portfolio_progress'] as num?)?.toDouble() ?? 0;
    final totalAlerts = (ps['total_alerts'] as int?) ?? 0;
    final projectsAtRisk = (ps['projects_at_risk'] as int?) ?? 0;
    final completedSvcs = (ps['completed_services'] as int?) ?? 0;
    final totalSvcs = (ps['total_services'] as int?) ?? 0;
    final budgetVariance = totalPlanned > 0 ? ((totalActual - totalPlanned) / totalPlanned * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Portfolio Overview',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.slate900,
              ),
            ),
            const Spacer(),
            Text(
              'Active projects: ${ps['total_projects'] ?? 0}',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: AppTheme.slate500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isMobile)
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            KpiCard.light(
              title: 'PORTFOLIO PROGRESS',
              value: '${portfolioProgress.toStringAsFixed(1)}%',
              subtitle: '$completedSvcs of $totalSvcs services completed',
              icon: Icons.trending_up,
              color: portfolioProgress >= 50 ? AppTheme.primaryGreen : Colors.orange,
              progress: portfolioProgress / 100,
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 12),
            KpiCard.light(
              title: 'PORTFOLIO CPI',
              value: portfolioCPI.toStringAsFixed(2),
              subtitle: portfolioCPI >= 1 ? 'Under budget' : 'Over budget',
              icon: Icons.account_balance,
              color: portfolioCPI >= 0.95 ? AppTheme.primaryGreen : AppTheme.errorRed,
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 12),
            KpiCard.light(
              title: 'BUDGET',
              value: '\$${_fmtCurrency(totalActual)} / \$${_fmtCurrency(totalPlanned)}',
              subtitle: '${budgetVariance >= 0 ? '+' : ''}${budgetVariance.toStringAsFixed(1)}% variance',
              icon: Icons.attach_money,
              color: budgetVariance <= 5 ? AppTheme.primaryGreen : AppTheme.errorRed,
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 12),
            KpiCard.light(
              title: 'ALERTS & RISKS',
              value: '$totalAlerts',
              subtitle: '$projectsAtRisk project${projectsAtRisk == 1 ? '' : 's'} at risk',
              icon: Icons.warning_amber_rounded,
              color: totalAlerts == 0 ? AppTheme.primaryGreen : AppTheme.errorRed,
              padding: const EdgeInsets.all(12),
            ),
          ])
        else
          Wrap(spacing: 16, runSpacing: 16, children: [
            SizedBox(
              width: 190,
              child: KpiCard.light(
                title: 'PORTFOLIO PROGRESS',
                value: '${portfolioProgress.toStringAsFixed(1)}%',
                subtitle: '$completedSvcs of $totalSvcs services completed',
                icon: Icons.trending_up,
                color: portfolioProgress >= 50 ? AppTheme.primaryGreen : Colors.orange,
                progress: portfolioProgress / 100,
                padding: const EdgeInsets.all(12),
              ),
            ),
            SizedBox(
              width: 190,
              child: KpiCard.light(
                title: 'PORTFOLIO CPI',
                value: portfolioCPI.toStringAsFixed(2),
                subtitle: portfolioCPI >= 1 ? 'Under budget' : 'Over budget',
                icon: Icons.account_balance,
                color: portfolioCPI >= 0.95 ? AppTheme.primaryGreen : AppTheme.errorRed,
                padding: const EdgeInsets.all(12),
              ),
            ),
            SizedBox(
              width: 190,
              child: KpiCard.light(
                title: 'BUDGET',
                value: '\$${_fmtCurrency(totalActual)} / \$${_fmtCurrency(totalPlanned)}',
                subtitle: '${budgetVariance >= 0 ? '+' : ''}${budgetVariance.toStringAsFixed(1)}% variance',
                icon: Icons.attach_money,
                color: budgetVariance <= 5 ? AppTheme.primaryGreen : AppTheme.errorRed,
                padding: const EdgeInsets.all(12),
              ),
            ),
            SizedBox(
              width: 190,
              child: KpiCard.light(
                title: 'ALERTS & RISKS',
                value: '$totalAlerts',
                subtitle: '$projectsAtRisk project${projectsAtRisk == 1 ? '' : 's'} at risk',
                icon: Icons.warning_amber_rounded,
                color: totalAlerts == 0 ? AppTheme.primaryGreen : AppTheme.errorRed,
                padding: const EdgeInsets.all(12),
              ),
            ),
          ]),
      ],
    );
  }

  String _fmtCurrency(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  Widget _buildSearchFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _currentPage = 1;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by title or client...',
                  hintStyle: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.slate400, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _statusFilter,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Status', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'active', child: Text('Active', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'completed', child: Text('Completed', style: TextStyle(fontSize: 13))),
                  DropdownMenuItem(value: 'on_hold', child: Text('On Hold', style: TextStyle(fontSize: 13))),
                ],
                onChanged: (v) {
                  setState(() {
                    _statusFilter = v ?? 'all';
                    _currentPage = 1;
                  });
                },
                style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(bool isMobile) {
    final items = _paginatedProjects;
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Expanded(flex: 22, child: _colHeader('PROJECT TITLE')),
                  Expanded(flex: 16, child: _colHeader('CLIENT')),
                  Expanded(flex: 14, child: _colHeader('START DATE')),
                  Expanded(flex: 10, child: _colHeader('STATUS')),
                  Expanded(flex: 26, child: _colHeader('PROGRESS')),
                ],
              ),
            ),
          if (items.isEmpty)
             const Padding(padding: EdgeInsets.all(32), child: Center(child: Text("No projects found.")))
          else
            ...items.map((q) => _buildTableRow(q, isMobile)),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${items.isEmpty ? 0 : (_currentPage - 1) * _pageSize + 1}-${(_currentPage - 1) * _pageSize + items.length} of ${_filteredProjects.length} results',
                  style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate500, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    _buildPageButton(Icons.chevron_left, _currentPage > 1 ? () {
                      setState(() => _currentPage--);
                    } : null),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$_currentPage',
                        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildPageButton(Icons.chevron_right, _currentPage < _totalPages ? () {
                      setState(() => _currentPage++);
                    } : null),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _colHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: AppTheme.slate500,
      ),
    );
  }

  Widget _buildProgressBar(double pct) {
    final color = pct >= 100 ? AppTheme.primaryGreen : (pct >= 50 ? Colors.orange : AppTheme.slate400);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              backgroundColor: AppTheme.slate200,
              color: color,
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 42,
          child: Text(
            '${pct.toStringAsFixed(0)}%',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(Map<String, dynamic> project, bool isMobile) {
    final title = project['title'] ?? 'N/A';
    final status = project['status'] ?? 'active';
    final date = project['start_date'] != null
      ? DateFormat('MMM dd, yyyy').format(DateTime.parse(project['start_date']).toLocal())
      : '-';
    final progress = _allServiceCompletions[project['id'] as String];
    final pct = (progress?['pct'] as num?)?.toDouble() ?? 0.0;
    final completed = progress?['completedServices'] as int? ?? 0;
    final totalSvcs = progress?['totalServices'] as int? ?? 0;

    if (isMobile) {
      return InkWell(
        onTap: () => context.go('/projects/${project['id']}/dashboard'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(title, style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold))),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 8),
              Text(project['client_name'] ?? '-', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate600)),
              const SizedBox(height: 4),
              Text('Started: $date', style: GoogleFonts.manrope(fontSize: 12, color: AppTheme.slate400)),
              const SizedBox(height: 8),
              _buildProgressBar(pct),
              if (totalSvcs > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$completed of $totalSvcs services',
                    style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate400),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/projects/${project['id']}/dashboard'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: Row(
            children: [
              Expanded(flex: 22, child: Padding(padding: const EdgeInsets.only(right: 16), child: Text(title, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.slate900), overflow: TextOverflow.ellipsis, maxLines: 2))),
              Expanded(flex: 16, child: Padding(padding: const EdgeInsets.only(right: 16), child: Text(project['client_name'] ?? '-', style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate700), overflow: TextOverflow.ellipsis, maxLines: 2))),
              Expanded(flex: 14, child: Text(date, style: GoogleFonts.manrope(fontSize: 13, color: AppTheme.slate500))),
              Expanded(flex: 10, child: _buildStatusBadge(status)),
              Expanded(flex: 26, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressBar(pct),
                  if (totalSvcs > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '$completed of $totalSvcs services complete',
                        style: GoogleFonts.manrope(fontSize: 10, color: AppTheme.slate400),
                      ),
                    ),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    switch(status.toLowerCase()) {
      case 'active': bg = AppTheme.primaryGreen.withOpacity(0.1); text = AppTheme.primaryGreen; break;
      case 'completed': bg = Colors.blue.withOpacity(0.1); text = Colors.blue; break;
      case 'on_hold': bg = Colors.orange.withOpacity(0.1); text = Colors.orange; break;
      default: bg = AppTheme.slate200; text = AppTheme.slate700; break;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(
          status.toUpperCase(),
          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w800, color: text, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildPageButton(IconData icon, VoidCallback? onTap) {
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.slate200),
          ),
          child: Icon(icon, size: 16, color: onTap != null ? AppTheme.slate700 : AppTheme.slate400),
        ),
      ),
    );
  }
}
