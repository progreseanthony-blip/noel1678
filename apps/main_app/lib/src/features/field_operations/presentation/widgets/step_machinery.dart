import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:noel_data/noel_data.dart';

class StepMachinery extends StatefulWidget {
  final String projectId;
  final List<Map<String, dynamic>> plannedMachinery;
  final List<Map<String, dynamic>> machineryLogs;
  final List<Map<String, dynamic>> workers;
  final List<Map<String, dynamic>> deviationReasons;
  final List<Map<String, dynamic>> laborLogs;
  final List<Map<String, dynamic>> plannedLabor;
  final List<Map<String, dynamic>> machineryCatalog;
  final bool isReadOnly;
  final ValueChanged<List<Map<String, dynamic>>> onLogsChanged;
  final VoidCallback? onNavigateToBaseline;
  final String? reportDate;

  const StepMachinery({
    super.key,
    required this.projectId,
    required this.plannedMachinery,
    required this.machineryLogs,
    required this.workers,
    required this.deviationReasons,
    required this.laborLogs,
    required this.plannedLabor,
    required this.machineryCatalog,
    required this.isReadOnly,
    required this.onLogsChanged,
    this.onNavigateToBaseline,
    this.reportDate,
  });

  @override
  State<StepMachinery> createState() => _StepMachineryState();
}

class _StepMachineryState extends State<StepMachinery> {
  List<Map<String, dynamic>> _entries = [];
  String? _serviceFilter;
  final Map<String, TextEditingController> _ctrls = {};
  Map<String, double> _machineryProduction = {};
  Map<String, double> _rawProd = {};
  Map<String, List<double>> _rawProdList = {};
  Map<String, List<double>> _machineryProdList = {};
  Map<String, Map<String, Map<String, dynamic>>> _estimationTargets = {};

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<Map<String, dynamic>> get _activeWorkers =>
      widget.workers.where((w) => w['status'] == 'Active').toList();

  List<Map<String, dynamic>> get _machReasons =>
      widget.deviationReasons
          .where((r) => r['category'] == 'machinery' || r['category'] == 'general')
          .toList();

  @override
  void initState() {
    super.initState();
    _entries = widget.machineryLogs.map((m) => Map<String, dynamic>.from(m)).toList();
    _enrichEntries();
    _loadProduction();
  }

  Future<void> _loadProduction() async {
    try {
      final rawProd = await ProjectBalanceHelper.getMachineryProduction(
        Supabase.instance.client, widget.projectId,
      );
      final perEntry = await ProjectBalanceHelper.getMachineryProductionPerEntry(
        Supabase.instance.client, widget.projectId,
      );
      final est = await ProjectBalanceHelper.getMachineryEstimationTargets(
        Supabase.instance.client, widget.projectId,
      );
      _estimationTargets = est;
      _rawProd = rawProd;
      _rawProdList = perEntry;
      _machineryProduction = _adjustMachineryProduction(rawProd, est);
      _machineryProdList = _adjustProductionList(perEntry);
      _recalculateCalculatedCy();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading machinery production: $e');
    }
  }

  @override
  void didUpdateWidget(StepMachinery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.machineryLogs != widget.machineryLogs) {
      _entries = widget.machineryLogs.map((m) => Map<String, dynamic>.from(m)).toList();
      _enrichEntries();
      _recalculateCalculatedCy();
    }
  }

  void _enrichEntries() {
    for (final entry in _entries) {
      entry['start_shift_photos'] ??= <String>[];
      entry['end_shift_photos'] ??= <String>[];
      final pmId = entry['project_machinery_id'] as String?;
      if (pmId != null) {
        final pm = widget.plannedMachinery.firstWhere(
          (p) => p['id'] == pmId,
          orElse: () => <String, dynamic>{},
        );
        if (pm.isNotEmpty) {
          entry['_is_principal'] = pm['is_principal'] == true;
          final unit = (pm['quote_services']?['unit_of_measure'] as String?)?.toLowerCase();
          entry['_is_cy'] = unit == 'cy';
          final machName = pm['machinery_name'] as String? ?? '';
          entry['_capacity'] = (pm['machinery']?['capacity_yards'] as num?)?.toDouble()
              ?? (widget.machineryCatalog.firstWhere(
                  (m) => (m['description'] as String? ?? '').toLowerCase() == machName.toLowerCase(),
                  orElse: () => <String, dynamic>{},
                )['capacity_yards'] as num?)?.toDouble() ?? 0;
          entry['_name'] = pm['machinery_name'] ?? pm['machinery']?['description'] ?? 'Machine';
        }
      }
      if (entry['_is_principal'] == null) {
        entry['_is_principal'] = entry['production_value'] != null;
        entry['_is_cy'] = entry['_is_principal'] == true;
        if (entry['_is_principal'] == true && (entry['_capacity'] == null || entry['_capacity'] == 0)) {
          final machName = entry['machinery']?['description'] as String? ?? '';
          if (machName.isNotEmpty) {
            entry['_capacity'] = (widget.machineryCatalog.firstWhere(
                (m) => (m['description'] as String? ?? '').toLowerCase() == machName.toLowerCase(),
                orElse: () => <String, dynamic>{},
              )['capacity_yards'] as num?)?.toDouble() ?? 0;
          }
        }
      }
      if (entry['_is_principal'] == true && entry['_is_cy'] == true) {
        final cap = (entry['_capacity'] as num?)?.toDouble() ?? 0;
        final prod = (entry['production_value'] as num?)?.toDouble() ?? 0;
        entry['_calculated_cy'] = cap > 0 ? prod * cap : 0;
      }
    }
  }

  void _emit() => widget.onLogsChanged(List<Map<String, dynamic>>.from(_entries));

  int _entryCount(String pmId) =>
      _entries.where((e) => e['project_machinery_id'] == pmId).length;
  List<int> _entriesFor(String pmId) {
    final indices = <int>[];
    for (int i = 0; i < _entries.length; i++) {
      if (_entries[i]['project_machinery_id'] == pmId) indices.add(i);
    }
    return indices;
  }

  void _addEntry(Map<String, dynamic> pm, {bool isUnplanned = false}) {
    final machName = pm['machinery_name'] ?? pm['machinery']?['description'] ?? 'Machine';
    final isPrincipal = pm['is_principal'] == true;
    final unit = (pm['quote_services']?['unit_of_measure'] as String?)?.toLowerCase();
    final isCY = unit == 'cy';
    final embeddedCapacity = (pm['machinery']?['capacity_yards'] as num?)?.toDouble() ?? 0;
    final capacity = embeddedCapacity > 0
        ? embeddedCapacity
        : ((widget.machineryCatalog.firstWhere(
            (m) => (m['description'] as String? ?? '').toLowerCase() == machName.toString().toLowerCase(),
            orElse: () => <String, dynamic>{},
          ))['capacity_yards'] as num?)?.toDouble() ?? 0;
    final machId = pm['machinery_id'] as String?
        ?? (widget.machineryCatalog.firstWhere(
            (m) => (m['description'] as String? ?? '').toLowerCase() == machName.toString().toLowerCase(),
            orElse: () => <String, dynamic>{},
          )['id'] as String?);
    final existingCount = isUnplanned ? 0 : _entryCount(pm['id'] as String);
    final inspections = pm['machinery_inspections'] as List? ?? [];
    final internalId = existingCount < inspections.length
        ? inspections[existingCount]['internal_id'] as String?
        : null;
    setState(() {
      _entries.add({
        'project_machinery_id': isUnplanned ? null : pm['id'],
        'machinery_id': machId,
        'operator_id': null,
        'start_meter': 0,
        'end_meter': null,
        'total_hours': 0,
        'fuel_added': 0,
        'is_unplanned': isUnplanned,
        'deviation_reason_id': null,
        'notes': '',
        '_name': machName,
        '_unit_number': existingCount + 1,
        '_internal_id': internalId,
        '_is_principal': isPrincipal,
        '_is_cy': isCY,
        '_capacity': capacity,
        '_calculated_cy': 0,
        'production_value': 0,
        'production_unit': isPrincipal ? unit : null,
        'start_shift_photos': <String>[],
        'end_shift_photos': <String>[],
      });
    });
    _emit();
  }

  Future<void> _showMachineryReassignDialog(Map<String, dynamic> pm) async {
    final machName = pm['machinery_name'] ?? pm['machinery']?['description'] ?? 'Machine';
    final currentSvc = pm['quote_services']?['name'] as String?;

    String? targetSvc;
    Map<String, dynamic>? targetPm;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Reassign $machName', style: _t(fontSize: 15, fontWeight: FontWeight.w700)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (currentSvc != null) ...[
                Text('Current service:', style: TextStyle(fontSize: 11, color: AppTheme.slate400)),
                Text(currentSvc!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
              ],
              Text('Target service', style: TextStyle(fontSize: 11, color: AppTheme.slate400)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: targetSvc,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                hint: Text('Select service...', style: TextStyle(fontSize: 13)),
                items: _allServices()
                  .where((s) => s != currentSvc)
                  .map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(fontSize: 13))))
                  .toList(),
                onChanged: (v) {
                  setDialogState(() {
                    targetSvc = v;
                    targetPm = widget.plannedMachinery.cast<Map<String, dynamic>?>().firstWhere(
                      (p) => p?['quote_services']?['name'] == v && p?['machinery_name'] == pm['machinery_name'],
                      orElse: () => widget.plannedMachinery.cast<Map<String, dynamic>?>().firstWhere(
                        (p) => p?['quote_services']?['name'] == v && p?['machinery']?['description'] == pm['machinery']?['description'],
                        orElse: () => widget.plannedMachinery.cast<Map<String, dynamic>?>().firstWhere(
                          (p) => p?['quote_services']?['name'] == v,
                          orElse: () => null,
                        ),
                      ),
                    );
                  });
                },
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: targetSvc != null && targetPm != null ? () {
                _addEntry(targetPm!);
                Navigator.pop(ctx);
              } : targetSvc != null && targetPm == null ? () {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('No matching machinery found for selected service')));
              } : null,
              child: Text(targetPm != null ? 'Reassign' : 'Select a service'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeEntry(int index) {
    setState(() => _entries.removeAt(index));
    _emit();
  }

  void _updateEntry(int index, String key, dynamic value) {
    setState(() {
      _entries[index][key] = value;
      if (key == 'start_meter' || key == 'end_meter') {
        final start = (_entries[index]['start_meter'] as num?)?.toDouble() ?? 0;
        final end = (_entries[index]['end_meter'] as num?)?.toDouble() ?? 0;
        if (end > start) {
          _entries[index]['total_hours'] = end - start;
        }
      }
    });
    _emit();
  }

  String _workerName(String? wid) {
    if (wid == null) return 'Select operator...';
    final w = widget.workers.firstWhere((x) => x['id'] == wid, orElse: () => <String, dynamic>{});
    final roleDesc = w['role']?['description'] as String? ?? '';
    if (roleDesc.isNotEmpty) {
      return '${w['full_name'] ?? '?'} — $roleDesc (${w['id_number'] ?? '-'})';
    }
    return '${w['full_name'] ?? '?'} (${w['id_number'] ?? '-'})';
  }

  String? _getOperatorRoleId(Map<String, dynamic> pm) {
    final machId = pm['machinery_id'] as String?;
    var opRoleId = pm['machinery']?['operator_role_id'] as String?;
    if (opRoleId == null && machId != null) {
      opRoleId = widget.machineryCatalog.firstWhere(
        (m) => m['id'] == machId,
        orElse: () => <String, dynamic>{},
      )['operator_role_id'] as String?;
    }
    if (opRoleId == null) {
      final machName = pm['machinery_name'] ?? pm['machinery']?['description'] ?? '';
      final machNameLower = machName.toString().toLowerCase();
      opRoleId = widget.machineryCatalog.firstWhere(
        (m) => (m['description'] as String? ?? '').toLowerCase() == machNameLower,
        orElse: () => <String, dynamic>{},
      )['operator_role_id'] as String?;
    }
    return opRoleId;
  }

  int Function(Map<String, dynamic>, Map<String, dynamic>) _byRoleMatch(String? targetRoleId) {
    return (Map<String, dynamic> a, Map<String, dynamic> b) {
      final aMatch = targetRoleId != null && a['role']?['id'] == targetRoleId;
      final bMatch = targetRoleId != null && b['role']?['id'] == targetRoleId;
      if (aMatch && !bMatch) return -1;
      if (!aMatch && bMatch) return 1;
      return ((a['full_name'] as String?) ?? '').compareTo((b['full_name'] as String?) ?? '');
    };
  }

  List<Map<String, dynamic>> _getOperatorsForMachine(Map<String, dynamic> pm) {
    final svcId = pm['quote_service_id'] as String?;
    final opRoleId = _getOperatorRoleId(pm);

    debugPrint('[OpFilter] ${pm['machinery_name'] ?? pm['machinery']?['description'] ?? ''}: svcId=$svcId opRoleId=$opRoleId');

    if (svcId == null || opRoleId == null) {
      debugPrint('[OpFilter] svcId or opRoleId is null, returning all workers');
      return List<Map<String, dynamic>>.from(_activeWorkers)..sort(_byRoleMatch(null));
    }

    final svcWorkerIds = <String>{};
    for (final pl in widget.plannedLabor) {
      if (pl['quote_service_id'] != svcId) continue;
      final assignments = pl['project_labor_assignments'] as List? ?? [];
      for (final a in assignments) {
        final w = a['workers'] as Map<String, dynamic>?;
        if (w != null) svcWorkerIds.add(w['id'] as String);
      }
    }

    debugPrint('[OpFilter] svcWorkerIds=${svcWorkerIds.length}');

    if (svcWorkerIds.isEmpty) {
      debugPrint('[OpFilter] no workers assigned to service, returning all');
      return List<Map<String, dynamic>>.from(_activeWorkers)..sort(_byRoleMatch(opRoleId));
    }

    final result = _activeWorkers.where((w) => svcWorkerIds.contains(w['id'])).toList();
    result.sort(_byRoleMatch(opRoleId));
    debugPrint('[OpFilter] returning ${result.length} operators sorted by role match');
    return result;
  }

  List<DropdownMenuItem<String>> _buildOperatorItems(List<Map<String, dynamic>> operators, Map<String, dynamic>? pm) {
    final opRoleId = pm != null ? _getOperatorRoleId(pm) : null;
    final matching = operators.where((w) => w['role']?['id'] == opRoleId).toList();
    final others = operators.where((w) => w['role']?['id'] != opRoleId).toList();

    final items = <DropdownMenuItem<String>>[];

    if (matching.isNotEmpty && opRoleId != null) {
      items.add(const DropdownMenuItem<String>(
        enabled: false,
        value: '',
        child: Text('── Qualified operators ──', style: TextStyle(color: AppTheme.slate400, fontSize: 11)),
      ));
      items.addAll(matching.map((w) => DropdownMenuItem<String>(
        value: w['id'] as String?,
        child: Text(_workerName(w['id'] as String?), style: TextStyle(fontSize: 11)),
      )));
    }

    if (others.isNotEmpty) {
      if (items.isNotEmpty) {
        items.add(const DropdownMenuItem<String>(
          enabled: false,
          value: '',
          child: Text('── Other workers ──', style: TextStyle(color: AppTheme.slate400, fontSize: 11)),
        ));
      }
      items.addAll(others.map((w) => DropdownMenuItem<String>(
        value: w['id'] as String?,
        child: Text(_workerName(w['id'] as String?), style: TextStyle(fontSize: 11)),
      )));
    }

    return items;
  }

  Widget _buildRateUpliftToggle(int index, Map<String, dynamic> entry, Map<String, dynamic> pm) {
    if (widget.isReadOnly) return const SizedBox.shrink();
    final currentOpId = entry['operator_id'] as String?;
    if (currentOpId == null) return const SizedBox.shrink();

    final opRoleId = _getOperatorRoleId(pm);
    if (opRoleId == null) return const SizedBox.shrink();

    final opRoleRate = widget.workers
        .map((w) => w['role'] as Map<String, dynamic>?)
        .where((r) => r?['id'] == opRoleId)
        .map((r) => (r?['hourly_rate'] as num?)?.toDouble())
        .firstOrNull;
    if (opRoleRate == null) return const SizedBox.shrink();

    final worker = widget.workers.firstWhere(
      (w) => w['id'] == currentOpId,
      orElse: () => <String, dynamic>{},
    );
    final workerRate = (worker['role']?['hourly_rate'] as num?)?.toDouble() ?? 0;

    if (workerRate >= opRoleRate) return const SizedBox.shrink();

    final isEnabled = entry['rate_override'] != null;
    final opRoleName = widget.workers
        .map((w) => w['role'] as Map<String, dynamic>?)
        .where((r) => r?['id'] == opRoleId)
        .map((r) => r?['description'] as String?)
        .firstOrNull ?? 'Operator';

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(children: [
        Switch(
          value: isEnabled,
          onChanged: (v) {
            _updateEntry(index, 'rate_override', v ? opRoleRate : null);
          },
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Pay as $opRoleName (\$${opRoleRate.toStringAsFixed(2)}/h instead of \$${workerRate.toStringAsFixed(2)}/h)',
            style: TextStyle(fontSize: 11, color: isEnabled ? AppTheme.primaryGreen : AppTheme.slate500),
          ),
        ),
      ]),
    );
  }

  List<Map<String, dynamic>> _filteredMachinery() {
    if (_serviceFilter == null) return widget.plannedMachinery;
    return widget.plannedMachinery.where((pm) {
      final svc = pm['quote_services']?['name'] as String?;
      return svc == _serviceFilter;
    }).toList();
  }

  List<String> _allServices() {
    final names = <String>{};
    for (final pm in widget.plannedMachinery) {
      final n = pm['quote_services']?['name'] as String?;
      if (n != null) names.add(n);
    }
    return names.toList()..sort();
  }

  Map<String?, List<Map<String, dynamic>>> _groupByService(List<Map<String, dynamic>> list) {
    final map = <String?, List<Map<String, dynamic>>>{};
    for (final pm in list) {
      final svc = pm['quote_services']?['name'] as String? ?? 'Unassigned';
      map.putIfAbsent(svc, () => []).add(pm);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMachinery();
    final grouped = _groupByService(filtered);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildServiceFilter(),
      const SizedBox(height: 12),
      if (filtered.isEmpty)
        _emptyState('No machinery scheduled for this date')
      else ...[
        ...grouped.entries.map((svc) => _buildServiceGroup(svc.key ?? 'Unassigned', svc.value)),
        const SizedBox(height: 12),
        if (!widget.isReadOnly)
          TextButton.icon(
            onPressed: widget.onNavigateToBaseline,
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: Text('+ Add to Baseline', style: _t(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
          ),
      ],
    ]);
  }

  Widget _buildServiceFilter() {
    final services = _allServices();
    if (services.isEmpty) return const SizedBox.shrink();
    return Row(children: [
      Text('Service:', style: _t(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.slate500)),
      const SizedBox(width: 12),
      SizedBox(width: 260, child: DropdownButtonFormField<String>(
        value: _serviceFilter,
        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        hint: Text('All Services', style: _t(fontSize: 13)),
        items: [
          DropdownMenuItem<String>(value: null, child: Text('All Services', style: _t(fontSize: 13))),
          ...services.map((s) => DropdownMenuItem(value: s, child: Text(s, style: _t(fontSize: 13)))),
        ],
        onChanged: (v) => setState(() => _serviceFilter = v),
      )),
    ]);
  }

  Widget _buildServiceGroup(String svcName, List<Map<String, dynamic>> items) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: AppTheme.slate200.withAlpha(120), borderRadius: BorderRadius.circular(6)),
        child: Text(svcName, style: _t(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.slate700)),
      ),
      const SizedBox(height: 6),
      ...items.map((pm) => _buildMachineryCard(pm)),
    ]);
  }

  Widget _buildMachineryCard(Map<String, dynamic> pm) {
    final pmId = pm['id'] as String;
    final machName = pm['machinery_name'] ?? pm['machinery']?['description'] ?? 'Machine';
    final expectedQty = (pm['expected_quantity'] as int?) ?? 1;
    final currentCount = _entryCount(pmId);
    final entryIndices = _entriesFor(pmId);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: AppTheme.slate200)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        initiallyExpanded: currentCount > 0,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: currentCount > 0 ? AppTheme.primaryGreen.withAlpha(25) : AppTheme.slate200,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(currentCount > 0 ? Icons.check_circle : Icons.precision_manufacturing, size: 16, color: currentCount > 0 ? AppTheme.primaryGreen : AppTheme.slate500),
        ),
          title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text('$machName ($currentCount/$expectedQty)', style: _t(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900))),
            ]),
            if (pm['is_principal'] == true) _buildDailyProgress(pm, pmId, expectedQty, entryIndices),
          ],
        ),
        children: [
          if (currentCount == 0)
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Row(children: [
                Expanded(child: Text('Not registered today', style: _t(fontSize: 11, color: AppTheme.slate400))),
                if (!widget.isReadOnly) ...[
                  TextButton.icon(
                    onPressed: () => _addEntry(pm),
                    icon: const Icon(Icons.add, size: 14),
                    label: Text('Add', style: _t(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => _showMachineryReassignDialog(pm),
                    icon: const Icon(Icons.swap_horiz, size: 14),
                    label: Text('Reassign', style: _t(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
                ],
              ]),
            )
          else ...[
            for (final idx in entryIndices)
              _buildEntryForm(idx, _entries[idx], pm: pm, totalCount: entryIndices.length),
            if (currentCount < expectedQty && !widget.isReadOnly)
              Padding(
                padding: const EdgeInsets.only(left: 44, top: 4),
                child: TextButton.icon(
                  onPressed: () => _addEntry(pm),
                  icon: const Icon(Icons.add, size: 14),
                  label: Text('Add another $machName', style: _t(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                ),
              ),
          ],
        ],
      ),
    );
  }

  double _daysElapsed(Map<String, dynamic> pm) {
    final startDateStr = pm['start_date'] as String?;
    if (startDateStr == null) return 1;
    try {
      final startDate = DateTime.parse(startDateStr.split(' ')[0]);
      final refDate = widget.reportDate != null
          ? DateTime.parse(widget.reportDate!)
          : DateTime.now();
      double effectiveDays = 0;
      for (var d = startDate; !d.isAfter(refDate); d = d.add(const Duration(days: 1))) {
        effectiveDays += d.weekday == DateTime.saturday ? 0.5 : 1.0;
      }
      return effectiveDays.clamp(1.0, 9999.0);
    } catch (_) {
      return 1;
    }
  }

  Map<String, dynamic>? _findEst(Map<String, dynamic> pm) {
    final qsId = pm['quote_service_id']?.toString();
    final machId = pm['machinery_id']?.toString();
    if (qsId == null) return null;
    final byService = _estimationTargets[qsId];
    if (byService == null) return null;
    if (machId != null && byService.containsKey(machId)) return byService[machId];

    final names = <String>{
      (pm['machinery']?['description'] as String?)?.toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ?? '',
      (pm['machinery_name'] as String?)?.toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ?? '',
    }..remove('');
    if (names.isEmpty) return null;

    for (final entry in byService.values) {
      final estName = (entry['_machine_name'] as String? ?? '').toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      if (names.any((n) => n == estName || estName.contains(n) || n.contains(estName))) {
        return entry;
      }
    }
    return null;
  }

  bool _isTripBased(Map<String, dynamic> pm) {
    final unit = pm['quote_services']?['unit_of_measure']?.toString().toLowerCase() ?? '';
    final isVolumeUnit = unit == 'cy' || unit == 'ft2' || unit == 'sqft' || unit == 'sf';
    if (!isVolumeUnit) return false;
    final est = _findEst(pm);
    if (est != null) {
      final capPerTrip = (est['capacity_per_trip'] as num?)?.toDouble() ?? 0;
      final tripsPerDay = (est['trips_per_day'] as num?)?.toDouble() ?? 0;
      return capPerTrip > 0 && tripsPerDay > 0;
    }
    return true;
  }

  void _recalculateCalculatedCy() {
    for (final entry in _entries) {
      if (entry['_is_principal'] != true) continue;
      final pmId = entry['project_machinery_id'] as String?;
      if (pmId == null) continue;
      final pm = widget.plannedMachinery.firstWhere(
        (p) => p['id'] == pmId,
        orElse: () => <String, dynamic>{},
      );
      if (pm.isEmpty) continue;
      final estCap = _getEstimationCapacity(pm);
      if (estCap > 0) entry['_capacity'] = estCap;
      final cap = (entry['_capacity'] as num?)?.toDouble() ?? 0;
      final prod = (entry['production_value'] as num?)?.toDouble() ?? 0;
      if (_isTripBased(pm)) {
        entry['_calculated_cy'] = cap > 0 ? prod * cap : prod;
      } else {
        entry['_calculated_cy'] = prod;
      }
    }
  }

  double _getMachineCapacity(Map<String, dynamic> pm) {
    final cap = (pm['machinery']?['capacity_yards'] as num?)?.toDouble()
        ?? (widget.machineryCatalog.firstWhere(
            (m) => (m['description'] as String? ?? '').toLowerCase() == (pm['machinery_name'] as String? ?? '').toLowerCase(),
            orElse: () => <String, dynamic>{},
          )['capacity_yards'] as num?)?.toDouble() ?? 1;
    return cap > 0 ? cap : 1;
  }

  double _getEstimationCapacity(Map<String, dynamic> pm) {
    final est = _findEst(pm);
    if (est != null) {
      final capPerTrip = (est['capacity_per_trip'] as num?)?.toDouble() ?? 0;
      if (capPerTrip > 0) return capPerTrip;
    }
    return _getMachineCapacity(pm);
  }

  Map<String, double> _adjustMachineryProduction(
    Map<String, double> rawProd, Map<String, Map<String, Map<String, dynamic>>> est,
  ) {
    final adjusted = Map<String, double>.from(rawProd);
    for (final pm in widget.plannedMachinery) {
      final pmId = pm['id'] as String?;
      if (pmId == null || !adjusted.containsKey(pmId)) continue;
      final raw = adjusted[pmId]!;
      if (raw == 0) continue;
      final unit = pm['quote_services']?['unit_of_measure']?.toString().toLowerCase() ?? '';
      final isVolumeUnit = unit == 'cy' || unit == 'ft2' || unit == 'sqft' || unit == 'sf';
      if (!isVolumeUnit) continue;
      final qsId = pm['quote_service_id']?.toString();
      final machId = pm['machinery_id']?.toString();
      bool isTripBased = true;
      if (qsId != null) {
        final byService = est[qsId];
        if (byService != null) {
          Map<String, dynamic>? pmEst;
          if (machId != null && byService.containsKey(machId)) {
            pmEst = byService[machId];
          } else {
            final names = <String>{
              (pm['machinery']?['description'] as String?)?.toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ?? '',
              (pm['machinery_name'] as String?)?.toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ?? '',
            }..remove('');
            if (names.isNotEmpty) {
              for (final entry in byService.values) {
                final estName = (entry['_machine_name'] as String? ?? '').toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
                if (names.any((n) => n == estName || estName.contains(n) || n.contains(estName))) {
                  pmEst = entry;
                  break;
                }
              }
            }
          }
          if (pmEst != null) {
            final capPerTrip = (pmEst['capacity_per_trip'] as num?)?.toDouble() ?? 0;
            final tripsPerDay = (pmEst['trips_per_day'] as num?)?.toDouble() ?? 0;
            isTripBased = capPerTrip > 0 && tripsPerDay > 0;
          }
        }
      }
      if (isTripBased) {
        adjusted[pmId] = raw * _getEstimationCapacity(pm);
      }
    }
    return adjusted;
  }

  Map<String, List<double>> _adjustProductionList(Map<String, List<double>> raw) {
    final adjusted = Map<String, List<double>>.from(raw);
    for (final pm in widget.plannedMachinery) {
      final pmId = pm['id'] as String?;
      if (pmId == null || !adjusted.containsKey(pmId)) continue;
      final unit = pm['quote_services']?['unit_of_measure']?.toString().toLowerCase() ?? '';
      final isVolumeUnit = unit == 'cy' || unit == 'ft2' || unit == 'sqft' || unit == 'sf';
      if (!isVolumeUnit) continue;
      final cap = _getEstimationCapacity(pm);
      if (cap > 0) {
        adjusted[pmId] = adjusted[pmId]!.map((v) => v * cap).toList();
      }
    }
    return adjusted;
  }

  Widget _buildDailyProgress(Map<String, dynamic> pm, String pmId, int expectedQty, List<int> entryIndices) {
    final est = _findEst(pm);
    if (est == null) return const SizedBox.shrink();

    final tripBased = _isTripBased(pm);
    final days = _daysElapsed(pm);

    if (tripBased) {
      final tripsPerDay = ((est['trips_per_day'] as num?)?.toDouble() ?? 0) * expectedQty;
      final capPerTrip = (est['capacity_per_trip'] as num?)?.toDouble() ?? 0;
      final dailyTargetCY = capPerTrip * tripsPerDay;
      if (dailyTargetCY <= 0) return const SizedBox.shrink();

      double todayTrips = 0;
      double todayCY = 0;
      for (final idx in entryIndices) {
        final entry = _entries[idx];
        todayTrips += ((entry['production_value'] as num?)?.toDouble() ?? 0);
        todayCY += ((entry['_calculated_cy'] as num?)?.toDouble() ?? 0);
      }

      final histTrips = _rawProd[pmId] ?? 0.0;
      final histCY = _machineryProduction[pmId] ?? 0.0;
      final cumTrips = histTrips + todayTrips;
      final cumCY = histCY + todayCY;
      final cumTargetTrips = tripsPerDay * days;
      final cumTargetCY = dailyTargetCY * days;

      if (cumTargetTrips <= 0 || cumTargetCY <= 0) return const SizedBox.shrink();

      final ratioTrips = (cumTrips / cumTargetTrips).clamp(0.0, 1.0);
      final ratioCY = (cumCY / cumTargetCY).clamp(0.0, 1.0);
      final pctTrips = (ratioTrips * 100).toInt();
      final pctCY = (ratioCY * 100).toInt();

      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Trips: ${cumTrips.toStringAsFixed(0)} / ${cumTargetTrips.toStringAsFixed(0)} ($pctTrips%)    CY: ${cumCY.toStringAsFixed(0)} / ${cumTargetCY.toStringAsFixed(0)} ($pctCY%)',
            style: _t(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.slate700),
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratioTrips,
              backgroundColor: AppTheme.slate200,
              valueColor: AlwaysStoppedAnimation<Color>(pctTrips >= 80 ? AppTheme.primaryGreen : (pctTrips >= 50 ? Colors.orange : AppTheme.errorRed)),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratioCY,
              backgroundColor: AppTheme.slate200,
              valueColor: AlwaysStoppedAnimation<Color>(pctCY >= 80 ? AppTheme.primaryGreen : (pctCY >= 50 ? Colors.orange : AppTheme.errorRed)),
              minHeight: 4,
            ),
          ),
        ]),
      );
    } else {
      final dailyTarget = ((est['performance_per_day'] as num?)?.toDouble() ?? 0) * expectedQty;
      if (dailyTarget <= 0) return const SizedBox.shrink();
      final unit = pm['quote_services']?['unit_of_measure']?.toString().toUpperCase() ?? 'units';

      double todayProd = 0;
      for (final idx in entryIndices) {
        final entry = _entries[idx];
        todayProd += ((entry['production_value'] as num?)?.toDouble() ?? 0);
      }

      final historicalProd = _rawProd[pmId] ?? 0.0;
      final cumulativeProd = historicalProd + todayProd;
      final cumulativeTarget = dailyTarget * days;

      if (cumulativeTarget <= 0) return const SizedBox.shrink();

      final ratio = (cumulativeProd / cumulativeTarget).clamp(0.0, 1.0);
      final pct = (ratio * 100).toInt();
      final barColor = pct >= 80 ? AppTheme.primaryGreen : (pct >= 50 ? Colors.orange : AppTheme.errorRed);

      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'To date: ${cumulativeProd.toStringAsFixed(0)} / ${cumulativeTarget.toStringAsFixed(0)} $unit  ($pct%)',
            style: _t(fontSize: 11, fontWeight: FontWeight.w600, color: barColor),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppTheme.slate200,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 6,
            ),
          ),
        ]),
      );
    }
  }

  Future<void> _pickAndUploadPhoto(int index, String shiftKey) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = file.extension ?? 'jpg';
    final filePath = 'daily_reports/machinery/${timestamp}_${index}_$shiftKey.$ext';

    try {
      await Supabase.instance.client.storage
          .from('machinery_evidence')
          .uploadBinary(filePath, file.bytes!,
              fileOptions: FileOptions(contentType: 'image/$ext'));

      final publicUrl = Supabase.instance.client.storage
          .from('machinery_evidence')
          .getPublicUrl(filePath);

      if (index >= _entries.length) return;
      final photos = List<String>.from(_entries[index][shiftKey] as List? ?? []);
      photos.add(publicUrl);
      _updateEntry(index, shiftKey, photos);
    } catch (e) {
      debugPrint('Error uploading photo: $e');
    }
  }

  void _removePhoto(int index, String shiftKey, String url) {
    final photos = List<String>.from(_entries[index][shiftKey] as List? ?? []);
    photos.remove(url);
    _updateEntry(index, shiftKey, photos);
  }

  Widget _buildPhotoSection(int index, Map<String, dynamic> entry, String shiftKey, String label) {
    final photos = List<String>.from(entry[shiftKey] as List? ?? []);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: _t(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.slate500)),
      const SizedBox(height: 6),
      if (photos.isNotEmpty)
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final url in photos)
            Stack(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                  ),
                ),
                if (!widget.isReadOnly)
                  Positioned(
                    top: 0, right: 0,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index, shiftKey, url),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: AppTheme.errorRed, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
        ]),
      if (!widget.isReadOnly) ...[
        const SizedBox(height: 6),
        SizedBox(
          width: 72, height: 72,
          child: InkWell(
            onTap: () => _pickAndUploadPhoto(index, shiftKey),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.slate200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.add_a_photo, size: 24, color: AppTheme.slate400),
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _buildEntryProgress(int index, Map<String, dynamic> entry, int totalCount, Map<String, dynamic> pm) {
    if (entry['_is_principal'] != true) return const SizedBox.shrink();
    final est = _findEst(pm);
    if (est == null) return const SizedBox.shrink();
    final tripBased = _isTripBased(pm);
    final pmId = pm['id'] as String;
    final days = _daysElapsed(pm);
    final entryIndices = _entriesFor(pmId);
    final myPos = entryIndices.indexOf(index);
    if (myPos < 0) return const SizedBox.shrink();

    if (tripBased) {
      final tripsPerDay = (est['trips_per_day'] as num?)?.toDouble() ?? 0;
      final capPerTrip = (est['capacity_per_trip'] as num?)?.toDouble() ?? 0;
      final dailyTargetCY = capPerTrip * tripsPerDay;
      if (dailyTargetCY <= 0) return const SizedBox.shrink();

      final todayTrips = (entry['production_value'] as num?)?.toDouble() ?? 0.0;
      final todayCY = (entry['_calculated_cy'] as num?)?.toDouble() ?? 0.0;

      final histListRaw = _rawProdList[pmId] ?? [];
      final histListCY = _machineryProdList[pmId] ?? [];
      final expectedQty = entryIndices.length;
      double histTrips = 0.0;
      for (int i = myPos; i < histListRaw.length; i += expectedQty) {
        histTrips += histListRaw[i];
      }
      double histCyFromList = 0.0;
      for (int i = myPos; i < histListCY.length; i += expectedQty) {
        histCyFromList += histListCY[i];
      }
      final cumTrips = histTrips + todayTrips;
      final cumCY = histCyFromList + todayCY;
      final cumTargetTrips = tripsPerDay * days;
      final cumTargetCY = dailyTargetCY * days;

      if (cumTargetTrips <= 0 || cumTargetCY <= 0) return const SizedBox.shrink();

      final ratioTrips = (cumTrips / cumTargetTrips).clamp(0.0, 1.0);
      final ratioCY = (cumCY / cumTargetCY).clamp(0.0, 1.0);

      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Trips: ${cumTrips.toStringAsFixed(0)} / ${cumTargetTrips.toStringAsFixed(0)}    CY: ${cumCY.toStringAsFixed(0)} / ${cumTargetCY.toStringAsFixed(0)}',
            style: _t(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.slate700),
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ratioTrips,
              backgroundColor: AppTheme.slate200,
              valueColor: AlwaysStoppedAnimation<Color>(ratioTrips >= 0.8 ? AppTheme.primaryGreen : (ratioTrips >= 0.5 ? Colors.orange : AppTheme.errorRed)),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ratioCY,
              backgroundColor: AppTheme.slate200,
              valueColor: AlwaysStoppedAnimation<Color>(ratioCY >= 0.8 ? AppTheme.primaryGreen : (ratioCY >= 0.5 ? Colors.orange : AppTheme.errorRed)),
              minHeight: 4,
            ),
          ),
        ]),
      );
    } else {
      final dailyTarget = (est['performance_per_day'] as num?)?.toDouble() ?? 0;
      if (dailyTarget <= 0) return const SizedBox.shrink();
      final unit = entry['production_unit']?.toString().toUpperCase() ?? 'units';

      final todayProd = (entry['production_value'] as num?)?.toDouble() ?? 0.0;

      final histList = _rawProdList[pmId] ?? [];
      final expectedQty = entryIndices.length;
      double historicalProd = 0.0;
      for (int i = myPos; i < histList.length; i += expectedQty) {
        historicalProd += histList[i];
      }
      final cumulativeProd = historicalProd + todayProd;
      final cumulativeTarget = dailyTarget * days;

      if (cumulativeTarget <= 0) return const SizedBox.shrink();

      final ratio = (cumulativeProd / cumulativeTarget).clamp(0.0, 1.0);
      final pct = (ratio * 100).toInt();
      final barColor = pct >= 80 ? AppTheme.primaryGreen : (pct >= 50 ? Colors.orange : AppTheme.errorRed);

      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Machine ${myPos + 1}/$totalCount: ${cumulativeProd.toStringAsFixed(0)} / ${cumulativeTarget.toStringAsFixed(0)} $unit  ($pct%)',
            style: _t(fontSize: 10, fontWeight: FontWeight.w600, color: barColor),
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppTheme.slate200,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 4,
            ),
          ),
        ]),
      );
    }
  }

  Widget _buildEntryForm(int index, Map<String, dynamic> entry, {Map<String, dynamic>? pm, int totalCount = 0}) {
    final isUnplanned = entry['is_unplanned'] as bool? ?? false;
    final operators = (pm != null ? _getOperatorsForMachine(pm) : _activeWorkers).toList();
    final currentOpId = entry['operator_id'] as String?;
    if (currentOpId != null) {
      final alreadyInList = operators.any((w) => w['id'] == currentOpId);
      if (!alreadyInList) {
        final currentOp = _activeWorkers.firstWhere(
          (w) => w['id'] == currentOpId,
          orElse: () => <String, dynamic>{},
        );
        if (currentOp.isNotEmpty) {
          operators.insert(0, currentOp);
        }
      }
    }

    final takenIds = _entries
        .where((e) => e != entry)
        .map((e) => e['operator_id'] as String?)
        .where((id) => id != null)
        .toSet();
    operators.removeWhere((w) => takenIds.contains(w['id'] as String?));

    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppTheme.primaryGreen.withAlpha(10), borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (entry['_unit_number'] != null || entry['_internal_id'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(color: AppTheme.slate200, borderRadius: BorderRadius.circular(4)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (entry['_internal_id'] != null) ...[
                  Text(entry['_internal_id'] as String, style: _t(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
                  const SizedBox(width: 8),
                ],
                if (entry['_unit_number'] != null && entry['_unit_number'] != 1)
                  Text('#${entry['_unit_number']}', style: _t(fontSize: 10, fontWeight: FontWeight.w500, color: AppTheme.slate500)),
              ]),
            ),
          if (pm != null)
            _buildEntryProgress(index, entry, totalCount, pm),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (!widget.isReadOnly) ...[
                  SizedBox(
                    width: double.infinity,
                    child: DropdownButtonFormField<String>(
                      value: entry['operator_id'],
                      decoration: const InputDecoration(labelText: 'Operator', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                      style: _t(fontSize: 12),
                      items: _buildOperatorItems(operators, pm),
                      onChanged: (v) {
                        _updateEntry(index, 'operator_id', v);
                        // Clear rate_override when operator changes
                        _updateEntry(index, 'rate_override', null);
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (pm != null) _buildRateUpliftToggle(index, entry, pm),
                  Row(children: [
                    Expanded(child: _numField(index, 'start_meter', 'Start', entry['start_meter']?.toString() ?? '', (v) => _updateEntry(index, 'start_meter', v))),
                    const SizedBox(width: 6),
                    Expanded(child: _numField(index, 'end_meter', 'End', entry['end_meter']?.toString() ?? '', (v) => _updateEntry(index, 'end_meter', v))),
                    const SizedBox(width: 6),
                    _displayBadge('Diff', entry['total_hours']?.toString() ?? '--', AppTheme.slate700),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    Expanded(child: _numField(index, 'fuel_added', 'Fuel (gal)', entry['fuel_added']?.toString() ?? '', (v) => _updateEntry(index, 'fuel_added', v))),
                    if (entry['_is_principal'] == true) ...[
                      if (pm != null && _isTripBased(pm)) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: _numField(index, 'production_value', 'Trips', entry['production_value']?.toString() ?? '', (v) {
                            final capacity = _getEstimationCapacity(pm!);
                            _updateEntry(index, 'production_value', v);
                            if (capacity > 0) {
                              _updateEntry(index, '_calculated_cy', v * capacity);
                            }
                          }),
                        ),
                        const SizedBox(width: 6),
                        _displayBadge('CY/trip', _getEstimationCapacity(pm!).toStringAsFixed(0), AppTheme.slate400),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _displayBadge('Total CY', (entry['_calculated_cy'] as num?)?.toString() ?? '--', AppTheme.primaryGreen, expand: true),
                        ),
                      ] else ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _numField(index, 'production_value', 'Prod (${entry['production_unit'] ?? 'units'})', entry['production_value']?.toString() ?? '', (v) {
                            _updateEntry(index, 'production_value', v);
                            _updateEntry(index, '_calculated_cy', v);
                          }),
                        ),
                      ],
                    ],
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    if (isUnplanned)
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: entry['deviation_reason_id'],
                          decoration: const InputDecoration(labelText: 'Reason', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6)),
                          items: _machReasons.map<DropdownMenuItem<String>>((r) =>
                            DropdownMenuItem(value: r['id'] as String?, child: Text(r['description'] ?? '', style: _t(fontSize: 10)))).toList(),
                          onChanged: (v) => _updateEntry(index, 'deviation_reason_id', v),
                        ),
                      ),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed), onPressed: () => _removeEntry(index), tooltip: 'Remove'),
                  ]),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _roField('Operator', _workerName(entry['operator_id'])),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    _roField('Start', entry['start_meter']?.toString() ?? '-'),
                    const SizedBox(width: 8),
                    _roField('End', entry['end_meter']?.toString() ?? '-'),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    _roField('Diff', entry['total_hours']?.toString() ?? '-'),
                    const SizedBox(width: 8),
                    _roField('Fuel', '${entry['fuel_added'] ?? '-'} gal'),
                  ]),
                  if (pm != null && pm['is_principal'] == true) ...[
                    const SizedBox(height: 4),
                    if (entry['_is_cy'] == true) ...[
                      Row(children: [
                        _roField('Trips', entry['production_value']?.toString() ?? '-'),
                        const SizedBox(width: 8),
                        _roField('CY/trip', (entry['_capacity'] as num?)?.toString() ?? '-'),
                      ]),
                      const SizedBox(height: 4),
                      _roField('Total CY', ((entry['production_value'] as num? ?? 0) * (entry['_capacity'] as num? ?? 0)).toString()),
                    ] else
                      _roField('Production', '${entry['production_value'] ?? '-'} ${entry['production_unit'] ?? ''}'),
                  ],
                  if (isUnplanned && entry['deviation_reason_id'] != null) ...[
                    const SizedBox(height: 4),
                    _roField('Reason', _machReasons.firstWhere(
                      (r) => r['id'] == entry['deviation_reason_id'],
                      orElse: () => <String, dynamic>{},
                    )['description'] as String? ?? '-'),
                  ],
                ],
              ]),
            )),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.slate200),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _buildPhotoSection(index, entry, 'start_shift_photos', 'Start')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPhotoSection(index, entry, 'end_shift_photos', 'End')),
                ]),
              ]),
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _numField(int idx, String field, String label, String initial, ValueChanged<double> onChanged) {
    final key = '${idx}_$field';
    if (!_ctrls.containsKey(key)) {
      final isZero = initial.isEmpty || initial == '0' || initial == '0.0';
      _ctrls[key] = TextEditingController(text: isZero ? '' : initial);
    }
    return TextField(
      controller: _ctrls[key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: _t(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        labelStyle: _t(fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: AppTheme.slate200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: AppTheme.slate200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: AppTheme.primaryGreen.withAlpha(150), width: 2)),
        fillColor: AppTheme.slate50,
        filled: true,
      ),
      onChanged: (v) {
        final d = double.tryParse(v) ?? 0;
        onChanged(d);
      },
    );
  }

  Widget _displayBadge(String label, String value, Color color, {bool expand = false}) {
    return Column(
      crossAxisAlignment: expand ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
      children: [
      Text(label, style: _t(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.slate400)),
      const SizedBox(height: 2),
      Container(
        padding: EdgeInsets.symmetric(horizontal: expand ? 4 : 12, vertical: 6),
        alignment: expand ? Alignment.center : null,
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Text(value, style: _t(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ),
    ]);
  }

  Widget _roField(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: _t(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.slate400)),
      Text(value, style: _t(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.slate900)),
    ]);
  }

  Widget _emptyState(String text) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppTheme.slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.slate200)),
      child: Column(children: [
        Icon(Icons.precision_manufacturing_outlined, size: 40, color: AppTheme.slate400),
        const SizedBox(height: 8),
        Text(text, style: _t(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.slate500)),
      ]),
    );
  }

  TextStyle _t({double? fontSize, FontWeight? fontWeight, Color? color}) {
    return GoogleFonts.manrope(fontSize: fontSize, fontWeight: fontWeight, color: color);
  }
}
