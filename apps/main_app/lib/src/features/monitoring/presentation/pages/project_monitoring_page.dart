import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_data/noel_data.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';
import '../../../../shared/widgets/kpi_card.dart';
import '../widgets/alert_list.dart';
import '../widgets/service_accordion.dart';

class ProjectMonitoringPage extends StatefulWidget {
  final String projectId;
  const ProjectMonitoringPage({super.key, required this.projectId});

  @override
  State<ProjectMonitoringPage> createState() => _ProjectMonitoringPageState();
}

class _ProjectMonitoringPageState extends State<ProjectMonitoringPage> {
  Map<String, dynamic>? _summary;
  Map<String, dynamic>? _measurement;
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _alerts = [];
  Map<String, List<Map<String, dynamic>>> _resources = {};
  Map<String, dynamic>? _workerIrregularities;
  Map<String, dynamic>? _machineryIrregularities;
  bool _isLoading = true;
  String? _error;
  String? _baselineEndDate;
  int _scheduleExtensionDays = 0;
  double _baselineBudget = 0;
  double _approvedCOsTotal = 0;
  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = ProductionMeasurementService(Supabase.instance.client);
      final summary = await service.getProjectSummary(widget.projectId);
      final measurement = await service.getProjectMeasurement(widget.projectId);
      final services = List<Map<String, dynamic>>.from(measurement['services'] ?? []);
      final allAlerts = List<Map<String, dynamic>>.from(measurement['alerts'] ?? []);

      final Map<String, List<Map<String, dynamic>>> resources = {};
      for (final svc in services) {
        final svcId = svc['quote_service_id']?.toString() ?? '';
        if (svcId.isNotEmpty) {
          final res = await service.getResourceDetails(widget.projectId, svcId);
          resources[svcId] = res;
        }
      }

      final workerIrreg = await service.getWorkerIrregularities(widget.projectId);
      final machIrreg = await service.getMachineryIrregularities(widget.projectId);

      for (final w in (workerIrreg['irregular_workers'] as List? ?? [])) {
        allAlerts.add({
          'type': 'worker',
          'severity': 'warning',
          'message': 'Worker ${w['name']}: ${w['deviation_count']} deviations, ${w['total_ot'].toStringAsFixed(0)}h OT',
        });
      }
      for (final m in (machIrreg['irregular_machines'] as List? ?? [])) {
        allAlerts.add({
          'type': 'machinery',
          'severity': 'warning',
          'message': 'Machine ${m['name']}: ${m['deviation_count']} deviations, ${m['total_production'].toStringAsFixed(0)} total prod',
        });
      }
      allAlerts.sort((a, b) {
        final sevA = a['severity']?.toString() == 'critical' ? 0 : 1;
        final sevB = b['severity']?.toString() == 'critical' ? 0 : 1;
        return sevA.compareTo(sevB);
      });

      if (mounted) {
        final supabase = Supabase.instance.client;
        final pResult = await supabase.from('projects')
            .select('baseline_end_date, schedule_extension_days, baseline_budget')
            .eq('id', widget.projectId).maybeSingle();
        final coResult = await supabase.from('change_orders')
            .select('adjustment_amount')
            .eq('project_id', widget.projectId).eq('status', 'approved');
        final approvedCOs = (coResult as List?)?.fold<double>(0, (s, r) =>
            s + (((r as Map)['adjustment_amount'] as num?)?.toDouble() ?? 0)) ?? 0;

        setState(() {
          _summary = summary;
          _measurement = measurement;
          _services = services;
          _alerts = allAlerts;
          _resources = resources;
          _workerIrregularities = workerIrreg;
          _machineryIrregularities = machIrreg;
          _isLoading = false;
          _baselineEndDate = pResult?['baseline_end_date']?.toString();
          _scheduleExtensionDays = (pResult?['schedule_extension_days'] as num?)?.toInt() ?? 0;
          _baselineBudget = (pResult?['baseline_budget'] as num?)?.toDouble() ?? (measurement['total_planned_cost'] as num?)?.toDouble() ?? 0;
          _approvedCOsTotal = approvedCOs;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = 'Error: $e'; _isLoading = false; });
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
      drawer: isMobile ? Drawer(
        backgroundColor: const Color(0xFF0F172A),
        child: Sidebar(
          userName: userName,
          userEmail: userEmail,
          currentPath: '/projects/${widget.projectId}/monitoring',
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
currentPath: '/projects/${widget.projectId}/monitoring',
              onLogout: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/signin');
              },
            ),
          Expanded(
            child: Column(
              children: [
                if (!isMobile)
                  TopHeader(userName: userName, breadcrumbs: const ['Operations', 'Projects', 'Monitoring Dashboard']),
                if (isMobile)
                  _buildMobileHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                      : _error != null
                          ? Center(child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                            ))
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
            'Monitoring Dashboard',
            style: GoogleFonts.manrope(
              fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    final s = _summary!;
    final m = _measurement!;
    final elapsedDays = (s['elapsed_days'] as int?) ?? 0;
    final totalDays = (s['total_days'] as int?) ?? 1;
    final servicesCount = (s['services_count'] as int?) ?? 0;
    final overallProgress = (m['overall_progress'] as num?)?.toDouble() ?? 0;
    final cpi = (m['cpi'] as num?)?.toDouble() ?? 1;
    final spi = (m['spi'] as num?)?.toDouble() ?? 1;
    final spiSubtitle = _baselineEndDate != null && _baselineEndDate!.isNotEmpty
        ? 'vs baseline ${_baselineEndDate!.substring(0, 10)}'
        : (spi >= 1 ? 'Ahead of schedule' : 'Behind schedule');
    final currentBudget = _baselineBudget + _approvedCOsTotal;
    final coServices = _services.where((s) => s['is_co_service'] == true).toList();
    final hasCOs = coServices.isNotEmpty;
    final originalProgress = _baselineBudget > 0
        ? ((m['total_earned_value'] as num?)?.toDouble() ?? 0) / currentBudget * 100
        : overallProgress;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back + title
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
            'Monitoring Dashboard',
            style: GoogleFonts.manrope(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            s['project_name'] ?? '',
            style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.slate400),
          ),
          const SizedBox(height: 20),

          // Summary cards
          if (isMobile)
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              KpiCard.dark(
                title: 'PHYSICAL PROGRESS', value: '${overallProgress.toStringAsFixed(1)}%',
                subtitle: '$servicesCount services · Day $elapsedDays/$totalDays',
                icon: Icons.speed, color: overallProgress >= 50 ? AppTheme.primaryGreen : Colors.orange,
                progress: overallProgress / 100,
              ),
              const SizedBox(height: 12),
              KpiCard.dark(
                title: 'CPI (COST INDEX)', value: cpi.toStringAsFixed(2),
                subtitle: cpi >= 1 ? 'Under budget' : 'Over budget',
                icon: Icons.account_balance, color: cpi >= 0.95 ? AppTheme.primaryGreen : Colors.redAccent,
                progress: cpi.clamp(0.0, 2.0) / 2,
              ),
              const SizedBox(height: 12),
              KpiCard.dark(
                title: 'SPI (SCHEDULE INDEX)', value: spi.toStringAsFixed(2),
                subtitle: spiSubtitle,
                icon: Icons.schedule, color: spi >= 0.9 ? AppTheme.primaryGreen : Colors.redAccent,
                progress: spi.clamp(0.0, 2.0) / 2,
              ),
              const SizedBox(height: 12),
              KpiCard.dark(
                title: 'ALERTS', value: '${_alerts.length}',
                subtitle: '${_workerIrregularities?['irregular_count'] ?? 0} workers · ${_machineryIrregularities?['irregular_count'] ?? 0} machines',
                icon: Icons.warning_amber_rounded, color: _alerts.isEmpty ? AppTheme.primaryGreen : Colors.redAccent,
              ),
            ])
          else
            Wrap(spacing: 16, runSpacing: 16, children: [
              SizedBox(
                width: 240,
                child: KpiCard.dark(
                  title: 'PHYSICAL PROGRESS', value: '${overallProgress.toStringAsFixed(1)}%',
                  subtitle: '$servicesCount services · Day $elapsedDays/$totalDays',
                  icon: Icons.speed, color: overallProgress >= 50 ? AppTheme.primaryGreen : Colors.orange,
                  progress: overallProgress / 100,
                ),
              ),
              SizedBox(
                width: 240,
                child: KpiCard.dark(
                  title: 'CPI (COST INDEX)', value: cpi.toStringAsFixed(2),
                  subtitle: cpi >= 1 ? 'Under budget' : 'Over budget',
                  icon: Icons.account_balance, color: cpi >= 0.95 ? AppTheme.primaryGreen : Colors.redAccent,
                  progress: cpi.clamp(0.0, 2.0) / 2,
                ),
              ),
              SizedBox(
                width: 240,
                child: KpiCard.dark(
                  title: 'SPI (SCHEDULE INDEX)', value: spi.toStringAsFixed(2),
                  subtitle: spiSubtitle,
                  icon: Icons.schedule, color: spi >= 0.9 ? AppTheme.primaryGreen : Colors.redAccent,
                  progress: spi.clamp(0.0, 2.0) / 2,
                ),
              ),
              SizedBox(
                width: 240,
                child: KpiCard.dark(
                  title: 'ALERTS', value: '${_alerts.length}',
                  subtitle: '${_workerIrregularities?['irregular_count'] ?? 0} workers · ${_machineryIrregularities?['irregular_count'] ?? 0} machines',
                  icon: Icons.warning_amber_rounded, color: _alerts.isEmpty ? AppTheme.primaryGreen : Colors.redAccent,
                ),
              ),
            ]),

          const SizedBox(height: 24),

          // Budget card
          if (_approvedCOsTotal > 0) ...[
            _buildBudgetCard(isMobile, currentBudget),
            const SizedBox(height: 20),
          ],

          // Alerts
          if (_alerts.isNotEmpty) ...[
            Text(
              'Alerts & Warnings',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            AlertList(alerts: _alerts),
            const SizedBox(height: 20),
          ],

          // Irregularities section
          if ((_workerIrregularities?['irregular_count'] ?? 0) > 0 ||
              (_machineryIrregularities?['irregular_count'] ?? 0) > 0) ...[
            _buildIrregularitiesSection(isMobile),
            const SizedBox(height: 20),
          ],

          // Service breakdown
          Text(
            'Services',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap a service to expand resources. Tap a resource to see daily history.',
            style: GoogleFonts.manrope(fontSize: 11, color: AppTheme.slate400),
          ),
          const SizedBox(height: 12),
          for (final svc in _services) ...[
            ServiceAccordion(
              projectId: widget.projectId,
              service: svc,
              resources: _resources[svc['quote_service_id']?.toString()] ?? [],
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildIrregularitiesSection(bool isMobile) {
    final workers = List<Map<String, dynamic>>.from(_workerIrregularities?['irregular_workers'] as List? ?? []);
    final machines = List<Map<String, dynamic>>.from(_machineryIrregularities?['irregular_machines'] as List? ?? []);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Resources Requiring Attention',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade200,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (workers.isNotEmpty) ...[
            Text('Workers', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate400, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            for (final w in workers.take(5))
              _irregularRow(w, Icons.person, '${w['name']} — ${w['deviation_count']} deviations, ${w['total_ot'].toStringAsFixed(0)}h OT'),
          ],
          if (workers.isNotEmpty && machines.isNotEmpty) const SizedBox(height: 10),
          if (machines.isNotEmpty) ...[
            Text('Machinery', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate400, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            for (final m in machines.take(5))
              _irregularRow(m, Icons.precision_manufacturing, '${m['name']} — ${m['deviation_count']} deviations, ${(m['total_hours'] as num?)?.toDouble() ?? 0}${m['odometer_unit'] == 'miles' ? ' mi' : 'h'}'),
          ],
        ],
      ),
    );
  }

  Widget _irregularRow(Map<String, dynamic> item, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.redAccent.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 11,
                color: Colors.red.shade100,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(bool isMobile, double currentBudget) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BUDGET', style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(children: [
            _budgetM('Original', _baselineBudget, Colors.blue.shade300),
            if (_approvedCOsTotal > 0) ...[
              const SizedBox(width: 12),
              _budgetM('+ COs', _approvedCOsTotal, Colors.orange.shade300),
              const SizedBox(width: 12),
              _budgetM('= Current', currentBudget, AppTheme.primaryGreen),
            ],
          ]),
          if (_scheduleExtensionDays > 0) ...[
            const SizedBox(height: 8),
            Text('Schedule extended by $_scheduleExtensionDays day(s)', style: GoogleFonts.manrope(fontSize: 10, color: Colors.orange.shade300)),
          ],
        ],
      ),
    );
  }

  Widget _budgetM(String label, double val, Color color) {
    final v = val >= 1000000 ? '${(val/1000000).toStringAsFixed(1)}M' :
        val >= 1000 ? '${(val/1000).toStringAsFixed(1)}K' : val.toStringAsFixed(0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('\$$v', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: GoogleFonts.manrope(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.slate500)),
    ]);
  }
}
