import 'package:flutter/material.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import '../utils/labor_planning_dates.dart';
import '../utils/labor_planning_availability.dart';
import '../../../users/presentation/widgets/user_form_dialog.dart';

List<Map<String, dynamic>> _rows(dynamic value) =>
    DailyExecutionService.rows(value);
bool _date(String? value) =>
    value != null &&
    RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) &&
    DateTime.tryParse(value)?.toIso8601String().substring(0, 10) == value;
bool _overlap(String from, String until, dynamic a, dynamic b) =>
    (a == null || a.toString().compareTo(until) <= 0) &&
    (b == null || b.toString().compareTo(from) >= 0);

/// A single planning workspace for worker dates and crew organization.
class LaborCrewPanel extends StatefulWidget {
  final String projectId;

  /// When supplied, the page owns the shared filter above the resource tabs.
  final String? serviceFilter;
  final LaborCrewPlanningService? service;
  final Future<void> Function()? onChanged;
  final Widget Function(String serviceKey)? planningBuilder;
  const LaborCrewPanel({
    super.key,
    required this.projectId,
    this.serviceFilter,
    this.service,
    this.onChanged,
    this.planningBuilder,
  });
  @override
  State<LaborCrewPanel> createState() => _LaborCrewPanelState();
}

class _LaborCrewPanelState extends State<LaborCrewPanel> {
  Map<String, dynamic> data = {};
  String? serviceKey, error;
  String search = '';
  bool loading = true, saving = false, crewsView = false;
  final selected = <String>{};
  LaborCrewPlanningService get api =>
      widget.service ?? LaborCrewPlanningService(Supabase.instance.client);
  bool get editable => data['project']?['status'] == 'active' && !saving;
  List<Map<String, dynamic>> get labor => _rows(data['labor']);
  Map<String, String> get serviceNames => {
    for (final l in labor)
      l['service_key'] as String: l['service_name'] as String,
    for (final r in _rows(data['shared_team_resources']))
      for (final s in _rows(r['services']))
        s['service_key'] as String: s['name'] as String,
  };
  bool matchesService(dynamic key) => widget.serviceFilter == null
      ? key == serviceKey
      : widget.serviceFilter == 'All Services' ||
            serviceNames[key] == widget.serviceFilter;
  Map<String, String> get visibleServices => {
    for (final s in serviceNames.entries)
      if (matchesService(s.key)) s.key: s.value,
  };
  bool get allServices => widget.serviceFilter == 'All Services';
  List<Map<String, dynamic>> get assignments => _rows(
    data['assignments'],
  ).where((a) => matchesService(a['service_key'])).toList();
  List<Map<String, dynamic>> get visible => assignments
      .where(
        (a) => '${a['worker_name']} ${a['role_name']}'.toLowerCase().contains(
          search.toLowerCase(),
        ),
      )
      .toList();
  List<Map<String, dynamic>> memberships(Map<String, dynamic> a) =>
      _rows(data['members'])
          .where(
            (m) =>
                m['worker_id'] == a['worker_id'] &&
                _overlap(
                  a['start_date'] ?? '0001-01-01',
                  a['end_date'] ?? '9999-12-31',
                  m['valid_from'],
                  m['valid_until'],
                ),
          )
          .toList();
  String crewName(dynamic id) =>
      _rows(data['crews']).where((c) => c['id'] == id).firstOrNull?['name']
          as String? ??
      'Cuadrilla';
  String leaderName(
    dynamic crew,
    dynamic from,
    dynamic until,
  ) => _rows(data['leaders'])
      .where(
        (l) =>
            l['crew_id'] == crew &&
            _overlap(
              from ?? '0001-01-01',
              until ?? '9999-12-31',
              l['valid_from'],
              l['valid_until'],
            ),
      )
      .map(
        (l) =>
            '${l['name']} (${l['valid_from']} → ${l['valid_until'] ?? 'sin fin'})',
      )
      .join(', ');

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant LaborCrewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serviceFilter != widget.serviceFilter) selected.clear();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await api.load(widget.projectId);
      if (!mounted) return;
      setState(() {
        data = result;
        if (!serviceNames.containsKey(serviceKey))
          serviceKey = labor.firstOrNull?['service_key'] as String?;
        selected.clear();
        loading = false;
      });
    } catch (e) {
      if (mounted)
        setState(() {
          error = e.toString();
          loading = false;
        });
    }
  }

  Future<void> refresh() async {
    await load();
    await widget.onChanged?.call();
  }

  Future<void> linkAccount() async {
    if (data['can_authorize'] != true || !editable) return;
    try {
      final users = await Supabase.instance.client
          .from('profiles')
          .select()
          .order('name');
      if (!mounted) return;
      final user = await showSafeDialog<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Selecciona una cuenta registrada'),
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Vincula su ficha de trabajador y revisa el rol y estado de acceso. Si no tiene cuenta, la persona debe registrarse primero.',
              ),
            ),
            ...users.map(
              (u) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, u),
                child: Text(
                  '${u['name'] ?? u['email']} · ${u['role']} · ${u['access_status']}',
                ),
              ),
            ),
          ],
        ),
      );
      if (user == null || !mounted) return;
      final result = await showSafeDialog<bool>(
        context: context,
        builder: (_) => UserFormDialog(userToEdit: user),
      );
      if (result == true && mounted) await refresh();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(laborPlanningError(e))));
    }
  }

  Future<void> changePlanning(
    Map<String, dynamic> row,
    String action, {
    bool leader = false,
  }) async {
    if (!editable) return;
    final reason = TextEditingController();
    final date = TextEditingController(
      text: (row[leader ? 'valid_from' : 'end_date'] ?? '').toString(),
    );
    final form = GlobalKey<FormState>();
    String? profile, failure;
    bool working = false;
    final title = switch (action) {
      'correct' => 'Corregir Foreman asignado',
      'replace' => 'Cambiar Foreman desde una fecha',
      'crew_end' => 'Retirar de la cuadrilla',
      'finish' => 'Finalizar asignación al servicio',
      _ => 'Cancelar asignación por error',
    };
    final result = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 480,
            child: Form(
              key: form,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leader
                          ? '${crewName(row['crew_id'])} · ${row['name']}'
                          : '${row['worker_name']} · ${row['role_name']}',
                    ),
                    const SizedBox(height: 12),
                    Text(switch (action) {
                      'correct' =>
                        'Sustituye al Foreman conservando las fechas. Solo se permite si no hay actividad vinculada.',
                      'replace' =>
                        'El Foreman anterior termina el día previo al inicio del nuevo. Se conservan los reportes existentes.',
                      'crew_end' =>
                        'Conserva la planificación laboral y su disponibilidad reservada en el servicio.',
                      'finish' =>
                        'Finaliza también las participaciones vinculadas y libera la disponibilidad posterior.',
                      _ =>
                        'Solo se permite sin ejecución ni historial dependiente. La corrección queda auditada.',
                    }),
                    const SizedBox(height: 16),
                    if (leader)
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Nuevo Foreman autorizado',
                        ),
                        isExpanded: true,
                        items:
                            {
                                  for (final f in _rows(data['foremen']))
                                    if (f['id'] != row['profile_id'])
                                      f['id'] as String:
                                          f['name'] as String? ?? 'Foreman',
                                }.entries
                                .map(
                                  (f) => DropdownMenuItem(
                                    value: f.key,
                                    child: Text(f.value),
                                  ),
                                )
                                .toList(),
                        onChanged: working ? null : (v) => profile = v,
                        validator: (v) =>
                            v == null ? 'Selecciona un Foreman' : null,
                      ),
                    if (action != 'correct' && action != 'cancel')
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: TextFormField(
                          controller: date,
                          decoration: InputDecoration(
                            labelText: leader
                                ? 'Inicio del nuevo Foreman (AAAA-MM-DD)'
                                : 'Último día de participación (AAAA-MM-DD)',
                          ),
                          validator: (v) => _date(v) ? null : 'Fecha inválida',
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: reason,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Motivo'),
                      validator: (v) => (v ?? '').trim().length < 3
                          ? 'Indica el motivo'
                          : null,
                    ),
                    if (failure != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          failure!,
                          style: TextStyle(
                            color: Theme.of(ctx).colorScheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: working ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: working
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      update(() {
                        working = true;
                        failure = null;
                      });
                      try {
                        if (leader) {
                          await api.changeForeman(
                            row['id'] as String,
                            profile!,
                            action,
                            action == 'correct' ? null : date.text,
                            reason.text.trim(),
                          );
                        } else {
                          await api.changeWorker(
                            row['id'] as String,
                            action,
                            action == 'cancel' ? null : date.text,
                            reason.text.trim(),
                          );
                        }
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        if (ctx.mounted)
                          update(() {
                            working = false;
                            failure = laborPlanningError(e);
                          });
                      }
                    },
              child: Text(working ? 'Guardando…' : 'Guardar cambio'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    reason.dispose();
    date.dispose();
    if (result == true && mounted) await refresh();
  }

  Future<void> organize({
    bool newPeople = false,
    Map<String, dynamic>? sharedResource,
  }) async {
    if (!editable) return;
    final planningServices = {
      for (final l in labor)
        if (matchesService(l['service_key']))
          l['service_key'] as String: l['service_name'] as String,
    };
    final initialRows = newPeople
        ? <Map<String, dynamic>>[]
        : assignments.where((a) => selected.contains(a['id'])).toList();
    final selectedServices = initialRows
        .map((a) => a['service_key'] as String)
        .toSet();
    if (selectedServices.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona trabajadores de un solo servicio para asignar una cuadrilla.',
          ),
        ),
      );
      return;
    }
    String? target =
        sharedResource?['owner_service_key'] as String? ??
        selectedServices.firstOrNull ??
        (planningServices.length == 1 ? planningServices.keys.first : null);
    if (target == null && newPeople && planningServices.isNotEmpty) {
      target = await showSafeDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Selecciona el servicio'),
          children: planningServices.entries
              .map(
                (s) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, s.key),
                  child: Text(s.value),
                ),
              )
              .toList(),
        ),
      );
    }
    if (target == null || !mounted) return;
    final result = await showSafeDialog<bool>(
      context: context,
      fullscreenOnMobile: true,
      builder: (_) => LaborCrewDialog(
        projectId: widget.projectId,
        serviceKey: target!,
        data: data,
        initialRows: initialRows,
        newPeople: newPeople,
        service: api,
        onlyTeamResourceId: sharedResource?['resource_id'] as String?,
      ),
    );
    if (result == true && mounted) await refresh();
  }

  Future<void> editDates(
    Map<String, dynamic> row, {
    String? kind,
    List<Map<String, dynamic>>? batch,
  }) async {
    if (!editable) return;
    final from = TextEditingController(
      text: (row[kind == null ? 'start_date' : 'valid_from'] ?? '').toString(),
    );
    final until = TextEditingController(
      text: (row[kind == null ? 'end_date' : 'valid_until'] ?? '').toString(),
    );
    final form = GlobalKey<FormState>();
    String? failure;
    bool working = false;
    Future<void> pickDate(
      BuildContext dialogContext,
      StateSetter update, {
      required bool start,
    }) async {
      if (working) return;
      final controller = start ? from : until;
      final first = !start && _date(from.text)
          ? DateTime.parse(from.text)
          : DateTime(2020);
      final last = DateTime(2100, 12, 31).isBefore(first)
          ? first
          : DateTime(2100, 12, 31);
      var initial = DateTime.tryParse(controller.text) ?? DateTime.now();
      if (initial.isBefore(first)) initial = first;
      if (initial.isAfter(last)) initial = last;
      final picked = await showDatePicker(
        context: dialogContext,
        initialDate: initial,
        firstDate: first,
        lastDate: last,
        initialEntryMode: DatePickerEntryMode.calendarOnly,
      );
      if (picked == null || !dialogContext.mounted) return;
      update(() {
        controller.text = LaborPlanningDates.iso(picked);
        if (start &&
            (!_date(until.text) ||
                DateTime.parse(until.text).isBefore(picked))) {
          until.text = controller.text;
        }
        failure = null;
      });
    }

    final result = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(
            batch != null
                ? 'Fechas de ${batch.length} trabajadores'
                : kind == null
                ? 'Fechas de planificación'
                : 'Finalizar vigencia',
          ),
          content: SizedBox(
            width: 430,
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Las fechas utilizadas por reportes e integrantes se conservarán.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  if (batch != null) ...[
                    const Text(
                      'Las fechas elegidas se aplicarán a todos los seleccionados. Si existe un conflicto, no se guardará ningún cambio.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (kind == null)
                    TextFormField(
                      controller: from,
                      readOnly: true,
                      enabled: !working,
                      onTap: () => pickDate(ctx, update, start: true),
                      decoration: const InputDecoration(
                        labelText: 'Desde',
                        suffixIcon: Icon(Icons.calendar_month_outlined),
                      ),
                      validator: (v) => _date(v) ? null : 'Fecha inválida',
                    ),
                  if (kind == null) const SizedBox(height: 16),
                  TextFormField(
                    controller: until,
                    readOnly: true,
                    enabled: !working,
                    onTap: () => pickDate(ctx, update, start: false),
                    decoration: const InputDecoration(
                      labelText: 'Hasta',
                      suffixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    validator: (v) => _date(v) ? null : 'Fecha inválida',
                  ),
                  if (failure != null)
                    Text(
                      failure!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: working ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: working
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      update(() {
                        working = true;
                        failure = null;
                      });
                      try {
                        if (batch != null) {
                          await api.datesBatch(
                            widget.projectId,
                            batch.map((a) => a['id'] as String).toList(),
                            from.text,
                            until.text,
                          );
                        } else if (kind == null) {
                          await api.dates(
                            row['id'] as String,
                            from.text,
                            until.text,
                          );
                        } else {
                          await api.end(kind, row['id'] as String, until.text);
                        }
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        if (ctx.mounted)
                          update(() {
                            working = false;
                            failure = e is PostgrestException
                                ? e.message
                                : e.toString();
                          });
                      }
                    },
              child: Text(working ? 'Guardando…' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
    // Dialog fields may still be animating out when the result is delivered.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    from.dispose();
    until.dispose();
    if (result == true && mounted) await refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null)
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!),
            TextButton(onPressed: load, child: const Text('Reintentar')),
          ],
        ),
      );
    final services = serviceNames;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.serviceFilter == null)
                SizedBox(
                  width: 350,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(serviceKey),
                    initialValue: serviceKey,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Servicio'),
                    items: services.entries
                        .map(
                          (s) => DropdownMenuItem(
                            value: s.key,
                            child: Text(s.value),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (v) => setState(() {
                            serviceKey = v;
                            selected.clear();
                          }),
                  ),
                ),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Personal'),
                    icon: Icon(Icons.people_outline),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Cuadrillas'),
                    icon: Icon(Icons.groups_outlined),
                  ),
                ],
                selected: {crewsView},
                onSelectionChanged: (v) => setState(() => crewsView = v.first),
              ),
              if (editable &&
                  labor.any((l) => matchesService(l['service_key'])))
                FilledButton.icon(
                  onPressed: () => organize(newPeople: true),
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Agregar personal'),
                ),
              if (editable && data['can_authorize'] == true)
                OutlinedButton.icon(
                  onPressed: linkAccount,
                  icon: const Icon(Icons.link),
                  label: const Text('Vincular usuario'),
                ),
            ],
          ),
        ),
        if (labor.any((l) => (l['operational_role'] ?? 'none') != 'none'))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 16,
              children: [
                for (final responsibility in ['Supervisor', 'Foreman'])
                  Text(
                    '$responsibility: ${labor.where((l) => l['operational_role'] == responsibility && _rows(data['assignments']).any((a) => a['project_labor_id'] == l['id'])).length}/${labor.where((l) => l['operational_role'] == responsibility).length} plazas asignadas',
                  ),
              ],
            ),
          ),
        if (!editable)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Planificación en consulta: el proyecto no está activo.',
            ),
          ),
        Expanded(
          child: visibleServices.isEmpty
              ? const Center(
                  child: Text(
                    'Planifica los oficios del servicio para organizar su personal.',
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: crewsView
                      ? _crewCards()
                      : [
                          ..._sharedResourceCards(),
                          if (labor.any(
                            (l) => matchesService(l['service_key']),
                          )) ...[
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                SizedBox(
                                  width: 300,
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      labelText: 'Buscar trabajador u oficio',
                                      prefixIcon: Icon(Icons.search),
                                    ),
                                    onChanged: (v) =>
                                        setState(() => search = v),
                                  ),
                                ),
                                if (editable)
                                  TextButton(
                                    onPressed: () => setState(() {
                                      final eligible = visible
                                          .where(
                                            (a) =>
                                                _date(a['start_date']) &&
                                                _date(a['end_date']) &&
                                                memberships(a).isEmpty,
                                          )
                                          .map((a) => a['id'] as String)
                                          .toSet();
                                      if (eligible.isNotEmpty &&
                                          selected.containsAll(eligible)) {
                                        selected.removeAll(eligible);
                                      } else {
                                        selected.addAll(eligible);
                                      }
                                    }),
                                    child: const Text(
                                      'Seleccionar disponibles',
                                    ),
                                  ),
                                Text('${selected.length} seleccionados'),
                                if (editable)
                                  FilledButton.tonalIcon(
                                    onPressed: selected.isEmpty
                                        ? null
                                        : () {
                                            final rows = assignments
                                                .where(
                                                  (a) => selected.contains(
                                                    a['id'],
                                                  ),
                                                )
                                                .toList();
                                            if (rows.isNotEmpty)
                                              editDates(
                                                rows.first,
                                                batch: rows,
                                              );
                                          },
                                    icon: const Icon(
                                      Icons.edit_calendar_outlined,
                                    ),
                                    label: const Text('Cambiar fechas'),
                                  ),
                                if (editable)
                                  FilledButton.tonal(
                                    onPressed: selected.isEmpty
                                        ? null
                                        : () => organize(),
                                    child: const Text('Asignar cuadrilla'),
                                  ),
                                if (selected.isNotEmpty)
                                  TextButton(
                                    onPressed: () => setState(selected.clear),
                                    child: const Text('Limpiar selección'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (assignments.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'No hay trabajadores asignados al servicio. Usa Agregar personal.',
                                ),
                              ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowHeight: 44,
                                dataRowMinHeight: 64,
                                dataRowMaxHeight: 72,
                                columnSpacing: 28,
                                horizontalMargin: 16,
                                showCheckboxColumn: editable,
                                columns: [
                                  const DataColumn(label: Text('Trabajador')),
                                  if (allServices)
                                    const DataColumn(label: Text('Servicio')),
                                  const DataColumn(label: Text('Oficio')),
                                  const DataColumn(label: Text('Desde')),
                                  const DataColumn(label: Text('Hasta')),
                                  const DataColumn(
                                    label: Text(
                                      'Cuadrilla / Foreman y vigencia',
                                    ),
                                  ),
                                  const DataColumn(label: Text('Acciones')),
                                ],
                                rows: visible
                                    .map(
                                      (a) => DataRow(
                                        selected: selected.contains(a['id']),
                                        onSelectChanged: !editable
                                            ? null
                                            : (v) => setState(() {
                                                if (v == true) {
                                                  selected.add(
                                                    a['id'] as String,
                                                  );
                                                } else {
                                                  selected.remove(a['id']);
                                                }
                                              }),
                                        cells: [
                                          DataCell(
                                            Text(a['worker_name'] as String),
                                          ),
                                          if (allServices)
                                            DataCell(
                                              Text(
                                                services[a['service_key']] ??
                                                    '—',
                                              ),
                                            ),
                                          DataCell(
                                            Text(
                                              a['role_name'] as String? ?? '—',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              a['start_date'] as String? ??
                                                  'Sin fecha',
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              a['end_date'] as String? ??
                                                  'Sin fecha',
                                            ),
                                          ),
                                          DataCell(
                                            SizedBox(
                                              width: 420,
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    if (memberships(a).isEmpty)
                                                      const Text(
                                                        'Sin cuadrilla',
                                                      ),
                                                    ...memberships(a).map(
                                                      (m) => Text(
                                                        '${crewName(m['crew_id'])}: ${m['valid_from']} → ${m['valid_until'] ?? 'sin fin'}',
                                                      ),
                                                    ),
                                                    ...memberships(a).map(
                                                      (m) => Text(
                                                        leaderName(
                                                          m['crew_id'],
                                                          m['valid_from'],
                                                          m['valid_until'],
                                                        ),
                                                        style: Theme.of(
                                                          context,
                                                        ).textTheme.bodySmall,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  tooltip:
                                                      'Editar fechas de planificación',
                                                  onPressed: editable
                                                      ? () => editDates(a)
                                                      : null,
                                                  icon: const Icon(
                                                    Icons
                                                        .edit_calendar_outlined,
                                                  ),
                                                ),
                                                if (editable)
                                                  PopupMenuButton<String>(
                                                    tooltip:
                                                        'Modificar asignación',
                                                    onSelected: (action) =>
                                                        changePlanning(
                                                          a,
                                                          action,
                                                        ),
                                                    itemBuilder: (_) => const [
                                                      PopupMenuItem(
                                                        value: 'crew_end',
                                                        child: Text(
                                                          'Retirar de la cuadrilla',
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'finish',
                                                        child: Text(
                                                          'Finalizar asignación al servicio',
                                                        ),
                                                      ),
                                                      PopupMenuItem(
                                                        value: 'cancel',
                                                        child: Text(
                                                          'Cancelar asignación por error',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                          if (widget.planningBuilder != null)
                            for (final entry in visibleServices.entries)
                              if (labor.any(
                                (l) => l['service_key'] == entry.key,
                              ))
                                ExpansionTile(
                                  title: Text(
                                    allServices
                                        ? '${entry.value} · Plazas y calendario por oficio'
                                        : 'Plazas y calendario por oficio',
                                  ),
                                  children: [
                                    SizedBox(
                                      height: 400,
                                      child: widget.planningBuilder!(entry.key),
                                    ),
                                  ],
                                ),
                        ],
                ),
        ),
      ],
    );
  }

  List<Widget> _sharedResourceCards() => [
    for (final resource in _rows(data['shared_team_resources']))
      if (!allServices &&
          !matchesService(resource['owner_service_key']) &&
          _rows(
            resource['services'],
          ).any((s) => matchesService(s['service_key'])))
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${resource['label']} · ${resource['responsibility']}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Recurso compartido con: ${_rows(resource['services']).map((s) => s['name']).join(', ')}',
                ),
                for (final coverage in _rows(
                  resource['services'],
                ).where((s) => matchesService(s['service_key'])))
                  Text(
                    '${coverage['start_date']} → ${coverage['end_date']} · ${coverage['dedication']} % de dedicación',
                  ),
                for (final assignment in _rows(data['assignments']).where(
                  (a) => (resource['slots'] as List).contains(
                    a['project_labor_id'],
                  ),
                ))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(assignment['worker_name'] as String),
                    subtitle: Text(
                      '${assignment['start_date']} → ${assignment['end_date']}',
                    ),
                    trailing: editable
                        ? IconButton(
                            tooltip: 'Editar fechas compartidas',
                            icon: const Icon(Icons.edit_calendar),
                            onPressed: () => editDates(assignment),
                          )
                        : null,
                  ),
                const Text(
                  'La persona se planifica una sola vez para los servicios cubiertos.',
                ),
                if (editable)
                  TextButton.icon(
                    onPressed: () =>
                        organize(newPeople: true, sharedResource: resource),
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Asignar personal al recurso compartido'),
                  ),
              ],
            ),
          ),
        ),
  ];

  Future<void> assignLeader(Map<String, dynamic> period) async {
    final from = TextEditingController(
      text: period['valid_from'] as String? ?? '',
    );
    final until = TextEditingController(
      text: period['valid_until'] as String? ?? '',
    );
    final form = GlobalKey<FormState>();
    String? profile, failure;
    bool working = false;
    final foremen = <String, String>{
      for (final f in _rows(data['foremen']))
        f['id'] as String: f['name'] as String? ?? 'Foreman',
    };
    final result = await showSafeDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: const Text('Asignar Foreman por período'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Finaliza la vigencia anterior antes de asignar un nuevo líder. Las fechas son inclusivas.',
                  ),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Foreman autorizado',
                    ),
                    items: foremen.entries
                        .map(
                          (f) => DropdownMenuItem(
                            value: f.key,
                            child: Text(f.value),
                          ),
                        )
                        .toList(),
                    onChanged: working ? null : (v) => profile = v,
                    validator: (v) =>
                        v == null ? 'Selecciona un Foreman' : null,
                  ),
                  TextFormField(
                    controller: from,
                    decoration: const InputDecoration(
                      labelText: 'Desde (AAAA-MM-DD)',
                    ),
                    validator: (v) => _date(v) ? null : 'Fecha inválida',
                  ),
                  TextFormField(
                    controller: until,
                    decoration: const InputDecoration(
                      labelText: 'Hasta (AAAA-MM-DD)',
                    ),
                    validator: (v) => _date(v) ? null : 'Fecha inválida',
                  ),
                  if (failure != null)
                    Text(
                      failure!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: working ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: working
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      update(() => working = true);
                      try {
                        await api.leader(
                          period['crew_id'] as String,
                          profile!,
                          from.text,
                          until.text,
                        );
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        if (ctx.mounted)
                          update(() {
                            working = false;
                            failure = e.toString();
                          });
                      }
                    },
              child: Text(working ? 'Guardando…' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    from.dispose();
    until.dispose();
    if (result == true && mounted) await refresh();
  }

  List<Widget> _crewCards() {
    final periods = _rows(
      data['periods'],
    ).where((p) => matchesService(p['service_key'])).toList();
    final legacy = _rows(data['crews']).where(
      (c) =>
          !_rows(data['periods']).any((p) => p['crew_id'] == c['id']) ||
          _rows(data['members']).any(
            (m) =>
                m['crew_id'] == c['id'] &&
                m['crew_service_assignment_id'] == null,
          ),
    );
    return [
      const Text(
        'Las vigencias conservan el historial del servicio, sus integrantes y líderes.',
      ),
      ...[
        ...periods,
        ...legacy.map((c) => <String, dynamic>{'crew_id': c['id']}),
      ].map((p) {
        final crew = p['crew_id'];
        final members = _rows(data['members'])
            .where(
              (m) => p['id'] == null
                  ? m['crew_id'] == crew &&
                        m['crew_service_assignment_id'] == null
                  : m['crew_service_assignment_id'] == p['id'],
            )
            .toList();
        final leaders = _rows(data['leaders'])
            .where(
              (l) =>
                  l['crew_id'] == crew &&
                  (p['id'] == null ||
                      _overlap(
                        p['valid_from'],
                        p['valid_until'],
                        l['valid_from'],
                        l['valid_until'],
                      )),
            )
            .toList();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crewName(crew),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  p['id'] == null
                      ? 'Servicio pendiente: historial anterior sin atribución automática.'
                      : '${visibleServices[p['service_key']] ?? 'Servicio'} · ${p['valid_from']} → ${p['valid_until']}',
                ),
                if (editable)
                  TextButton.icon(
                    onPressed: () => assignLeader(p),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Asignar Foreman por período'),
                  ),
                ...leaders.map(
                  (l) => ListTile(
                    dense: true,
                    title: Text('Foreman: ${l['name']}'),
                    subtitle: Text(
                      '${l['valid_from']} → ${l['valid_until'] ?? 'sin fin'}',
                    ),
                    trailing: editable
                        ? Wrap(
                            children: [
                              TextButton(
                                onPressed: () => editDates(l, kind: 'leader'),
                                child: const Text('Definir fin'),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Cambiar Foreman',
                                onSelected: (action) =>
                                    changePlanning(l, action, leader: true),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'correct',
                                    child: Text('Corregir Foreman asignado'),
                                  ),
                                  PopupMenuItem(
                                    value: 'replace',
                                    child: Text(
                                      'Cambiar Foreman desde una fecha',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
                ...members.map(
                  (m) => ListTile(
                    dense: true,
                    title: Text(m['worker_name'] as String),
                    subtitle: Text(
                      '${m['valid_from']} → ${m['valid_until'] ?? 'sin fin'}',
                    ),
                    trailing: editable
                        ? TextButton(
                            onPressed: () => editDates(m, kind: 'member'),
                            child: const Text('Definir fin'),
                          )
                        : null,
                  ),
                ),
                if (members.isEmpty)
                  const Text('Sin integrantes en esta vigencia.'),
              ],
            ),
          ),
        );
      }),
      if (periods.isEmpty && legacy.isEmpty)
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Selecciona personal y usa Asignar cuadrilla para crear el equipo del servicio.',
          ),
        ),
    ];
  }
}

class LaborCrewDialog extends StatefulWidget {
  final String? onlyTeamResourceId;
  final String projectId, serviceKey;
  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> initialRows;
  final bool newPeople;
  final LaborCrewPlanningService service;
  const LaborCrewDialog({
    super.key,
    required this.projectId,
    required this.serviceKey,
    required this.data,
    required this.initialRows,
    required this.newPeople,
    required this.service,
    this.onlyTeamResourceId,
  });
  @override
  State<LaborCrewDialog> createState() => _LaborCrewDialogState();
}

class _LaborCrewDialogState extends State<LaborCrewDialog> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      from = TextEditingController(),
      until = TextEditingController();
  List<Map<String, dynamic>> selected = [];
  String? roleId, crew, foreman, error;
  String query = '';
  int revision = 0;
  bool saving = false;
  bool summaryTab = false;
  bool checkingWorkers = true;
  String? availabilityFailure;
  Set<String> globalBusy = {};
  List<Map<String, dynamic>> bookings = [];
  int availabilityRequest = 0;
  Future<void> refreshWorkerAvailability() async {
    if (!widget.newPeople) return;
    final request = ++availabilityRequest;
    final start = from.text, end = until.text;
    setState(() {
      checkingWorkers = true;
      availabilityFailure = null;
    });
    if (!_date(start) || !_date(end) || end.compareTo(start) < 0) {
      setState(() {
        checkingWorkers = false;
        globalBusy = {};
        availabilityFailure =
            'Select valid dates to check worker availability.';
      });
      return;
    }
    try {
      final currentBookings = await widget.service.workerBookings(
        widget.projectId,
        start,
        end,
      );
      if (!mounted || request != availabilityRequest) return;
      setState(() {
        bookings = currentBookings;
        globalBusy = currentBookings
            .map((r) => r['worker_id'] as String)
            .toSet();
        checkingWorkers = false;
        // A date change must not keep unavailable people marked. Confirmed rows
        // remain in the summary until the user explicitly accepts a replacement.
        draft.removeAll(globalBusy);
      });
    } catch (e) {
      if (mounted && request == availabilityRequest)
        setState(() {
          checkingWorkers = false;
          availabilityFailure =
              'Could not check availability. Retry before selecting workers.';
        });
    }
  }

  bool stagedElsewhere(String worker) => selected.any(
    (r) =>
        r['worker_id'] == worker &&
        r['project_labor_id'] != roleId &&
        LaborPlanningAvailability.overlaps(
          from.text,
          until.text,
          r['valid_from'],
          r['valid_until'],
        ),
  );

  final choices = <String, Set<String>>{};
  final rolePeriods = <String, List<String>>{};
  final changedPeriods = <String>{};
  Set<String> get draft => choices.putIfAbsent(
    roleId ?? '',
    () => selected
        .where((r) => r['project_labor_id'] == roleId)
        .map((r) => r['worker_id'] as String)
        .toSet(),
  );
  List<Map<String, dynamic>> acceptedFor(String? id) =>
      selected.where((r) => r['project_labor_id'] == id).toList();
  bool get currentChanged =>
      changedPeriods.contains(roleId) ||
      draft.length != acceptedFor(roleId).length ||
      !draft.containsAll(
        acceptedFor(roleId).map((r) => r['worker_id'] as String),
      );
  bool get hasPending =>
      changedPeriods.isNotEmpty ||
      choices.entries.any((e) {
        final accepted = acceptedFor(
          e.key,
        ).map((r) => r['worker_id'] as String).toSet();
        return e.value.length != accepted.length ||
            !e.value.containsAll(accepted);
      });
  void switchRole(String? id) {
    if (roleId != null) rolePeriods[roleId!] = [from.text, until.text];
    roleId = id;
    query = '';
    final period = rolePeriods[id];
    if (period == null) {
      proposeDates();
    } else {
      from.text = period[0];
      until.text = period[1];
    }
    revision++;
  }

  void acceptRole() {
    if (!_date(from.text) ||
        !_date(until.text) ||
        until.text.compareTo(from.text) < 0) {
      setState(() => error = 'Select start and end dates for this trade');
      return;
    }
    setState(() {
      final old = {
        for (final r in acceptedFor(roleId)) r['worker_id'] as String: r,
      };
      final proposed = selected
          .where((r) => r['project_labor_id'] != roleId)
          .toList();
      for (final worker in _rows(
        widget.data['workers'],
      ).where((w) => draft.contains(w['id']))) {
        final previous = old[worker['id']];
        proposed.add(
          previous != null && !changedPeriods.contains(roleId)
              ? previous
              : {
                  'worker_id': worker['id'],
                  'worker_name': worker['full_name'],
                  'project_labor_id': roleId,
                  'role_name': role?['role_name'],
                  'valid_from': from.text,
                  'valid_until': until.text,
                },
        );
      }
      final conflict = availability.validate(proposed);
      if (conflict != null) {
        error = conflict;
        return;
      }
      selected = proposed;
      changedPeriods.remove(roleId);
      error = null;
      revision++;
    });
  }

  late final List<Map<String, dynamic>> planningLabor;
  List<Map<String, dynamic>> get labor => planningLabor
      .where(
        (l) =>
            l['service_key'] == widget.serviceKey &&
            (widget.onlyTeamResourceId == null ||
                l['team_resource_id'] == widget.onlyTeamResourceId),
      )
      .toList();
  List<Map<String, dynamic>> get roles {
    final found = <String>{};
    return labor
        .where(
          (l) => found.add(
            '${l['role_name']}|${l['operational_role'] ?? 'none'}|${l['coverage_scope'] ?? 'service'}|${l['team_resource_id'] ?? ''}',
          ),
        )
        .toList();
  }

  Map<String, dynamic>? get role =>
      labor.where((l) => l['id'] == roleId).firstOrNull;
  LaborPlanningAvailability get availability =>
      LaborPlanningAvailability(labor, _rows(widget.data['assignments']));
  Map<String, double> get calendar => {
    for (final d in _rows(widget.data['non_working_days']))
      d['date'] as String: (d['partial_ratio'] as num?)?.toDouble() ?? 0,
  };
  String get serviceName =>
      labor.firstOrNull?['service_name'] as String? ?? 'Service';

  @override
  void initState() {
    super.initState();
    planningLabor = LaborPlanningDates.coverageRoles(
      _rows(widget.data['labor']),
      calendar,
    );
    selected = widget.initialRows
        .map(
          (a) => <String, dynamic>{
            ...a,
            'assignment_id': a['id'],
            'valid_from': a['start_date'] ?? '',
            'valid_until': a['end_date'] ?? '',
          },
        )
        .toList();
    roleId = roles.firstOrNull?['id'] as String?;
    if (!widget.newPeople && widget.initialRows.isNotEmpty) {
      roleId =
          widget.initialRows.first['project_labor_id'] as String? ?? roleId;
    }
    proposeDates();
    if (!widget.newPeople) {
      crew = '__new__';
    } else {
      refreshWorkerAvailability();
    }
  }

  void proposeDates() {
    final dates = LaborPlanningDates.propose(role ?? {}, calendar);
    from.text = LaborPlanningDates.iso(dates.start);
    until.text = LaborPlanningDates.iso(dates.end);
  }

  @override
  void dispose() {
    name.dispose();
    from.dispose();
    until.dispose();
    super.dispose();
  }

  String? rowError(Map<String, dynamic> row) {
    final a = row['valid_from'] as String?, b = row['valid_until'] as String?;
    if (!_date(a) || !_date(b) || b!.compareTo(a!) < 0)
      return 'Select valid start and end dates';
    if (row['assignment_id'] != null &&
        (!_date(row['start_date']) || !_date(row['end_date'])))
      return 'Complete the planning dates first';
    if (row['assignment_id'] != null &&
        (a.compareTo(row['start_date'] as String) < 0 ||
            b.compareTo(row['end_date'] as String) > 0))
      return 'Crew participation must remain within the worker’s planned period';
    if (crew != null &&
        _rows(widget.data['members']).any(
          (m) =>
              m['worker_id'] == row['worker_id'] &&
              _overlap(a, b, m['valid_from'], m['valid_until']),
        ))
      return 'Already assigned to a crew during this period';
    return null;
  }

  Future<void> save() async {
    if (widget.newPeople && hasPending) {
      setState(
        () => error =
            'Confirm each trade selection before saving. Pending changes are retained.',
      );
      return;
    }
    if (!form.currentState!.validate()) {
      if (widget.newPeople) setState(() => summaryTab = true);
      return;
    }
    final problem = selected.map(rowError).whereType<String>().firstOrNull;
    if (selected.isEmpty || problem != null) {
      setState(() => error = problem ?? 'Select workers');
      return;
    }
    if (widget.newPeople) {
      final conflict = availability.validate(selected);
      if (conflict != null) {
        setState(() => error = conflict);
        return;
      }
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      if (widget.newPeople) {
        final ranges = <String, Future<Set<String>>>{};
        for (final r in selected) {
          final key = '${r['valid_from']}/${r['valid_until']}';
          ranges.putIfAbsent(
            key,
            () => widget.service.busyWorkers(
              widget.projectId,
              r['valid_from'] as String,
              r['valid_until'] as String,
            ),
          );
        }
        final keys = ranges.keys.toList();
        final results = await Future.wait(ranges.values);
        if (!mounted) return;
        final busyByPeriod = {
          for (var i = 0; i < keys.length; i++) keys[i]: results[i],
        };
        for (final r in selected) {
          if (busyByPeriod['${r['valid_from']}/${r['valid_until']}']!.contains(
            r['worker_id'],
          )) {
            setState(() {
              saving = false;
              error =
                  '${r['worker_name']} is already planned from ${r['valid_from']} to ${r['valid_until']}. Adjust the dates or remove the selection.';
            });
            return;
          }
        }
      }
      await widget.service.save(
        projectId: widget.projectId,
        serviceKey: widget.serviceKey,
        rows: selected
            .map(
              (r) => {
                for (final k in [
                  'assignment_id',
                  'worker_id',
                  'project_labor_id',
                  'valid_from',
                  'valid_until',
                ])
                  if (r[k] != null) k: r[k],
              },
            )
            .toList(),
        crewId: crew == '__new__' ? null : crew,
        crewName: crew == '__new__' ? name.text.trim() : null,
        foremanId: crew == null ? null : foreman,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        setState(() {
          saving = false;
          error = laborPlanningError(e);
        });
    }
  }

  String roleOption(Map<String, dynamic> r) {
    final id = r['id'] as String,
        total = availability.slots(r['id'] as String).length;
    final registered = availability.registeredSlots(id),
        accepted = acceptedFor(id).length;
    final function = r['operational_role'] ?? 'none';
    final scope = r['coverage_scope'] == 'project' ? 'project' : 'service';
    return '${r['team_resource_label'] ?? r['role_name'] ?? 'General'}${function == 'none' ? '' : ' ($function · $scope)'} · $registered/$total assigned${accepted == 0 ? '' : ' · $accepted confirmed'}';
  }

  int get freeForCurrent =>
      roleId != null &&
          _date(from.text) &&
          _date(until.text) &&
          until.text.compareTo(from.text) >= 0
      ? availability.available(roleId!, from.text, until.text)
      : 0;

  Widget vacancySummary() {
    if (roleId == null || !_date(from.text) || !_date(until.text))
      return const SizedBox.shrink();
    final free = availability.available(roleId!, from.text, until.text),
        total = availability.slots(roleId!).length;
    final registered = availability.registered(roleId!);
    final assignedSlots = availability.registeredSlots(roleId!);
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('vacancy-summary'),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: free == 0
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registered positions: $assignedSlots/$total',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Period occupancy: ${total - free}/$total · Available positions: $free',
            style: theme.textTheme.titleSmall,
          ),
          Text(
            'Availability period: ${from.text} → ${until.text}',
            style: theme.textTheme.bodySmall,
          ),
          if (registered.isNotEmpty) const SizedBox(height: 8),
          for (final a in registered)
            Text(
              'Assigned: ${a['worker_name']} · ${a['start_date'] ?? 'No start'} → ${a['end_date'] ?? 'No end'}${LaborPlanningAvailability.overlaps(from.text, until.text, a['start_date'], a['end_date']) ? ' · Overlaps this period' : ' · Outside this period'}',
            ),
          if (registered.isNotEmpty && free == total)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Existing assignments fall outside these dates. A position can be reused in non-overlapping periods.',
              ),
            ),
          if (free == 0)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Review existing personnel assignments or choose another period. Workers are not replaced automatically.',
              ),
            ),
        ],
      ),
    );
  }

  Widget acceptedSummary() {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('accepted-personnel'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirmed personnel · ${selected.length}',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (selected.isEmpty)
            const Text('Select workers and confirm this trade selection.'),
          for (final r in roles.where(
            (r) => acceptedFor(r['id'] as String).isNotEmpty,
          )) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: Text(
                '${r['role_name']} · ${acceptedFor(r['id'] as String).length} confirmed',
                style: theme.textTheme.labelLarge,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: acceptedFor(r['id'] as String)
                  .map(
                    (person) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InputChip(
                          avatar: const Icon(
                            Icons.check_circle_outline,
                            size: 18,
                          ),
                          label: Text(person['worker_name'] as String),
                          tooltip:
                              '${person['valid_from']} → ${person['valid_until']}',
                          onDeleted: saving
                              ? null
                              : () => setState(() {
                                  selected.remove(person);
                                  choices[person['project_labor_id']]?.remove(
                                    person['worker_id'],
                                  );
                                  if (acceptedFor(
                                        person['project_labor_id'] as String?,
                                      ).isEmpty &&
                                      (choices[person['project_labor_id']]
                                              ?.isEmpty ??
                                          true))
                                    changedPeriods.remove(
                                      person['project_labor_id'],
                                    );
                                }),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${person['valid_from']} → ${person['valid_until']}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            IconButton(
                              tooltip:
                                  'Edit dates for ${person['worker_name']}',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.edit_calendar_outlined,
                                size: 18,
                              ),
                              onPressed: saving
                                  ? null
                                  : () => editPersonDates(person),
                            ),
                          ],
                        ),
                        if (rowError(person) != null)
                          Text(
                            rowError(person)!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          const Text('Selections are saved when you save the plan.'),
        ],
      ),
    );
  }

  Future<void> editPersonDates(Map<String, dynamic> person) async {
    await showSafeDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => AlertDialog(
          title: Text(person['worker_name'] as String),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final start in [true, false])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      key: ValueKey('person-date-$start-$revision'),
                      initialValue:
                          person[start ? 'valid_from' : 'valid_until']
                              as String?,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: start ? 'Start date' : 'End date',
                        suffixIcon: const Icon(Icons.calendar_month_outlined),
                      ),
                      onTap: () async {
                        await pick(start, row: person);
                        if (ctx.mounted) update(() {});
                      },
                    ),
                  ),
                if (rowError(person) != null)
                  Text(
                    rowError(person)!,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget field(String label, Widget input, {String? help}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      ),
      input,
      if (help != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(help, style: Theme.of(context).textTheme.bodySmall),
        ),
    ],
  );
  Widget pair(Widget left, Widget right) => LayoutBuilder(
    builder: (context, size) => size.maxWidth < 600
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 16), right],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 16),
              Expanded(child: right),
            ],
          ),
  );
  Widget section(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        ...children,
      ],
    ),
  );

  Future<void> pick(bool start, {Map<String, dynamic>? row}) async {
    final current = LaborPlanningDates.date(
      row == null
          ? (start ? from.text : until.text)
          : row[start ? 'valid_from' : 'valid_until'],
    );
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('en'),
      initialDate:
          current ?? LaborPlanningDates.date(from.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2200, 12, 31),
    );
    if (picked == null || !mounted) return;
    setState(() {
      revision++;
      final value = LaborPlanningDates.iso(picked);
      if (row == null) {
        if (start) {
          from.text = value;
          final end = LaborPlanningDates.endFor(
            picked,
            role?['working_days'] as num?,
            calendar,
          );
          if (end != null) {
            until.text = LaborPlanningDates.iso(end);
          } else if (LaborPlanningDates.date(until.text)?.isBefore(picked) ??
              false) {
            until.text = value;
          }
        } else {
          until.text = value;
        }
        if (widget.newPeople &&
            (draft.isNotEmpty || acceptedFor(roleId).isNotEmpty))
          changedPeriods.add(roleId!);
      } else {
        row[start ? 'valid_from' : 'valid_until'] = value;
        if (start && row['assignment_id'] == null) {
          final end = LaborPlanningDates.endFor(
            picked,
            labor
                    .where((l) => l['id'] == row['project_labor_id'])
                    .firstOrNull?['working_days']
                as num?,
            calendar,
          );
          if (end != null) row['valid_until'] = LaborPlanningDates.iso(end);
        }
      }
    });
    if (row == null) await refreshWorkerAvailability();
  }

  Widget dateField(bool start, {Map<String, dynamic>? row}) => field(
    start ? 'Start date' : 'End date',
    TextFormField(
      key: ValueKey(
        row == null
            ? (start ? 'common-start' : 'common-end')
            : '${row['worker_id']}-${row['assignment_id'] ?? row['project_labor_id']}-${start ? 'start' : 'end'}-$revision',
      ),
      controller: row == null ? (start ? from : until) : null,
      initialValue: row == null
          ? null
          : row[start ? 'valid_from' : 'valid_until'] as String?,
      readOnly: true,
      enabled: !saving,
      onTap: () => pick(start, row: row),
      decoration: const InputDecoration(
        hintText: 'Choose date',
        suffixIcon: Icon(Icons.calendar_month_outlined),
      ),
      validator: row == null ? null : (_) => rowError(row),
    ),
  );
  Widget reference() {
    final r = role ?? {};
    final start = LaborPlanningDates.iso(
      LaborPlanningDates.date(r['reference_start']),
    );
    final end = LaborPlanningDates.iso(
      LaborPlanningDates.date(r['reference_end']),
    );
    final duration = r['working_days'] as num?;
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('labor-period-reference'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_month_outlined,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r['coverage_scope'] == 'project'
                      ? 'PROJECT PERIOD (REFERENCE)'
                      : r['reference_source'] == 'estimation'
                      ? 'ESTIMATED PERIOD (REFERENCE)'
                      : 'SERVICE PERIOD (REFERENCE)',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${start.isEmpty ? 'Not set' : start} → ${end.isEmpty ? 'Not set' : end}${duration == null ? '' : ' · ${duration.toString().replaceFirst(RegExp(r"\.0$"), "")} working days'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget workerIdentity(
    Map<String, dynamic> worker,
    String responsibility,
    bool needsAccount,
  ) {
    final theme = Theme.of(context);
    final name = worker['full_name'] as String;
    final position = worker['role_name'] as String? ?? 'No trade';
    final status = responsibility == 'none'
        ? null
        : needsAccount
        ? 'Account required'
        : 'Active account';
    return LayoutBuilder(
      builder: (context, size) {
        final person = Tooltip(
          message: name,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        );
        final trade = Tooltip(
          message: position,
          child: Text(
            position,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        );
        final account = status == null
            ? null
            : Text(status, style: theme.textTheme.bodySmall);
        if (size.maxWidth < 520)
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              person,
              Wrap(
                spacing: 8,
                runSpacing: 2,
                children: [trade, if (account != null) account],
              ),
            ],
          );
        return Row(
          children: [
            Expanded(flex: 3, child: person),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: trade),
            if (account != null) ...[
              const SizedBox(width: 12),
              Expanded(flex: 2, child: account),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foremen = <String, String>{
      for (final f in _rows(widget.data['foremen']))
        f['id'] as String: f['name'] as String? ?? 'Foreman',
    };
    final candidates = _rows(widget.data['workers'])
        .where(
          (w) =>
              !checkingWorkers &&
              availabilityFailure == null &&
              '${w['full_name']} ${w['role_name']}'.toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();
    bool matchesRole(Map<String, dynamic> worker) {
      final plannedRole = role;
      if (plannedRole == null) return false;
      if (plannedRole['role_id'] != null && worker['role_id'] != null) {
        return plannedRole['role_id'] == worker['role_id'];
      }
      final name = (plannedRole['role_name'] as String? ?? '')
          .trim()
          .toLowerCase();
      return name.isNotEmpty &&
          name == (worker['role_name'] as String? ?? '').trim().toLowerCase();
    }

    candidates.sort((a, b) {
      final priority = (matchesRole(a) ? 0 : 1).compareTo(
        matchesRole(b) ? 0 : 1,
      );
      if (priority != 0) return priority;
      final name = (a['full_name'] as String).toLowerCase().compareTo(
        (b['full_name'] as String).toLowerCase(),
      );
      return name != 0
          ? name
          : (a['id'] as String).compareTo(b['id'] as String);
    });
    final personnelPanel = widget.newPeople
        ? LayoutBuilder(
            key: const ValueKey('personnel-column'),
            builder: (context, bounds) {
              final controls = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  field(
                    'Planned trade',
                    DropdownButtonFormField<String>(
                      initialValue: roleId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Select trade',
                      ),
                      items: roles
                          .map(
                            (r) => DropdownMenuItem(
                              value: r['id'] as String,
                              child: Text(
                                roleOption(r),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (v) {
                              setState(() {
                                switchRole(v);
                              });
                              refreshWorkerAvailability();
                            },
                    ),
                  ),
                  const SizedBox(height: 8),
                  pair(dateField(true), dateField(false)),
                  const SizedBox(height: 8),
                  Text(
                    'The end date follows the service duration.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  if (freeForCurrent > 0 && draft.length >= freeForCurrent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'All $freeForCurrent available positions are selected. Clear a selection to choose another worker.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  field(
                    'Search workers',
                    TextField(
                      key: ValueKey('worker-search-$roleId'),
                      decoration: const InputDecoration(
                        hintText: 'First or last name',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
              final candidatesList = Container(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: checkingWorkers
                    ? const Center(child: CircularProgressIndicator())
                    : availabilityFailure != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(availabilityFailure!),
                              TextButton(
                                onPressed: refreshWorkerAvailability,
                                child: const Text('Retry availability'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : candidates.isEmpty
                    ? const Center(child: Text('No workers match your search.'))
                    : ListView.separated(
                        primary: false,
                        padding: EdgeInsets.zero,
                        itemCount: candidates.length,
                        separatorBuilder: (_, i) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final w = candidates[i];
                          final busy = globalBusy.contains(w['id']);
                          final responsibility =
                              role?['operational_role'] ?? 'none';
                          final needsAccount =
                              responsibility != 'none' &&
                              (w['profile_id'] == null ||
                                  w['access_status'] != 'active' ||
                                  w['profile_role'] != responsibility);
                          final staged = stagedElsewhere(w['id'] as String);
                          final reasons = bookings.where(
                            (b) => b['worker_id'] == w['id'],
                          );
                          return Material(
                            color: theme.colorScheme.surface,
                            child: CheckboxListTile(
                              dense: true,
                              key: ValueKey('worker-option-${w['id']}'),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 2,
                              ),
                              visualDensity: const VisualDensity(
                                horizontal: -1,
                                vertical: -2,
                              ),
                              minTileHeight: 48,
                              title: workerIdentity(
                                w,
                                responsibility,
                                needsAccount,
                              ),
                              subtitle:
                                  !needsAccount && reasons.isEmpty && !staged
                                  ? null
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (needsAccount)
                                          Text(
                                            'Requires an active linked $responsibility account.',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        for (final booking in reasons)
                                          Text(
                                            'Booked in ${booking['project_title']} · ${booking['role_name'] ?? 'Worker'} · ${booking['start_date'] ?? 'No start'} → ${booking['end_date'] ?? 'No end'}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color:
                                                      theme.colorScheme.error,
                                                ),
                                          ),
                                        if (staged)
                                          const Text(
                                            'Already selected for another trade in this service.',
                                          ),
                                      ],
                                    ),
                              value: draft.contains(w['id']),
                              onChanged:
                                  saving ||
                                      busy ||
                                      needsAccount ||
                                      staged ||
                                      (!draft.contains(w['id']) &&
                                          draft.length >= freeForCurrent)
                                  ? null
                                  : (v) => setState(() {
                                      if (v == true) {
                                        draft.add(w['id'] as String);
                                      } else {
                                        draft.remove(w['id']);
                                      }
                                    }),
                            ),
                          );
                        },
                      ),
              );
              final actions = Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${draft.length} selected · $freeForCurrent positions available',
                    style: theme.textTheme.bodySmall,
                  ),
                  FilledButton.icon(
                    key: const ValueKey('accept-role'),
                    icon: const Icon(Icons.add),
                    onPressed:
                        saving ||
                            checkingWorkers ||
                            availabilityFailure != null ||
                            (draft.isEmpty && acceptedFor(roleId).isEmpty)
                        ? null
                        : acceptRole,
                    label: Text(
                      currentChanged || acceptedFor(roleId).isEmpty
                          ? 'Add to summary'
                          : 'Selection added',
                    ),
                  ),
                ],
              );
              if (bounds.maxHeight < 550) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    actions,
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            controls,
                            SizedBox(height: 240, child: candidatesList),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  actions,
                  const SizedBox(height: 8),
                  controls,
                  Expanded(child: candidatesList),
                ],
              );
            },
          )
        : const SizedBox.shrink();
    final summaryPanel = Column(
      key: const ValueKey('summary-column'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        acceptedSummary(),
        reference(),
        Material(
          color: theme.colorScheme.surface,
          child: ExpansionTile(
            key: const PageStorageKey('occupancy-details'),
            tilePadding: EdgeInsets.zero,
            title: Text(
              'Available positions: $freeForCurrent',
              style: theme.textTheme.labelLarge,
            ),
            children: [vacancySummary()],
          ),
        ),

        if (widget.onlyTeamResourceId == null)
          section(
            widget.newPeople ? '2. Crew and leader' : '1. Crew and leader',
            [
              field(
                'Crew',
                DropdownButtonFormField<String>(
                  initialValue: crew,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Plan without a crew for now',
                  ),
                  items: [
                    if (widget.newPeople)
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Plan without a crew for now'),
                      ),
                    const DropdownMenuItem(
                      value: '__new__',
                      child: Text('Create new crew'),
                    ),
                    ..._rows(widget.data['crews'])
                        .where((c) => c['active'] == true)
                        .map(
                          (c) => DropdownMenuItem(
                            value: c['id'] as String,
                            child: Text(
                              c['name'] as String,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                  ],
                  onChanged: saving
                      ? null
                      : (v) => setState(() {
                          crew = v;
                          foreman = null;
                        }),
                ),
              ),
              if (crew == '__new__') ...[
                const SizedBox(height: 16),
                field(
                  'Crew name',
                  TextFormField(
                    key: const ValueKey('crew-name'),
                    controller: name,
                    enabled: !saving,
                    decoration: const InputDecoration(hintText: 'e.g. Crew A'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter a name' : null,
                  ),
                ),
              ],
              if (crew != null) ...[
                const SizedBox(height: 16),
                field(
                  'Authorized Foreman',
                  DropdownButtonFormField<String>(
                    key: ValueKey(crew),
                    initialValue: foreman,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Select Foreman',
                    ),
                    items: foremen.entries
                        .map(
                          (f) => DropdownMenuItem(
                            value: f.key,
                            child: Text(
                              f.value,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (v) => setState(() => foreman = v),
                    validator: (v) => crew == '__new__' && v == null
                        ? 'Select an authorized Foreman'
                        : null,
                  ),
                  help: foremen.isEmpty
                      ? 'An administrator must authorize a Foreman under Project Access.'
                      : 'Leave blank to retain the existing crew leader.',
                ),
              ],
            ],
          ),
      ],
    );
    return Theme(
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
        title: widget.newPeople
            ? 'Assign Personnel and Crew'
            : 'Organize Selected Personnel',
        subtitle: serviceName,
        icon: Icons.groups_outlined,
        maxWidth: 1200,
        scrollBody: !widget.newPeople,
        bodyPadding: const EdgeInsets.all(24),
        headerColor: theme.colorScheme.surface,
        footerColor: theme.colorScheme.surface,
        onClose: () {
          if (!saving) Navigator.pop(context, false);
        },
        body: widget.newPeople
            ? Form(
                key: form,
                child: LayoutBuilder(
                  builder: (context, bounds) {
                    Widget panel(Widget child, String id) =>
                        SingleChildScrollView(
                          key: PageStorageKey(id),
                          padding: const EdgeInsets.only(right: 8),
                          child: child,
                        );
                    if (bounds.maxWidth >= 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 65, child: personnelPanel),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 35,
                            child: panel(summaryPanel, 'summary-scroll'),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        SegmentedButton<bool>(
                          segments: [
                            const ButtonSegment(
                              value: false,
                              label: Text('Personal'),
                              icon: Icon(Icons.people_outline),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text('Resumen (${selected.length})'),
                              icon: const Icon(Icons.fact_check_outlined),
                            ),
                          ],
                          selected: {summaryTab},
                          onSelectionChanged: (value) =>
                              setState(() => summaryTab = value.first),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: IndexedStack(
                            index: summaryTab ? 1 : 0,
                            children: [
                              personnelPanel,
                              panel(summaryPanel, 'summary-scroll'),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              )
            : Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    reference(),
                    if (widget.onlyTeamResourceId == null)
                      section(
                        widget.newPeople
                            ? '2. Crew and leader'
                            : '1. Crew and leader',
                        [
                          field(
                            'Crew',
                            DropdownButtonFormField<String>(
                              initialValue: crew,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                hintText: 'Plan without a crew for now',
                              ),
                              items: [
                                if (widget.newPeople)
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Plan without a crew for now'),
                                  ),
                                const DropdownMenuItem(
                                  value: '__new__',
                                  child: Text('Create new crew'),
                                ),
                                ..._rows(widget.data['crews'])
                                    .where((c) => c['active'] == true)
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c['id'] as String,
                                        child: Text(
                                          c['name'] as String,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                              ],
                              onChanged: saving
                                  ? null
                                  : (v) => setState(() {
                                      crew = v;
                                      foreman = null;
                                    }),
                            ),
                          ),
                          if (crew == '__new__') ...[
                            const SizedBox(height: 16),
                            field(
                              'Crew name',
                              TextFormField(
                                key: const ValueKey('crew-name'),
                                controller: name,
                                enabled: !saving,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Crew A',
                                ),
                                validator: (v) => v == null || v.trim().isEmpty
                                    ? 'Enter a name'
                                    : null,
                              ),
                            ),
                          ],
                          if (crew != null) ...[
                            const SizedBox(height: 16),
                            field(
                              'Authorized Foreman',
                              DropdownButtonFormField<String>(
                                key: ValueKey(crew),
                                initialValue: foreman,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  hintText: 'Select Foreman',
                                ),
                                items: foremen.entries
                                    .map(
                                      (f) => DropdownMenuItem(
                                        value: f.key,
                                        child: Text(
                                          f.value,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: saving
                                    ? null
                                    : (v) => setState(() => foreman = v),
                                validator: (v) => crew == '__new__' && v == null
                                    ? 'Select an authorized Foreman'
                                    : null,
                              ),
                              help: foremen.isEmpty
                                  ? 'An administrator must authorize a Foreman under Project Access.'
                                  : 'Leave blank to retain the existing crew leader.',
                            ),
                          ],
                        ],
                      ),
                    section(
                      widget.newPeople
                          ? '3. Assignment dates'
                          : '2. Participation dates',
                      [
                        if (!widget.newPeople) ...[
                          const Text('Proposed common period'),
                          const SizedBox(height: 8),
                          pair(dateField(true), dateField(false)),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.date_range),
                              label: const Text('Apply period to selected'),
                              onPressed: saving || selected.isEmpty
                                  ? null
                                  : () {
                                      if (!_date(from.text) ||
                                          !_date(until.text) ||
                                          until.text.compareTo(from.text) < 0) {
                                        setState(
                                          () => error =
                                              'Select a valid common period',
                                        );
                                        return;
                                      }
                                      setState(() {
                                        revision++;
                                        error = null;
                                        for (final r in selected) {
                                          r['valid_from'] = from.text;
                                          r['valid_until'] = until.text;
                                        }
                                      });
                                    },
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        Text(
                          'Individual periods (${selected.length})',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.newPeople
                              ? 'These workers are confirmed. Adjust their dates before saving.'
                              : 'Crew participation must remain within each worker’s original plan.',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (selected.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('Select workers to set their dates.'),
                          ),
                        ...selected.map(
                          (r) => Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  r['worker_name'] as String,
                                  style: theme.textTheme.titleSmall,
                                ),
                                if (r['role_name'] != null)
                                  Text(
                                    'Trade: ${r['role_name']}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                if (r['assignment_id'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Original plan: ${r['start_date'] ?? 'Not set'} → ${r['end_date'] ?? 'Not set'}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                pair(
                                  dateField(true, row: r),
                                  dateField(false, row: r),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (error != null && !widget.newPeople)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
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
            Text(
              '${selected.length} workers selected',
              style: theme.textTheme.labelLarge,
            ),
            if (widget.newPeople && error != null)
              SizedBox(
                width: double.infinity,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: SingleChildScrollView(
                    child: Text(
                      error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ),
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving ? null : save,
              child: Text(saving ? 'Saving…' : 'Save plan'),
            ),
          ],
        ),
      ),
    );
  }
}
