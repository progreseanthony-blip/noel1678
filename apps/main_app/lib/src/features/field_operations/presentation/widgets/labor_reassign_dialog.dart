import 'package:flutter/material.dart';

class LaborReassignment {
  final String crew, labor, start, end, reason;
  const LaborReassignment(
    this.crew,
    this.labor,
    this.start,
    this.end,
    this.reason,
  );
}

class LaborReassignDialog extends StatefulWidget {
  final String crew, labor, workerName, initialStart;
  final bool borrowed;
  final List<Map<String, dynamic>> crews, laborOptions;
  const LaborReassignDialog({
    super.key,
    required this.crew,
    required this.labor,
    required this.workerName,
    required this.initialStart,
    required this.crews,
    required this.laborOptions,
    this.borrowed = false,
  });
  @override
  State<LaborReassignDialog> createState() => _LaborReassignDialogState();
}

class _LaborReassignDialogState extends State<LaborReassignDialog> {
  late String crew = widget.crew;
  String? labor;
  late String start = widget.initialStart;
  String? end;
  final reason = TextEditingController();
  final form = GlobalKey<FormState>();
  List<Map<String, dynamic>> get options => widget.laborOptions
      .where(
        (l) =>
            (l['crew_ids'] as List? ?? []).contains(crew) &&
            (!widget.borrowed || l['id'] == widget.labor),
      )
      .toList();
  @override
  void initState() {
    super.initState();
    if (options.any((l) => l['id'] == widget.labor)) labor = widget.labor;
  }

  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  Future<void> pick(bool first) async {
    final value = (first ? start : end ?? start).split(':');
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(value[0]),
        minute: int.parse(value[1]),
      ),
    );
    if (time != null && mounted)
      setState(() {
        final text =
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
        if (first) {
          start = text;
        } else {
          end = text;
        }
      });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('Reassign ${widget.workerName}'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The current attendance must end before the new segment. A temporary loan keeps the worker’s base crew unchanged.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: crew,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Destination crew',
                ),
                items: widget.crews
                    .where((c) => !widget.borrowed || c['id'] == widget.crew)
                    .map(
                      (c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Text(
                          c['name'] as String,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  crew = value!;
                  labor = null;
                }),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(crew),
                initialValue: labor,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Service / position',
                ),
                items: options
                    .map(
                      (l) => DropdownMenuItem(
                        value: l['id'] as String,
                        child: Text(
                          '${l['service_name']} · ${l['role_name']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                validator: (value) => value == null
                    ? 'Select a planned service / position'
                    : null,
                onChanged: (value) => setState(() => labor = value),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: () => pick(true),
                    child: Text('Start: ${start.substring(0, 5)}'),
                  ),
                  OutlinedButton(
                    onPressed: () => pick(false),
                    child: Text('End: ${end?.substring(0, 5) ?? 'Choose'}'),
                  ),
                ],
              ),
              TextFormField(
                controller: reason,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Reason'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a reason'
                    : null,
              ),
              if (crew != widget.crew)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'The origin attendance is saved first. A Supervisor or Administrator must authorize the temporary loan.',
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (!form.currentState!.validate()) return;
          if (end == null || end!.compareTo(start) <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Choose an end time after the start time.'),
              ),
            );
            return;
          }
          Navigator.pop(
            context,
            LaborReassignment(crew, labor!, start, end!, reason.text.trim()),
          );
        },
        child: Text(
          crew == widget.crew ? 'Add work segment' : 'Request temporary loan',
        ),
      ),
    ],
  );
}
