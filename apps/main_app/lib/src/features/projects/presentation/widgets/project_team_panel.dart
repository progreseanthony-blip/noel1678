import 'package:flutter/material.dart';
import 'package:noel_data/noel_data.dart';
import 'package:noel_ui_components/noel_ui_components.dart';
import '../utils/project_access_periods.dart';
import 'project_responsible_dialog.dart';

/// Team organization inside Resource Planning; account authorization is admin-only.
class ProjectResponsiblesPanel extends StatefulWidget {
  final String projectId;
  const ProjectResponsiblesPanel({super.key, required this.projectId});
  @override
  State<ProjectResponsiblesPanel> createState() =>
      _ProjectResponsiblesPanelState();
}

class _ProjectResponsiblesPanelState extends State<ProjectResponsiblesPanel> {
  final db = Supabase.instance.client;
  AccessContext access = const AccessContext();
  List<Map<String, dynamic>> users = [], members = [];
  String? error;
  List<ProjectAccessPeriod> periods = [];
  bool busy = true, saving = false, active = false;
  bool get canOrganize => active && (access.isAdmin || access.isSupervisor);
  bool editable(String table) =>
      canOrganize && (table != 'project_members' || access.isAdmin);
  List<Map<String, dynamic>> rows(dynamic value) =>
      List<Map<String, dynamic>>.from(value as List);

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(covariant ProjectResponsiblesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      load();
    }
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      access = await AccessService(db).load();
      final project = await db
          .from('projects')
          .select('status,quote_id')
          .eq('id', widget.projectId)
          .single();
      active = project['status'] == 'active';
      final referenceData = await Future.wait<dynamic>([
        if (project['quote_id'] != null)
          db
              .from('quote_services')
              .select(
                'id,name,quote_service_estimations(id,start_date,end_date,total_working_days,updated_at,created_at)',
              )
              .eq('quote_id', project['quote_id'])
        else
          Future.value(<Map<String, dynamic>>[]),
        db
            .from('project_services')
            .select('id,name,quote_service_id')
            .eq('project_id', widget.projectId),
        db
            .from('project_tasks')
            .select(
              'quote_service_id,project_service_id,planned_start_date,planned_end_date',
            )
            .eq('project_id', widget.projectId),
      ]);
      periods = ProjectAccessPeriod.fromSources(
        quoted: rows(referenceData[0]),
        live: rows(referenceData[1]),
        tasks: rows(referenceData[2]),
      );
      users = rows(
        await db
            .from('profiles')
            .select('id,name,role,access_status')
            .order('name'),
      );
      members = rows(
        await db
            .from('project_members')
            .select()
            .eq('project_id', widget.projectId)
            .order('valid_from'),
      );
    } catch (e) {
      error = e.toString();
    }
    if (mounted) {
      setState(() => busy = false);
    }
  }

  String userName(dynamic id) =>
      users.where((u) => u['id'] == id).firstOrNull?['name']?.toString() ??
      id.toString();
  Future<void> action(Future<void> Function() task) async {
    setState(() => saving = true);
    try {
      await task();
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> add(String type) async {
    if (!editable(type) || saving) {
      return;
    }
    final ok = await showSafeDialog<bool>(
      context: context,
      builder: (_) => ProjectResponsibleDialog(
        users: users,
        periods: periods,
        onSave: (data) => db.from('project_members').insert({
          'project_id': widget.projectId,
          ...data,
        }),
      ),
    );
    if (ok == true && mounted) await load();
  }

  Future<void> end(String table, Map<String, dynamic> row) async {
    if (!editable(table) || saving) {
      return;
    }
    final today = DateTime.now(),
        first = DateTime.parse(row['valid_from'] as String);
    final date = await showDatePicker(
      context: context,
      locale: const Locale('en'),
      initialDate: today.isBefore(first) ? first : today,
      firstDate: first,
      lastDate: DateTime(
        (first.year > today.year ? first.year : today.year) + 5,
      ),
    );
    if (date != null && mounted) {
      await action(() async {
        await db
            .from(table)
            .update({'valid_until': date.toIso8601String().substring(0, 10)})
            .eq('id', row['id']);
      });
    }
  }

  Widget section(
    String title,
    String table,
    List<Map<String, dynamic>> data,
    String Function(Map<String, dynamic>) label,
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
              if (editable(table))
                IconButton(
                  tooltip: 'Add authorization',
                  onPressed: saving ? null : () => add(table),
                  icon: const Icon(Icons.add),
                ),
            ],
          ),
          if (data.isEmpty) const Text('No authorizations'),
          ...data.map(
            (r) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(label(r)),
              subtitle: Text(
                '${r['valid_from']} → ${r['valid_until'] ?? 'Open-ended'}',
              ),
              trailing: editable(table)
                  ? TextButton(
                      onPressed: saving ? null : () => end(table, r),
                      child: const Text('Set end date'),
                    )
                  : null,
            ),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!),
            TextButton(onPressed: load, child: const Text('Retry')),
          ],
        ),
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Access authorizations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Administrators authorize Supervisors and Foremen for this project. Organize crew members and leaders under Labor and Crews.',
            ),
            if (!active)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'This project is read-only. Team changes are disabled.',
                ),
              ),
            section(
              'Authorized Supervisors and Foremen',
              'project_members',
              members,
              (m) => '${userName(m['profile_id'])} · ${m['responsibility']}',
            ),
          ],
        ),
      ),
    );
  }
}
