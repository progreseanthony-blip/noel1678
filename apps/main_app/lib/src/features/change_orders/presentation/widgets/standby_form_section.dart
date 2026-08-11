import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:noel_core/noel_core.dart';
import 'package:intl/intl.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import '../providers/change_order_providers.dart';

class StandbyFormSection extends ConsumerStatefulWidget {
  final String projectId;
  final String? selectedDisruptionReasonId;
  final DateTime? disruptionStart;
  final DateTime? disruptionEnd;
  final int delayDays;
  final ValueChanged<int> onDelayDaysChanged;
  final List<Map<String, dynamic>> lines;
  final ValueChanged<String?> onDisruptionReasonChanged;
  final ValueChanged<DateTime?> onDisruptionStartChanged;
  final ValueChanged<DateTime?> onDisruptionEndChanged;
  final ValueChanged<List<Map<String, dynamic>>> onLinesChanged;
  final List<String>? allowedQuoteServiceIds;
  final List<String>? allowedProjectServiceIds;

  const StandbyFormSection({
    super.key,
    required this.projectId,
    this.selectedDisruptionReasonId,
    this.disruptionStart,
    this.disruptionEnd,
    this.delayDays = 0,
    required this.onDelayDaysChanged,
    required this.lines,
    required this.onDisruptionReasonChanged,
    required this.onDisruptionStartChanged,
    required this.onDisruptionEndChanged,
    required this.onLinesChanged,
    this.allowedQuoteServiceIds,
    this.allowedProjectServiceIds,
  });

  @override
  ConsumerState<StandbyFormSection> createState() => _StandbyFormSectionState();
}

class _StandbyFormSectionState extends ConsumerState<StandbyFormSection> {
  final _fmt = NumberFormat('#,##0.00', 'en_US');
  String? _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = 'machinery';
  }

  List<Map<String, dynamic>> get _machineryLines =>
      widget.lines.where((l) => l['line_type'] == 'standby_machinery').toList();
  List<Map<String, dynamic>> get _laborLines =>
      widget.lines.where((l) => l['line_type'] == 'standby_labor').toList();
  List<Map<String, dynamic>> get _materialLines =>
      widget.lines.where((l) => l['line_type'] == 'standby_material').toList();

  void _addLine(Map<String, dynamic> line) {
    final newLines = List<Map<String, dynamic>>.from(widget.lines)..add(line);
    widget.onLinesChanged(newLines);
  }

  void _removeLine(int index) {
    final newLines = List<Map<String, dynamic>>.from(widget.lines)
      ..removeAt(index);
    widget.onLinesChanged(newLines);
  }

  void _updateLine(int index, String key, dynamic value) {
    final newLines = List<Map<String, dynamic>>.from(widget.lines);
    newLines[index][key] = value;
    widget.onLinesChanged(newLines);
  }

  double _totalCompensation() {
    double total = 0;
    for (final l in widget.lines) {
      switch (l['line_type'] as String?) {
        case 'standby_machinery':
        case 'standby_labor':
          total +=
              ((l['standby_hours'] as num?)?.toDouble() ?? 0) *
              ((l['standby_rate'] as num?)?.toDouble() ?? 0);
          break;
        case 'standby_material':
          total +=
              ((l['quantity_lost'] as num?)?.toDouble() ?? 0) *
              ((l['replacement_unit_cost'] as num?)?.toDouble() ?? 0);
          break;
      }
    }
    return total;
  }

  Future<void> _pickDate(
    BuildContext ctx,
    ValueChanged<DateTime?> onPicked,
  ) async {
    final picked = await showDatePicker(
      context: ctx,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppTheme.primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  int _calculateDefaultStandbyHours() {
    final start = widget.disruptionStart;
    final end = widget.disruptionEnd;
    if (start == null || end == null) return 8;

    int totalHours = 0;
    var current = start;
    while (!current.isAfter(end)) {
      switch (current.weekday) {
        case DateTime.monday:
        case DateTime.tuesday:
        case DateTime.wednesday:
        case DateTime.thursday:
        case DateTime.friday:
          totalHours += 8;
          break;
        case DateTime.saturday:
          totalHours += 5;
          break;
      }
      current = current.add(const Duration(days: 1));
    }
    return totalHours;
  }

  int _countWorkingDays(DateTime start, DateTime end) {
    int days = 0;
    var current = start;
    while (!current.isAfter(end)) {
      if (current.weekday != DateTime.sunday) days++;
      current = current.add(const Duration(days: 1));
    }
    return days;
  }

  Widget _buildDelayDaysField() {
    final start = widget.disruptionStart;
    final end = widget.disruptionEnd;
    final computed = (start != null && end != null) ? _countWorkingDays(start, end) : 0;
    final current = widget.delayDays;
    final hasComputed = start != null && end != null;
    final ctrl = TextEditingController(
      text: current > 0 ? current.toString() : '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Schedule Delay (working days)',
                  helperText: hasComputed ? 'Auto: $computed working days from date range' : 'Set start/end dates for auto calculation',
                  helperMaxLines: 2,
                ),
                onChanged: (v) {
                  final parsed = int.tryParse(v) ?? 0;
                  widget.onDelayDaysChanged(parsed);
                },
              ),
            ),
            if (hasComputed && computed != current) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  ctrl.text = computed.toString();
                  widget.onDelayDaysChanged(computed);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Use $computed days',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (hasComputed && computed > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Schedule impact preview: project end date will be extended by ${current > 0 ? current : computed} working day(s). Resources assigned to affected services will be rescheduled automatically on approval.',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reasonsAsync = ref.watch(disruptionReasonListProvider);
    final machAsync = ref.watch(
      projectMachineryForStandbyProvider(
        widget.projectId,
        widget.allowedQuoteServiceIds,
        widget.allowedProjectServiceIds,
      ),
    );
    final laborAsync = ref.watch(
      projectLaborForStandbyProvider(
        widget.projectId,
        widget.allowedQuoteServiceIds,
        widget.allowedProjectServiceIds,
      ),
    );
    final matAsync = ref.watch(
      projectMaterialsForStandbyProvider(
        widget.projectId,
        widget.allowedQuoteServiceIds,
        widget.allowedProjectServiceIds,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Disruption header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Disruption Information',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              reasonsAsync.when(
                loading: () => const SizedBox(
                  height: 40,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Text(
                  'Error: $e',
                  style: const TextStyle(color: Colors.red),
                ),
                data: (reasons) => DropdownButtonFormField<String>(
                  value: widget.selectedDisruptionReasonId,
                  decoration: const InputDecoration(
                    labelText: 'Cause of Disruption *',
                  ),
                  isExpanded: true,
                  items: [
                    for (final r in reasons)
                      DropdownMenuItem(
                        value: r['id'] as String,
                        child: Text(
                          '${r['description'] ?? ''} (${r['category'] ?? ''})',
                          style: GoogleFonts.manrope(fontSize: 13),
                        ),
                      ),
                  ],
                  onChanged: widget.onDisruptionReasonChanged,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () =>
                          _pickDate(context, widget.onDisruptionStartChanged),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date *',
                        ),
                        child: Text(
                          widget.disruptionStart != null
                              ? DateFormat(
                                  'MMM dd, yyyy',
                                ).format(widget.disruptionStart!)
                              : 'Select date...',
                          style: GoogleFonts.manrope(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () =>
                          _pickDate(context, widget.onDisruptionEndChanged),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                        ),
                        child: Text(
                          widget.disruptionEnd != null
                              ? DateFormat(
                                  'MMM dd, yyyy',
                                ).format(widget.disruptionEnd!)
                              : 'Ongoing...',
                          style: GoogleFonts.manrope(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDelayDaysField(),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Tabs: Machinery | Labor | Materials
        Container(
          decoration: BoxDecoration(
            color: AppTheme.slate50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _tabBtn(
                'machinery',
                'Machinery',
                Icons.precision_manufacturing,
                _machineryLines.length,
              ),
              _tabBtn('labor', 'Labor', Icons.engineering, _laborLines.length),
              _tabBtn(
                'materials',
                'Materials',
                Icons.inventory,
                _materialLines.length,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tab content
        if (_selectedTab == 'machinery')
          _buildMachineryTab(machAsync)
        else if (_selectedTab == 'labor')
          _buildLaborTab(laborAsync)
        else if (_selectedTab == 'materials')
          _buildMaterialsTab(matAsync),

        const SizedBox(height: 16),

        // Total compensation
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.slate50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.slate200),
          ),
          child: Row(
            children: [
              Text(
                'Estimated Compensation: ',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${_fmt.format(_totalCompensation())}',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _totalCompensation() >= 0
                      ? AppTheme.primaryGreen
                      : AppTheme.errorRed,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabBtn(String key, String label, IconData icon, int count) {
    final active = _selectedTab == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: active ? Border.all(color: AppTheme.slate200) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? AppTheme.primaryGreen : AppTheme.slate500,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: active ? AppTheme.slate900 : AppTheme.slate500,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMachineryTab(AsyncValue<List<Map<String, dynamic>>> machAsync) {
    final usedIds = _machineryLines
        .map((l) => l['project_machinery_id'] as String?)
        .toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._machineryLines.map(
          (line) => _buildStandbyRow(
            widget.lines.indexOf(line),
            line,
            'standby_machinery',
          ),
        ),
        const SizedBox(height: 8),
        machAsync.when(
          loading: () => const SizedBox(
            height: 24,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (machines) {
            final available = machines
                .where((m) => !usedIds.contains(m['id'] as String?))
                .toList();
            if (available.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddMachineryDialog(available),
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Add Machinery',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: BorderSide(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLaborTab(AsyncValue<List<Map<String, dynamic>>> laborAsync) {
    final usedIds = _laborLines
        .map((l) => l['project_labor_id'] as String?)
        .toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._laborLines.map(
          (line) => _buildStandbyRow(
            widget.lines.indexOf(line),
            line,
            'standby_labor',
          ),
        ),
        const SizedBox(height: 8),
        laborAsync.when(
          loading: () => const SizedBox(
            height: 24,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (labor) {
            final available = labor
                .where((l) => !usedIds.contains(l['id'] as String?))
                .toList();
            if (available.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddLaborDialog(available),
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Add Labor',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: BorderSide(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMaterialsTab(AsyncValue<List<Map<String, dynamic>>> matAsync) {
    final usedMatIds = _materialLines
        .map((l) => l['project_material_id'] as String?)
        .toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._materialLines.map(
          (line) => _buildMaterialRow(widget.lines.indexOf(line), line),
        ),
        const SizedBox(height: 8),
        matAsync.when(
          loading: () => const SizedBox(
            height: 24,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (materials) {
            final available = materials
                .where((m) => !usedMatIds.contains(m['id'] as String?))
                .toList();
            if (available.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                        materials.isEmpty
                            ? 'No materials registered in the project or service'
                            : 'All materials have already been added',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: AppTheme.slate500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddMaterialDialog(available),
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Add Material',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  side: BorderSide(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStandbyRow(
    int index,
    Map<String, dynamic> line,
    String lineType,
  ) {
    final svcName = line['service_name'] ?? 'Resource';
    final hrs = (line['standby_hours'] as num?)?.toDouble() ?? 0;
    final rate = (line['standby_rate'] as num?)?.toDouble() ?? 0;
    final total = hrs * rate;
    final isMach = lineType == 'standby_machinery';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isMach ? Icons.precision_manufacturing : Icons.engineering,
                size: 16,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  svcName,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppTheme.errorRed,
                ),
                onPressed: () => _removeLine(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Est. Hours',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: hrs > 0 ? hrs.toString() : '',
                  style: GoogleFonts.manrope(fontSize: 13),
                  onChanged: (v) => _updateLine(
                    index,
                    'standby_hours',
                    double.tryParse(v) ?? 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Standby Rate (\$/hr)',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: rate > 0 ? rate.toString() : '',
                  style: GoogleFonts.manrope(fontSize: 13),
                  onChanged: (v) => _updateLine(
                    index,
                    'standby_rate',
                    double.tryParse(v) ?? 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.slate50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '\$${_fmt.format(total)}',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialRow(int index, Map<String, dynamic> line) {
    final name = line['service_name'] ?? 'Material';
    final qty = (line['quantity_lost'] as num?)?.toDouble() ?? 0;
    final cost = (line['replacement_unit_cost'] as num?)?.toDouble() ?? 0;
    final total = qty * cost;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory, size: 16, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppTheme.errorRed,
                ),
                onPressed: () => _removeLine(index),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Quantity Lost',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: qty > 0 ? qty.toString() : '',
                  style: GoogleFonts.manrope(fontSize: 13),
                  onChanged: (v) => _updateLine(
                    index,
                    'quantity_lost',
                    double.tryParse(v) ?? 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Replacement \$/unit',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  initialValue: cost > 0 ? cost.toString() : '',
                  style: GoogleFonts.manrope(fontSize: 13),
                  onChanged: (v) => _updateLine(
                    index,
                    'replacement_unit_cost',
                    double.tryParse(v) ?? 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.slate50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '\$${_fmt.format(total)}',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAddMachineryDialog(
    List<Map<String, dynamic>> machines,
  ) async {
    final selectedIds = <String>{};
    final defaultHours = _calculateDefaultStandbyHours();
    final result = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Select Machinery',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    if (selectedIds.length == machines.length) {
                      selectedIds.clear();
                    } else {
                      selectedIds.addAll(machines.map((m) => m['id'] as String));
                    }
                  });
                },
                child: Text(
                  selectedIds.length == machines.length ? 'Deselect All' : 'Select All',
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 350),
              child: SingleChildScrollView(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              children: machines.map((m) {
                final id = m['id'] as String;
                final name =
                    m['machinery_name'] ??
                    m['machinery']?['description'] ??
                    'Machine';
                final svcName = m['quote_services']?['name'] as String? ?? '';
                final monthlyRent = (m['quote_service_machineries']?['monthly_rent_cost'] as num?)?.toDouble() ?? 0;
                final hourlyRate = monthlyRent > 0 ? monthlyRent / 30 / 8 : 0;
                final subtitleParts = <String>[];
                if (svcName.isNotEmpty) subtitleParts.add(svcName);
                if (hourlyRate > 0) subtitleParts.add('\$${hourlyRate.toStringAsFixed(2)}/hr');
                final subtitleText = subtitleParts.isNotEmpty ? subtitleParts.join(' — ') : 'Standby compensation';
                final photoUrl = m['machinery']?['photo_url']?.toString();
                return CheckboxListTile(
                  dense: true,
                  secondary: Container(
                    width: 50,
                    height: 40,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: AppTheme.slate50),
                    clipBehavior: Clip.antiAlias,
                    child: (photoUrl != null && photoUrl.isNotEmpty)
                        ? Image.network(photoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.precision_manufacturing,
                                    size: 20, color: AppTheme.slate400))
                        : const Icon(Icons.precision_manufacturing,
                            size: 20, color: AppTheme.slate400),
                  ),
                  title: Text(
                    name,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    subtitleText,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppTheme.slate500,
                    ),
                  ),
                  value: selectedIds.contains(id),
                  onChanged: (val) {
                    setDialogState(() {
                      if (val == true) {
                        selectedIds.add(id);
                      } else {
                        selectedIds.remove(id);
                      }
                    });
                  },
                );
              }).toList(),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedIds.isEmpty
                  ? null
                  : () => Navigator.of(ctx).pop(true),
              child: Text('Add Selected (${selectedIds.length})'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      for (final m in machines) {
        final id = m['id'] as String;
        if (!selectedIds.contains(id)) continue;
        final name =
            m['machinery_name'] ??
            m['machinery']?['description'] ??
            'Machine';
        final svcName = m['quote_services']?['name'] as String? ?? '';
        final rate =
            (m['quote_service_machineries']?['monthly_rent_cost'] as num?)
                ?.toDouble() ??
            0;
        final suggestedRate = rate > 0
            ? (rate / 30 / 8).toStringAsFixed(2)
            : '0';
        _addLine({
          'project_machinery_id': id,
          'service_name': '$name ($svcName)',
          'unit_of_measure': 'hrs',
          'line_type': 'standby_machinery',
          'standby_hours': defaultHours,
          'standby_rate': double.tryParse(suggestedRate) ?? 0,
          'quantity_change': 0,
          'unit_price': double.tryParse(suggestedRate) ?? 0,
          'disruption_reason_id': widget.selectedDisruptionReasonId,
        });
      }
    }
  }

  Future<void> _showAddLaborDialog(List<Map<String, dynamic>> labor) async {
    final selectedIds = <String>{};
    final defaultHours = _calculateDefaultStandbyHours();
    final result = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Select Labor Role',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    if (selectedIds.length == labor.length) {
                      selectedIds.clear();
                    } else {
                      selectedIds.addAll(labor.map((m) => m['id'] as String));
                    }
                  });
                },
                child: Text(
                  selectedIds.length == labor.length ? 'Deselect All' : 'Select All',
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: labor.map((l) {
                final id = l['id'] as String;
                final role =
                    l['role_name'] ?? l['labor_roles']?['description'] ?? 'Worker';
                final svcName = l['quote_services']?['name'] as String? ?? '';
                final qsRate = (l['quote_service_labors']?['hourly_rate'] as num?)
                    ?.toDouble();
                final lrRate = (l['labor_roles']?['hourly_rate'] as num?)?.toDouble();
                final rate = qsRate ?? lrRate ?? 0;
                return CheckboxListTile(
                  dense: true,
                  title: Text(
                    role,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '$svcName — Rate: \$${rate.toStringAsFixed(2)}/hr',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppTheme.slate500,
                    ),
                  ),
                  value: selectedIds.contains(id),
                  onChanged: (val) {
                    setDialogState(() {
                      if (val == true) {
                        selectedIds.add(id);
                      } else {
                        selectedIds.remove(id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedIds.isEmpty
                  ? null
                  : () => Navigator.of(ctx).pop(true),
              child: Text('Add Selected (${selectedIds.length})'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      for (final l in labor) {
        final id = l['id'] as String;
        if (!selectedIds.contains(id)) continue;
        final role =
            l['role_name'] ?? l['labor_roles']?['description'] ?? 'Worker';
        final svcName = l['quote_services']?['name'] as String? ?? '';
        final qsRate = (l['quote_service_labors']?['hourly_rate'] as num?)
            ?.toDouble();
        final lrRate = (l['labor_roles']?['hourly_rate'] as num?)?.toDouble();
        final rate = qsRate ?? lrRate ?? 0;
        _addLine({
          'project_labor_id': id,
          'service_name': '$role ($svcName)',
          'unit_of_measure': 'hrs',
          'line_type': 'standby_labor',
          'standby_hours': defaultHours,
          'standby_rate': double.tryParse(rate.toStringAsFixed(2)) ?? 0,
          'quantity_change': 0,
          'unit_price': double.tryParse(rate.toStringAsFixed(2)) ?? 0,
          'disruption_reason_id': widget.selectedDisruptionReasonId,
        });
      }
    }
  }

  Future<void> _showAddMaterialDialog(
    List<Map<String, dynamic>> materials,
  ) async {
    final selectedIds = <String>{};
    final result = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Select Material',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    if (selectedIds.length == materials.length) {
                      selectedIds.clear();
                    } else {
                      selectedIds.addAll(materials.map((m) => m['id'] as String));
                    }
                  });
                },
                child: Text(
                  selectedIds.length == materials.length ? 'Deselect All' : 'Select All',
                  style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: materials.map((m) {
                final id = m['id'] as String;
                final name =
                    m['material_name'] ??
                    m['materials']?['description'] ??
                    'Material';
                final svcName = m['quote_services']?['name'] as String? ?? '';
                final price =
                    (m['quote_service_materials']?['unit_price'] as num?)
                        ?.toDouble() ??
                    0;
                final unit =
                    (m['materials']?['unit'] as String?) ?? m['unit_name'] ?? '';
                return CheckboxListTile(
                  dense: true,
                  title: Text(
                    name,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '$svcName — \$${price.toStringAsFixed(2)}/$unit',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppTheme.slate500,
                    ),
                  ),
                  value: selectedIds.contains(id),
                  onChanged: (val) {
                    setDialogState(() {
                      if (val == true) {
                        selectedIds.add(id);
                      } else {
                        selectedIds.remove(id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedIds.isEmpty
                  ? null
                  : () => Navigator.of(ctx).pop(true),
              child: Text('Add Selected (${selectedIds.length})'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      for (final m in materials) {
        final id = m['id'] as String;
        if (!selectedIds.contains(id)) continue;
        final name =
            m['material_name'] ??
            m['materials']?['description'] ??
            'Material';
        final svcName = m['quote_services']?['name'] as String? ?? '';
        final price =
            (m['quote_service_materials']?['unit_price'] as num?)
                ?.toDouble() ??
            0;
        final unit =
            (m['materials']?['unit'] as String?) ?? m['unit_name'] ?? '';
        final unitPrice = double.tryParse(price.toStringAsFixed(2)) ?? 0;
        _addLine({
          'project_material_id': id,
          'material_id': null,
          'service_name': '$name ($svcName)',
          'unit_of_measure': unit.isNotEmpty ? unit : 'und',
          'line_type': 'standby_material',
          'quantity_lost': 0,
          'replacement_unit_cost': unitPrice,
          'quantity_change': 0,
          'unit_price': unitPrice,
          'disruption_reason_id': widget.selectedDisruptionReasonId,
        });
      }
    }
  }
}
