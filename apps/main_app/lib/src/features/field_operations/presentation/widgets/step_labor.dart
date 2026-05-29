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

  const StepLabor({
    super.key,
    required this.plannedLabor,
    required this.laborLogs,
    required this.workers,
    required this.deviationReasons,
    required this.isReadOnly,
    required this.onLogsChanged,
  });

  @override
  State<StepLabor> createState() => _StepLaborState();
}

class _StepLaborState extends State<StepLabor> {
  List<Map<String, dynamic>> _entries = [];
  String? _serviceFilter;
  final Map<String, String?> _absentWorkers = {};

  List<Map<String, dynamic>> get _laborReasons => widget.deviationReasons
      .where((r) => r['category'] == 'labor' || r['category'] == 'general')
      .toList();

  List<Map<String, dynamic>> get _activeWorkers =>
      widget.workers.where((w) => w['status'] == 'Active').toList();

  @override
  void initState() {
    super.initState();
    _entries =
        widget.laborLogs.map((log) => Map<String, dynamic>.from(log)).toList();
  }

  @override
  void didUpdateWidget(StepLabor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.laborLogs != widget.laborLogs) {
      _entries = widget.laborLogs
          .map((log) => Map<String, dynamic>.from(log))
          .toList();
    }
  }

  void _emit() =>
      widget.onLogsChanged(List<Map<String, dynamic>>.from(_entries));

  bool _isInEntries(String workerId) =>
      _entries.any((e) => e['worker_id'] == workerId);
  int _entryIndex(String workerId) =>
      _entries.indexWhere((e) => e['worker_id'] == workerId);

  void _addEntry(String workerId,
      {String? plannedLaborId, bool isUnplanned = false}) {
    final now = TimeOfDay.now();
    final checkIn =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';
    setState(() {
      _entries.add({
        'worker_id': workerId,
        'project_labor_id': plannedLaborId,
        'check_in_time': isUnplanned ? checkIn : null,
        'check_out_time': null,
        'regular_hours': 0.0,
        'overtime_hours': 0.0,
        'is_unplanned': isUnplanned,
        'deviation_reason_id': null,
        'notes': '',
      });
    });
    _emit();
  }

  void _removeEntry(int index) {
    final wid = _entries[index]['worker_id'] as String?;
    setState(() {
      _entries.removeAt(index);
      _absentWorkers.remove(wid);
    });
    _emit();
  }

  void _toggleAbsent(String workerId) {
    if (_absentWorkers.containsKey(workerId)) {
      setState(() => _absentWorkers.remove(workerId));
    } else {
      final idx = _entryIndex(workerId);
      if (idx >= 0) _entries.removeAt(idx);
      setState(() => _absentWorkers[workerId] = null);
      _emit();
    }
  }

  void _updateEntryField(int index, String key, dynamic value) {
    setState(() {
      _entries[index][key] = value;
      if (key == 'check_in_time' || key == 'check_out_time') {
        _recalcHours(index);
      }
    });
    _emit();
  }

  void _recalcHours(int index) {
    final e = _entries[index];
    final ci = e['check_in_time'] as String?;
    final co = e['check_out_time'] as String?;
    if (ci == null || ci.isEmpty || co == null || co.isEmpty) {
      e['regular_hours'] = 0.0;
      e['overtime_hours'] = 0.0;
      return;
    }
    try {
      final ip = ci.split(':');
      final op = co.split(':');
      final im = int.parse(ip[0]) * 60 + int.parse(ip[1]);
      final om = int.parse(op[0]) * 60 + int.parse(op[1]);
      double total = (om - im) / 60.0;
      if (total < 0) total = 0;
      e['regular_hours'] = total > 8 ? 8.0 : total;
      e['overtime_hours'] = total > 8 ? total - 8.0 : 0.0;
    } catch (_) {
      e['regular_hours'] = 0.0;
      e['overtime_hours'] = 0.0;
    }
  }

  String _workerName(String? wid) {
    if (wid == null) return '-';
    final w = widget.workers.firstWhere((x) => x['id'] == wid,
        orElse: () => <String, dynamic>{});
    return '${w['full_name'] ?? '?'} (${w['id_number'] ?? '-'})';
  }

  // ── Filters ──

  List<Map<String, dynamic>> _filteredLabor() {
    if (_serviceFilter == null) return widget.plannedLabor;
    return widget.plannedLabor.where((pl) {
      final svc = pl['quote_services']?['name'] as String?;
      return svc == _serviceFilter;
    }).toList();
  }

  List<Map<String, dynamic>> _filteredExtras() {
    final extras = _entries
        .where(
            (e) => e['is_unplanned'] == true && e['project_labor_id'] == null)
        .toList();
    return extras;
  }

  List<String> _allServices() {
    final names = <String>{};
    for (final pl in widget.plannedLabor) {
      final n = pl['quote_services']?['name'] as String?;
      if (n != null) names.add(n);
    }
    return names.toList()..sort();
  }

  Map<String, List<Map<String, dynamic>>> _groupByService(
      List<Map<String, dynamic>> list) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final pl in list) {
      final svc = pl['quote_services']?['name'] as String? ?? 'Unassigned';
      map.putIfAbsent(svc, () => []).add(pl);
    }
    return map;
  }

  // ── Dialogs ──

  void _showAddExtraDialog() {
    final takenIds = _entries.map((e) => e['worker_id']).toSet();
    showDialog(
      context: context,
      builder: (ctx) {
        String? wid;
        return StatefulBuilder(builder: (ctx, setD) {
          return AlertDialog(
            title: Text('Add Extra Worker',
                style: _t(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900)),
            content: SizedBox(
              width: 400,
              child: DropdownButtonFormField<String>(
                decoration:
                    const InputDecoration(labelText: 'Select Worker'),
                isExpanded: true,
                items: _activeWorkers
                    .where((w) => !takenIds.contains(w['id']))
                    .map((w) => DropdownMenuItem<String>(
                        value: w['id'] as String?,
                        child: Text(
                            '${w['full_name']} (${w['id_number'] ?? '-'})',
                            style: _t(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setD(() => wid = v),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: wid != null
                    ? () {
                        Navigator.pop(ctx);
                        _addEntry(wid!, isUnplanned: true);
                      }
                    : null,
                child: const Text('Add'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _pickTime(
      BuildContext ctx, String? current, ValueChanged<String> cb) async {
    TimeOfDay initial;
    if (current != null && current.isNotEmpty) {
      final p = current.split(':');
      initial = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    } else {
      final now = TimeOfDay.now();
      initial = TimeOfDay(hour: now.hour, minute: (now.minute ~/ 15) * 15);
    }
    final picked = await showTimePicker(context: ctx, initialTime: initial);
    if (picked != null) {
      cb(
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00');
    }
  }

  String? _fmtDateRange(dynamic startStr, dynamic endStr) {
    if (startStr == null && endStr == null) return null;
    String fmt(dynamic d) {
      if (d == null) return '?';
      try {
        final dt = DateTime.parse(d.toString().split(' ')[0]);
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${months[dt.month - 1]} ${dt.day}';
      } catch (_) {
        return '?';
      }
    }
    return '${fmt(startStr)} \u2192 ${fmt(endStr)}';
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredLabor();
    final grouped = _groupByService(filtered);
    final extras = _filteredExtras();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildServiceFilter(),
      const SizedBox(height: 12),
      if (filtered.isEmpty && extras.isEmpty)
        _emptyState('No workers scheduled for this date')
      else ...[
        ...grouped.entries
            .map((svc) => _buildServiceGroup(svc.key, svc.value)),
        if (extras.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildExtrasCard(extras),
        ],
        const SizedBox(height: 12),
        if (!widget.isReadOnly)
          TextButton.icon(
            onPressed: _showAddExtraDialog,
            icon: const Icon(Icons.person_add, size: 16),
            label: Text('+ Extra Worker',
                style: _t(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen)),
          ),
      ],
    ]);
  }

  Widget _buildServiceFilter() {
    final services = _allServices();
    if (services.isEmpty) return const SizedBox.shrink();
    return Row(children: [
      Text('Service:',
          style: _t(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.slate500)),
      const SizedBox(width: 12),
      SizedBox(
        width: 260,
        child: DropdownButtonFormField<String>(
          value: _serviceFilter,
          decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          hint: Text('All Services', style: _t(fontSize: 13)),
          items: <DropdownMenuItem<String>>[
            DropdownMenuItem<String>(
                value: null,
                child: Text('All Services', style: _t(fontSize: 13))),
            ...services.map((s) => DropdownMenuItem<String>(
                value: s, child: Text(s, style: _t(fontSize: 13)))),
          ],
          onChanged: (v) => setState(() => _serviceFilter = v),
        ),
      ),
    ]);
  }

  Widget _buildServiceGroup(
      String svcName, List<Map<String, dynamic>> roles) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: AppTheme.slate200.withAlpha(120),
            borderRadius: BorderRadius.circular(6)),
        child: Text(svcName,
            style: _t(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.slate700)),
      ),
      const SizedBox(height: 6),
      ...roles.map((pl) => _buildRoleCard(pl)),
    ]);
  }

  Widget _buildRoleCard(Map<String, dynamic> pl) {
    final roleName =
        pl['role_name'] ?? pl['labor_roles']?['description'] ?? 'Worker';
    final expected = pl['expected_employees'] as int? ?? 1;
    final assignments = pl['project_labor_assignments'] as List? ?? [];

    final presentCount = assignments.where((a) {
      final w = a['workers'] as Map<String, dynamic>?;
      return w != null && _isInEntries(w['id'] as String);
    }).length;
    final activeCount = assignments.length;
    final allPresent = presentCount == activeCount && activeCount > 0;
    final pendingCount = activeCount - presentCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: AppTheme.slate200)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        initiallyExpanded: pendingCount > 0,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: allPresent
                ? AppTheme.primaryGreen.withAlpha(25)
                : AppTheme.slate200,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
              allPresent ? Icons.check_circle : Icons.engineering,
              size: 16,
              color: allPresent
                  ? AppTheme.primaryGreen
                  : AppTheme.slate500),
        ),
        title: Row(children: [
          Expanded(
              child: Text('$roleName ($presentCount/$activeCount)',
                  style: _t(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate900))),
          if (!widget.isReadOnly && pendingCount > 0)
            TextButton.icon(
              onPressed: () {
                for (final a in assignments) {
                  final w = a['workers'] as Map<String, dynamic>?;
                  if (w != null) {
                    final wid = w['id'] as String;
                    if (!_isInEntries(wid) &&
                        !_absentWorkers.containsKey(wid)) {
                      _addEntry(wid, plannedLaborId: pl['id'] as String);
                    }
                  }
                }
              },
              icon: const Icon(Icons.group_add, size: 14),
              label: Text('Add all',
                  style: _t(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen)),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
        ]),
        children: [
          if (assignments.isEmpty)
            _compactRow(
                null,
                'No workers assigned',
                Icons.info_outline,
                AppTheme.slate400,
                () {})
          else ...[
            ...assignments.map(
                (a) => _buildWorkerRow(a, pl['id'] as String)),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkerRow(
      Map<String, dynamic> assignment, String plannedLaborId) {
    final w = assignment['workers'] as Map<String, dynamic>?;
    if (w == null) return const SizedBox.shrink();

    final wid = w['id'] as String;
    final wName = '${w['full_name'] ?? '?'} (${w['id_number'] ?? '-'})';
    final inEntries = _isInEntries(wid);
    final isAbsent = _absentWorkers.containsKey(wid);
    final isReadOnly = widget.isReadOnly;
    final dateRange =
        _fmtDateRange(assignment['start_date'], assignment['end_date']);
    final entryIdx = inEntries ? _entryIndex(wid) : -1;
    final entry = inEntries ? _entries[entryIdx] : null;

    if (isAbsent) {
      String reasonText = 'None specified';
      final reasonId = _absentWorkers[wid];
      if (reasonId != null) {
        final reason = _laborReasons.firstWhere(
            (r) => r['id'] == reasonId,
            orElse: () => <String, dynamic>{});
        reasonText =
            reason['description'] as String? ?? 'Unknown';
      }
      final isReadOnlyFinal = isReadOnly;
      return _compactRow(
          wid, '$wName — Absent', Icons.person_off, Colors.orange,
          () => isReadOnlyFinal ? null : _toggleAbsent(wid),
          subtitle: 'Reason: $reasonText');
    }

    if (inEntries && entry != null) {
      return _buildExpandedRow(entryIdx, entry, wName, dateRange,
          isUnplanned: false);
    }

    final isReadOnlyFinal = isReadOnly;
    return _compactRow(
        wid, wName, Icons.add_circle_outline, AppTheme.slate400,
        () => isReadOnlyFinal
            ? null
            : _addEntry(wid, plannedLaborId: plannedLaborId),
        subtitle: dateRange,
        trailingAction: () =>
            isReadOnlyFinal ? null : _toggleAbsent(wid));
  }

  Widget _compactRow(String? workerId, String text, IconData icon,
      Color color, VoidCallback? onTap,
      {String? subtitle, VoidCallback? trailingAction}) {
    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              Text(text,
                  style: _t(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color == AppTheme.slate400
                          ? AppTheme.slate700
                          : AppTheme.slate900)),
              if (subtitle != null)
                Text(subtitle,
                    style: _t(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.slate400)),
            ])),
            if (trailingAction != null)
              InkWell(
                onTap: trailingAction,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.person_off,
                      size: 16, color: Colors.orange),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildExpandedRow(int index, Map<String, dynamic> entry,
      String wName, String? dateRange,
      {bool isUnplanned = false}) {
    final ci = entry['check_in_time'] as String?;
    final co = entry['check_out_time'] as String?;
    final ciDisplay =
        ci != null && ci.isNotEmpty ? ci.substring(0, 5) : '--:--';
    final coDisplay =
        co != null && co.isNotEmpty ? co.substring(0, 5) : '--:--';

    return Padding(
      padding: const EdgeInsets.only(left: 44, top: 4, bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppTheme.primaryGreen.withAlpha(40))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.check_circle,
                    size: 16, color: AppTheme.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                  Text(wName,
                      style: _t(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.slate900)),
                  if (dateRange != null)
                    Text(dateRange,
                        style: _t(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.slate400)),
                ])),
                if (!widget.isReadOnly)
                  IconButton(
                      icon: const Icon(Icons.close,
                          size: 16, color: AppTheme.errorRed),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _removeEntry(index),
                      tooltip: 'Remove'),
              ]),
              const SizedBox(height: 8),
              if (!widget.isReadOnly) ...[
                Row(children: [
                  Expanded(
                      child: InkWell(
                    onTap: () => _pickTime(context, ci,
                        (v) => _updateEntryField(index, 'check_in_time', v)),
                    child: _timeBox('Check-in', ciDisplay, Icons.login,
                        AppTheme.primaryGreen),
                  )),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward,
                      size: 14, color: AppTheme.slate400),
                  const SizedBox(width: 8),
                  Expanded(
                      child: InkWell(
                    onTap: () => _pickTime(context, co,
                        (v) => _updateEntryField(index, 'check_out_time', v)),
                    child: _timeBox('Check-out', coDisplay, Icons.logout,
                        AppTheme.errorRed),
                  )),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  _hoursBadge(entry['regular_hours'] as double? ?? 0,
                      AppTheme.primaryGreen),
                  const SizedBox(width: 6),
                  _hoursBadge(entry['overtime_hours'] as double? ?? 0,
                      Colors.orange),
                  const Spacer(),
                  if (isUnplanned)
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        value: entry['deviation_reason_id'],
                        decoration: const InputDecoration(
                            labelText: 'Reason',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 6)),
                        items: _laborReasons
                            .map((r) => DropdownMenuItem<String>(
                                value: r['id'] as String?,
                                child: Text(r['description'] ?? '',
                                    style: _t(fontSize: 10))))
                            .toList(),
                        onChanged: (v) => _updateEntryField(
                            index, 'deviation_reason_id', v),
                      ),
                    ),
                ]),
              ] else ...[
                Row(children: [
                  _roField('In', ciDisplay),
                  const SizedBox(width: 16),
                  _roField('Out', coDisplay),
                  const SizedBox(width: 16),
                  _hoursBadge(entry['regular_hours'] as double? ?? 0,
                      AppTheme.primaryGreen),
                  _hoursBadge(entry['overtime_hours'] as double? ?? 0,
                      Colors.orange),
                ]),
              ],
            ]),
      ),
    );
  }

  Widget _buildExtrasCard(List<Map<String, dynamic>> extras) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.orange.withAlpha(130))),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        initiallyExpanded: true,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: Colors.orange.withAlpha(30),
              borderRadius: BorderRadius.circular(6)),
          child: const Icon(Icons.person_add_alt,
              size: 16, color: Colors.orange),
        ),
        title: Text('Extra Workers (${extras.length})',
            style: _t(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.orange[800])),
        children: extras.map((e) {
          final idx = _entries.indexOf(e);
          final wName = _workerName(e['worker_id']);
          return _buildExpandedRow(
              idx >= 0 ? idx : _entries.length - 1, e, wName, null,
              isUnplanned: true);
        }).toList(),
      ),
    );
  }

  // ── Widget helpers ──

  Widget _timeBox(
      String label, String display, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(50))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(display,
            style: _t(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate900)),
      ]),
    );
  }

  Widget _hoursBadge(double hours, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12)),
      child: Text('${hours.toStringAsFixed(1)}h',
          style: _t(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _roField(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: _t(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.slate400)),
      Text(value,
          style: _t(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.slate900)),
    ]);
  }

  Widget _emptyState(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: AppTheme.slate50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.slate200)),
      child: Column(children: [
        Icon(Icons.people_outline, size: 40, color: AppTheme.slate400),
        const SizedBox(height: 8),
        Text(text,
            style: _t(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.slate500)),
      ]),
    );
  }

  TextStyle _t({double? fontSize, FontWeight? fontWeight, Color? color}) {
    return GoogleFonts.manrope(
        fontSize: fontSize, fontWeight: fontWeight, color: color);
  }
}
