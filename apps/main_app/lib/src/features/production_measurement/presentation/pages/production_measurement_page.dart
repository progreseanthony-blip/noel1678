import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;

      // Load project info
      final project = await supabase
          .from('projects')
          .select('id, title, quote_id, start_date, end_date')
          .eq('id', widget.projectId)
          .maybeSingle();
      if (project == null) throw 'Project not found';

      final quoteId = project['quote_id'];

      // Planned quantities
      List<Map<String, dynamic>> plannedServices = [];
      if (quoteId != null) {
        final qsResult = await supabase
            .from('quote_services')
            .select('id, name, quantity, unit_of_measure, direct_cost')
            .eq('quote_id', quoteId);
        plannedServices = List<Map<String, dynamic>>.from(qsResult ?? []);
      }

      // Actual machinery production
      final machResult = await supabase
          .from('report_machinery_logs')
          .select('''
            production_value, total_hours,
            machinery!inner(capacity_yards),
            project_machinery!inner(quote_service_id),
            daily_reports!inner(status)
          ''')
          .eq('project_machinery.project_id', widget.projectId)
          .in_('daily_reports.status', ['submitted', 'approved']);
      final machLogs = List<Map<String, dynamic>>.from(machResult ?? []);

      // Actual labor hours
      final laborResult = await supabase
          .from('report_labor_logs')
          .select('''
            regular_hours, overtime_hours,
            project_labor!inner(quote_service_id),
            daily_reports!inner(status)
          ''')
          .eq('project_labor.project_id', widget.projectId)
          .in_('daily_reports.status', ['submitted', 'approved']);
      final laborLogs = List<Map<String, dynamic>>.from(laborResult ?? []);

      // Aggregate by quote_service_id
      final Map<String, double> actualProduction = {};
      final Map<String, double> actualMachHours = {};
      final Map<String, double> actualLaborHours = {};

      for (final log in machLogs) {
        final qsId = log['project_machinery']?['quote_service_id']?.toString();
        if (qsId == null) continue;
        final cap = (log['machinery']?['capacity_yards'] as num?)?.toDouble() ?? 1;
        final prod = (log['production_value'] as num?)?.toDouble() ?? 0;
        final hrs = (log['total_hours'] as num?)?.toDouble() ?? 0;
        actualProduction[qsId] = (actualProduction[qsId] ?? 0) + prod * cap;
        actualMachHours[qsId] = (actualMachHours[qsId] ?? 0) + hrs;
      }

      for (final log in laborLogs) {
        final qsId = log['project_labor']?['quote_service_id']?.toString();
        if (qsId == null) continue;
        final hrs = ((log['regular_hours'] as num?)?.toDouble() ?? 0) +
            ((log['overtime_hours'] as num?)?.toDouble() ?? 0);
        actualLaborHours[qsId] = (actualLaborHours[qsId] ?? 0) + hrs;
      }

      double totalPlannedUnits = 0;
      double totalActualUnits = 0;
      double totalPlannedCost = 0;
      double totalEarnedValue = 0;

      final List<Map<String, dynamic>> services = [];
      final List<Map<String, dynamic>> alerts = [];

      const laborRate = 25.0;
      const machRate = 85.0;

      for (final ps in plannedServices) {
        final qsId = ps['id']?.toString() ?? '';
        final plannedQty = (ps['quantity'] as num?)?.toDouble() ?? 0;
        final directCost = (ps['direct_cost'] as num?)?.toDouble() ?? 0;
        final actualProd = actualProduction[qsId] ?? 0;
        final progress = plannedQty > 0 ? (actualProd / plannedQty * 100) : 0.0;
        final unitCost = plannedQty > 0 ? directCost / plannedQty : 0;
        final ev = actualProd * unitCost;
        final machHrs = actualMachHours[qsId] ?? 0;
        final laborHrs = actualLaborHours[qsId] ?? 0;
        final actualCost = laborHrs * laborRate + machHrs * machRate;
        final totalHrs = machHrs + laborHrs;

        totalPlannedUnits += plannedQty;
        totalActualUnits += actualProd;
        totalPlannedCost += directCost;
        totalEarnedValue += ev;

        services.add({
          'name': ps['name'] ?? '',
          'unit': ps['unit_of_measure'] ?? '',
          'planned_quantity': plannedQty,
          'actual_quantity': actualProd,
          'progress': progress,
          'planned_cost': directCost,
          'actual_cost': actualCost,
          'earned_value': ev,
          'performance': totalHrs > 0 ? actualProd / totalHrs : 0.0,
          'performance_unit': '${ps['unit_of_measure'] ?? 'units'}/hr',
        });

        if (directCost > 0 && ev > 0 && actualCost > 0) {
          final cpi = ev / actualCost;
          if (cpi < 0.95) {
            alerts.add({
              'type': 'cost',
              'severity': 'warning',
              'message': '${ps['name']}: CPI ${cpi.toStringAsFixed(2)} — below threshold',
            });
          }
        }
        if (plannedQty > 0 && progress < 50) {
          alerts.add({
            'type': 'schedule',
            'severity': progress < 10 ? 'critical' : 'warning',
            'message': '${ps['name']}: Only ${progress.toStringAsFixed(1)}% complete',
          });
        }
      }

      double totalActualCost = 0;
      for (final s in services) {
        totalActualCost += (s['actual_cost'] as num).toDouble();
      }

      final overallProgress = totalPlannedUnits > 0
          ? (totalActualUnits / totalPlannedUnits * 100)
          : 0.0;
      final cpi = totalActualCost > 0 ? totalEarnedValue / totalActualCost : 1.0;
      final eac = cpi > 0 ? totalPlannedCost / cpi : totalPlannedCost;

      double spi = 1.0;
      if (project['start_date'] != null && project['end_date'] != null) {
        final start = DateTime.tryParse(project['start_date']?.toString() ?? '');
        final end = DateTime.tryParse(project['end_date']?.toString() ?? '');
        if (start != null && end != null && end.isAfter(start)) {
          final totalDays = end.difference(start).inDays;
          final elapsed = DateTime.now().difference(start).inDays;
          if (totalDays > 0 && elapsed > 0) {
            final pv = (elapsed / totalDays) * totalPlannedCost;
            spi = pv > 0 ? totalEarnedValue / pv : 1.0;
          }
        }
      }

      if (mounted) {
        setState(() {
          _measurement = {
            'project_name': project['title'] ?? '',
            'overall_progress': overallProgress,
            'spi': spi,
            'cpi': cpi,
            'eac': eac,
            'total_planned_cost': totalPlannedCost,
            'total_actual_cost': totalActualCost,
            'total_earned_value': totalEarnedValue,
            'total_planned_units': totalPlannedUnits,
            'total_actual_units': totalActualUnits,
            'services': services,
            'alerts': alerts,
          };
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
