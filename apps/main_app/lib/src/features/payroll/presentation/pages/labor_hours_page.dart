import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_data/noel_data.dart';
import 'package:printing/printing.dart';
import '../utils/worker_individual_report_pdf_generator.dart';
import '../utils/worker_signoff_pdf_generator.dart';
import '../utils/save_bytes.dart';

/// Read-only hours view within Labor Cost; financial period editing stays admin-only.
class LaborHoursPage extends StatefulWidget {
  final String projectId;
  final LaborHoursService? service;
  final DateTimeRange? initialRange;
  const LaborHoursPage({
    super.key,
    required this.projectId,
    this.service,
    this.initialRange,
  });
  @override
  State<LaborHoursPage> createState() => _LaborHoursPageState();
}

class _LaborHoursPageState extends State<LaborHoursPage> {
  late DateTimeRange _range;
  String? _crew, _period, _error;
  bool _busy = true, _exporting = false;
  int _generation = 0;
  Map<String, dynamic> _data = {};
  LaborHoursService get _service =>
      widget.service ?? LaborHoursService(Supabase.instance.client);
  String date(DateTime d) => d.toIso8601String().split('T').first;
  List<Map<String, dynamic>> get _rows => LaborHoursService.rows(_data['rows']);
  List<Map<String, dynamic>> get _workers => LaborHoursService.workers(_rows);
  String get _periodName =>
      'Validated hours${_crew == null ? '' : ' · selected crew'}';
  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _range =
        widget.initialRange ??
        DateTimeRange(
          start: today.subtract(const Duration(days: 13)),
          end: today,
        );
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
      _data = {};
    });
    try {
      final result = await _service.query(
        widget.projectId,
        date(_range.start),
        date(_range.end),
        crew: _crew,
      );
      if (mounted && generation == _generation) setState(() => _data = result);
    } catch (e) {
      if (mounted && generation == _generation)
        setState(
          () => _error = e is PostgrestException
              ? e.message
              : 'Unable to load worked hours.',
        );
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _pickRange() async {
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (range == null || !mounted) return;
    if (range.duration.inDays > 365) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose up to 366 days.')));
      return;
    }
    setState(() {
      _range = range;
      _crew = null;
      _period = null;
    });
    await _load();
  }

  Future<void> _export({Map<String, dynamic>? worker}) async {
    if (_workers.isEmpty || _busy || _exporting) return;
    setState(() => _exporting = true);
    try {
      final workers = _workers;
      double total(String key) =>
          workers.fold(0.0, (sum, w) => sum + (w[key] as num).toDouble());
      final title = _data['project'] as String? ?? '';
      final bytes = worker == null
          ? await WorkerSignoffPdfGenerator.generate(
              projectTitle: title,
              periodName: _periodName,
              startDate: date(_range.start),
              endDate: date(_range.end),
              workers: workers,
              totalReg: total('regular_hours'),
              totalOT: total('overtime_hours'),
              totalHours: total('total_hours'),
              totalWorkers: workers.length,
            )
          : await WorkerIndividualReportPdfGenerator.generate(
              projectTitle: title,
              periodName: _periodName,
              startDate: date(_range.start),
              endDate: date(_range.end),
              worker: worker,
              totalReg: worker['regular_hours'] as num,
              totalOT: worker['overtime_hours'] as num,
              totalHours: worker['total_hours'] as num,
              dailyLogs: _rows
                  .where(
                    (r) =>
                        r['validated'] == true &&
                        r['worker_id'] == worker['worker_id'],
                  )
                  .map(
                    (r) => {
                      ...r,
                      'check_in': r['check_in'] ?? '',
                      'check_out': r['check_out'] ?? '',
                      'notes': [
                        r['service'],
                        r['crew'],
                        if (r['transfer_id'] != null) 'Temporary loan',
                      ].where((v) => v != null).join(' / '),
                    },
                  )
                  .toList(),
            );
      if (!mounted) return;
      final filename =
          'worked_hours_${worker?['worker_id'] ?? 'signoff'}_${date(_range.start)}.pdf';
      if (worker != null) {
        // Preserve the original Labor Cost row-click / print-preview flow.
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: filename);
      } else {
        await saveBytes(bytes, filename, 'application/pdf');
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to export the time report.')),
        );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _openWorkerReport(String workerId) async {
    if (_busy || _exporting) return;
    final workers = _workers.where((w) => w['worker_id'] == workerId);
    if (workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No validated hours for this worker in the selected date range.',
          ),
        ),
      );
      return;
    }
    await _export(worker: workers.first);
  }

  String hours(dynamic value) =>
      value == null ? '—' : (value as num).toStringAsFixed(2);
  @override
  Widget build(BuildContext context) {
    final crews = LaborHoursService.rows(_data['crews']);
    final periods = LaborHoursService.rows(_data['periods']);
    final workers = _workers;
    final pending = _rows
        .where((r) => r['validated'] != true)
        .fold(0.0, (sum, r) => sum + (r['net_hours'] as num? ?? 0));
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/labor-cost')),
        title: const Text('Labor Cost · Worked hours'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _busy || _exporting ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_data['project'] != null)
            Text(
              _data['project'] as String,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _busy || _exporting ? null : _pickRange,
                icon: const Icon(Icons.date_range),
                label: Text('${date(_range.start)} → ${date(_range.end)}'),
              ),
              SizedBox(
                width: 270,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('crew-$_generation'),
                  initialValue: crews.any((c) => c['id'] == _crew)
                      ? _crew
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Crew'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All authorized crews'),
                    ),
                    ...crews.map(
                      (c) => DropdownMenuItem<String>(
                        value: c['id'] as String,
                        child: Text(
                          c['name'] as String,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: _busy || _exporting
                      ? null
                      : (v) {
                          setState(() => _crew = v);
                          _load();
                        },
                ),
              ),
              if (periods.isNotEmpty)
                SizedBox(
                  width: 270,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('period-$_generation'),
                    initialValue: _period,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Existing period',
                    ),
                    items: periods
                        .map(
                          (p) => DropdownMenuItem<String>(
                            value: p['id'] as String,
                            child: Text(
                              '${p['name']} (${p['status']})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _busy || _exporting
                        ? null
                        : (v) {
                            final p = periods.firstWhere((p) => p['id'] == v);
                            setState(() {
                              _period = v;
                              _crew = null;
                              _range = DateTimeRange(
                                start: DateTime.parse(p['start_date']),
                                end: DateTime.parse(p['end_date']),
                              );
                            });
                            _load();
                          },
                  ),
                ),
              FilledButton.icon(
                onPressed: _busy || _exporting || workers.isEmpty
                    ? null
                    : () => _export(),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Sign-off PDF'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Regular and overtime hours use validated work across the full ISO week (Monday–Sunday), before filtering. Overtime starts after 40 hours. Pending entries are shown below but excluded from totals and PDFs.',
          ),
          const SizedBox(height: 12),
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (!_busy && _error == null) ...[
            Text(
              'Validated: ${hours(workers.fold(0.0, (sum, w) => sum + (w['total_hours'] as num)))} h · Unvalidated: ${hours(pending)} h',
            ),
            const SizedBox(height: 12),
            Text(
              'Work segments',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_rows.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No worked hours for this date range.'),
              ),
            if (_rows.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  showCheckboxColumn: false,
                  columns: [
                    for (final label in [
                      'Date',
                      'Worker',
                      'Crew / Service',
                      'In',
                      'Out',
                      'Break (min)',
                      'Net h',
                      'Regular h',
                      'Overtime h',
                      'Status',
                    ])
                      DataColumn(label: Text(label)),
                  ],
                  rows: _rows
                      .map(
                        (r) => DataRow(
                          onSelectChanged: _busy || _exporting
                              ? null
                              : (_) =>
                                    _openWorkerReport(r['worker_id'] as String),
                          cells: [
                            DataCell(Text(r['date'] as String)),
                            DataCell(Text(r['worker'] as String)),
                            DataCell(
                              Text(
                                '${r['crew'] ?? 'Unassigned / legacy'} / ${r['service'] ?? r['role'] ?? ''}${r['transfer_id'] == null ? '' : ' · Loan'}',
                              ),
                            ),
                            DataCell(Text((r['check_in'] ?? '—').toString())),
                            DataCell(Text((r['check_out'] ?? '—').toString())),
                            DataCell(Text('${r['break_minutes']}')),
                            DataCell(Text(hours(r['net_hours']))),
                            DataCell(Text(hours(r['regular_hours']))),
                            DataCell(Text(hours(r['overtime_hours']))),
                            DataCell(Text(r['status'] as String)),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
