import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';

class StepLabor extends StatefulWidget {
  final List<Map<String, dynamic>> plannedLabor;
  final List<Map<String, dynamic>> laborLogs;
  final List<Map<String, dynamic>> workers;
  final List<Map<String, dynamic>> deviationReasons;
  final bool isReadOnly;
  final ValueChanged<List<Map<String, dynamic>>> onLogsChanged;

  const StepLabor({super.key, required this.plannedLabor, required this.laborLogs, required this.workers, required this.deviationReasons, required this.isReadOnly, required this.onLogsChanged});

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

  bool _isInEntries(String workerId) => _entries.any((e) => e['worker_id'] == workerId);
  int _entryIndex(String workerId) => _entries.indexWhere((e) => e['worker_id'] == workerId);

  String _workerName(Map<String, dynamic> w) {
    final role = w['role']?['description'] as String? ?? '';
    final name = '${w['full_name'] ?? '?'} (${w['id_number'] ?? '-'})';
    return role.isNotEmpty ? '$name \u2014 $role' : name;
  }

  String _workerNameById(String? wid) {
    if (wid == null) return '-';
    final w = widget.workers.firstWhere((x) => x['id'] == wid, orElse: () => <String, dynamic>{});
    return _workerName(w);
  }

  void _addEntry(String workerId, {String? plannedLaborId, bool isUnplanned = false}) {
    final now = TimeOfDay.now();
    final ci = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
    setState(() { _entries.add({ 'worker_id': workerId, 'project_labor_id': plannedLaborId, 'check_in_time': isUnplanned ? ci : null, 'check_out_time': null, 'regular_hours': 0.0, 'overtime_hours': 0.0, 'is_unplanned': isUnplanned, 'deviation_reason_id': null, 'notes': '' }); });
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
    if (ci == null || ci.isEmpty || co == null || co.isEmpty) { e['regular_hours'] = 0.0; e['overtime_hours'] = 0.0; return; }
    try { final ip = ci.split(':'); final op = co.split(':'); final im = int.parse(ip[0]) * 60 + int.parse(ip[1]); final om = int.parse(op[0]) * 60 + int.parse(op[1]); double total = (om - im) / 60.0; if (total < 0) total = 0; e['regular_hours'] = total > 8 ? 8.0 : total; e['overtime_hours'] = total > 8 ? total - 8.0 : 0.0; } catch (_) { e['regular_hours'] = 0.0; e['overtime_hours'] = 0.0; }
  }

  List<Map<String, dynamic>> _filteredLabor() { if (_serviceFilter == null) return widget.plannedLabor; return widget.plannedLabor.where((pl) => (pl['quote_services']?['name'] as String?) == _serviceFilter).toList(); }
  List<Map<String, dynamic>> _filteredExtras() => _entries.where((e) => e['is_unplanned'] == true && e['project_labor_id'] == null).toList();
  List<String> _allServices() { final ns = <String>{}; for (final pl in widget.plannedLabor) { final n = pl['quote_services']?['name'] as String?; if (n != null) ns.add(n); } return ns.toList()..sort(); }
  Map<String, List<Map<String, dynamic>>> _groupByService(List<Map<String, dynamic>> l) { final m = <String, List<Map<String, dynamic>>>{}; for (final pl in l) { final svc = pl['quote_services']?['name'] as String? ?? 'Unassigned'; m.putIfAbsent(svc, () => []).add(pl); } return m; }

  String? _fmtDateRange(dynamic s, dynamic e) { if (s == null && e == null) return null; String f(dynamic d) { if (d == null) return '?'; try { final dt = DateTime.parse(d.toString().split(' ')[0]); const ms = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']; return '${ms[dt.month-1]} ${dt.day}'; } catch (_) { return '?'; } } return '${f(s)} \u2192 ${f(e)}'; }

  void _showAddExtraDialog() {
    final takenIds = _entries.map((e) => e['worker_id']).toSet();
    showDialog(context: context, builder: (ctx) {
      String? wid;
      return StatefulBuilder(builder: (ctx, setD) => AlertDialog(
        title: Text('Add Extra Worker', style: _t(fs: 16, w: FontWeight.w700, c: AppTheme.slate900)),
        content: SizedBox(width: 400, child: DropdownButtonFormField<String>(
          decoration: const InputDecoration(labelText: 'Select Worker'), isExpanded: true,
          items: _activeWorkers.where((w) => !takenIds.contains(w['id'])).map((w) => DropdownMenuItem<String>(value: w['id'] as String?, child: Text(_workerName(w), style: _t()))).toList(),
          onChanged: (v) => setD(() => wid = v),
        )),
        actions: [ TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')), ElevatedButton(onPressed: wid != null ? () { Navigator.pop(ctx); _addEntry(wid!, isUnplanned: true); } : null, child: const Text('Add')) ],
      ));
    });
  }

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
    final fl = _filteredLabor(); final g = _groupByService(fl); final ex = _filteredExtras();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildServiceFilter(), const SizedBox(height: 12),
      if (fl.isEmpty && ex.isEmpty) _empty('No workers scheduled for this date')
      else ...[ ...g.entries.map((svc) => _buildServiceGroup(svc.key, svc.value)),
        if (ex.isNotEmpty) ...[const SizedBox(height: 8), _buildExtrasCard(ex)],
        const SizedBox(height: 12),
        if (!widget.isReadOnly) TextButton.icon(onPressed: _showAddExtraDialog, icon: const Icon(Icons.person_add, size: 16), label: Text('+ Extra Worker', style: _t(fs: 13, w: FontWeight.w600, c: AppTheme.primaryGreen))),
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
      children: [if (asgn.isEmpty) _compactRow(null, 'No workers assigned', Icons.info_outline, AppTheme.slate400, () {}) else ...asgn.map((a) => _buildWorkerRow(a, pl['id'] as String))]));
  }

  Widget _buildWorkerRow(Map<String, dynamic> asgn, String plId) {
    final w = asgn['workers'] as Map<String, dynamic>?; if (w == null) return const SizedBox.shrink();
    final wid = w['id'] as String; final inE = _isInEntries(wid); final isA = _absentWorkers.containsKey(wid);
    final dr = _fmtDateRange(asgn['start_date'], asgn['end_date']); final eIdx = inE ? _entryIndex(wid) : -1; final e = inE ? _entries[eIdx] : null;
    final r = widget.isReadOnly;

    if (isA) {
      String rt = 'None specified'; final rid = _absentWorkers[wid]; if (rid != null) { final rr = _laborReasons.firstWhere((x) => x['id'] == rid, orElse: () => {'description': 'Unknown'}); rt = rr['description'] as String? ?? 'Unknown'; }
      return _compactRow(wid, '${_workerName(w)} \u2014 Absent', Icons.person_off, Colors.orange, r ? null : () => _toggleAbsent(wid), sub: 'Reason: $rt');
    }
    if (inE && e != null) return _buildExpandedRow(eIdx, e, _workerName(w), dr, isUnplanned: false, w: w);
    return _compactRow(wid, _workerName(w), Icons.add_circle_outline, AppTheme.slate400, r ? null : () => _addEntry(wid, plannedLaborId: plId), sub: dr, trailing: r ? null : () => _toggleAbsent(wid));
  }

  Widget _compactRow(String? wId, String text, IconData ic, Color col, VoidCallback? onTap, {String? sub, VoidCallback? trailing}) => Padding(padding: const EdgeInsets.only(left: 44), child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [Icon(ic, size: 18, color: col), const SizedBox(width: 8), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(text, style: _t(fs: 12, w: FontWeight.w600, c: col == AppTheme.slate400 ? AppTheme.slate700 : AppTheme.slate900)), if (sub != null) Text(sub, style: _t(fs: 10, w: FontWeight.w500, c: AppTheme.slate400))])), if (trailing != null) InkWell(onTap: trailing, child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.person_off, size: 16, color: Colors.orange)))]))));

  Widget _buildWorkerSwapper(int idx, Map<String, dynamic> entry, String? dr) {
    final cwid = entry['worker_id'] as String?;
    final takenIds = _entries.where((x) => x != entry).map((x) => x['worker_id'] as String?).where((id) => id != null).toSet();
    final avail = _activeWorkers.where((w) => !takenIds.contains(w['id'])).toList();
    if (cwid != null && !avail.any((w) => w['id'] == cwid)) { final cw = _activeWorkers.firstWhere((w) => w['id'] == cwid, orElse: () => <String, dynamic>{}); if (cw.isNotEmpty) avail.insert(0, cw); }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DropdownButtonHideUnderline(child: DropdownButton<String>(value: cwid, isExpanded: true, isDense: true, style: _t(fs: 12, w: FontWeight.w700, c: AppTheme.slate900), hint: Text('Select...', style: _t(fs: 12, c: AppTheme.slate400)), items: avail.map((w) => DropdownMenuItem<String>(value: w['id'] as String?, child: Text(_workerName(w), style: _t(fs: 12, w: FontWeight.w600), overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) => _swapWorker(idx, v))),
      if (dr != null) Padding(padding: const EdgeInsets.only(top: 1), child: Text(dr, style: _t(fs: 10, w: FontWeight.w500, c: AppTheme.slate400)))]);
  }

  Widget _buildExpandedRow(int idx, Map<String, dynamic> e, String wName, String? dr, {bool isUnplanned = false, Map<String, dynamic>? w}) {
    final ci = e['check_in_time'] as String?; final co = e['check_out_time'] as String?;
    final ciD = ci != null && ci.isNotEmpty ? ci.substring(0, 5) : '--:--'; final coD = co != null && co.isNotEmpty ? co.substring(0, 5) : '--:--';
    return Padding(padding: const EdgeInsets.only(left: 44, top: 4, bottom: 6), child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primaryGreen.withAlpha(10), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.primaryGreen.withAlpha(40))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.check_circle, size: 16, color: AppTheme.primaryGreen), const SizedBox(width: 8),
        Expanded(child: widget.isReadOnly ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(wName, style: _t(fs: 12, w: FontWeight.w700, c: AppTheme.slate900)), if (dr != null) Text(dr, style: _t(fs: 10, w: FontWeight.w500, c: AppTheme.slate400))]) : _buildWorkerSwapper(idx, e, dr)),
        if (!widget.isReadOnly) IconButton(icon: const Icon(Icons.close, size: 16, color: AppTheme.errorRed), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => _removeEntry(idx), tooltip: 'Remove')]),
      const SizedBox(height: 8),
      if (!widget.isReadOnly) ...[
        Row(children: [Expanded(child: InkWell(onTap: () => _pickTime(context, ci, (v) => _updateEntryField(idx, 'check_in_time', v)), child: _timeBox('Check-in', ciD, Icons.login, AppTheme.primaryGreen))), const SizedBox(width: 8), Icon(Icons.arrow_forward, size: 14, color: AppTheme.slate400), const SizedBox(width: 8), Expanded(child: InkWell(onTap: () => _pickTime(context, co, (v) => _updateEntryField(idx, 'check_out_time', v)), child: _timeBox('Check-out', coD, Icons.logout, AppTheme.errorRed)))]),
        const SizedBox(height: 8),
        Row(children: [_hoursBadge(e['regular_hours'] as double? ?? 0, AppTheme.primaryGreen), const SizedBox(width: 6), _hoursBadge(e['overtime_hours'] as double? ?? 0, Colors.orange), const Spacer(), if (isUnplanned) SizedBox(width: 160, child: DropdownButtonFormField<String>(value: e['deviation_reason_id'], decoration: const InputDecoration(labelText: 'Reason', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6)), items: _laborReasons.map((r) => DropdownMenuItem<String>(value: r['id'] as String?, child: Text(r['description'] ?? '', style: _t(fs: 10)))).toList(), onChanged: (v) => _updateEntryField(idx, 'deviation_reason_id', v)))]),
      ] else ...[
        Row(children: [_roField('In', ciD), const SizedBox(width: 16), _roField('Out', coD), const SizedBox(width: 16), _hoursBadge(e['regular_hours'] as double? ?? 0, AppTheme.primaryGreen), _hoursBadge(e['overtime_hours'] as double? ?? 0, Colors.orange)]),
      ]])));
  }

  Widget _buildExtrasCard(List<Map<String, dynamic>> ex) => Card(margin: const EdgeInsets.only(bottom: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.orange.withAlpha(130))), clipBehavior: Clip.antiAlias, child: ExpansionTile(tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10), initiallyExpanded: true, leading: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.orange.withAlpha(30), borderRadius: BorderRadius.circular(6)), child: const Icon(Icons.person_add_alt, size: 16, color: Colors.orange)), title: Text('Extra Workers (${ex.length})', style: _t(fs: 13, w: FontWeight.w700, c: Colors.orange[800])), children: ex.map((e) { final i = _entries.indexOf(e); return _buildExpandedRow(i >= 0 ? i : _entries.length - 1, e, _workerNameById(e['worker_id']), null, isUnplanned: true); }).toList()));
}
