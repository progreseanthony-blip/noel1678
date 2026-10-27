import 'package:flutter/material.dart';
import '../utils/machinery_planning_dates.dart';
import '../utils/labor_planning_dates.dart';
import 'standard_period_picker_dialog.dart';

class MachineryBatchSelection {
  final String mode;
  final DateTimeRange range;
  final List<Map<String, dynamic>> machines;
  const MachineryBatchSelection(this.mode, this.range, this.machines);
}

class MachineryBatchScheduleDialog extends StatefulWidget {
  final List<Map<String, dynamic>> machines;
  final Map<String, Map<String, DateTime?>> references;
  final Map<String, double?> durations;
  final Map<String, double> calendar;
  const MachineryBatchScheduleDialog({
    super.key,
    required this.machines,
    required this.references,
    required this.durations,
    required this.calendar,
  });
  @override
  State<MachineryBatchScheduleDialog> createState() =>
      _MachineryBatchScheduleDialogState();
}

class _MachineryBatchScheduleDialogState
    extends State<MachineryBatchScheduleDialog> {
  String mode = 'pending';
  @override
  Widget build(BuildContext context) {
    final targets = widget.machines
        .where(
          (m) =>
              mode == 'replace' || MachineryPlanningDates.missingUnits(m) > 0,
        )
        .toList();
    final units = targets.fold<int>(
      0,
      (sum, m) =>
          sum +
          (mode == 'pending'
              ? MachineryPlanningDates.missingUnits(m)
              : (m['expected_quantity'] as num).toInt()),
    );
    final names =
        widget.machines.map((m) => m['service_name'] as String).toSet().toList()
          ..sort();
    MachineryPlanningDates propose(Map<String, dynamic> m, bool saved) {
      final name = m['service_name'] as String;
      return MachineryPlanningDates.propose(
        saved ? m : {},
        referenceStart: widget.references[name]?['start'],
        referenceEnd: widget.references[name]?['end'],
        workingDays: widget.durations[name],
        calendar: widget.calendar,
      );
    }

    final reference = MachineryPlanningDates.common(
      targets.map((m) => propose(m, false)).toList(),
    );
    final initial =
        (mode == 'replace'
            ? MachineryPlanningDates.common(
                targets.map((m) => propose(m, true)).toList(),
              )
            : null) ??
        reference;
    return StandardPeriodPickerDialog(
      key: ValueKey(mode),
      title: 'Machinery Bulk Planning',
      subtitle: names.length == 1
          ? names.single
          : '${names.length} shown services',
      maxWidth: 640,
      initialStart: initial?.start,
      initialEnd: initial?.end,
      referenceLabel: 'SERVICE PERIOD (REFERENCE)',
      referenceStart: reference?.start,
      referenceEnd: reference?.end,
      referenceFallback:
          'Service periods differ or dates are missing. Choose a common range below.',
      details: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            initialValue: mode,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Action'),
            items: const [
              DropdownMenuItem(
                value: 'pending',
                child: Text('Schedule pending units'),
              ),
              DropdownMenuItem(
                value: 'replace',
                child: Text('Replace dates for all shown units'),
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => mode = v);
            },
          ),
          const SizedBox(height: 12),
          Text(
            '${targets.length} machine(s) · $units unit(s) will be updated.',
          ),
          Text(
            mode == 'pending'
                ? 'Existing unit dates are retained.'
                : 'All planned dates in the shown services will be replaced. Actual execution dates are retained.',
          ),
          if (targets.isEmpty)
            const Text(
              'No pending units. Select the replacement action to correct existing dates.',
            ),
          if (names.length > 1) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final name in names)
                      Text(
                        '$name · ${LaborPlanningDates.iso(widget.references[name]?['start']).isEmpty ? 'Not set' : LaborPlanningDates.iso(widget.references[name]?['start'])} → ${LaborPlanningDates.iso(widget.references[name]?['end']).isEmpty ? 'Not set' : LaborPlanningDates.iso(widget.references[name]?['end'])}',
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      canConfirm: targets.isNotEmpty,
      confirmLabel: 'Apply dates',
      onConfirm: (range) =>
          Navigator.pop(context, MachineryBatchSelection(mode, range, targets)),
    );
  }
}
