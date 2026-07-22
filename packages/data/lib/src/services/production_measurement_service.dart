import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:noel_core/noel_core.dart';
import '../remote/supabase_client.dart';
import 'daily_report_service.dart';

part 'production_measurement_service.g.dart';

@riverpod
ProductionMeasurementService productionMeasurementService(ProductionMeasurementServiceRef ref) {
  return ProductionMeasurementService(ref.watch(supabaseClientProvider));
}

class ProductionMeasurementService {
  final SupabaseClient _supabase;
  ProductionMeasurementService(this._supabase);

  Future<Map<String, dynamic>> getProjectMeasurement(String projectId) async {
    final project = await _supabase
        .from('projects')
        .select('id, title, quote_id, start_date, end_date, calculation_metadata')
        .eq('id', projectId)
        .maybeSingle();
    if (project == null) return {'error': 'Project not found'};

    final quoteId = project['quote_id'];

    List<Map<String, dynamic>> plannedServices = [];
    if (quoteId != null) {
      final qsResult = await _supabase
          .from('quote_services')
          .select('id, name, quantity, unit_of_measure, direct_cost')
          .eq('quote_id', quoteId);
      plannedServices = List<Map<String, dynamic>>.from(qsResult ?? []);
    }

    final serviceUnits = {for (final s in plannedServices) s['id'].toString(): (s['unit_of_measure'] as String?)?.toLowerCase() ?? ''};

    final machLogs = await _fetchMachineryLogs(projectId, serviceUnits);
    final laborLogs = await _fetchLaborLogs(projectId);
    final matLogs = await _fetchMaterialLogs(projectId);

    final machCostMap = await _fetchMachineryCostMap(projectId);

    final serviceIds = plannedServices.map((s) => s['id'].toString()).toList();

    final matPriceMap = await _fetchMaterialPriceMap(projectId);

    final elapsedDays = await _computeElapsedDays(project, projectId);

    final equipCostByService = await _fetchEquipmentCosts(serviceIds, elapsedDays);

    final Map<String, double> actualProduction = {};
    final Map<String, double> actualMachHours = {};
    final Map<String, double> actualLaborHours = {};
    final Map<String, double> actualLaborCost = {};
    final Map<String, double> actualMachCost = {};

    for (final log in machLogs) {
      final qsId = log['project_machinery']?['quote_service_id']?.toString();
      if (qsId == null) continue;
      final cap = (log['machinery']?['capacity_yards'] as num?)?.toDouble() ?? 0;
      final prod = (log['production_value'] as num?)?.toDouble() ?? 0;
      final hrs = (log['total_hours'] as num?)?.toDouble() ?? 0;
      final unit = serviceUnits[qsId] ?? '';
      actualProduction[qsId] = (actualProduction[qsId] ?? 0) + computeEffectiveProduction(prod, cap, unit);
      actualMachHours[qsId] = (actualMachHours[qsId] ?? 0) + hrs;

      final pmId = log['project_machinery_id']?.toString();
      final costInfo = pmId != null ? machCostMap[pmId] : null;
      if (costInfo != null) {
        final fuelAdded = (log['fuel_added'] as num?)?.toDouble() ?? 0;
        actualMachCost[qsId] = (actualMachCost[qsId] ?? 0) +
            computeMachineryCost(
              hours: hrs,
              monthlyRent: costInfo['monthly_rent_cost'] as double,
              fuelAdded: fuelAdded,
              gallonCost: costInfo['gallon_cost'] as double,
            );
      }
    }

    for (final log in laborLogs) {
      final qsId = log['project_labor']?['quote_service_id']?.toString();
      if (qsId == null) continue;
      final regHrs = (log['regular_hours'] as num?)?.toDouble() ?? 0;
      final otHrs = (log['overtime_hours'] as num?)?.toDouble() ?? 0;
      actualLaborHours[qsId] = (actualLaborHours[qsId] ?? 0) + regHrs + otHrs;

      final rate = (log['workers']?['labor_roles']?['hourly_rate'] as num?)?.toDouble() ?? 0;
      actualLaborCost[qsId] = (actualLaborCost[qsId] ?? 0) +
          computeLaborCost(regularHours: regHrs, overtimeHours: otHrs, hourlyRate: rate);
    }

    final Map<String, double> matCostByService = {};
    for (final log in matLogs) {
      final qsId = log['project_materials']?['quote_service_id']?.toString();
      if (qsId == null) continue;
      final qty = (log['quantity_used'] as num?)?.toDouble() ?? 0;
      final pmId = log['project_material_id']?.toString();
      final unitPrice = pmId != null ? (matPriceMap[pmId] ?? 0) : 0;
      matCostByService[qsId] = (matCostByService[qsId] ?? 0) + qty * unitPrice;
    }

    double totalPlannedUnits = 0;
    double totalActualUnits = 0;
    double totalPlannedCost = 0;
    double totalEarnedValue = 0;

    final List<Map<String, dynamic>> services = [];
    final List<Map<String, dynamic>> alerts = [];

    for (final ps in plannedServices) {
      final qsId = ps['id']?.toString() ?? '';
      final plannedQty = (ps['quantity'] as num?)?.toDouble() ?? 0;
      final directCost = (ps['direct_cost'] as num?)?.toDouble() ?? 0;
      final actualProd = actualProduction[qsId] ?? 0;
      final progress = computeProgress(actualProd, plannedQty);
      final unitCost = plannedQty > 0 ? directCost / plannedQty : 0;
      final ev = actualProd * unitCost;
      final machHrs = actualMachHours[qsId] ?? 0;
      final laborHrs = actualLaborHours[qsId] ?? 0;
      final actualCost = (actualLaborCost[qsId] ?? 0) +
          (actualMachCost[qsId] ?? 0) +
          (matCostByService[qsId] ?? 0) +
          (equipCostByService[qsId] ?? 0);
      final cpi = computeCPI(ev, actualCost);

      totalPlannedUnits += plannedQty;
      totalActualUnits += actualProd;
      totalPlannedCost += directCost;
      totalEarnedValue += ev;

      services.add({
        'quote_service_id': qsId,
        'name': ps['name'] ?? '',
        'unit': ps['unit_of_measure'] ?? '',
        'planned_quantity': plannedQty,
        'actual_quantity': actualProd,
        'progress': progress,
        'planned_cost': directCost,
        'actual_cost': actualCost,
        'earned_value': ev,
        'cpi': cpi,
        'performance': (machHrs + laborHrs) > 0 ? actualProd / (machHrs + laborHrs) : 0.0,
        'performance_unit': '${ps['unit_of_measure']}/hr',
      });

      alerts.addAll(generateServiceAlerts(
        serviceName: ps['name'] ?? '',
        serviceId: qsId,
        plannedQuantity: plannedQty,
        directCost: directCost,
        earnedValue: ev,
        actualCost: actualCost,
        progress: progress,
      ));
    }

    double totalActualCost = 0;
    for (final s in services) {
      totalActualCost += (s['actual_cost'] as num).toDouble();
    }

    final overallProgress = totalPlannedUnits > 0
        ? (totalActualUnits / totalPlannedUnits * 100).clamp(0.0, 100.0)
        : 0.0;
    final cpi = computeCPI(totalEarnedValue, totalActualCost);
    final eac = cpi > 0 ? totalPlannedCost / cpi : totalPlannedCost;

    double spi = 1.0;
    if (project['start_date'] != null && project['end_date'] != null) {
      final start = DateTime.tryParse(project['start_date']?.toString() ?? '');
      final end = DateTime.tryParse(project['end_date']?.toString() ?? '');
      if (start != null && end != null && end.isAfter(start)) {
        final reportService = DailyReportService(_supabase);
        final totalDays = await reportService.getEffectiveElapsedDays(projectId, start, end);
        final elapsed = await reportService.getEffectiveElapsedDays(projectId, start, DateTime.now());
        if (totalDays > 0 && elapsed > 0) {
          final pv = (elapsed / totalDays) * totalPlannedCost;
          spi = computeSPI(totalEarnedValue, pv);
        }
      }
    }

    return {
      'project_id': projectId,
      'project_name': project['title'] ?? '',
      'overall_progress': overallProgress,
      'spi': spi,
      'cpi': cpi,
      'eac': eac,
      'total_planned_cost': totalPlannedCost,
      'total_actual_cost': totalActualCost,
      'total_earned_value': totalEarnedValue,
      'total_planned_units': totalPlannedUnits,
      'total_actual_units': totalActualUnits,
      'services': services,
      'alerts': alerts,
    };
  }

  Future<Map<String, dynamic>> getProjectSummary(String projectId) async {
    final project = await _supabase
        .from('projects')
        .select('id, title, start_date, end_date, quote_id')
        .eq('id', projectId)
        .maybeSingle();

    final quoteId = project?['quote_id'];
    double totalPlannedCost = 0;
    int servicesCount = 0;
    if (quoteId != null) {
      final qs = await _supabase
          .from('quote_services')
          .select('id, direct_cost')
          .eq('quote_id', quoteId);
      final plannedServices = List<Map<String, dynamic>>.from(qs ?? []);
      servicesCount = plannedServices.length;
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
      'services_count': servicesCount,
    };
  }

  Future<Map<String, List<Map<String, dynamic>>>> getServiceDetails(String projectId) async {
    final measurement = await getProjectMeasurement(projectId);
    if (measurement.containsKey('error')) {
      return {'services': [], 'alerts': []};
    }
    return {
      'services': List<Map<String, dynamic>>.from(measurement['services'] ?? []),
      'alerts': List<Map<String, dynamic>>.from(measurement['alerts'] ?? []),
    };
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

    if (machMap.isNotEmpty) {
      final pmIds = machMap.keys.toList();
      final inspResult = await _supabase
          .from('machinery_inspections')
          .select('project_machinery_id, odometer_unit')
          .in_('project_machinery_id', pmIds);
      final Map<String, String> odometerMap = {};
      for (final row in inspResult ?? []) {
        final pmId = row['project_machinery_id']?.toString();
        if (pmId != null) {
          odometerMap[pmId] = row['odometer_unit']?.toString() ?? 'hours';
        }
      }
      for (final entry in machMap.values) {
        entry['odometer_unit'] = odometerMap[entry['id'] as String] ?? 'hours';
      }
    }

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

  Future<List<Map<String, dynamic>>> getDailyHistory(
    String projectId,
    String resourceType,
    String resourceId,
  ) async {
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

    if (machines.isNotEmpty) {
      final pmIds = machines.keys.toList();
      final inspResult = await _supabase
          .from('machinery_inspections')
          .select('project_machinery_id, odometer_unit')
          .in_('project_machinery_id', pmIds);
      final Map<String, String> odometerMap = {};
      for (final row in inspResult ?? []) {
        final pmId = row['project_machinery_id']?.toString();
        if (pmId != null) {
          odometerMap[pmId] = row['odometer_unit']?.toString() ?? 'hours';
        }
      }
      for (final entry in machines.values) {
        entry['odometer_unit'] = odometerMap[entry['id'] as String] ?? 'hours';
      }
    }

    return {
      'irregular_machines': irregulars,
      'total_machines': machines.length,
      'irregular_count': irregulars.length,
    };
  }

  Future<Map<String, dynamic>> getPortfolioSummary() async {
    final projectsResult = await _supabase
        .from('projects')
        .select('id, title, status')
        .in_('status', ['active', 'on_hold', 'completed']);

    final projects = List<Map<String, dynamic>>.from(projectsResult ?? []);

    double totalPlannedCost = 0;
    double totalActualCost = 0;
    double totalEarnedValue = 0;
    double totalPlannedUnits = 0;
    double totalActualUnits = 0;
    int totalAlerts = 0;
    int projectsAtRisk = 0;
    int completedServices = 0;
    int totalServices = 0;

    final List<Map<String, dynamic>> projectSummaries = [];

    for (final p in projects) {
      final projectId = p['id'] as String;
      final measurement = await getProjectMeasurement(projectId);
      if (measurement.containsKey('error')) continue;

      final plannedCost = (measurement['total_planned_cost'] as num?)?.toDouble() ?? 0;
      final actualCost = (measurement['total_actual_cost'] as num?)?.toDouble() ?? 0;
      final ev = (measurement['total_earned_value'] as num?)?.toDouble() ?? 0;
      final plannedUnits = (measurement['total_planned_units'] as num?)?.toDouble() ?? 0;
      final actualUnits = (measurement['total_actual_units'] as num?)?.toDouble() ?? 0;
      final cpi = (measurement['cpi'] as num?)?.toDouble() ?? 1;
      final spi = (measurement['spi'] as num?)?.toDouble() ?? 1;
      final progress = (measurement['overall_progress'] as num?)?.toDouble() ?? 0;
      final alerts = List<Map<String, dynamic>>.from(measurement['alerts'] ?? []);
      final services = List<Map<String, dynamic>>.from(measurement['services'] ?? []);

      totalPlannedCost += plannedCost;
      totalActualCost += actualCost;
      totalEarnedValue += ev;
      totalPlannedUnits += plannedUnits;
      totalActualUnits += actualUnits;
      totalAlerts += alerts.length;

      int svcCompleted = 0;
      for (final s in services) {
        if (((s['progress'] as num?)?.toDouble() ?? 0) >= 100) svcCompleted++;
      }
      completedServices += svcCompleted;
      totalServices += services.length;

      if (cpi < 0.95 || spi < 0.9) projectsAtRisk++;

      projectSummaries.add({
        'project_id': projectId,
        'project_name': p['title'] ?? '',
        'status': p['status'] ?? '',
        'progress': progress,
        'cpi': cpi,
        'spi': spi,
        'planned_cost': plannedCost,
        'actual_cost': actualCost,
        'earned_value': ev,
        'alerts_count': alerts.length,
        'completed_services': svcCompleted,
        'total_services': services.length,
      });
    }

    final portfolioCPI = computeCPI(totalEarnedValue, totalActualCost);
    final portfolioProgress = totalPlannedUnits > 0
        ? (totalActualUnits / totalPlannedUnits * 100).clamp(0.0, 100.0)
        : 0.0;

    return {
      'total_planned_cost': totalPlannedCost,
      'total_actual_cost': totalActualCost,
      'total_earned_value': totalEarnedValue,
      'portfolio_cpi': portfolioCPI,
      'portfolio_progress': portfolioProgress,
      'total_alerts': totalAlerts,
      'projects_at_risk': projectsAtRisk,
      'total_projects': projects.length,
      'completed_services': completedServices,
      'total_services': totalServices,
      'project_summaries': projectSummaries,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchMachineryLogs(
    String projectId,
    Map<String, String> serviceUnits,
  ) async {
    final result = await _supabase
        .from('report_machinery_logs')
        .select('''
          production_value, total_hours, fuel_added,
          machinery!inner(capacity_yards),
          project_machinery!inner(quote_service_id, project_id, id),
          daily_reports!inner(status)
        ''')
        .eq('project_machinery.project_id', projectId)
        .in_('daily_reports.status', ['submitted', 'approved']);
    return List<Map<String, dynamic>>.from(result ?? []);
  }

  Future<List<Map<String, dynamic>>> _fetchLaborLogs(String projectId) async {
    final result = await _supabase
        .from('report_labor_logs')
        .select('''
          regular_hours, overtime_hours,
          project_labor!inner(quote_service_id, project_id),
          daily_reports!inner(status),
          workers!inner(role_id, labor_roles!inner(hourly_rate))
        ''')
        .eq('project_labor.project_id', projectId)
        .in_('daily_reports.status', ['submitted', 'approved']);
    return List<Map<String, dynamic>>.from(result ?? []);
  }

  Future<List<Map<String, dynamic>>> _fetchMaterialLogs(String projectId) async {
    final result = await _supabase
        .from('report_material_usage')
        .select('''
          quantity_used,
          project_materials!inner(quote_service_id, project_id, id),
          daily_reports!inner(status)
        ''')
        .eq('project_materials.project_id', projectId)
        .in_('daily_reports.status', ['submitted', 'approved']);
    return List<Map<String, dynamic>>.from(result ?? []);
  }

  Future<Map<String, Map<String, dynamic>>> _fetchMachineryCostMap(String projectId) async {
    final rows = await _supabase
        .from('project_machinery')
        .select('id, quote_service_machineries(monthly_rent_cost, gallons_per_hour, gallon_cost)')
        .eq('project_id', projectId);
    final Map<String, Map<String, dynamic>> map = {};
    for (final row in rows ?? []) {
      final pmId = row['id']?.toString();
      if (pmId != null) {
        final qsm = row['quote_service_machineries'];
        if (qsm is Map<String, dynamic>) {
          map[pmId] = {
            'monthly_rent_cost': (qsm['monthly_rent_cost'] as num?)?.toDouble() ?? 0,
            'gallon_cost': (qsm['gallon_cost'] as num?)?.toDouble() ?? 0,
          };
        }
      }
    }
    return map;
  }

  Future<Map<String, double>> _fetchMaterialPriceMap(String projectId) async {
    final rows = await _supabase
        .from('project_materials')
        .select('id, quote_service_materials(unit_price)')
        .eq('project_id', projectId);
    final Map<String, double> map = {};
    for (final row in rows ?? []) {
      final pmId = row['id']?.toString();
      if (pmId != null) {
        final qsm = row['quote_service_materials'];
        if (qsm is Map<String, dynamic>) {
          map[pmId] = (qsm['unit_price'] as num?)?.toDouble() ?? 0;
        }
      }
    }
    return map;
  }

  Future<double> _computeElapsedDays(Map<String, dynamic>? project, String projectId) async {
    final start = DateTime.tryParse(project?['start_date']?.toString() ?? '');
    if (start == null) return 0;
    final reportService = DailyReportService(_supabase);
    return await reportService.getEffectiveElapsedDays(projectId, start, DateTime.now());
  }

  Future<Map<String, double>> _fetchEquipmentCosts(
    List<String> serviceIds,
    double elapsedDays,
  ) async {
    final Map<String, double> costs = {};
    if (serviceIds.isEmpty) return costs;

    final rows = await _supabase
        .from('quote_service_instruments')
        .select('quote_service_id, total_cost, days')
        .in_('quote_service_id', serviceIds);
    for (final row in rows ?? []) {
      final qsId = row['quote_service_id']?.toString();
      if (qsId == null) continue;
      final totalCost = (row['total_cost'] as num?)?.toDouble() ?? 0;
      final instrumentDays = (row['days'] as num?)?.toDouble() ?? 1;
      costs[qsId] = (costs[qsId] ?? 0) +
          computeProratedEquipmentCost(
            totalCost: totalCost,
            instrumentDays: instrumentDays,
            elapsedDays: elapsedDays,
          );
    }
    return costs;
  }
}
