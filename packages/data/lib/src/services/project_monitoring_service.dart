import 'package:supabase_flutter/supabase_flutter.dart';

class ProjectMonitoringService {
  final SupabaseClient _supabase;
  ProjectMonitoringService(this._supabase);

  Future<Map<String, dynamic>> getProjectSummary(String projectId) async {
    final project = await _supabase
        .from('projects')
        .select('id, title, start_date, end_date, quote_id')
        .eq('id', projectId)
        .maybeSingle();

    final quoteId = project?['quote_id'];
    double totalPlannedCost = 0;
    List<Map<String, dynamic>> plannedServices = [];
    if (quoteId != null) {
      final qs = await _supabase
          .from('quote_services')
          .select('id, name, quantity, unit_of_measure, direct_cost')
          .eq('quote_id', quoteId);
      plannedServices = List<Map<String, dynamic>>.from(qs ?? []);
      for (final s in plannedServices) {
        totalPlannedCost += (s['direct_cost'] as num?)?.toDouble() ?? 0;
      }
    }

    final now = DateTime.now();
    final start = DateTime.tryParse(project?['start_date']?.toString() ?? '');
    final end = DateTime.tryParse(project?['end_date']?.toString() ?? '');
    final totalDays = start != null && end != null ? end.difference(start).inDays : 1;
    final elapsedDays = start != null ? now.difference(start).inDays.clamp(0, totalDays) : 0;

    return {
      'project_id': projectId,
      'project_name': project?['title'] ?? '',
      'total_planned_cost': totalPlannedCost,
      'start_date': project?['start_date'],
      'end_date': project?['end_date'],
      'total_days': totalDays,
      'elapsed_days': elapsedDays,
      'services_count': plannedServices.length,
    };
  }

  Future<Map<String, List<Map<String, dynamic>>>> getServiceDetails(String projectId) async {
    final project = await _supabase
        .from('projects')
        .select('quote_id')
        .eq('id', projectId)
        .maybeSingle();
    final quoteId = project?['quote_id'];
    if (quoteId == null) return {'services': [], 'alerts': []};

    final plannedServices = await _supabase
        .from('quote_services')
        .select('id, name, quantity, unit_of_measure, direct_cost')
        .eq('quote_id', quoteId);
    final services = List<Map<String, dynamic>>.from(plannedServices ?? []);

    final machLogs = await _supabase
        .from('report_machinery_logs')
        .select('''
          production_value, total_hours,
          machinery!inner(capacity_yards),
          project_machinery!inner(quote_service_id, project_id, id),
          daily_reports!inner(status),
          workers!operator_id!inner(role_id, labor_roles!inner(hourly_rate))
        ''')
        .eq('project_machinery.project_id', projectId)
        .in_('daily_reports.status', ['submitted', 'approved']);
    final machList = List<Map<String, dynamic>>.from(machLogs ?? []);

    final laborLogs = await _supabase
        .from('report_labor_logs')
        .select('''
          regular_hours, overtime_hours,
          project_labor!inner(quote_service_id, project_id),
          daily_reports!inner(status)
        ''')
        .eq('project_labor.project_id', projectId)
        .in_('daily_reports.status', ['submitted', 'approved']);
    final laborList = List<Map<String, dynamic>>.from(laborLogs ?? []);

    final Map<String, double> prodByService = {};
    final Map<String, double> hrsByService = {};
    for (final log in machList) {
      final qsId = log['project_machinery']?['quote_service_id']?.toString();
      if (qsId == null) continue;
      final cap = (log['machinery']?['capacity_yards'] as num?)?.toDouble() ?? 1;
      final prod = (log['production_value'] as num?)?.toDouble() ?? 0;
      final hrs = (log['total_hours'] as num?)?.toDouble() ?? 0;
      prodByService[qsId] = (prodByService[qsId] ?? 0) + prod * cap;
      hrsByService[qsId] = (hrsByService[qsId] ?? 0) + hrs;
    }

    final Map<String, double> laborHrsByService = {};
    final Map<String, double> laborCostByService = {};
    for (final log in laborList) {
      final qsId = log['project_labor']?['quote_service_id']?.toString();
      if (qsId == null) continue;
      final reg = (log['regular_hours'] as num?)?.toDouble() ?? 0;
      final ot = (log['overtime_hours'] as num?)?.toDouble() ?? 0;
      laborHrsByService[qsId] = (laborHrsByService[qsId] ?? 0) + reg + ot;
      final rate = 0.0;
      laborCostByService[qsId] = (laborCostByService[qsId] ?? 0) + reg * rate + ot * rate * 1.5;
    }

    final List<Map<String, dynamic>> resultServices = [];
    final List<Map<String, dynamic>> alerts = [];

    for (final svc in services) {
      final qsId = svc['id'].toString();
      final plannedQty = (svc['quantity'] as num?)?.toDouble() ?? 0;
      final directCost = (svc['direct_cost'] as num?)?.toDouble() ?? 0;
      final actualProd = prodByService[qsId] ?? 0;
      final progress = plannedQty > 0 ? (actualProd / plannedQty * 100) : 0.0;
      final unitCost = plannedQty > 0 ? directCost / plannedQty : 0;
      final ev = actualProd * unitCost;
      final totalHrs = (hrsByService[qsId] ?? 0) + (laborHrsByService[qsId] ?? 0);
      final actualCost = laborCostByService[qsId] ?? 0;
      final cpi = actualCost > 0 && ev > 0 ? ev / actualCost : 1.0;

      if (actualCost > 0 && ev > 0 && cpi < 0.95) {
        alerts.add({
          'type': 'cost',
          'severity': 'warning',
          'message': '${svc['name']}: CPI ${cpi.toStringAsFixed(2)} below threshold',
          'service_id': qsId,
        });
      }
      if (plannedQty > 0 && progress < 50) {
        alerts.add({
          'type': 'schedule',
          'severity': progress < 10 ? 'critical' : 'warning',
          'message': '${svc['name']}: Only ${progress.toStringAsFixed(1)}% complete',
          'service_id': qsId,
        });
      }

      resultServices.add({
        'quote_service_id': qsId,
        'name': svc['name'],
        'unit': svc['unit_of_measure'] ?? '',
        'planned_quantity': plannedQty,
        'actual_quantity': actualProd,
        'progress': progress,
        'planned_cost': directCost,
        'actual_cost': actualCost,
        'earned_value': ev,
        'cpi': cpi,
        'performance': totalHrs > 0 ? actualProd / totalHrs : 0.0,
      });
    }

    return {'services': resultServices, 'alerts': alerts};
  }

  Future<List<Map<String, dynamic>>> getResourceDetails(String projectId, String serviceId) async {
    final List<Map<String, dynamic>> resources = [];

    final machResult = await _supabase
        .from('report_machinery_logs')
        .select('''
          production_value, total_hours,
          project_machinery!inner(id, machinery_name, quote_service_id, project_id),
          daily_reports!inner(status),
          machinery!inner(description, capacity_yards),
          deviation_reasons(code, description)
        ''')
        .eq('project_machinery.project_id', projectId)
        .eq('project_machinery.quote_service_id', serviceId)
        .in_('daily_reports.status', ['submitted', 'approved']);
    final machList = List<Map<String, dynamic>>.from(machResult ?? []);

    final Map<String, Map<String, dynamic>> machMap = {};
    for (final log in machList) {
      final pmId = log['project_machinery']?['id']?.toString() ?? '';
      if (pmId.isEmpty) continue;
      if (!machMap.containsKey(pmId)) {
        final cap = (log['machinery']?['capacity_yards'] as num?)?.toDouble() ?? 1;
        machMap[pmId] = {
          'id': pmId,
          'type': 'machinery',
          'name': log['project_machinery']?['machinery_name']?.toString() ?? log['machinery']?['description']?.toString() ?? 'Unknown',
          'total_production': 0.0,
          'total_hours': 0.0,
          'entries_count': 0,
          'deviation_count': 0,
          'capacity_yards': cap,
        };
      }
      final entry = machMap[pmId]!;
      entry['total_production'] = (entry['total_production'] as double) + ((log['production_value'] as num?)?.toDouble() ?? 0);
      entry['total_hours'] = (entry['total_hours'] as double) + ((log['total_hours'] as num?)?.toDouble() ?? 0);
      entry['entries_count'] = (entry['entries_count'] as int) + 1;
      if (log['deviation_reasons'] != null) {
        entry['deviation_count'] = (entry['deviation_count'] as int) + 1;
      }
    }
    resources.addAll(machMap.values);

    final laborResult = await _supabase
        .from('report_labor_logs')
        .select('''
          regular_hours, overtime_hours, is_unplanned, deviation_reason_id,
          project_labor!inner(id, role_name, quote_service_id, project_id),
          daily_reports!inner(status),
          workers!inner(full_name, id_number, role_id, labor_roles!inner(description, hourly_rate)),
          deviation_reasons(code, description)
        ''')
        .eq('project_labor.project_id', projectId)
        .eq('project_labor.quote_service_id', serviceId)
        .in_('daily_reports.status', ['submitted', 'approved']);
    final laborList = List<Map<String, dynamic>>.from(laborResult ?? []);

    final Map<String, Map<String, dynamic>> workerMap = {};
    for (final log in laborList) {
      final workerId = log['workers']?['id']?.toString() ?? '';
      if (workerId.isEmpty) continue;
      if (!workerMap.containsKey(workerId)) {
        workerMap[workerId] = {
          'id': workerId,
          'type': 'labor',
          'name': log['workers']?['full_name']?.toString() ?? 'Unknown',
          'id_number': log['workers']?['id_number']?.toString() ?? '',
          'role': log['workers']?['labor_roles']?['description']?.toString() ?? '',
          'total_hours': 0.0,
          'total_ot': 0.0,
          'entries_count': 0,
          'deviation_count': 0,
          'unplanned_count': 0,
        };
      }
      final entry = workerMap[workerId]!;
      final reg = (log['regular_hours'] as num?)?.toDouble() ?? 0;
      final ot = (log['overtime_hours'] as num?)?.toDouble() ?? 0;
      entry['total_hours'] = (entry['total_hours'] as double) + reg + ot;
      entry['total_ot'] = (entry['total_ot'] as double) + ot;
      entry['entries_count'] = (entry['entries_count'] as int) + 1;
      if (log['deviation_reason_id'] != null) {
        entry['deviation_count'] = (entry['deviation_count'] as int) + 1;
      }
      if (log['is_unplanned'] == true) {
        entry['unplanned_count'] = (entry['unplanned_count'] as int) + 1;
      }
    }
    resources.addAll(workerMap.values);

    return resources;
  }

  Future<List<Map<String, dynamic>>> getDailyHistory(String projectId, String resourceType, String resourceId) async {
    if (resourceType == 'machinery') {
      final logs = await _supabase
          .from('report_machinery_logs')
          .select('''
            id, production_value, total_hours, fuel_added, is_unplanned,
            daily_reports!inner(report_date, status),
            deviation_reasons(code, description)
          ''')
          .eq('project_machinery_id', resourceId)
          .in_('daily_reports.status', ['submitted', 'approved'])
          .order('id', ascending: true);
      return List<Map<String, dynamic>>.from(logs ?? []);
    } else if (resourceType == 'labor') {
      final logs = await _supabase
          .from('report_labor_logs')
          .select('''
            id, regular_hours, overtime_hours, is_unplanned,
            daily_reports!inner(report_date, status),
            deviation_reasons(code, description)
          ''')
          .eq('worker_id', resourceId)
          .eq('daily_reports.project_id', projectId)
          .in_('daily_reports.status', ['submitted', 'approved'])
          .order('id', ascending: true);
      return List<Map<String, dynamic>>.from(logs ?? []);
    }
    return [];
  }

  Future<Map<String, dynamic>> getWorkerIrregularities(String projectId) async {
    final logs = await _supabase
        .from('report_labor_logs')
        .select('''
          id, regular_hours, overtime_hours, is_unplanned, deviation_reason_id,
          project_labor!inner(project_id),
          daily_reports!inner(status),
          workers!inner(id, full_name, id_number, role_id, labor_roles!inner(description, hourly_rate)),
          deviation_reasons(code, description)
        ''')
        .eq('project_labor.project_id', projectId)
        .in_('daily_reports.status', ['submitted', 'approved']);
    final allLogs = List<Map<String, dynamic>>.from(logs ?? []);

    final Map<String, Map<String, dynamic>> workers = {};
    for (final log in allLogs) {
      final w = log['workers'] as Map<String, dynamic>?;
      final wid = w?['id']?.toString() ?? '';
      if (wid.isEmpty) continue;
      if (!workers.containsKey(wid)) {
        workers[wid] = {
          'id': wid,
          'name': w?['full_name'] ?? '',
          'id_number': w?['id_number'] ?? '',
          'role': w?['labor_roles']?['description'] ?? '',
          'total_hours': 0.0,
          'total_ot': 0.0,
          'deviation_count': 0,
          'unplanned_count': 0,
          'absence_count': 0,
        };
      }
      final entry = workers[wid]!;
      final reg = (log['regular_hours'] as num?)?.toDouble() ?? 0;
      final ot = (log['overtime_hours'] as num?)?.toDouble() ?? 0;
      entry['total_hours'] = (entry['total_hours'] as double) + reg + ot;
      entry['total_ot'] = (entry['total_ot'] as double) + ot;
      if (log['deviation_reason_id'] != null) {
        entry['deviation_count'] = (entry['deviation_count'] as int) + 1;
      }
      if (log['is_unplanned'] == true) {
        entry['unplanned_count'] = (entry['unplanned_count'] as int) + 1;
      }
    }
    final irregulars = workers.values.where((w) =>
        (w['deviation_count'] as int) >= 3 ||
        (w['unplanned_count'] as int) >= 2 ||
        (w['total_ot'] as double) > 20
    ).toList();
    irregulars.sort((a, b) => (b['deviation_count'] as int).compareTo(a['deviation_count'] as int));

    return {
      'irregular_workers': irregulars,
      'total_workers': workers.length,
      'irregular_count': irregulars.length,
    };
  }

  Future<Map<String, dynamic>> getMachineryIrregularities(String projectId) async {
    final logs = await _supabase
        .from('report_machinery_logs')
        .select('''
          id, production_value, total_hours, is_unplanned, deviation_reason_id,
          project_machinery!inner(id, machinery_name, project_id),
          daily_reports!inner(status),
          machinery!inner(description, capacity_yards),
          deviation_reasons(code, description)
        ''')
        .eq('project_machinery.project_id', projectId)
        .in_('daily_reports.status', ['submitted', 'approved']);
    final allLogs = List<Map<String, dynamic>>.from(logs ?? []);

    final Map<String, Map<String, dynamic>> machines = {};
    for (final log in allLogs) {
      final pm = log['project_machinery'] as Map<String, dynamic>?;
      final pmId = pm?['id']?.toString() ?? '';
      if (pmId.isEmpty) continue;
      if (!machines.containsKey(pmId)) {
        machines[pmId] = {
          'id': pmId,
          'name': pm?['machinery_name']?.toString() ?? log['machinery']?['description']?.toString() ?? '',
          'total_production': 0.0,
          'total_hours': 0.0,
          'deviation_count': 0,
          'entries_count': 0,
        };
      }
      final entry = machines[pmId]!;
      entry['total_production'] = (entry['total_production'] as double) + ((log['production_value'] as num?)?.toDouble() ?? 0);
      entry['total_hours'] = (entry['total_hours'] as double) + ((log['total_hours'] as num?)?.toDouble() ?? 0);
      entry['entries_count'] = (entry['entries_count'] as int) + 1;
      if (log['deviation_reason_id'] != null) {
        entry['deviation_count'] = (entry['deviation_count'] as int) + 1;
      }
    }
    final irregulars = machines.values.where((m) =>
        (m['deviation_count'] as int) >= 2 ||
        ((m['total_production'] as double) / ((m['total_hours'] as double).clamp(1, 9999))) < 1.0
    ).toList();
    irregulars.sort((a, b) => (b['deviation_count'] as int).compareTo(a['deviation_count'] as int));

    return {
      'irregular_machines': irregulars,
      'total_machines': machines.length,
      'irregular_count': irregulars.length,
    };
  }
}
