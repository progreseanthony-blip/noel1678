import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:noel_ui_components/noel_ui_components.dart';

class StepLabor extends StatefulWidget {
  final List<Map<String, dynamic>> plannedLabor;
  final List<Map<String, dynamic>> laborLogs;
  final List<Map<String, dynamic>> workers;
  final List<Map<String, dynamic>> deviationReasons;
  final bool isReadOnly;
  final ValueChanged<List<Map<String, dynamic>>> onLogsChanged;
  final VoidCallback? onNavigateToBaseline;

  const StepLabor({super.key, required this.plannedLabor, required this.laborLogs, required this.workers, required this.deviationReasons, required this.isReadOnly, required this.onLogsChanged, this.onNavigateToBaseline});

  @override
  State<StepLabor> createState() => _StepLaborState();
}

class _StepLaborState extends State<StepLabor> {
  List<Map<String, dynamic>> _entries = [];
  String? _serviceFilter;
  final Map<String, String?> _absentWorkers = {};

  List<Map<String, dynamic>> get _laborReasons => widget.deviationReasons.where((r) => r['category'] == 'labor' || r['category'] == 'general').toList();
  List<Map<String, dynamic>> get _activeWorkers => widget.workers.where((w) => w['status'] == 'Active').toList();

  @override
  void initState() { super.initState(); _entries = widget.laborLogs.map((l) => Map<String, dynamic>.from(l)).toList(); }
  @override
  void didUpdateWidget(StepLabor old) { super.didUpdateWidget(old); if (old.laborLogs != widget.laborLogs) _entries = widget.laborLogs.map((l) => Map<String, dynamic>.from(l)).toList(); }

  void _emit() => widget.onLogsChanged(List<Map<String, dynamic>>.from(_entries));

  String _reasonEn(String es) {
    const map = {
      'Ausencia justificada del trabajador': 'Justified worker absence',
      'Sustitución por enfermedad o emergencia': 'Sick or emergency substitution',
      'Refuerzo por retraso en la tarea': 'Reinforcement for task delay',
      'Condiciones climáticas adversas': 'Adverse weather conditions',
      'Urgencia solicitada por el cliente': 'Client urgency request',
      'Otro motivo (especificar en notas)': 'Other reason (specify in notes)',
    };
    return map[es] ?? es;
  }

  bool _isInEntries(String workerId) => _entries.any((e) => e['worker_id'] == workerId);
  int _entryIndex(String workerId) => _entries.indexWhere((e) => e['worker_id'] == workerId);
  bool _isInEntriesFor(String workerId, String plId) => _entries.any((e) => e['worker_id'] == workerId && e['project_labor_id'] == plId);
  int _entryIndexFor(String workerId, String plId) => _entries.indexWhere((e) => e['worker_id'] == workerId && e['project_labor_id'] == plId);

  String _workerName(Map<String, dynamic> w) {
    return '${w['full_name'] ?? '?'} (${w['id_number'] ?? '-'})';
  }

  String _workerNameById(String? wid) {
    if (wid == null) return '-';
    final w = widget.workers.firstWhere((x) => x['id'] == wid, orElse: () => <String, dynamic>{});
    return _workerName(w);
  }

  String? _getRoleIdForEntry(Map<String, dynamic> entry) {
    final plId = entry['project_labor_id'] as String?;
    if (plId == null) return null;
    for (final pl in widget.plannedLabor) {
      if (pl['id'] == plId) {
        return pl['role_id'] as String?
            ?? pl['labor_roles']?['id'] as String?;
      }
    }
    return null;
  }

  String? _getRoleNameForEntry(Map<String, dynamic> entry) {
    final plId = entry['project_labor_id'] as String?;
    if (plId == null) return null;
    for (final pl in widget.plannedLabor) {
      if (pl['id'] == plId) {
        return pl['role_name'] as String?
            ?? pl['labor_roles']?['description'] as String?;
      }
    }
    return null;
  }

  void _addEntry(String workerId, {String? plannedLaborId, bool isUnplanned = false}) {
    final now = TimeOfDay.now();
    final ci = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
    setState(() { _entries.add({ 'worker_id': workerId, 'project_labor_id': plannedLaborId, 'check_in_time': isUnplanned ? ci : null, 'check_out_time': null, 'regular_hours': 0.0, 'overtime_hours': 0.0, 'break_minutes': 30, 'total_net_hours': 0.0, 'is_unplanned': isUnplanned, 'deviation_reason_id': null, 'notes': '' }); });
    _emit();
  }

  void _removeEntry(int index) { final wid = _entries[index]['worker_id'] as String?; setState(() { _entries.removeAt(index); _absentWorkers.remove(wid); }); _emit(); }

  void _toggleAbsent(String workerId) {
    if (_absentWorkers.containsKey(workerId)) { setState(() => _absentWorkers.remove(workerId)); return; }
    final idx = _entryIndex(workerId);
    if (idx >= 0) _entries.removeAt(idx);
    setState(() => _absentWorkers[workerId] = null);
    _emit();
  }

  Future<void> _showReassignDialog(String workerId, String currentPlId) async {
    final worker = widget.workers.firstWhere((w) => w['id'] == workerId, orElse: () => <String, dynamic>{});
    if (worker.isEmpty) return;

    String? currentSvc;
    for (final pl in widget.plannedLabor) {
      if (pl['id'] == currentPlId) {
        currentSvc = pl['quote_services']?['name'] as String?;
        break;
      }
    }

    String? targetSvc;
    String? targetReason;

    await showSafeDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Reassign ${worker['full_name'] ?? 'Worker'}', style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w700)),
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
                onChanged: (v) => setDialogState(() => targetSvc = v),
              ),
              const SizedBox(height: 12),
              Text('Deviation reason', style: TextStyle(fontSize: 11, color: AppTheme.slate400)),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: targetReason,
                isExpanded: true,
                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                hint: Text('Select reason...', style: TextStyle(fontSize: 13)),
                items: _laborReasons.map((r) {
                  final desc = r['description'] as String? ?? '';
                  final en = _reasonEn(desc);
                  return DropdownMenuItem<String>(
                    value: r['id'] as String?,
                    child: Text(en, style: TextStyle(fontSize: 12)),
                  );
                }).toList(),
                onChanged: (v) => setDialogState(() => targetReason = v),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: targetSvc != null ? () {
                final targetPl = widget.plannedLabor.where((pl) =>
                  (pl['quote_services']?['name'] as String?) == targetSvc).toList();

                String? targetPlId;
                if (targetPl.length == 1) {
                  targetPlId = targetPl.first['id'] as String?;
                } else if (targetPl.length > 1) {
                  final roleId = worker['role_id'] as String? ?? worker['role']?['id'] as String?;
                  if (roleId != null) {
                    final match = targetPl.cast<Map<String, dynamic>?>().firstWhere(
                      (pl) => pl?['role_id'] == roleId || pl?['labor_roles']?['id'] == roleId,
                      orElse: () => null,
                    );
                    targetPlId = match?['id'] as String?;
                  }
                }
                if (targetPlId == null && targetPl.isNotEmpty) {
                  targetPlId = targetPl.first['id'] as String?;
                }

                if (targetPlId == null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('No matching services found')));
                  return;
                }

                _addEntry(workerId, plannedLaborId: targetPlId, isUnplanned: true);
                if (targetReason != null) {
                  final idx = _entryIndexFor(workerId, targetPlId);
                  if (idx >= 0) {
                    _updateEntryField(idx, 'deviation_reason_id', targetReason);
                    _updateEntryField(idx, 'notes', 'Reassigned from $currentSvc');
                  }
                }
                Navigator.pop(ctx);
              } : null,
              child: const Text('Reassign'),
            ),
          ],
        ),
      ),
    );
  }

  void _swapWorker(int index, String? newWorkerId) {
    if (newWorkerId == null) return;
    setState(() { _entries[index]['worker_id'] = newWorkerId; });
    _emit();
  }

  void _updateEntryField(int index, String key, dynamic value) {
    setState(() { _entries[index][key] = value; if (key == 'check_in_time' || key == 'check_out_time') _recalcHours(index); });
    _emit();
  }

  void _recalcHours(int index) {
    final e = _entries[index];
    final ci = e['check_in_time'] as String?; final co = e['check_out_time'] as String?;
    if (ci == null || ci.isEmpty || co == null || co.isEmpty) { e['regular_hours'] = 0.0; e['overtime_hours'] = 0.0; e['total_net_hours'] = 0.0; return; }
    try {
      final ip = ci.split(':'); final op = co.split(':');
      final im = int.parse(ip[0]) * 60 + int.parse(ip[1]); final om = int.parse(op[0]) * 60 + int.parse(op[1]);
      double span = (om - im) / 60.0; if (span < 0) span = 0;
      const breakMin = 30; const threshold = 6.0;
      final breakHr = span >= threshold ? breakMin / 60.0 : 0.0;
      final net = span - breakHr;
      e['break_minutes'] = breakHr > 0 ? breakMin : 0;
      e['total_net_hours'] = net;
      e['regular_hours'] = net > 8 ? 8.0 : net;
      e['overtime_hours'] = net > 8 ? net - 8.0 : 0.0;
    } catch (_) { e['regular_hours'] = 0.0; e['overtime_hours'] = 0.0; e['total_net_hours'] = 0.0; }
  }

  List<Map<String, dynamic>> _filteredLabor() { if (_serviceFilter == null) return widget.plannedLabor; return widget.plannedLabor.where((pl) => (pl['quote_services']?['name'] as String?) == _serviceFilter).toList(); }
  List<String> _allServices() { final ns = <String>{}; for (final pl in widget.plannedLabor) { final n = pl['quote_services']?['name'] as String?; if (n != null) ns.add(n); } return ns.toList()..sort(); }
  Map<String, List<Map<String, dynamic>>> _groupByService(List<Map<String, dynamic>> l) { final m = <String, List<Map<String, dynamic>>>{}; for (final pl in l) { final svc = pl['quote_services']?['name'] as String? ?? 'Unassigned'; m.putIfAbsent(svc, () => []).add(pl); } return m; }

  String? _fmtDateRange(dynamic s, dynamic e) { if (s == null && e == null) return null; String f(dynamic d) { if (d == null) return '?'; try { final dt = DateTime.parse(d.toString().split(' ')[0]); const ms = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']; return '${ms[dt.month-1]} ${dt.day}'; } catch (_) { return '?'; } } return '${f(s)} \u2192 ${f(e)}'; }

  Future<void> _pickTime(BuildContext ctx, String? cur, ValueChanged<String> cb) async {
    TimeOfDay i; if (cur != null && cur.isNotEmpty) { final p = cur.split(':'); i = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])); } else { final n = TimeOfDay.now(); i = TimeOfDay(hour: n.hour, minute: (n.minute ~/ 15) * 15); }
    final p = await showTimePicker(context: ctx, initialTime: i); if (p != null) cb('${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}:00');
  }

  // ── Helpers ──

  TextStyle _t({double? fs, FontWeight? w, Color? c}) => GoogleFonts.manrope(fontSize: fs, fontWeight: w, color: c);

  Widget _timeBox(String lb, String d, IconData ic, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: c.withAlpha(20), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withAlpha(50))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(ic, size: 14, color: c), const SizedBox(width: 6), Text(d, style: _t(fs: 13, w: FontWeight.w700, c: AppTheme.slate900))]));
  Widget _hoursBadge(double h, Color c) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: c.withAlpha(25), borderRadius: BorderRadius.circular(12)), child: Text('${h.toStringAsFixed(1)}h', style: _t(fs: 11, w: FontWeight.w700, c: c)));
  Widget _roField(String l, String v) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: _t(fs: 10, w: FontWeight.w600, c: AppTheme.slate400)), Text(v, style: _t(fs: 13, w: FontWeight.w600, c: AppTheme.slate900))]);
  Widget _empty(String t) => Container(width: double.infinity, padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: AppTheme.slate50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.slate200)), child: Column(children: [Icon(Icons.people_outline, size: 40, color: AppTheme.slate400), const SizedBox(height: 8), Text(t, style: _t(fs: 13, w: FontWeight.w600, c: AppTheme.slate500))]));

  // ── Layout ──

  @override
  Widget build(BuildContext c) {
    final fl = _filteredLabor(); final g = _groupByService(fl);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildServiceFilter(), const SizedBox(height: 12),
      if (fl.isEmpty) _empty('No workers scheduled for this date')
      else ...[ ...g.entries.map((svc) => _buildServiceGroup(svc.key, svc.value)),
        const SizedBox(height: 12),
        if (!widget.isReadOnly) TextButton.icon(onPressed: widget.onNavigateToBaseline, icon: const Icon(Icons.add_circle_outline, size: 16), label: Text('+ Add to Baseline', style: _t(fs: 13, w: FontWeight.w600, c: AppTheme.primaryGreen))),
      ]]);
  }

  Widget _buildServiceFilter() { final svcs = _allServices(); if (svcs.isEmpty) return const SizedBox.shrink(); return Row(children: [Text('Service:', style: _t(fs: 12, w: FontWeight.w600, c: AppTheme.slate500)), const SizedBox(width: 12), SizedBox(width: 260, child: DropdownButtonFormField<String>(value: _serviceFilter, decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)), hint: Text('All Services', style: _t(fs: 13)), items: [DropdownMenuItem<String>(value: null, child: Text('All Services', style: _t(fs: 13))), ...svcs.map((s) => DropdownMenuItem(value: s, child: Text(s, style: _t(fs: 13))))], onChanged: (v) => setState(() => _serviceFilter = v)))]); }

  Widget _buildServiceGroup(String svc, List<Map<String, dynamic>> roles) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppTheme.slate200.withAlpha(120), borderRadius: BorderRadius.circular(6)), child: Text(svc, style: _t(fs: 12, w: FontWeight.w800, c: AppTheme.slate700))), const SizedBox(height: 6), ...roles.map((pl) => _buildRoleCard(pl))]);

  Widget _buildRoleCard(Map<String, dynamic> pl) {
    final rn = pl['role_name'] ?? pl['labor_roles']?['description'] ?? 'Worker';
    final exp = pl['expected_employees'] as int? ?? 1;
    final asgn = pl['project_labor_assignments'] as List? ?? [];
    final pc = asgn.where((a) { final w = a['workers'] as Map<String, dynamic>?; return w != null && _isInEntries(w['id'] as String); }).length;
    final ac = asgn.length; final ap = pc == ac && ac > 0; final pend = ac - pc;
    return Card(margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: AppTheme.slate200)), clipBehavior: Clip.antiAlias, child: ExpansionTile(tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10), initiallyExpanded: pend > 0, leading: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: ap ? AppTheme.primaryGreen.withAlpha(25) : AppTheme.slate200, borderRadius: BorderRadius.circular(6)), child: Icon(ap ? Icons.check_circle : Icons.engineering, size: 16, color: ap ? AppTheme.primaryGreen : AppTheme.slate500)),
      title: Row(children: [Expanded(child: Text('$rn ($pc/$ac)', style: _t(fs: 13, w: FontWeight.w700, c: AppTheme.slate900))), if (!widget.isReadOnly && pend > 0) TextButton.icon(onPressed: () { for (final a in asgn) { final w = a['workers'] as Map<String, dynamic>?; if (w != null) { final wid = w['id'] as String; if (!_isInEntries(wid) && !_absentWorkers.containsKey(wid)) _addEntry(wid, plannedLaborId: pl['id'] as String); } } }, icon: const Icon(Icons.group_add, size: 14), label: Text('Add all', style: _t(fs: 11, w: FontWeight.w600, c: AppTheme.primaryGreen)), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap))]),
      children: [
        if (asgn.isEmpty) _compactRow(null, 'No workers assigned', Icons.info_outline, AppTheme.slate400, () {})
        else ...asgn.map((a) => _buildWorkerRow(a, pl['id'] as String)),
        ..._buildUnplannedEntries(pl['id'] as String),
      ]));
  }

  List<Widget> _buildUnplannedEntries(String plId) {
    final plRecord = widget.plannedLabor.firstWhere(
      (pl) => pl['id'] == plId,
      orElse: () => <String, dynamic>{},
    );
    final plannedIds = (plRecord['project_labor_assignments'] as List? ?? [])
        .map((a) {
          final w = (a as Map<String, dynamic>?)?['workers'] as Map<String, dynamic>?;
          return w?['id'] as String?;
        })
        .whereType<String>()
        .toSet();
    final unplanned = _entries.where((e) =>
      e['project_labor_id'] == plId &&
      e['is_unplanned'] == true &&
      !plannedIds.contains(e['worker_id'] as String)
    ).toList();
    if (unplanned.isEmpty) return [];
    return [
      const Padding(
        padding: EdgeInsets.only(left: 44, top: 6, bottom: 2),
        child: Text('Reassigned workers', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange)),
      ),
      ...unplanned.map((e) {
        final idx = _entries.indexOf(e);
        final wid = e['worker_id'] as String?;
        final w = _activeWorkers.firstWhere((x) => x['id'] == wid, orElse: () => <String, dynamic>{});
        final wName = _workerName(w);
        return _buildExpandedRow(idx, e, wName, null, plId: plId, isUnplanned: true);
      }),
    ];
  }

  Widget _buildWorkerRow(Map<String, dynamic> asgn, String plId) {
    final w = asgn['workers'] as Map<String, dynamic>?; if (w == null) return const SizedBox.shrink();
    final wid = w['id'] as String; final inE = _isInEntriesFor(wid, plId); final isA = _absentWorkers.containsKey(wid);
    final dr = _fmtDateRange(asgn['start_date'], asgn['end_date']); final eIdx = inE ? _entryIndexFor(wid, plId) : -1; final e = inE ? _entries[eIdx] : null;
    final r = widget.isReadOnly;

    if (isA) {
      String rt = 'None specified'; final rid = _absentWorkers[wid]; if (rid != null) { final rr = _laborReasons.firstWhere((x) => x['id'] == rid, orElse: () => {'description': 'Unknown'}); rt = rr['description'] as String? ?? 'Unknown'; }
      return Padding(padding: const EdgeInsets.only(left: 44), child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
        Icon(Icons.person_off, size: 18, color: Colors.orange),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${_workerName(w)} \u2014 Absent', style: _t(fs: 12, w: FontWeight.w600, c: AppTheme.slate900)),
          Text('Reason: $rt', style: _t(fs: 10, w: FontWeight.w500, c: AppTheme.slate400)),
        ])),
        if (!r) ...[
          TextButton.icon(
            onPressed: () => _showReassignDialog(wid, plId),
            icon: const Icon(Icons.swap_horiz, size: 14),
            label: Text('Reassign', style: _t(fs: 11, w: FontWeight.w600, c: AppTheme.primaryGreen)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ),
          InkWell(onTap: () => _toggleAbsent(wid), child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.undo, size: 16, color: AppTheme.slate400))),
        ],
      ])));
    }
    if (inE && e != null) return _buildExpandedRow(eIdx, e, _workerName(w), dr, plId: plId, isUnplanned: false, w: w);
    return Padding(padding: const EdgeInsets.only(left: 44), child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
      Icon(Icons.add_circle_outline, size: 18, color: AppTheme.slate400),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_workerName(w), style: _t(fs: 12, w: FontWeight.w600, c: AppTheme.slate700)),
        if (dr != null) Text(dr, style: _t(fs: 10, w: FontWeight.w500, c: AppTheme.slate400)),
      ])),
      if (!r) ...[
        TextButton.icon(
          onPressed: () => _showReassignDialog(wid, plId),
          icon: const Icon(Icons.swap_horiz, size: 14),
          label: Text('Reassign', style: _t(fs: 11, w: FontWeight.w600, c: AppTheme.primaryGreen)),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        ),
        InkWell(onTap: () => _toggleAbsent(wid), child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.person_off, size: 16, color: Colors.orange))),
      ],
    ])));
  }

  Widget _compactRow(String? wId, String text, IconData ic, Color col, VoidCallback? onTap, {String? sub, VoidCallback? trailing}) => Padding(padding: const EdgeInsets.only(left: 44), child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Icon(ic, size: 18, color: col), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(text, style: _t(fs: 12, w: FontWeight.w600, c: col == AppTheme.slate400 ? AppTheme.slate700 : AppTheme.slate900)), if (sub != null) Text(sub, style: _t(fs: 10, w: FontWeight.w500, c: AppTheme.slate400))])), if (trailing != null) InkWell(onTap: trailing, child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.person_off, size: 16, color: Colors.orange)))]))));

  Widget _buildWorkerSwapper(int idx, Map<String, dynamic> entry, String? dr) {
    final cwid = entry['worker_id'] as String?;
    final roleId = _getRoleIdForEntry(entry);
    final roleName = _getRoleNameForEntry(entry);
    final takenIds = _entries.where((x) => x != entry).map((x) => x['worker_id'] as String?).where((id) => id != null).toSet();
    final avail = _activeWorkers.where((w) {
      if (takenIds.contains(w['id'])) return false;
      if (roleId != null) return w['role_id'] == roleId || w['role']?['id'] == roleId;
      if (roleName != null) {
        final wRoleName = w['role']?['description'] as String? ?? '';
        return wRoleName.toUpperCase() == roleName.toUpperCase();
      }
      return true;
    }).toList();
    if (cwid != null && !avail.any((w) => w['id'] == cwid)) { final cw = _activeWorkers.firstWhere((w) => w['id'] == cwid, orElse: () => <String, dynamic>{}); if (cw.isNotEmpty) avail.insert(0, cw); }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DropdownButtonHideUnderline(child: DropdownButton<String>(value: cwid, isExpanded: true, isDense: true, style: _t(fs: 12, w: FontWeight.w700, c: AppTheme.slate900), hint: Text('Select...', style: _t(fs: 12, c: AppTheme.slate400)), items: avail.map((w) => DropdownMenuItem<String>(value: w['id'] as String?, child: Text(_workerName(w), style: _t(fs: 12, w: FontWeight.w600), overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) => _swapWorker(idx, v))),
      if (dr != null) Padding(padding: const EdgeInsets.only(top: 1), child: Text(dr, style: _t(fs: 10, w: FontWeight.w500, c: AppTheme.slate400)))]);
  }

  Widget _buildExpandedRow(int idx, Map<String, dynamic> e, String wName, String? dr, {required String plId, bool isUnplanned = false, Map<String, dynamic>? w}) {
    final ci = e['check_in_time'] as String?; final co = e['check_out_time'] as String?;
    final ciD = ci != null && ci.isNotEmpty ? ci.substring(0, 5) : '--:--'; final coD = co != null && co.isNotEmpty ? co.substring(0, 5) : '--:--';
    final bm = e['break_minutes'] as int? ?? 0; final tn = e['total_net_hours'] as double? ?? 0;
    return Padding(padding: const EdgeInsets.only(left: 44, top: 4, bottom: 6), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primaryGreen.withAlpha(10), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.primaryGreen.withAlpha(40))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.check_circle, size: 16, color: AppTheme.primaryGreen), const SizedBox(width: 8),
        Expanded(child: widget.isReadOnly ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(wName, style: _t(fs: 12, w: FontWeight.w700, c: AppTheme.slate900)), if (dr != null) Text(dr, style: _t(fs: 10, w: FontWeight.w500, c: AppTheme.slate400))]) : _buildWorkerSwapper(idx, e, dr)),
        if (!widget.isReadOnly) IconButton(icon: const Icon(Icons.close, size: 16, color: AppTheme.errorRed), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => _removeEntry(idx), tooltip: 'Remove')]),
      const SizedBox(height: 8),
      if (!widget.isReadOnly) ...[
        Row(children: [Expanded(child: InkWell(onTap: () => _pickTime(context, ci, (v) => _updateEntryField(idx, 'check_in_time', v)), child: _timeBox('Check-in', ciD, Icons.login, AppTheme.primaryGreen))), const SizedBox(width: 8), Icon(Icons.arrow_forward, size: 14, color: AppTheme.slate400), const SizedBox(width: 8), Expanded(child: InkWell(onTap: () => _pickTime(context, co, (v) => _updateEntryField(idx, 'check_out_time', v)), child: _timeBox('Check-out', coD, Icons.logout, AppTheme.errorRed)))]),
        const SizedBox(height: 8),
        Row(children: [
          _hoursBadge(e['regular_hours'] as double? ?? 0, AppTheme.primaryGreen),
          const SizedBox(width: 6),
          _hoursBadge(e['overtime_hours'] as double? ?? 0, Colors.orange),
          if (bm > 0) ...[const SizedBox(width: 6), _hoursBadge(-(bm / 60.0), AppTheme.slate400)],
          const SizedBox(width: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: AppTheme.slate200, borderRadius: BorderRadius.circular(12)), child: Text('Net ${tn.toStringAsFixed(1)}h', style: _t(fs: 10, w: FontWeight.w700, c: AppTheme.slate600))),
          TextButton.icon(
            onPressed: () => _showReassignDialog(e['worker_id'] as String, plId),
            icon: const Icon(Icons.swap_horiz, size: 14),
            label: Text('Reassign', style: _t(fs: 11, w: FontWeight.w600, c: AppTheme.primaryGreen)),
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          ),
          const Spacer(),
          if (isUnplanned || e['deviation_reason_id'] != null) Flexible(child: DropdownButtonFormField<String>(value: e['deviation_reason_id'], isExpanded: true, decoration: const InputDecoration(labelText: 'Reason', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6)), items: _laborReasons.map((r) => DropdownMenuItem<String>(value: r['id'] as String?, child: Text(r['description'] ?? '', style: _t(fs: 10)))).toList(), onChanged: (v) => _updateEntryField(idx, 'deviation_reason_id', v)))]),
      ] else ...[
        Row(children: [
          _roField('In', ciD), const SizedBox(width: 8),
          _roField('Out', coD), const SizedBox(width: 8),
          _hoursBadge(e['regular_hours'] as double? ?? 0, AppTheme.primaryGreen),
          if ((e['overtime_hours'] as double? ?? 0) > 0) ...[const SizedBox(width: 4), _hoursBadge(e['overtime_hours'] as double? ?? 0, Colors.orange)],
          if (bm > 0) ...[const SizedBox(width: 4), _hoursBadge(-(bm / 60.0), AppTheme.slate400)],
          const SizedBox(width: 4),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: AppTheme.slate200, borderRadius: BorderRadius.circular(12)), child: Text('Net ${tn.toStringAsFixed(1)}h', style: _t(fs: 10, w: FontWeight.w700, c: AppTheme.slate600))),
        ]),
        if (e['notes'] != null && (e['notes'] as String).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(e['notes'] as String, style: _t(fs: 10, w: FontWeight.w500, c: AppTheme.slate400)),
          ),
        if (isUnplanned || e['deviation_reason_id'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _roField('Reason', _laborReasons.firstWhere(
              (r) => r['id'] == e['deviation_reason_id'],
              orElse: () => <String, dynamic>{},
            )['description'] as String? ?? '-'),
          ),
      ]])));
  }

}
