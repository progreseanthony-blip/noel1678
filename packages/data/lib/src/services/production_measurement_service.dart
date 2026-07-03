import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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

    // Planned quantities per service
    List<Map<String, dynamic>> plannedServices = [];
    if (quoteId != null) {
      final qsResult = await _supabase
          .from('quote_services')
          .select('id, name, quantity, unit_of_measure, direct_cost')
          .eq('quote_id', quoteId);
      plannedServices = List<Map<String, dynamic>>.from(qsResult ?? []);
    }

    final serviceUnits = {for (final s in plannedServices) s['id'].toString(): (s['unit_of_measure'] as String?)?.toLowerCase() ?? ''};

    // Actual production per service from machinery logs
    final machResult = await _supabase
        .from('report_machinery_logs')
        .select('''
          production_value, total_hours,
          machinery!inner(capacity_yards),
          project_machinery!inner(quote_service_id, project_id),
          daily_reports!inner(status)
        ''')
        .eq('project_machinery.project_id', projectId)
        .in_('daily_reports.status', ['submitted', 'approved']);
    final machLogs = List<Map<String, dynamic>>.from(machResult ?? []);

    // Actual labor hours per service with real rates
    final laborResult = await _supabase
        .from('report_labor_logs')
        .select('''
          regular_hours, overtime_hours,
          project_labor!inner(quote_service_id, project_id),
          daily_reports!inner(status),
          workers!inner(role_id, labor_roles!inner(hourly_rate))
        ''')
        .eq('project_labor.project_id', projectId)
        .in_('daily_reports.status', ['submitted', 'approved']);
    final laborLogs = List<Map<String, dynamic>>.from(laborResult ?? []);

    // Actual material usage per service
    final matResult = await _supabase
        .from('report_material_usage')
        .select('''
          quantity_used,
          project_materials!inner(quote_service_id, project_id),
          daily_reports!inner(status)
        ''')
        .eq('project_materials.project_id', projectId)
        .in_('daily_reports.status', ['submitted', 'approved']);
    final matLogs = List<Map<String, dynamic>>.from(matResult ?? []);

    // Machinery cost rates per project_machinery
    final machCostRows = await _supabase
        .from('project_machinery')
        .select('id, quote_service_machineries(monthly_rent_cost, gallons_per_hour, gallon_cost)')
        .eq('project_id', projectId);
    final Map<String, Map<String, dynamic>> machCostMap = {};
    for (final row in machCostRows ?? []) {
      final pmId = row['id']?.toString();
      if (pmId != null) {
        final qsm = row['quote_service_machineries'];
        if (qsm is Map<String, dynamic>) {
          machCostMap[pmId] = {
            'monthly_rent_cost': (qsm['monthly_rent_cost'] as num?)?.toDouble() ?? 0,
            'gallons_per_hour': (qsm['gallons_per_hour'] as num?)?.toDouble() ?? 0,
            'gallon_cost': (qsm['gallon_cost'] as num?)?.toDouble() ?? 0,
          };
        }
      }
    }

    // Aggregate actual by quote_service_id
    final Map<String, double> actualProduction = {};
    final Map<String, double> actualMachHours = {};
    final Map<String, double> actualLaborHours = {};
    final Map<String, double> actualLaborCost = {};
    final Map<String, double> actualMachCost = {};
    final Map<String, double> actualMaterialUsed = {};

    for (final log in machLogs) {
      final qsId = log['project_machinery']?['quote_service_id']?.toString();
      if (qsId == null) continue;
      final cap = (log['machinery']?['capacity_yards'] as num?)?.toDouble() ?? 0;
      final prod = (log['production_value'] as num?)?.toDouble() ?? 0;
      final hrs = (log['total_hours'] as num?)?.toDouble() ?? 0;
      final unit = serviceUnits[qsId] ?? '';
      final isVolumeUnit = unit == 'cy' || unit == 'ft2' || unit == 'sqft' || unit == 'sf';
      actualProduction[qsId] = (actualProduction[qsId] ?? 0) + (isVolumeUnit && cap > 0 ? prod * cap : prod);
      actualMachHours[qsId] = (actualMachHours[qsId] ?? 0) + hrs;

      final pmId = log['project_machinery_id']?.toString();
      final costInfo = pmId != null ? machCostMap[pmId] : null;
      if (costInfo != null) {
        final monthlyRent = costInfo['monthly_rent_cost'] as double;
        final gallonCost = costInfo['gallon_cost'] as double;
        final fuelAdded = (log['fuel_added'] as num?)?.toDouble() ?? 0;
        final rentCost = monthlyRent > 0 ? (hrs / 8) * (monthlyRent / 30) : 0;
        final fuelCost = fuelAdded * gallonCost;
        actualMachCost[qsId] = (actualMachCost[qsId] ?? 0) + rentCost + fuelCost;
      }
    }

    for (final log in laborLogs) {
      final qsId = log['project_labor']?['quote_service_id']?.toString();
      if (qsId == null) continue;
      final regHrs = (log['regular_hours'] as num?)?.toDouble() ?? 0;
      final otHrs = (log['overtime_hours'] as num?)?.toDouble() ?? 0;
      final hrs = regHrs + otHrs;
      actualLaborHours[qsId] = (actualLaborHours[qsId] ?? 0) + hrs;

      final rate = (log['workers']?['labor_roles']?['hourly_rate'] as num?)?.toDouble() ?? 0;
      final cost = regHrs * rate + otHrs * rate * 1.5;
      actualLaborCost[qsId] = (actualLaborCost[qsId] ?? 0) + cost;
    }

    for (final log in matLogs) {
      final qsId = log['project_materials']?['quote_service_id']?.toString();
      if (qsId == null) continue;
      final qty = (log['quantity_used'] as num?)?.toDouble() ?? 0;
      actualMaterialUsed[qsId] = (actualMaterialUsed[qsId] ?? 0) + qty;
    }

    // Build service measurements
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
      final progress = plannedQty > 0 ? (actualProd / plannedQty * 100) : 0.0;
      final unitCost = plannedQty > 0 ? directCost / plannedQty : 0;
      final ev = actualProd * unitCost;
      final machHrs = actualMachHours[qsId] ?? 0;
      final laborHrs = actualLaborHours[qsId] ?? 0;
      final actualCost = (actualLaborCost[qsId] ?? 0) + (actualMachCost[qsId] ?? 0);

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
        'performance': (machHrs + laborHrs) > 0
            ? actualProd / (machHrs + laborHrs)
            : 0.0,
        'performance_unit': '${ps['unit_of_measure']}/hr',
      });

      if (directCost > 0 && ev > 0 && actualCost > 0) {
        final cpi = ev / actualCost;
        if (cpi < 0.95) {
          alerts.add({
            'type': 'cost',
            'severity': 'warning',
            'message': '${ps['name']}: CPI=${cpi.toStringAsFixed(2)} below threshold',
            'value': cpi,
          });
        }
      }
      if (plannedQty > 0 && progress < 50) {
        alerts.add({
          'type': 'schedule',
          'severity': progress < 10 ? 'critical' : 'warning',
          'message': '${ps['name']}: Only ${progress.toStringAsFixed(1)}% complete',
          'value': progress,
        });
      }
    }

    // Compute total actual cost
    double totalActualCost = 0;
    for (final s in services) {
      totalActualCost += (s['actual_cost'] as num).toDouble();
    }

    // Overall EVM
    final overallProgress = totalPlannedUnits > 0
        ? (totalActualUnits / totalPlannedUnits * 100)
        : 0.0;
    final cpi = totalActualCost > 0 ? totalEarnedValue / totalActualCost : 1.0;
    final eac = cpi > 0 ? totalPlannedCost / cpi : totalPlannedCost;

    // SPI based on effective days (excluding non-working days)
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
          spi = pv > 0 ? totalEarnedValue / pv : 1.0;
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
}
