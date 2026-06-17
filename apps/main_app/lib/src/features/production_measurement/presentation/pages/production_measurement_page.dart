import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';
import '../widgets/evm_kpi_card.dart';
import '../widgets/alert_banner.dart';
import '../widgets/service_progress_table.dart';

class ProductionMeasurementPage extends StatefulWidget {
  final String projectId;
  const ProductionMeasurementPage({super.key, required this.projectId});

  @override
  State<ProductionMeasurementPage> createState() => _ProductionMeasurementPageState();
}

class _ProductionMeasurementPageState extends State<ProductionMeasurementPage> {
  Map<String, dynamic>? _measurement;
  bool _isLoading = true;
  String? _error;
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = ProductionMeasurementService(Supabase.instance.client);
      final measurement = await service.getProjectMeasurement(widget.projectId);
      if (measurement['error'] != null) throw measurement['error']!.toString();
      if (mounted) {
        setState(() {
          _measurement = measurement;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading production data: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _fmtCurrency(dynamic val) {
    if (val == null) return '-';
    final d = (val as num).toDouble();
    return '\$${d.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
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
                  TopHeader(userName: userName, breadcrumbs: const ['Operations', 'Projects', 'Production Metrics']),
                if (isMobile)
                  _buildMobileHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                      : _error != null
                          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                          : _buildContent(isMobile),
                ),
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
        left: 16, right: 16, bottom: 12,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _mobileScaffoldKey.currentState?.openDrawer(),
            child: const Icon(Icons.menu, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            'Production Metrics',
            style: GoogleFonts.manrope(
              fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    final m = _measurement!;
    final progress = (m['overall_progress'] as num?)?.toDouble() ?? 0;
    final spi = (m['spi'] as num?)?.toDouble() ?? 1;
    final cpi = (m['cpi'] as num?)?.toDouble() ?? 1;
    final eac = (m['eac'] as num?)?.toDouble() ?? 0;
    final totalPlanned = (m['total_planned_cost'] as num?)?.toDouble() ?? 0;
    final totalActual = (m['total_actual_cost'] as num?)?.toDouble() ?? 0;
    final costDev = totalPlanned > 0 ? ((totalActual - totalPlanned) / totalPlanned * 100) : 0.0;
    final services = List<Map<String, dynamic>>.from(m['services'] as List? ?? []);
    final alerts = List<Map<String, dynamic>>.from(m['alerts'] as List? ?? []);

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
                const Icon(Icons.arrow_back, size: 16, color: AppTheme.slate400),
                const SizedBox(width: 6),
                Text('Back to Project', style: GoogleFonts.manrope(color: AppTheme.slate400, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Production Measurement',
            style: GoogleFonts.manrope(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            m['project_name'] ?? '',
            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.slate400),
          ),
          const SizedBox(height: 20),

          // Alert banners
          if (alerts.isNotEmpty) ...[
            ...alerts.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AlertBanner(
                message: a['message'] ?? '',
                severity: a['severity'] ?? 'warning',
              ),
            )),
            const SizedBox(height: 16),
          ],

          // KPI Cards
          if (isMobile)
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              EvmKpiCard(title: 'PHYSICAL PROGRESS', value: '${progress.toStringAsFixed(1)}%', subtitle: '${_fmtCurrency(m['total_actual_units'])} / ${_fmtCurrency(m['total_planned_units'])} ${m['total_planned_units'] > 0 ? 'units' : ''}', icon: Icons.speed, color: progress >= 50 ? AppTheme.primaryGreen : Colors.orange, progress: progress / 100),
              const SizedBox(height: 12),
              EvmKpiCard(title: 'CPI (COST INDEX)', value: cpi.toStringAsFixed(2), subtitle: cpi >= 1 ? 'Under budget (EV > AC)' : 'Over budget (EV < AC)', icon: Icons.account_balance, color: cpi >= 0.95 ? AppTheme.primaryGreen : Colors.redAccent, progress: cpi.clamp(0.0, 2.0) / 2),
              const SizedBox(height: 12),
              EvmKpiCard(title: 'SPI (SCHEDULE INDEX)', value: spi.toStringAsFixed(2), subtitle: spi >= 1 ? 'Ahead of schedule' : 'Behind schedule', icon: Icons.schedule, color: spi >= 0.9 ? AppTheme.primaryGreen : Colors.redAccent, progress: spi.clamp(0.0, 2.0) / 2),
              const SizedBox(height: 12),
              EvmKpiCard(title: 'COST VARIANCE', value: '${costDev >= 0 ? '+' : ''}${costDev.toStringAsFixed(1)}%', subtitle: 'EAC: ${_fmtCurrency(eac)}', icon: Icons.trending_up, color: costDev <= 5 ? AppTheme.primaryGreen : Colors.redAccent),
            ])
          else
            Wrap(spacing: 16, runSpacing: 16, children: [
              SizedBox(width: 240, child: EvmKpiCard(title: 'PHYSICAL PROGRESS', value: '${progress.toStringAsFixed(1)}%', subtitle: '${_fmtCurrency(m['total_actual_units'])} / ${_fmtCurrency(m['total_planned_units'])} ${m['total_planned_units'] > 0 ? 'units' : ''}', icon: Icons.speed, color: progress >= 50 ? AppTheme.primaryGreen : Colors.orange, progress: progress / 100)),
              SizedBox(width: 240, child: EvmKpiCard(title: 'CPI (COST INDEX)', value: cpi.toStringAsFixed(2), subtitle: cpi >= 1 ? 'Under budget (EV > AC)' : 'Over budget (EV < AC)', icon: Icons.account_balance, color: cpi >= 0.95 ? AppTheme.primaryGreen : Colors.redAccent, progress: cpi.clamp(0.0, 2.0) / 2)),
              SizedBox(width: 240, child: EvmKpiCard(title: 'SPI (SCHEDULE INDEX)', value: spi.toStringAsFixed(2), subtitle: spi >= 1 ? 'Ahead of schedule' : 'Behind schedule', icon: Icons.schedule, color: spi >= 0.9 ? AppTheme.primaryGreen : Colors.redAccent, progress: spi.clamp(0.0, 2.0) / 2)),
              SizedBox(width: 240, child: EvmKpiCard(title: 'COST VARIANCE', value: '${costDev >= 0 ? '+' : ''}${costDev.toStringAsFixed(1)}%', subtitle: 'EAC: ${_fmtCurrency(eac)}', icon: Icons.trending_up, color: costDev <= 5 ? AppTheme.primaryGreen : Colors.redAccent)),
            ]),

          const SizedBox(height: 24),

          // Budget summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BUDGET EXECUTION SUMMARY', style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
                const SizedBox(height: 16),
                if (isMobile)
                  Column(children: [
                    _buildBudgetMetric('Planned Budget', _fmtCurrency(totalPlanned), Colors.blue),
                    const SizedBox(height: 8),
                    _buildBudgetMetric('Actual Cost', _fmtCurrency(totalActual), Colors.orange),
                    const SizedBox(height: 8),
                    _buildBudgetMetric('Earned Value', _fmtCurrency(m['total_earned_value']), AppTheme.primaryGreen),
                    const SizedBox(height: 8),
                    _buildBudgetMetric('EAC', _fmtCurrency(eac), Colors.cyan),
                  ])
                else
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    SizedBox(width: 200, child: _buildBudgetMetric('Planned Budget', _fmtCurrency(totalPlanned), Colors.blue)),
                    SizedBox(width: 200, child: _buildBudgetMetric('Actual Cost', _fmtCurrency(totalActual), Colors.orange)),
                    SizedBox(width: 200, child: _buildBudgetMetric('Earned Value', _fmtCurrency(m['total_earned_value']), AppTheme.primaryGreen)),
                    SizedBox(width: 200, child: _buildBudgetMetric('EAC', _fmtCurrency(eac), Colors.cyan)),
                  ]),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Service breakdown
          Text(
            'Service Breakdown',
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ServiceProgressTable(services: services),
        ],
      ),
    );
  }

  Widget _buildBudgetMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.manrope(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
