import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';

class StepMachinery extends StatefulWidget {
  final List<Map<String, dynamic>> plannedMachinery;
  final List<Map<String, dynamic>> machineryLogs;
  final List<Map<String, dynamic>> workers;
  final List<Map<String, dynamic>> deviationReasons;
  final List<Map<String, dynamic>> laborLogs;
  final List<Map<String, dynamic>> plannedLabor;
  final List<Map<String, dynamic>> machineryCatalog;
  final bool isReadOnly;
  final ValueChanged<List<Map<String, dynamic>>> onLogsChanged;

  const StepMachinery({
    super.key,
    required this.plannedMachinery,
    required this.machineryLogs,
    required this.workers,
    required this.deviationReasons,
    required this.laborLogs,
    required this.plannedLabor,
    required this.machineryCatalog,
    required this.isReadOnly,
    required this.onLogsChanged,
  });

  @override
  State<StepMachinery> createState() => _StepMachineryState();
}

class _StepMachineryState extends State<StepMachinery> {
  List<Map<String, dynamic>> _entries = [];
  String? _serviceFilter;
  final Map<String, TextEditingController> _ctrls = {};

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
  }

  @override
  void didUpdateWidget(StepMachinery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.machineryLogs != widget.machineryLogs) {
      _entries = widget.machineryLogs.map((m) => Map<String, dynamic>.from(m)).toList();
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
    final existingCount = isUnplanned ? 0 : _entryCount(pm['id'] as String);
    final inspections = pm['machinery_inspections'] as List? ?? [];
    final internalId = existingCount < inspections.length
        ? inspections[existingCount]['internal_id'] as String?
        : null;
    setState(() {
      _entries.add({
        'project_machinery_id': isUnplanned ? null : pm['id'],
        'machinery_id': pm['machinery_id'],
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
        'production_value': 0,
        'production_unit': isPrincipal ? unit : null,
      });
    });
    _emit();
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
    final role = w['role']?['description'] as String? ?? 'Sin rol';
    final name = '${w['full_name'] ?? '?'} (${w['id_number'] ?? '-'})';
    return '$name — $role';
  }

  List<Map<String, dynamic>> _getOperatorsForMachine(Map<String, dynamic> pm) {
    final svcId = pm['quote_service_id'] as String?;
    final machId = pm['machinery_id'] as String?;
    final machName = pm['machinery_name'] ?? pm['machinery']?['description'] ?? machId;

    var opRoleId = pm['machinery']?['operator_role_id'] as String?;
    if (opRoleId == null && machId != null) {
      final cat = widget.machineryCatalog.firstWhere(
        (m) => m['id'] == machId,
        orElse: () => <String, dynamic>{},
      );
      opRoleId = cat['operator_role_id'] as String?;
    }
    if (opRoleId == null) {
      final machNameLower = machName.toString().toLowerCase();
      final cat = widget.machineryCatalog.firstWhere(
        (m) => (m['description'] as String? ?? '').toLowerCase() == machNameLower,
        orElse: () => <String, dynamic>{},
      );
      opRoleId = cat['operator_role_id'] as String?;
    }

    debugPrint('[OpFilter] $machName: svcId=$svcId opRoleId=$opRoleId');

    if (svcId == null || opRoleId == null) {
      debugPrint('[OpFilter] $machName: svcId or opRoleId is null, returning all workers');
      return _activeWorkers;
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

    debugPrint('[OpFilter] $machName: svcWorkerIds=${svcWorkerIds.length}');

    if (svcWorkerIds.isEmpty) {
      debugPrint('[OpFilter] $machName: no workers assigned to service');
      return _activeWorkers;
    }

    final filtered = _activeWorkers.where((w) {
      if (!svcWorkerIds.contains(w['id'])) return false;
      return w['role']?['id'] == opRoleId;
    }).toList();

    debugPrint('[OpFilter] $machName: returning ${filtered.length} operators');

    if (filtered.isEmpty) {
      debugPrint('[OpFilter] $machName: no workers with role, falling back to all service workers');
      return _activeWorkers.where((w) => svcWorkerIds.contains(w['id'])).toList();
    }

    return filtered;
  }

  List<Map<String, dynamic>> _filteredMachinery() {
    if (_serviceFilter == null) return widget.plannedMachinery;
    return widget.plannedMachinery.where((pm) {
      final svc = pm['quote_services']?['name'] as String?;
      return svc == _serviceFilter;
    }).toList();
  }

  List<Map<String, dynamic>> _filteredExtras() {
    final visibleIds = _filteredMachinery().map((pm) => pm['id'] as String).toSet();
    return _entries.where((e) {
      if (e['is_unplanned'] == true && e['project_machinery_id'] == null) return true;
      final pid = e['project_machinery_id'] as String?;
      if (pid != null && !visibleIds.contains(pid)) return true;
      return false;
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

  void _showAddExtraDialog() {
    final addedIds = _entries.map((e) => e['project_machinery_id'] as String?).toSet();
    final available = widget.plannedMachinery.where((pm) => !addedIds.contains(pm['id'] as String?)).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All planned machinery already added', style: _t(fontSize: 13))),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) {
        String? pid;
        return StatefulBuilder(builder: (ctx, setD) {
          return AlertDialog(
            title: Text('Add Extra Machinery', style: _t(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.slate900)),
            content: SizedBox(
              width: 400,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select machinery'),
                isExpanded: true,
                items: available
                    .map((pm) => DropdownMenuItem<String>(
                        value: pm['id'] as String?,
                        child: Text(pm['machinery_name'] ?? pm['machinery']?['description'] ?? '', style: _t(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setD(() => pid = v),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: pid != null ? () { Navigator.pop(ctx); final pm = available.firstWhere((x) => x['id'] == pid); _addEntry(pm, isUnplanned: true); } : null,
                child: const Text('Add')),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredMachinery();
    final grouped = _groupByService(filtered);
    final extras = _filteredExtras();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildServiceFilter(),
      const SizedBox(height: 12),
      if (filtered.isEmpty && extras.isEmpty)
        _emptyState('No machinery scheduled for this date')
      else ...[
        ...grouped.entries.map((svc) => _buildServiceGroup(svc.key ?? 'Unassigned', svc.value)),
        if (extras.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildExtrasCard(extras),
        ],
        const SizedBox(height: 12),
        if (!widget.isReadOnly)
          TextButton.icon(
            onPressed: _showAddExtraDialog,
            icon: const Icon(Icons.precision_manufacturing, size: 16),
            label: Text('+ Extra Machinery', style: _t(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
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
        title: Row(children: [
          Expanded(child: Text('$machName ($currentCount/$expectedQty)', style: _t(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.slate900))),
        ]),
        children: [
          if (currentCount == 0)
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Row(children: [
                Expanded(child: Text('Not registered today', style: _t(fontSize: 11, color: AppTheme.slate400))),
                if (!widget.isReadOnly)
                  TextButton.icon(
                    onPressed: () => _addEntry(pm),
                    icon: const Icon(Icons.add, size: 14),
                    label: Text('Add', style: _t(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ),
              ]),
            )
          else ...[
            for (final idx in entryIndices)
              _buildEntryForm(idx, _entries[idx], pm: pm),
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

  Widget _buildEntryForm(int index, Map<String, dynamic> entry, {Map<String, dynamic>? pm}) {
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
          if (!widget.isReadOnly) ...[
            SizedBox(
              width: double.infinity,
              child: DropdownButtonFormField<String>(
                value: entry['operator_id'],
                decoration: const InputDecoration(labelText: 'Operator', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                items: operators.map<DropdownMenuItem<String>>((w) =>
                  DropdownMenuItem(value: w['id'] as String?, child: Text(_workerName(w['id'] as String?), style: _t(fontSize: 12)))).toList(),
                onChanged: (v) => _updateEntry(index, 'operator_id', v),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _numField(index, 'start_meter', 'Start Meter', entry['start_meter']?.toString() ?? '', (v) => _updateEntry(index, 'start_meter', v))),
              const SizedBox(width: 10),
              Expanded(child: _numField(index, 'end_meter', 'End Meter', entry['end_meter']?.toString() ?? '', (v) => _updateEntry(index, 'end_meter', v))),
              const SizedBox(width: 10),
              _displayBadge('Total diff', entry['total_hours']?.toString() ?? '--', AppTheme.slate700),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _numField(index, 'fuel_added', 'Fuel Added (gal)', entry['fuel_added']?.toString() ?? '', (v) => _updateEntry(index, 'fuel_added', v))),
            ]),
            if (entry['_is_principal'] == true) ...[
              const SizedBox(height: 10),
              if (entry['_is_cy'] == true) ...[
                Row(children: [
                  Expanded(
                    flex: 2,
                    child: _numField(index, 'production_value', 'Trips today', entry['production_value']?.toString() ?? '', (v) {
                      final capacity = (entry['_capacity'] as num?)?.toDouble() ?? 0;
                      _updateEntry(index, 'production_value', v);
                      if (capacity > 0) {
                        _updateEntry(index, '_calculated_cy', v * capacity);
                      }
                    }),
                  ),
                  const SizedBox(width: 8),
                  _displayBadge('CY/trip', (entry['_capacity'] as num?)?.toString() ?? '--', AppTheme.slate400),
                  const SizedBox(width: 8),
                  _displayBadge('Total CY', (entry['_calculated_cy'] as num?)?.toString() ?? '--', AppTheme.primaryGreen),
                ]),
              ] else
                Row(children: [
                  Expanded(
                    child: _numField(index, 'production_value', 'Production (${entry['production_unit'] ?? 'units'})', entry['production_value']?.toString() ?? '', (v) => _updateEntry(index, 'production_value', v)),
                  ),
                ]),
            ],
            const SizedBox(height: 8),
            Row(children: [
              if (isUnplanned)
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: entry['deviation_reason_id'],
                    decoration: const InputDecoration(labelText: 'Reason for extra', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6)),
                    items: _machReasons.map<DropdownMenuItem<String>>((r) =>
                      DropdownMenuItem(value: r['id'] as String?, child: Text(r['description'] ?? '', style: _t(fontSize: 10)))).toList(),
                    onChanged: (v) => _updateEntry(index, 'deviation_reason_id', v),
                  ),
                ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.errorRed), onPressed: () => _removeEntry(index), tooltip: 'Remove'),
            ]),
          ] else ...[
            _roField('Operator', _workerName(entry['operator_id'])),
            const SizedBox(height: 6),
            Row(children: [
              _roField('Start', entry['start_meter']?.toString() ?? '-'),
              const SizedBox(width: 16),
              _roField('End', entry['end_meter']?.toString() ?? '-'),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              _roField('Diff', entry['total_hours']?.toString() ?? '-'),
              const SizedBox(width: 16),
              _roField('Fuel', '${entry['fuel_added'] ?? '-'} gal'),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _buildExtrasCard(List<Map<String, dynamic>> extras) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.orange.withAlpha(130))),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        initiallyExpanded: true,
        leading: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.orange.withAlpha(30), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.precision_manufacturing, size: 16, color: Colors.orange)),
        title: Text('Extra Machinery (${extras.length})', style: _t(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.orange[800])),
        children: extras.map((e) {
          final idx = _entries.indexOf(e);
          return _buildEntryForm(idx, e);
        }).toList(),
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
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.slate200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.slate200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.primaryGreen.withAlpha(150), width: 2)),
        fillColor: AppTheme.slate50,
        filled: true,
      ),
      onChanged: (v) {
        final d = double.tryParse(v) ?? 0;
        onChanged(d);
      },
    );
  }

  Widget _displayBadge(String label, String value, Color color) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: _t(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.slate400)),
      const SizedBox(height: 2),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Text(value, style: _t(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
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
