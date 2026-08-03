import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';
import '../../../../shared/widgets/kpi_card.dart';
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
  bool _includeCOServices = true;
  double _baselineBudget = 0;
  double _approvedCOsTotal = 0;
  String? _baselineEndDate;
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

      final supabase = Supabase.instance.client;
      final pResult = await supabase.from('projects')
          .select('baseline_budget, baseline_end_date')
          .eq('id', widget.projectId).maybeSingle();
      final coResult = await supabase.from('change_orders')
          .select('adjustment_amount')
          .eq('project_id', widget.projectId).eq('status', 'approved');
      final approvedCOs = (coResult as List?)?.fold<double>(0, (s, r) =>
          s + (((r as Map)['adjustment_amount'] as num?)?.toDouble() ?? 0)) ?? 0;
      final dbBaseline = (pResult?['baseline_budget'] as num?)?.toDouble() ?? 0;
      final baselineEnd = pResult?['baseline_end_date']?.toString();

      if (mounted) {
        setState(() {
          _measurement = measurement;
          _isLoading = false;
          _baselineBudget = dbBaseline > 0 ? dbBaseline : (measurement['total_planned_cost'] as num?)?.toDouble() ?? 0;
          _approvedCOsTotal = approvedCOs;
          _baselineEndDate = baselineEnd;
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
          currentPath: '/projects/${widget.projectId}/production-measurement',
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
currentPath: '/projects/${widget.projectId}/production-measurement',
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
    final allServices = List<Map<String, dynamic>>.from(m['services'] as List? ?? []);
    final services = _includeCOServices ? allServices : allServices.where((s) => s['is_co_service'] != true).toList();
    final alerts = List<Map<String, dynamic>>.from(m['alerts'] as List? ?? []);
    final currentBudget = _baselineBudget + _approvedCOsTotal;

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
              KpiCard.dark(title: 'PHYSICAL PROGRESS', value: '${progress.toStringAsFixed(1)}%', subtitle: '${_fmtCurrency(m['total_actual_units'])} / ${_fmtCurrency(m['total_planned_units'])} ${m['total_planned_units'] > 0 ? 'units' : ''}', icon: Icons.speed, color: progress >= 50 ? AppTheme.primaryGreen : Colors.orange, progress: progress / 100),
              const SizedBox(height: 12),
              KpiCard.dark(title: 'CPI (COST INDEX)', value: cpi.toStringAsFixed(2), subtitle: cpi >= 1 ? 'Under budget (EV > AC)' : 'Over budget (EV < AC)', icon: Icons.account_balance, color: cpi >= 0.95 ? AppTheme.primaryGreen : Colors.redAccent, progress: cpi.clamp(0.0, 2.0) / 2),
              const SizedBox(height: 12),
              KpiCard.dark(title: 'SPI (SCHEDULE INDEX)', value: spi.toStringAsFixed(2), subtitle: spi >= 1 ? 'Ahead of schedule' : 'Behind schedule', icon: Icons.schedule, color: spi >= 0.9 ? AppTheme.primaryGreen : Colors.redAccent, progress: spi.clamp(0.0, 2.0) / 2),
              const SizedBox(height: 12),
              KpiCard.dark(title: 'COST VARIANCE', value: '${costDev >= 0 ? '+' : ''}${costDev.toStringAsFixed(1)}%', subtitle: 'EAC: ${_fmtCurrency(eac)}', icon: Icons.trending_up, color: costDev <= 5 ? AppTheme.primaryGreen : Colors.redAccent),
            ])
          else
            Wrap(spacing: 16, runSpacing: 16, children: [
              SizedBox(width: 240, child: KpiCard.dark(title: 'PHYSICAL PROGRESS', value: '${progress.toStringAsFixed(1)}%', subtitle: '${_fmtCurrency(m['total_actual_units'])} / ${_fmtCurrency(m['total_planned_units'])} ${m['total_planned_units'] > 0 ? 'units' : ''}', icon: Icons.speed, color: progress >= 50 ? AppTheme.primaryGreen : Colors.orange, progress: progress / 100)),
              SizedBox(width: 240, child: KpiCard.dark(title: 'CPI (COST INDEX)', value: cpi.toStringAsFixed(2), subtitle: cpi >= 1 ? 'Under budget (EV > AC)' : 'Over budget (EV < AC)', icon: Icons.account_balance, color: cpi >= 0.95 ? AppTheme.primaryGreen : Colors.redAccent, progress: cpi.clamp(0.0, 2.0) / 2)),
              SizedBox(width: 240, child: KpiCard.dark(title: 'SPI (SCHEDULE INDEX)', value: spi.toStringAsFixed(2), subtitle: spi >= 1 ? 'Ahead of schedule' : 'Behind schedule', icon: Icons.schedule, color: spi >= 0.9 ? AppTheme.primaryGreen : Colors.redAccent, progress: spi.clamp(0.0, 2.0) / 2)),
              SizedBox(width: 240, child: KpiCard.dark(title: 'COST VARIANCE', value: '${costDev >= 0 ? '+' : ''}${costDev.toStringAsFixed(1)}%', subtitle: 'EAC: ${_fmtCurrency(eac)}', icon: Icons.trending_up, color: costDev <= 5 ? AppTheme.primaryGreen : Colors.redAccent)),
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
                    _buildBudgetWaterfallMobile(currentBudget),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: _buildBudgetMetric('Actual Cost', _fmtCurrency(totalActual), Colors.orange)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildBudgetMetric('Earned Value', _fmtCurrency(m['total_earned_value']), AppTheme.primaryGreen)),
                    ]),
                    const SizedBox(height: 8),
                    _buildBudgetMetric('EAC', _fmtCurrency(eac), Colors.cyan),
                  ])
                else
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    SizedBox(width: 300, child: _buildBudgetWaterfall(currentBudget)),
                    SizedBox(width: 180, child: _buildBudgetMetric('Actual Cost', _fmtCurrency(totalActual), Colors.orange)),
                    SizedBox(width: 180, child: _buildBudgetMetric('Earned Value', _fmtCurrency(m['total_earned_value']), AppTheme.primaryGreen)),
                    SizedBox(width: 180, child: _buildBudgetMetric('EAC', _fmtCurrency(eac), Colors.cyan)),
                  ]),
                // Baseline schedule context
                if (_baselineEndDate != null && _baselineEndDate!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.indigo.shade300),
                        const SizedBox(width: 8),
                        Text('SPI calculated against baseline end date: $_baselineEndDate',
                            style: GoogleFonts.manrope(fontSize: 11, color: Colors.indigo.shade200)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Service breakdown
          Row(
            children: [
              Text(
                'Service Breakdown',
                style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Include COs', style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate400)),
                const SizedBox(width: 6),
                SizedBox(
                  height: 24,
                  child: Switch(
                    value: _includeCOServices,
                    onChanged: (v) => setState(() => _includeCOServices = v),
                    activeColor: AppTheme.primaryGreen,
                  ),
                ),
              ]),
            ],
          ),
          const SizedBox(height: 12),
          ServiceProgressTable(services: services, hideCoServices: !_includeCOServices),
        ],
      ),
    );
  }

  Widget _buildBudgetWaterfall(double currentBudget) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Budget', style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 11, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _budgetItem('Original', _fmtCurrency(_baselineBudget), Colors.blue.shade300)),
              if (_approvedCOsTotal > 0) ...[
                Icon(Icons.add, size: 14, color: AppTheme.slate500),
                Expanded(child: _budgetItem('COs', _fmtCurrency(_approvedCOsTotal), Colors.orange.shade300)),
                Icon(Icons.drag_handle, size: 14, color: AppTheme.slate500),
              ],
              Expanded(child: _budgetItem('Current', _fmtCurrency(currentBudget), AppTheme.primaryGreen)),
            ],
          ),
          if (_approvedCOsTotal > 0) ...[
            const SizedBox(height: 6),
            _buildWaterfallBar(_baselineBudget, _approvedCOsTotal),
          ],
        ],
      ),
    );
  }

  Widget _buildWaterfallBar(double original, double coTotal) {
    final total = original + coTotal;
    if (total <= 0) return const SizedBox.shrink();
    final oFrac = original / total;
    final cFrac = coTotal / total;
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(height: 6, child: Row(children: [
        if (oFrac > 0) Expanded(flex: (oFrac * 1000).round(), child: Container(color: Colors.blue)),
        if (cFrac > 0) Expanded(flex: (cFrac * 1000).round(), child: Container(color: Colors.orange)),
      ])),
    );
  }

  Widget _buildBudgetWaterfallMobile(double currentBudget) {
    return _buildBudgetWaterfall(currentBudget);
  }

  Widget _budgetItem(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(value, style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.slate500)),
    ]);
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
