import 'package:flutter/material.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import '../utils/project_access_periods.dart';

class ProjectResponsibleDialog extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final List<ProjectAccessPeriod> periods;
  final Future<void> Function(Map<String, dynamic>) onSave;
  const ProjectResponsibleDialog({
    super.key,
    required this.users,
    required this.periods,
    required this.onSave,
  });

  @override
  State<ProjectResponsibleDialog> createState() =>
      _ProjectResponsibleDialogState();
}

class _ProjectResponsibleDialogState extends State<ProjectResponsibleDialog> {
  final form = GlobalKey<FormState>();
  final periodScroll = ScrollController();
  late final TextEditingController from, until;
  String? selected, error;
  bool saving = false;
  DateTime? get referenceStart =>
      ProjectAccessPeriod.firstStart(widget.periods);
  DateTime? get referenceEnd => ProjectAccessPeriod.lastEnd(widget.periods);
  List<Map<String, dynamic>> get eligible => widget.users
      .where(
        (u) =>
            u['access_status'] == 'active' &&
            ['Supervisor', 'Foreman'].contains(u['role']),
      )
      .toList();

  @override
  void initState() {
    super.initState();
    from = TextEditingController(text: ProjectAccessPeriod.iso(referenceStart));
    until = TextEditingController(text: ProjectAccessPeriod.iso(referenceEnd));
  }

  @override
  void dispose() {
    periodScroll.dispose();
    from.dispose();
    until.dispose();
    super.dispose();
  }

  bool validDate(String? text) =>
      text != null &&
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) &&
      ProjectAccessPeriod.iso(ProjectAccessPeriod.date(text)) == text;

  Future<void> pick(TextEditingController controller) async {
    final initial =
        ProjectAccessPeriod.date(controller.text) ??
        referenceStart ??
        DateTime.now();
    final day = await showDatePicker(
      context: context,
      locale: const Locale('en'),
      initialDate: initial,
      firstDate: DateTime(initial.year - 100),
      lastDate: DateTime(initial.year + 100, 12, 31),
    );
    if (day != null && mounted) {
      setState(() => controller.text = ProjectAccessPeriod.iso(day));
    }
  }

  Future<void> save() async {
    if (saving || !form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.onSave({
        'profile_id': selected,
        'responsibility': eligible.firstWhere(
          (u) => u['id'] == selected,
        )['role'],
        'valid_from': from.text,
        'valid_until': until.text.isEmpty ? null : until.text,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Could not save project authorization: $e');
      if (mounted) {
        setState(
          () => error =
              'Could not save this authorization. Check the assignment and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget field(String label, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      child,
    ],
  );

  Widget dateField(
    String label,
    TextEditingController controller, {
    bool optional = false,
  }) => field(
    label,
    TextFormField(
      controller: controller,
      enabled: !saving,
      keyboardType: TextInputType.datetime,
      decoration: InputDecoration(
        hintText: 'YYYY-MM-DD',
        suffixIcon: IconButton(
          tooltip: 'Choose date',
          onPressed: saving ? null : () => pick(controller),
          icon: const Icon(Icons.calendar_today_outlined, size: 20),
        ),
      ),
      validator: (v) {
        if (optional && (v == null || v.isEmpty)) return null;
        if (!validDate(v)) return 'Enter a valid date (YYYY-MM-DD)';
        if (optional &&
            validDate(from.text) &&
            ProjectAccessPeriod.date(
              v,
            )!.isBefore(ProjectAccessPeriod.date(from.text)!)) {
          return 'End date must be on or after start date';
        }
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final known = referenceStart != null || referenceEnd != null;
    return PopScope(
      canPop: !saving,
      child: Theme(
        data: theme.copyWith(
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            floatingLabelBehavior: FloatingLabelBehavior.never,
          ),
        ),
        child: ResponsiveDialogShell(
          title: 'Assign Project Access',
          subtitle: 'Supervisor / Foreman access authorization',
          icon: Icons.manage_accounts_outlined,
          maxWidth: 760,
          headerColor: theme.colorScheme.surface,
          footerColor: theme.colorScheme.surface,
          bodyPadding: const EdgeInsets.all(24),
          onClose: () {
            if (!saving) Navigator.pop(context, false);
          },
          body: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.35,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service periods · reference',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      if (widget.periods.isEmpty)
                        const Text(
                          'No service dates are available. Enter the access period manually.',
                        ),
                      if (widget.periods.isNotEmpty)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 160),
                          child: Scrollbar(
                            controller: periodScroll,
                            child: SingleChildScrollView(
                              controller: periodScroll,
                              primary: false,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final period in widget.periods)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: period.name,
                                              style: theme.textTheme.labelLarge,
                                            ),
                                            TextSpan(
                                              text:
                                                  ' · ${ProjectAccessPeriod.iso(period.start).isEmpty ? 'Not set' : ProjectAccessPeriod.iso(period.start)} → ${ProjectAccessPeriod.iso(period.end).isEmpty ? 'Not set' : ProjectAccessPeriod.iso(period.end)}',
                                            ),
                                            TextSpan(
                                              text: period.workingDays == null
                                                  ? ' · Days not set'
                                                  : ' · ${period.workingDays.toString().replaceFirst(RegExp(r"\.0$"), "")} est. days',
                                            ),
                                          ],
                                        ),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (widget.periods.any(
                        (p) => p.start == null || p.end == null,
                      ))
                        const Text(
                          'Some service dates are missing. Review the proposed access period.',
                        ),
                      if (known)
                        TextButton.icon(
                          onPressed: saving
                              ? null
                              : () => setState(() {
                                  from.text = ProjectAccessPeriod.iso(
                                    referenceStart,
                                  );
                                  until.text = ProjectAccessPeriod.iso(
                                    referenceEnd,
                                  );
                                }),
                          icon: const Icon(Icons.date_range_outlined),
                          label: const Text('Use service period'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                field(
                  'Person',
                  DropdownButtonFormField<String>(
                    initialValue: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Select Supervisor or Foreman',
                    ),
                    items: eligible
                        .map(
                          (u) => DropdownMenuItem(
                            value: u['id'] as String,
                            child: Text(
                              '${u['name']} (${u['role']})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (v) => setState(() => selected = v),
                    validator: (v) => v == null ? 'Select a person' : null,
                  ),
                ),
                if (eligible.isEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'No active Supervisor or Foreman accounts are available.',
                  ),
                ],
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final start = dateField('Start date', from);
                    final end = dateField(
                      'End date (optional)',
                      until,
                      optional: true,
                    );
                    return constraints.maxWidth < 520
                        ? Column(
                            children: [start, const SizedBox(height: 16), end],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: start),
                              const SizedBox(width: 16),
                              Expanded(child: end),
                            ],
                          );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'These dates control access to the entire project, not a worker’s assignment to a service or crew. Both dates are inclusive. Leave the end date blank for open-ended access.',
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
              ],
            ),
          ),
          footer: Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving || eligible.isEmpty ? null : save,
                child: Text(saving ? 'Saving…' : 'Save Authorization'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
