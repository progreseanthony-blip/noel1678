import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noel_data/noel_data.dart';
import '../../shared/widgets/sidebar.dart';
import '../payroll/presentation/utils/save_bytes.dart';

class CrewReportsPage extends StatefulWidget {
  final bool hoursOnly;
  const CrewReportsPage({super.key, this.hoursOnly = false});
  @override
  State<CrewReportsPage> createState() => _CrewReportsPageState();
}

class _CrewReportsPageState extends State<CrewReportsPage> {
  final db = Supabase.instance.client;
  final notes = TextEditingController();
  final form = GlobalKey<FormState>();
  AccessContext access = const AccessContext();
  List<Map<String, dynamic>> crews = [],
      people = [],
      machines = [],
      materials = [],
      reports = [],
      labor = [],
      machinery = [],
      usage = [],
      hours = [];
  String? crewId, error;
  DateTime day = DateTime.now(),
      start = DateTime.now().subtract(const Duration(days: 13)),
      end = DateTime.now();
  bool busy = true, saving = false, locked = true, projectActive = false;
  String date(DateTime d) => d.toIso8601String().substring(0, 10);
  List<Map<String, dynamic>> rows(dynamic x) =>
      List<Map<String, dynamic>>.from(x as List? ?? []);
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      access = await AccessService(db).load();
      crews = rows(await db.rpc('get_crew_workspace'));
      crewId ??= crews.firstOrNull?['id'] as String?;
      if (crewId != null) {
        final data = Map<String, dynamic>.from(
          await db.rpc(
                'get_crew_workspace',
                params: {'p_crew': crewId, 'p_day': date(day)},
              )
              as Map,
        );
        people = rows(data['workers']);
        machines = rows(data['machinery']);
        materials = rows(data['materials']);
        reports = rows(data['reports']);
        projectActive = data['project_status'] == 'active';
        final current = reports
            .where((r) => r['report_date'] == date(day))
            .firstOrNull;
        notes.text = current?['notes'] as String? ?? '';
        labor = rows(
          current?['labor'],
        ).map((r) => Map<String, dynamic>.from(r)).toList();
        machinery = rows(
          current?['machinery'],
        ).map((r) => Map<String, dynamic>.from(r)).toList();
        usage = rows(
          current?['materials'],
        ).map((r) => Map<String, dynamic>.from(r)).toList();
        locked =
            !access.isForeman ||
            !projectActive ||
            (current != null &&
                (!['draft', 'returned'].contains(current['status']) ||
                    current['created_by'] != db.auth.currentUser?.id));
        hours = rows(
          await db.rpc(
            'get_operational_hours',
            params: {
              'p_crew': crewId,
              'p_start': date(start),
              'p_end': date(end),
            },
          ),
        );
      }
    } catch (e) {
      error = e.toString();
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> run(Future<void> Function() task) async {
    setState(() => saving = true);
    try {
      await task();
      await load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> save(bool submit) async {
    if (!form.currentState!.validate()) return;
    await run(() async {
      await db.rpc(
        'save_crew_report',
        params: {
          'p_crew': crewId,
          'p_day': date(day),
          'p_notes': notes.text,
          'p_labor': labor,
          'p_machinery': machinery,
          'p_materials': usage,
          'p_submit': submit,
        },
      );
    });
  }

  Future<void> review(Map<String, dynamic> report, bool approve) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          approve ? 'Incorporar al reporte diario' : 'Devolver para corrección',
        ),
        content: approve
            ? const Text(
                'Se incorporarán las horas, producción y consumos una sola vez. El reporte consolidado continuará en borrador para su revisión final.',
              )
            : TextField(
                controller: reason,
                decoration: const InputDecoration(
                  labelText: 'Motivo obligatorio',
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (ok == true)
      await run(() async {
        await db.rpc(
          'review_crew_report',
          params: {
            'p_report': report['id'],
            'p_approve': approve,
            'p_reason': reason.text,
          },
        );
      });
    reason.dispose();
  }

  Future<void> chooseDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      day = picked;
      await load();
    }
  }

  Widget number(
    Map<String, dynamic> row,
    String key,
    String label, {
    String fallback = '0',
    bool integer = false,
  }) => SizedBox(
    width: 145,
    child: TextFormField(
      key: ValueKey('${row.hashCode}$key'),
      initialValue: '${row[key] ?? fallback}',
      enabled: !locked && !saving,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      onChanged: (v) => row[key] = integer ? int.tryParse(v) : num.tryParse(v),
      validator: (v) {
        final n = num.tryParse(v ?? '');
        return n == null ||
                !n.isFinite ||
                n < 0 ||
                (integer && n != n.roundToDouble())
            ? 'Valor inválido'
            : null;
      },
    ),
  );
  Widget time(Map<String, dynamic> row, String key, String label) => SizedBox(
    width: 145,
    child: TextFormField(
      key: ValueKey('${row.hashCode}$key'),
      initialValue: '${row[key] ?? ''}',
      enabled: !locked && !saving,
      decoration: InputDecoration(labelText: label),
      onChanged: (v) => row[key] = v,
      validator: (v) =>
          RegExp(r'^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$').hasMatch(v ?? '')
          ? null
          : 'Usa HH:MM',
    ),
  );
  Widget select(
    Map<String, dynamic> row,
    String key,
    String label,
    List<Map<String, dynamic>> options, {
    String id = 'id',
  }) => SizedBox(
    width: 240,
    child: DropdownButtonFormField<String>(
      isExpanded: true,
      value: options.any((p) => p[id] == row[key]) ? row[key] as String? : null,
      decoration: InputDecoration(labelText: label),
      items: options
          .map(
            (p) => DropdownMenuItem(
              value: p[id] as String,
              child: Text('${p['name']}', overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: locked || saving ? null : (v) => setState(() => row[key] = v),
      validator: (v) => v == null ? 'Obligatorio' : null,
    ),
  );
  Widget card(
    String title,
    List<Map<String, dynamic>> data,
    Map<String, dynamic> Function() create,
    List<Widget> Function(Map<String, dynamic>) fields,
  ) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (!locked)
                IconButton(
                  onPressed: saving
                      ? null
                      : () => setState(() => data.add(create())),
                  icon: const Icon(Icons.add),
                  tooltip: 'Agregar',
                ),
            ],
          ),
          ...data.map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ...fields(r),
                  if (!locked)
                    IconButton(
                      onPressed: saving
                          ? null
                          : () => setState(() => data.remove(r)),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                ],
              ),
            ),
          ),
          if (data.isEmpty) const Text('Sin registros'),
        ],
      ),
    ),
  );
  Future<void> export() async {
    String cell(dynamic v) => '"${(v ?? '').toString().replaceAll('"', '""')}"';
    final csv = [
      [
        'Fecha',
        'Trabajador',
        'Entrada',
        'Salida',
        'Descanso (min)',
        'Horas netas',
        'Estado',
      ],
      ...hours.map(
        (h) => [
          '${h['date']}',
          '${h['worker']}',
          '${h['check_in']}',
          '${h['check_out']}',
          '${h['break_minutes']}',
          '${h['hours']}',
          '${h['status']}',
        ],
      ),
    ].map((r) => r.map(cell).join(',')).join('\r\n');
    await saveBytes(
      Uint8List.fromList(utf8.encode('\uFEFF$csv')),
      'horas_${date(start)}_${date(end)}.csv',
      'text/csv;charset=utf-8',
    );
  }

  Widget hoursView() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Horas incorporadas al reporte diario. El estado indica si el consolidado ya fue aprobado.',
      ),
      Wrap(
        spacing: 16,
        children: [
          TextButton(
            onPressed: () => pickRange(true),
            child: Text('Desde: ${date(start)}'),
          ),
          TextButton(
            onPressed: () => pickRange(false),
            child: Text('Hasta: ${date(end)}'),
          ),
          FilledButton.icon(
            onPressed: hours.isEmpty ? null : () => run(export),
            icon: const Icon(Icons.download),
            label: const Text('Exportar CSV'),
          ),
        ],
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Fecha')),
            DataColumn(label: Text('Trabajador')),
            DataColumn(label: Text('Entrada')),
            DataColumn(label: Text('Salida')),
            DataColumn(label: Text('Horas netas')),
            DataColumn(label: Text('Estado')),
          ],
          rows: hours
              .map(
                (h) => DataRow(
                  cells: [
                    DataCell(Text('${h['date']}')),
                    DataCell(Text('${h['worker']}')),
                    DataCell(Text('${h['check_in']}')),
                    DataCell(Text('${h['check_out']}')),
                    DataCell(Text('${h['hours']}')),
                    DataCell(Text('${h['status']}')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
      if (hours.isEmpty)
        const Text('No hay horas incorporadas en este período.'),
    ],
  );
  Future<void> pickRange(bool first) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: first ? start : end,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (first) {
        start = picked;
        if (end.isBefore(start)) end = start;
      } else {
        end = picked;
        if (start.isAfter(end)) start = end;
      }
      await load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.hoursOnly ? 'Horas trabajadas' : 'Reportes de cuadrilla',
      ),
    ),
    drawer: Drawer(
      child: Sidebar(
        userName: db.auth.currentUser?.email ?? '',
        userEmail: '',
        onLogout: () async {
          await db.auth.signOut();
          if (context.mounted) context.go('/signin');
        },
        currentPath: widget.hoursOnly ? '/worked-hours' : '/crew-reports',
      ),
    ),
    body: busy
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error!),
                TextButton(onPressed: load, child: const Text('Reintentar')),
              ],
            ),
          )
        : crews.isEmpty
        ? const Center(
            child: Text(
              'No tienes cuadrillas asignadas. Contacta al administrador.',
            ),
          )
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: crewId,
                    decoration: const InputDecoration(
                      labelText: 'Proyecto / Cuadrilla',
                    ),
                    items: crews
                        .map(
                          (c) => DropdownMenuItem(
                            value: c['id'] as String,
                            child: Text('${c['project_title']} / ${c['name']}'),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (v) {
                            crewId = v;
                            load();
                          },
                  ),
                  const SizedBox(height: 16),
                  if (widget.hoursOnly)
                    hoursView()
                  else ...[
                    TextButton.icon(
                      onPressed: saving ? null : chooseDay,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(date(day)),
                    ),
                    if (!projectActive)
                      const Text(
                        'Proyecto en consulta: no se pueden registrar ni aprobar cambios.',
                      ),
                    Form(
                      key: form,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: notes,
                            enabled: !locked && !saving,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText:
                                  'Trabajo realizado, observaciones y novedades',
                            ),
                          ),
                          card(
                            'Personal y horas',
                            labor,
                            () => {
                              'break_minutes': 30,
                              'check_in_time': '07:00',
                              'check_out_time': '16:00',
                            },
                            (r) => [
                              SizedBox(
                                width: 240,
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value:
                                      people.any(
                                        (p) =>
                                            p['id'] == r['worker_id'] &&
                                            p['project_labor_id'] ==
                                                r['project_labor_id'],
                                      )
                                      ? '${r['worker_id']}|${r['project_labor_id']}'
                                      : null,
                                  decoration: const InputDecoration(
                                    labelText: 'Trabajador / asignación',
                                  ),
                                  items: people
                                      .map(
                                        (p) => DropdownMenuItem(
                                          value:
                                              '${p['id']}|${p['project_labor_id']}',
                                          child: Text(
                                            '${p['name']}',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: locked || saving
                                      ? null
                                      : (v) {
                                          final p = v!.split('|');
                                          setState(() {
                                            r['worker_id'] = p[0];
                                            r['project_labor_id'] = p[1];
                                          });
                                        },
                                  validator: (v) => v == null
                                      ? 'Selecciona asignación'
                                      : null,
                                ),
                              ),
                              time(r, 'check_in_time', 'Entrada (HH:MM)'),
                              time(r, 'check_out_time', 'Salida (HH:MM)'),
                              number(
                                r,
                                'break_minutes',
                                'Descanso (min)',
                                fallback: '30',
                                integer: true,
                              ),
                            ],
                          ),
                          card(
                            'Maquinaria y producción',
                            machinery,
                            () => {
                              'start_meter': 0,
                              'end_meter': 0,
                              'production_value': 0,
                            },
                            (r) => [
                              select(
                                r,
                                'project_machinery_id',
                                'Equipo planificado',
                                machines
                                    .where((m) => m['machinery_id'] != null)
                                    .toList(),
                              ),
                              select(
                                r,
                                'operator_id',
                                'Operador',
                                people.fold<List<Map<String, dynamic>>>([], (
                                  out,
                                  p,
                                ) {
                                  if (!out.any((x) => x['id'] == p['id']))
                                    out.add(p);
                                  return out;
                                }),
                              ),
                              number(r, 'start_meter', 'Horómetro inicial'),
                              number(r, 'end_meter', 'Horómetro final'),
                              number(r, 'production_value', 'Producción'),
                              SizedBox(
                                width: 145,
                                child: TextFormField(
                                  key: ValueKey('${r.hashCode}unit'),
                                  initialValue: r['production_unit'] as String?,
                                  enabled: !locked && !saving,
                                  decoration: const InputDecoration(
                                    labelText: 'Unidad producción',
                                  ),
                                  onChanged: (v) => r['production_unit'] = v,
                                ),
                              ),
                            ],
                          ),
                          card(
                            'Consumo de materiales',
                            usage,
                            () => {'quantity_used': 0},
                            (r) => [
                              select(
                                r,
                                'project_material_id',
                                'Material planificado',
                                materials
                                    .where((m) => m['material_id'] != null)
                                    .toList(),
                              ),
                              number(r, 'quantity_used', 'Cantidad utilizada'),
                            ],
                          ),
                          if (!locked)
                            Wrap(
                              spacing: 16,
                              children: [
                                OutlinedButton(
                                  onPressed: saving ? null : () => save(false),
                                  child: const Text('Guardar borrador'),
                                ),
                                FilledButton(
                                  onPressed: saving ? null : () => save(true),
                                  child: const Text('Enviar para revisión'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Historial y revisión',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ...reports.map(
                      (r) => Card(
                        child: ExpansionTile(
                          title: Text('${r['report_date']} · ${r['status']}'),
                          subtitle: Text('${r['review_notes'] ?? r['notes']}'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Observaciones: ${r['notes']}'),
                                  ...rows(r['labor']).map(
                                    (l) => Text(
                                      '${people.where((p) => p['id'] == l['worker_id']).firstOrNull?['name'] ?? l['worker_id']}: ${l['check_in_time']} – ${l['check_out_time']} · descanso ${l['break_minutes']} min',
                                    ),
                                  ),
                                  ...rows(r['machinery']).map(
                                    (m) => Text(
                                      'Equipo ${machines.where((p) => p['id'] == m['project_machinery_id']).firstOrNull?['name'] ?? m['project_machinery_id']}: ${m['start_meter']} → ${m['end_meter']}; producción ${m['production_value']} ${m['production_unit'] ?? ''}',
                                    ),
                                  ),
                                  ...rows(r['materials']).map(
                                    (m) => Text(
                                      'Material ${materials.where((p) => p['id'] == m['project_material_id']).firstOrNull?['name'] ?? m['project_material_id']}: ${m['quantity_used']}',
                                    ),
                                  ),
                                  if (r['status'] == 'submitted' &&
                                      !access.isForeman &&
                                      r['created_by'] !=
                                          db.auth.currentUser?.id &&
                                      projectActive)
                                    Wrap(
                                      spacing: 16,
                                      children: [
                                        FilledButton(
                                          onPressed: saving
                                              ? null
                                              : () => review(r, true),
                                          child: const Text('Aprobar aporte'),
                                        ),
                                        OutlinedButton(
                                          onPressed: saving
                                              ? null
                                              : () => review(r, false),
                                          child: const Text('Devolver'),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
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
