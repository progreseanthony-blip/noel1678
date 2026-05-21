import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/sidebar.dart';
import '../../../../shared/widgets/top_header.dart';
import '../widgets/add_unplanned_resource_dialog.dart';

class ProjectBaselinePage extends StatefulWidget {
  final String projectId;
  const ProjectBaselinePage({super.key, required this.projectId});

  @override
  State<ProjectBaselinePage> createState() => _ProjectBaselinePageState();
}

class _ProjectBaselinePageState extends State<ProjectBaselinePage> {
  Map<String, dynamic>? _project;
  bool _isLoading = true;
  String? _error;

  final GlobalKey<ScaffoldState> _mobileScaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  double _originalCost = 0.0;
  double _deviationCost = 0.0;
  double _totalDaysSaved = 0.0;
  double _originalTotalDays = 0.0;
  double _totalCompressionSavings = 0.0;
  List<Map<String, dynamic>> _unplannedResources = [];
  Map<String, double> _serviceOriginalDurations = {};

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final supabase = Supabase.instance.client;
      // Fetch project with quote total_amount
      final pResult = await supabase
          .from('projects')
          .select('*, quotes(total_amount)')
          .eq('id', widget.projectId)
          .maybeSingle();
      
      if (pResult == null) throw 'Project not found';

      // Fetch unplanned resources with service and metadata
      final machResult = await supabase.from('project_machinery')
          .select('*, quote_services(name)')
          .eq('project_id', widget.projectId)
          .eq('is_unplanned', true);
      final laborResult = await supabase.from('project_labor')
          .select('*, quote_services(name)')
          .eq('project_id', widget.projectId)
          .eq('is_unplanned', true);
      final matResult = await supabase.from('project_materials')
          .select('*, quote_services(name)')
          .eq('project_id', widget.projectId)
          .eq('is_unplanned', true);
      final instResult = await supabase.from('project_instruments')
          .select('*, quote_services(name)')
          .eq('project_id', widget.projectId)
          .eq('is_unplanned', true);

      double original = (pResult['quotes']?['total_amount'] as num?)?.toDouble() ?? 0.0;
      double deviation = 0.0;
      List<Map<String, dynamic>> unplanned = [];

      // Helper to process results
      void processResult(List<dynamic> results, String type, String nameField) {
        for (var r in results) {
          double cost = (r['unplanned_cost'] as num?)?.toDouble() ?? 0.0;
          deviation += cost;
          unplanned.add({
            'type': type,
            'name': r[nameField],
            'serviceName': r['quote_services']?['name'] ?? 'General',
            'cost': cost,
            'id': r['id'],
            'metadata': r['calculation_metadata'],
            'createdAt': DateTime.tryParse(r['created_at']?.toString() ?? '') ?? DateTime.now(),
            'quote_service_id': r['quote_service_id'],
            'linked_machinery_id': r is Map && r.containsKey('linked_machinery_id') ? r['linked_machinery_id'] : null,
          });
        }
      }

      processResult(machResult, 'Machinery', 'machinery_name');
      processResult(laborResult, 'Labor', 'role_name');
      processResult(matResult, 'Material', 'material_name');
      processResult(instResult, 'Instrument', 'instrument_name');

      // Add catalog IDs to the maps after processing
      for (var i = 0; i < unplanned.length; i++) {
        if (unplanned[i]['type'] == 'Machinery') {
          unplanned[i]['catalogId'] = machResult.firstWhere((r) => r['id'] == unplanned[i]['id'])['machinery_id'];
        } else if (unplanned[i]['type'] == 'Labor') {
          unplanned[i]['catalogId'] = laborResult.firstWhere((r) => r['id'] == unplanned[i]['id'])['role_id'];
        } else if (unplanned[i]['type'] == 'Material') {
          unplanned[i]['catalogId'] = matResult.firstWhere((r) => r['id'] == unplanned[i]['id'])['material_id'];
        } else if (unplanned[i]['type'] == 'Instrument') {
          unplanned[i]['catalogId'] = instResult.firstWhere((r) => r['id'] == unplanned[i]['id'])['instrument_id'];
        }
      }

      // Group by type and then sort each group chronologically (oldest to newest)
      final Map<String, List<Map<String, dynamic>>> groupedByType = {};
      for (final item in unplanned) {
        final type = item['type'] as String;
        groupedByType.putIfAbsent(type, () => []).add(item);
      }

      final List<Map<String, dynamic>> sortedUnplanned = [];
      final typeOrder = ['Machinery', 'Labor', 'Material', 'Instrument'];
      
      for (final type in typeOrder) {
        if (groupedByType.containsKey(type)) {
          final items = groupedByType[type]!;
          items.sort((a, b) => (a['createdAt'] as DateTime).compareTo(b['createdAt'] as DateTime));
          for (var i = 0; i < items.length; i++) {
            items[i]['seqNumber'] = i + 1;
            sortedUnplanned.add(items[i]);
          }
        }
      }
      
      groupedByType.forEach((type, items) {
        if (!typeOrder.contains(type)) {
          items.sort((a, b) => (a['createdAt'] as DateTime).compareTo(b['createdAt'] as DateTime));
          for (var i = 0; i < items.length; i++) {
            items[i]['seqNumber'] = i + 1;
            sortedUnplanned.add(items[i]);
          }
        }
      });

      unplanned = sortedUnplanned;

      // Compute total timeline savings across all unplanned resources
      double totalDaysSaved = 0;
      double totalCompressionSavings = 0;
      for (final r in unplanned) {
        final meta = r['metadata'] as Map<String, dynamic>?;
        if (meta != null) {
          totalDaysSaved += (meta['days_saved'] as num?)?.toDouble() ?? 0;
          totalCompressionSavings += (meta['compression_savings'] as num?)?.toDouble() ?? 0;
        }
      }

      // Compute total original duration from all service estimations in the quote
      double originalTotalDays = 0;
      final Map<String, double> serviceOriginalDurations = {};
      final quoteId = pResult['quote_id'];
      if (quoteId != null) {
        final estData = await supabase
            .from('quote_service_estimations')
            .select('total_working_days, quote_service_id, quote_services!inner(quote_id)')
            .eq('quote_services.quote_id', quoteId);
        
        for (var e in estData) {
          final days = (e['total_working_days'] as num?)?.toDouble() ?? 0;
          originalTotalDays += days;
          final sId = e['quote_service_id']?.toString();
          if (sId != null) {
            serviceOriginalDurations[sId] = days;
          }
        }
      }

      if (mounted) {
        setState(() {
          _project = pResult;
          _originalCost = original;
          _deviationCost = deviation;
          _unplannedResources = unplanned;
          _totalDaysSaved = totalDaysSaved;
          _originalTotalDays = originalTotalDays;
          _totalCompressionSavings = totalCompressionSavings;
          _serviceOriginalDurations = serviceOriginalDurations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading baseline: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteUnplannedResource(Map<String, dynamic> resource) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Extra Resource', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete ${resource['name']}? Project savings and timeline will be automatically recalculated.', style: GoogleFonts.manrope(color: const Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Cancel', style: GoogleFonts.manrope(color: const Color(0xFF94A3B8)))),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Delete', style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;
      String table = '';
      if (resource['type'] == 'Machinery') table = 'project_machinery';
      else if (resource['type'] == 'Labor') table = 'project_labor';
      else if (resource['type'] == 'Material') table = 'project_materials';
      else if (resource['type'] == 'Instrument') table = 'project_instruments';

      if (table.isNotEmpty) {
        await supabase.from(table).delete().eq('id', resource['id']);
      }

      // If it's machinery and has a service ID, trigger timeline sequence recalculation for remaining machines
      if (resource['type'] == 'Machinery' && resource['quote_service_id'] != null) {
        await _recalculateUnplannedMachinerySequence(resource['quote_service_id'].toString());
      }
      
      _loadData();
    } catch (e) {
      debugPrint('Error deleting: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _recalculateUnplannedMachinerySequence(String serviceId) async {
    try {
      final supabase = Supabase.instance.client;
      final machs = await supabase
          .from('project_machinery')
          .select('id, calculation_metadata')
          .eq('project_id', widget.projectId)
          .eq('quote_service_id', serviceId)
          .eq('is_unplanned', true)
          .order('created_at', ascending: true);

      double otherUnplannedProdSum = 0;
      double otherUnplannedDaysSavedSum = 0;

      for (final m in machs) {
        final meta = m['calculation_metadata'] as Map<String, dynamic>?;
        if (meta == null) continue;

        final p0 = (meta['original_fleet_daily_production'] as num?)?.toDouble() ?? 0;
        final targetVolume = (meta['target_volume'] as num?)?.toDouble() ?? 0;
        final originalDuration = (meta['original_duration_days'] as num?)?.toDouble() ?? 0;
        final dailyRate = (meta['other_resources_daily_cost'] as num?)?.toDouble() ?? 500.0;
        final mProd = (meta['performance_per_day'] as num?)?.toDouble() ?? 0;
        final days = (meta['days'] as num?)?.toDouble() ?? 1;

        if (originalDuration > 0 && p0 > 0 && targetVolume > 0 && mProd > 0) {
          double currentBaselineDuration = originalDuration - otherUnplannedDaysSavedSum;
          if (currentBaselineDuration < 0) currentBaselineDuration = 0;
          
          final totalFleetProdDay = p0 + otherUnplannedProdSum + mProd;
          final fullAccDuration = targetVolume / totalFleetProdDay;

          final currentFullAcc = targetVolume / (p0 + mProd);
          final currentDiff = originalDuration - currentFullAcc;
          
          double currentDaysSaved = 0;
          if (currentDiff > 0 && currentFullAcc > 0) {
            currentDaysSaved = days * (currentDiff / currentFullAcc);
            if (currentDaysSaved > currentDiff) currentDaysSaved = currentDiff;
          } else {
            currentDaysSaved = currentDiff;
          }

          double newEstimatedDuration = currentBaselineDuration - currentDaysSaved;
          if (newEstimatedDuration < fullAccDuration) newEstimatedDuration = fullAccDuration;
          if (newEstimatedDuration < 0) newEstimatedDuration = 0;

          final incrementalDaysSaved = currentBaselineDuration - newEstimatedDuration;
          double compressionSavings = incrementalDaysSaved > 0 ? incrementalDaysSaved * dailyRate : 0;

          meta['new_estimated_duration_days'] = newEstimatedDuration;
          meta['days_saved'] = incrementalDaysSaved;
          meta['compression_savings'] = compressionSavings;

          await supabase.from('project_machinery').update({'calculation_metadata': meta}).eq('id', m['id']);

          otherUnplannedProdSum += mProd;
          otherUnplannedDaysSavedSum += incrementalDaysSaved;
        }
      }
    } catch (e) {
      debugPrint('Error recalculating sequence: $e');
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
      backgroundColor: const Color(0xFF0F172A), // Dark mode background for command center
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
                  TopHeader(userName: userName, breadcrumbs: const ['Operations', 'Projects', 'Baseline Analysis']),
                if (isMobile)
                  _buildMobileHeader(),
                  
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                    : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
                      : _buildMainContent(isMobile),
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
            'Baseline Analysis',
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

  Widget _buildMainContent(bool isMobile) {
    final double projectedCost = _originalCost + _deviationCost - _totalCompressionSavings;
    final double deviationPercent = _originalCost > 0 ? ((projectedCost - _originalCost) / _originalCost) * 100 : 0.0;
    
    // Simple formatters since intl might not be imported here
    String formatCurrency(double amount) => '\$${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, size: 16, color: AppTheme.slate400),
                    const SizedBox(width: 6),
                    Text('Back to Project Details', style: GoogleFonts.manrope(color: AppTheme.slate400, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  debugPrint('Baseline View Timeline button pressed');
                  context.pop('show_gantt');
                },
                icon: const Icon(Icons.calendar_month, size: 16, color: AppTheme.primaryGreen),
                label: Text('View Timeline', style: GoogleFonts.manrope(color: AppTheme.primaryGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Execution Baseline',
            style: GoogleFonts.manrope(
              fontSize: isMobile ? 24 : 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            _project?['title'] ?? 'Unknown Project',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.slate400,
            ),
          ),
          const SizedBox(height: 20),

          // High-level Stats Row
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(width: 240, child: _buildStatCard('Original Quote', formatCurrency(_originalCost), 'Budgeted Cost', Icons.account_balance_wallet, Colors.blue)),
              SizedBox(width: 240, child: _buildStatCard('Execution Baseline', formatCurrency(projectedCost), 'Total Projected', Icons.insights, AppTheme.primaryGreen)),
              SizedBox(width: 240, child: _buildStatCard('Cost Variance', '+${deviationPercent.toStringAsFixed(1)}%', '${formatCurrency(_deviationCost)} Over Budget', Icons.warning_amber_rounded, deviationPercent > 0 ? Colors.orange : Colors.green)),
              if (_totalCompressionSavings > 0)
                SizedBox(
                  width: 240,
                  child: _buildStatCard(
                    'Net Financial Impact',
                    formatCurrency(_deviationCost - _totalCompressionSavings),
                    'Added Cost - Saved Costs',
                    Icons.balance,
                    (_deviationCost - _totalCompressionSavings) < _deviationCost ? Colors.teal : Colors.orange,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 20),

          // --- New Timeline Impact Section ---
          if (_totalDaysSaved > 0) ...[
            Text('Project Timeline Impact', style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF22D3EE).withOpacity(0.3)),
                boxShadow: [BoxShadow(color: const Color(0xFF22D3EE).withOpacity(0.05), blurRadius: 20)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.speed, color: Color(0xFF22D3EE), size: 20),
                      const SizedBox(width: 12),
                      Text('ACCELERATED EXECUTION', style: GoogleFonts.manrope(color: const Color(0xFF22D3EE), fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.2)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimelineMiniStat('ORIGINAL', '${_originalTotalDays.toStringAsFixed(0)} days', Colors.blue.withOpacity(0.5)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, color: AppTheme.slate500, size: 14),
                      const SizedBox(width: 8),
                      _buildTimelineMiniStat('COMPRESSED', '${(_originalTotalDays - _totalDaysSaved).toStringAsFixed(1)} days', AppTheme.primaryGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('↓ ${_totalDaysSaved.toStringAsFixed(1)} working days compressed', style: GoogleFonts.manrope(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('This optimization results in ${formatCurrency(_totalCompressionSavings)} savings from reduced overhead and labor duration.', style: GoogleFonts.manrope(color: const Color(0xFFCBD5E1), fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Cost Comparison Panel with detailed budget impact metrics
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cost Comparison & Budget Impact', style: GoogleFonts.manrope(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Icon(Icons.bar_chart, color: AppTheme.slate500, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                _buildComparisonBar('Original Budget', _originalCost, _originalCost > projectedCost ? _originalCost : projectedCost, Colors.blue),
                const SizedBox(height: 20),
                _buildComparisonBar('Current Baseline', projectedCost, _originalCost > projectedCost ? _originalCost : projectedCost, projectedCost > _originalCost ? Colors.orange : AppTheme.primaryGreen),
                const Divider(color: Color(0xFF334155), height: 32),
                Text(
                  'BUDGET IMPACT DETAILS',
                  style: GoogleFonts.manrope(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 16),
                 LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth < 768;
                    if (isSmall) {
                      return Column(
                        children: [
                          _buildImpactMetricCard(
                            'Extra Resource Investment',
                            formatCurrency(_deviationCost),
                            'Additional machinery, labor & instruments introduced to compress timeline.',
                            Colors.orange,
                            double.infinity,
                          ),
                          const SizedBox(height: 16),
                          _buildImpactMetricCard(
                            'Timeline Compression Savings',
                            '-${formatCurrency(_totalCompressionSavings)}',
                            'Savings generated in related resources by reducing task duration.',
                            const Color(0xFF22D3EE),
                            double.infinity,
                          ),
                          const SizedBox(height: 16),
                          _buildImpactMetricCard(
                            'Net Budget Impact',
                            '${_deviationCost - _totalCompressionSavings <= 0 ? "-" : "+"}${formatCurrency((_deviationCost - _totalCompressionSavings).abs())}',
                            _deviationCost - _totalCompressionSavings <= 0
                                ? (_deviationCost > 0 
                                    ? 'Net cost reduction on the overall project budget. Every \$1.00 invested in extra acceleration returned \$${(_totalCompressionSavings / _deviationCost).toStringAsFixed(2)} in baseline savings.' 
                                    : 'Net cost reduction on the overall project budget.')
                                : 'Net cost increase on the overall project budget.',
                            _deviationCost - _totalCompressionSavings <= 0
                                ? AppTheme.primaryGreen
                                : Colors.orange,
                            double.infinity,
                            isProminent: true,
                            roiText: _deviationCost > 0 && _totalCompressionSavings > 0
                                ? '${((_totalCompressionSavings / _deviationCost) * 100).toStringAsFixed(1)}% ROI'
                                : null,
                          ),
                        ],
                      );
                    } else {
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildImpactMetricCard(
                                'Extra Resource Investment',
                                formatCurrency(_deviationCost),
                                'Additional machinery, labor & instruments introduced to compress timeline.',
                                Colors.orange,
                                double.infinity,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildImpactMetricCard(
                                'Timeline Compression Savings',
                                '-${formatCurrency(_totalCompressionSavings)}',
                                'Savings generated in related resources by reducing task duration.',
                                const Color(0xFF22D3EE),
                                double.infinity,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildImpactMetricCard(
                                'Net Budget Impact',
                                '${_deviationCost - _totalCompressionSavings <= 0 ? "-" : "+"}${formatCurrency((_deviationCost - _totalCompressionSavings).abs())}',
                                _deviationCost - _totalCompressionSavings <= 0
                                    ? (_deviationCost > 0 
                                        ? 'Net cost reduction on the overall project budget. Every \$1.00 invested in extra acceleration returned \$${(_totalCompressionSavings / _deviationCost).toStringAsFixed(2)} in baseline savings.' 
                                        : 'Net cost reduction on the overall project budget.')
                                    : 'Net cost increase on the overall project budget.',
                                _deviationCost - _totalCompressionSavings <= 0
                                    ? AppTheme.primaryGreen
                                    : Colors.orange,
                                double.infinity,
                                isProminent: true,
                                roiText: _deviationCost > 0 && _totalCompressionSavings > 0
                                    ? '${((_totalCompressionSavings / _deviationCost) * 100).toStringAsFixed(1)}% ROI'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Unplanned Resources Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Re-Planned Resources',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red, width: 2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⬇ DIAGNOSTIC TEST BUTTON BELOW ⬇', style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.red)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('TEST BUTTON: SÍ RESPONDE'), backgroundColor: Colors.green, duration: Duration(seconds: 3)),
                        );
                        showDialog(
                          context: context,
                          useRootNavigator: false,
                          barrierColor: Colors.black.withOpacity(0.5),
                          builder: (ctx) => AddUnplannedResourceDialog(projectId: widget.projectId),
                        ).then((added) {
                          if (added == true) _loadData();
                        }).catchError((e, st) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Dialog error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        });
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 60),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 20),
                          SizedBox(width: 8),
                          Text('TEST: ADD EXTRA RESOURCE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_unplannedResources.isEmpty)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('No unplanned resources added yet.', style: GoogleFonts.manrope(color: AppTheme.slate500))),
            )
          else
            ...(() {
              // Group unplanned resources by service name
              final Map<String, List<Map<String, dynamic>>> groupedResources = {};
              for (final res in _unplannedResources) {
                final serviceName = res['serviceName'] as String? ?? 'General';
                groupedResources.putIfAbsent(serviceName, () => []).add(res);
              }

              return groupedResources.entries.map((entry) {
                final serviceName = entry.key;
                final items = entry.value;

                // Calculate totals for this service group
                double groupExtraCost = 0;
                double groupDaysSaved = 0;
                double groupSavings = 0;
                
                for (final res in items) {
                  groupExtraCost += (res['cost'] as num?)?.toDouble() ?? 0.0;
                  final rawMeta = res['metadata'];
                  final meta = rawMeta is Map ? Map<String, dynamic>.from(rawMeta) : null;
                  if (meta != null) {
                    groupDaysSaved += (meta['days_saved'] as num?)?.toDouble() ?? 0.0;
                    groupSavings += (meta['compression_savings'] as num?)?.toDouble() ?? 0.0;
                  }
                }

                final groupNetImpact = groupExtraCost - groupSavings;

                // Lookup original duration of this service
                String? quoteServiceId;
                for (final res in items) {
                  if (res['quote_service_id'] != null) {
                    quoteServiceId = res['quote_service_id'].toString();
                    break;
                  }
                }

                final double originalServiceDays = quoteServiceId != null 
                    ? (_serviceOriginalDurations[quoteServiceId] ?? 0.0)
                    : 0.0;

                final double compressedServiceDays = originalServiceDays - groupDaysSaved > 0 
                    ? originalServiceDays - groupDaysSaved 
                    : 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header of the service group
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F172A),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.assignment, color: Color(0xFF38BDF8), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    serviceName.toUpperCase(),
                                    style: GoogleFonts.manrope(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Group-level micro metrics row
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildMicroBadge(
                                  'Extra Cost: ${formatCurrency(groupExtraCost)}',
                                  Colors.orange.withOpacity(0.1),
                                  Colors.orange,
                                  Icons.add_circle_outline,
                                ),
                                if (groupDaysSaved > 0)
                                  _buildMicroBadge(
                                    '-${groupDaysSaved.toStringAsFixed(1)}d saved',
                                    const Color(0xFF22D3EE).withOpacity(0.1),
                                    const Color(0xFF22D3EE),
                                    Icons.speed,
                                  ),
                                if (groupSavings > 0)
                                  _buildMicroBadge(
                                    'Savings: ${formatCurrency(groupSavings)}',
                                    AppTheme.primaryGreen.withOpacity(0.1),
                                    AppTheme.primaryGreen,
                                    Icons.trending_down,
                                  ),
                                _buildMicroBadge(
                                  'Net Balance: ${groupNetImpact <= 0 ? "-" : "+"}${formatCurrency(groupNetImpact.abs())}',
                                  groupNetImpact <= 0 
                                      ? AppTheme.primaryGreen.withOpacity(0.15)
                                      : Colors.orange.withOpacity(0.15),
                                  groupNetImpact <= 0 
                                      ? AppTheme.primaryGreen
                                      : Colors.orange,
                                  Icons.account_balance,
                                ),
                                if (groupExtraCost > 0 && groupSavings > 0)
                                  _buildMicroBadge(
                                    '⚡ ROI: ${((groupSavings / groupExtraCost) * 100).toStringAsFixed(1)}%',
                                    const Color(0xFF22D3EE).withOpacity(0.15),
                                    const Color(0xFF22D3EE),
                                    Icons.flash_on,
                                  ),
                              ],
                            ),
                            if (originalServiceDays > 0) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF334155)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.timer_outlined, color: Color(0xFF38BDF8), size: 14),
                                            const SizedBox(width: 6),
                                            Text(
                                              'SERVICE TIMELINE COMPRESSION',
                                              style: GoogleFonts.manrope(
                                                color: const Color(0xFF94A3B8),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 10,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${originalServiceDays.toStringAsFixed(1)}d ➔ ${compressedServiceDays.toStringAsFixed(1)}d (-${groupDaysSaved.toStringAsFixed(1)}d)',
                                          style: GoogleFonts.manrope(
                                            color: const Color(0xFF38BDF8),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Stack(
                                      children: [
                                        Container(
                                          height: 8,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        // Original track (Blue)
                                        FractionallySizedBox(
                                          widthFactor: 1.0,
                                          child: Container(
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                        // Compressed track (Cyan glow)
                                        FractionallySizedBox(
                                          widthFactor: (compressedServiceDays / originalServiceDays).clamp(0.0, 1.0),
                                          child: Container(
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF22D3EE),
                                              borderRadius: BorderRadius.circular(4),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF22D3EE).withOpacity(0.4),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Divider(color: Color(0xFF334155), height: 1),
                      // Resources inside this service group
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(color: Color(0xFF334155), height: 1),
                        itemBuilder: (context, index) {
                          final res = items[index];
                          final rawMeta = res['metadata'];
                          final meta = rawMeta is Map ? Map<String, dynamic>.from(rawMeta) : null;
                          final breakdown = meta != null 
                            ? 'Rent: \$${meta['rent']} | Fuel: \$${(meta['fuel_gph'] ?? 0) * (meta['hours_per_day'] ?? 0) * (meta['fuel_price'] ?? 0)} | Transport: \$${meta['transport']}'
                            : null;

                          IconData icon;
                          if (res['type'] == 'Machinery') icon = Icons.precision_manufacturing;
                          else if (res['type'] == 'Labor') icon = Icons.people;
                          else icon = Icons.inventory;

                          return ListTile(
                            onTap: () {
                              showDialog(
                                context: context,
                                barrierColor: Colors.black.withOpacity(0.5),
                                builder: (_) => AddUnplannedResourceDialog(
                                  projectId: widget.projectId,
                                  initialData: res,
                                ),
                              ).then((updated) {
                                if (updated == true) _loadData();
                              });
                            },
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(8)),
                              child: Icon(icon, color: Colors.white, size: 20),
                            ),
                            title: Row(
                              children: [
                                if (res['seqNumber'] != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E293B),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFF475569)),
                                    ),
                                    child: Text(
                                      '#${res['seqNumber']}',
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                  ),
                                ],
                                Expanded(child: Text(res['name'], style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.bold))),
                                if (meta?['days_saved'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22D3EE).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFF22D3EE).withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.schedule, size: 10, color: Color(0xFF22D3EE)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '-${(meta!['days_saved'] as num).toStringAsFixed(1)}d saved',
                                          style: GoogleFonts.manrope(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF22D3EE)),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Type: ${res['type']}', style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 12)),
                                if (breakdown != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(breakdown, style: GoogleFonts.manrope(color: AppTheme.primaryGreen.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.w600)),
                                  ),
                                if (meta?['compression_savings'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Schedule savings: ${formatCurrency((meta!['compression_savings'] as num).toDouble())} in related resources',
                                      style: GoogleFonts.manrope(color: const Color(0xFF22D3EE).withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '+ ${formatCurrency(res['cost'])}',
                                      style: GoogleFonts.manrope(color: Colors.orange, fontWeight: FontWeight.w800, fontSize: 16),
                                    ),
                                    if (meta != null && meta['days'] != null)
                                      Text('${meta['days']} days', style: GoogleFonts.manrope(color: AppTheme.slate500, fontSize: 11)),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => _deleteUnplannedResource(res),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList();
            }()),
        ],
      ),
    );
  }

  Widget _buildMicroBadge(String text, Color bgColor, Color textColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonBar(String label, double value, double maxValue, Color color) {
    double factor = maxValue > 0 ? (value / maxValue) : 0;
    if (factor > 1.0) factor = 1.0; 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13, fontWeight: FontWeight.w600)),
            Text('\$${value.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}', style: GoogleFonts.manrope(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(6)),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: factor,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: color, 
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.manrope(color: AppTheme.slate400, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.manrope(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.manrope(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTimelineMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.manrope(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          Text(value, style: GoogleFonts.manrope(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildImpactMetricCard(
    String title,
    String value,
    String description,
    Color color,
    double width, {
    bool isProminent = false,
    String? roiText,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isProminent ? color.withOpacity(0.05) : const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isProminent ? color.withOpacity(0.4) : const Color(0xFF334155),
          width: isProminent ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  color: const Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (roiText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22D3EE).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF22D3EE).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on, size: 10, color: Color(0xFF22D3EE)),
                      const SizedBox(width: 4),
                      Text(
                        roiText,
                        style: GoogleFonts.manrope(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF22D3EE),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.manrope(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.manrope(
              color: const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
