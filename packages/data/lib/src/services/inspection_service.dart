import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../remote/supabase_client.dart';

part 'inspection_service.g.dart';

@riverpod
InspectionService inspectionService(InspectionServiceRef ref) {
  return InspectionService(ref.watch(supabaseClientProvider));
}

class InspectionService {
  final SupabaseClient _supabase;

  InspectionService(this._supabase);

  // ── Weekly Inspections CRUD ──

  Future<List<Map<String, dynamic>>> getInspectionsByProject(String projectId) async {
    final response = await _supabase
        .from('weekly_inspections')
        .select('*, profiles!inspector_id(name)')
        .eq('project_id', projectId)
        .order('inspection_date', ascending: false);
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<Map<String, dynamic>> getInspectionById(String id) async {
    final response = await _supabase
        .from('weekly_inspections')
        .select('*, profiles!inspector_id(name)')
        .eq('id', id)
        .single();
    return response;
  }

  Future<Map<String, dynamic>> createInspection(Map<String, dynamic> data) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    data['inspector_id'] = data['inspector_id'] ?? currentUserId;
    final response = await _supabase
        .from('weekly_inspections')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateInspection(String id, Map<String, dynamic> data) async {
    await _supabase.from('weekly_inspections').update(data).eq('id', id);
  }

  Future<void> deleteInspection(String id) async {
    await _supabase.from('weekly_inspections').delete().eq('id', id);
  }

  Future<void> submitInspection(String id) async {
    await _supabase.from('weekly_inspections').update({
      'status': 'submitted',
    }).eq('id', id);
  }

  Future<void> approveInspection(String id) async {
    await _supabase.from('weekly_inspections').update({
      'status': 'approved',
    }).eq('id', id);
  }

  // ── Inspection Details ──

  Future<List<Map<String, dynamic>>> getInspectionDetails(String inspectionId) async {
    final response = await _supabase
        .from('weekly_inspection_details')
        .select('*, quote_services(name, unit_of_measure)')
        .eq('inspection_id', inspectionId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<Map<String, dynamic>> addInspectionDetail(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('weekly_inspection_details')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateInspectionDetail(String id, Map<String, dynamic> data) async {
    await _supabase.from('weekly_inspection_details').update(data).eq('id', id);
  }

  Future<void> deleteInspectionDetail(String id) async {
    await _supabase.from('weekly_inspection_details').delete().eq('id', id);
  }

  // ── Project Service Info (for inspection form) ──

  Future<List<Map<String, dynamic>>> getProjectServicesForInspection(String projectId) async {
    final project = await _supabase
        .from('projects')
        .select('quote_id')
        .eq('id', projectId)
        .maybeSingle();
    final quoteId = project?['quote_id'];
    if (quoteId == null) return [];

    final response = await _supabase
        .from('quote_services')
        .select('id, name, quantity, unit_of_measure')
        .eq('quote_id', quoteId)
        .order('service_number');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  // ── Thresholds ──

  Future<Map<String, double>> getAllThresholds() async {
    final response = await _supabase
        .from('service_inspection_thresholds')
        .select('service_id, threshold_percentage');
    final result = <String, double>{};
    for (final row in response ?? []) {
      result[row['service_id'].toString()] =
          (row['threshold_percentage'] as num?)?.toDouble() ?? 5.0;
    }
    return result;
  }

  Future<double> getThresholdForService(String serviceId) async {
    final response = await _supabase
        .from('service_inspection_thresholds')
        .select('threshold_percentage')
        .eq('service_id', serviceId)
        .maybeSingle();
    return (response?['threshold_percentage'] as num?)?.toDouble() ?? 5.0;
  }

  Future<void> upsertServiceThreshold(String serviceId, double threshold) async {
    await _supabase.from('service_inspection_thresholds').upsert({
      'service_id': serviceId,
      'threshold_percentage': threshold,
    });
  }

  // ── Comparison Logic ──

  Future<List<Map<String, dynamic>>> runComparison(String inspectionId) async {
    final details = await getInspectionDetails(inspectionId);
    final inspection = await getInspectionById(inspectionId);
    final inspectionDate = inspection['inspection_date'] as String;
    final projectId = inspection['project_id'] as String;

    final thresholds = await getAllThresholds();

    final results = <Map<String, dynamic>>[];

    for (final detail in details) {
      final quoteServiceId = detail['quote_service_id'] as String;
      final measuredQuantity =
          (detail['measured_quantity'] as num?)?.toDouble() ?? 0;
      final totalPlanned =
          (detail['total_planned_quantity'] as num?)?.toDouble() ?? 0;

      final accumulatedQty = await _accumulateDailyProgress(
          projectId, quoteServiceId, inspectionDate);

      final deviationAbs = (accumulatedQty - measuredQuantity).abs();
      final deviationPct =
          totalPlanned > 0 ? (deviationAbs / totalPlanned) * 100 : 0;

      final catalogServiceId = await _getCatalogServiceId(quoteServiceId);
      final threshold =
          catalogServiceId != null && thresholds.containsKey(catalogServiceId)
              ? thresholds[catalogServiceId]!
              : 5.0;

      final exceeds = deviationPct > threshold;

      // Find period start (first daily report for this service or project start)
      var periodStart = await _getFirstReportDate(projectId, quoteServiceId);
      if (periodStart == null) {
        final project = await _supabase
            .from('projects')
            .select('start_date')
            .eq('id', projectId)
            .maybeSingle();
        periodStart = project?['start_date']?.toString()?.split('T')[0];
      }

      // Delete existing comparison for this detail if any
      await _supabase
          .from('progress_comparisons')
          .delete()
          .eq('inspection_detail_id', detail['id']);

      final status = exceeds ? 'exceeds_threshold' : 'comparison_done';

      final comparison = await _supabase
          .from('progress_comparisons')
          .insert({
            'inspection_id': inspectionId,
            'inspection_detail_id': detail['id'],
            'quote_service_id': quoteServiceId,
            'period_start': periodStart,
            'period_end': inspectionDate,
            'accumulated_daily_quantity': accumulatedQty,
            'inspection_measured_quantity': measuredQuantity,
            'deviation_absolute': deviationAbs,
            'deviation_percentage': deviationPct,
            'threshold_configured': threshold,
            'exceeds_threshold': exceeds,
            'status': status,
          })
          .select()
          .single();

      results.add(comparison);
    }

    return results;
  }

  Future<double> _accumulateDailyProgress(
      String projectId, String quoteServiceId, String upToDate) async {
    double total = 0;

    // Machinery production logs
    final machResult = await _supabase
        .from('report_machinery_logs')
        .select('production_value, daily_reports!inner(report_date, status), project_machinery!inner(project_id, quote_service_id)')
        .eq('project_machinery.project_id', projectId)
        .eq('project_machinery.quote_service_id', quoteServiceId)
        .lte('daily_reports.report_date', upToDate)
        .in_('daily_reports.status', ['submitted', 'approved']);
    for (final log in machResult ?? []) {
      total += (log['production_value'] as num?)?.toDouble() ?? 0;
    }

    // Material usage
    final matResult = await _supabase
        .from('report_material_usage')
        .select('quantity_used, daily_reports!inner(report_date, status), project_materials!inner(project_id, quote_service_id)')
        .eq('project_materials.project_id', projectId)
        .eq('project_materials.quote_service_id', quoteServiceId)
        .lte('daily_reports.report_date', upToDate)
        .in_('daily_reports.status', ['submitted', 'approved']);
    for (final log in matResult ?? []) {
      total += (log['quantity_used'] as num?)?.toDouble() ?? 0;
    }

    return total;
  }

  Future<String?> _getFirstReportDate(
      String projectId, String quoteServiceId) async {
    final results = await _supabase
        .from('report_machinery_logs')
        .select('daily_reports!inner(report_date), project_machinery!inner(project_id, quote_service_id)')
        .eq('project_machinery.project_id', projectId)
        .eq('project_machinery.quote_service_id', quoteServiceId);

    final sorted = (results ?? []).cast<Map<String, dynamic>>();
    sorted.sort((a, b) {
      final dateA = (a['daily_reports'] as Map?)?['report_date']?.toString() ?? '';
      final dateB = (b['daily_reports'] as Map?)?['report_date']?.toString() ?? '';
      return dateA.compareTo(dateB);
    });

    final first = sorted.isNotEmpty ? sorted.first : null;
    return (first?['daily_reports'] as Map?)?['report_date']?.toString();
  }

  Future<String?> _getCatalogServiceId(String quoteServiceId) async {
    final result = await _supabase
        .from('quote_services')
        .select('name')
        .eq('id', quoteServiceId)
        .maybeSingle();
    final serviceName = result?['name'];
    if (serviceName == null) return null;
    final catalogResult = await _supabase
        .from('services')
        .select('id')
        .eq('description', serviceName)
        .maybeSingle();
    return catalogResult?['id']?.toString();
  }

  // ── Comparison Queries ──

  Future<List<Map<String, dynamic>>> getComparisonsByInspection(
      String inspectionId) async {
    final response = await _supabase
        .from('progress_comparisons')
        .select(
            '*, quote_services(name, unit_of_measure), weekly_inspection_details(measured_quantity, total_planned_quantity, percentage_completion)')
        .eq('inspection_id', inspectionId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<List<Map<String, dynamic>>> getComparisonsByProject(
      String projectId) async {
    final response = await _supabase
        .from('progress_comparisons')
        .select(
            '*, quote_services(name, unit_of_measure), weekly_inspections!inner(inspection_date, project_id)')
        .eq('weekly_inspections.project_id', projectId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<List<Map<String, dynamic>>> getPendingReconciliations() async {
    final response = await _supabase
        .from('progress_comparisons')
        .select(
            '*, quote_services(name, unit_of_measure), weekly_inspections!inner(inspection_date, project_id, projects!inner(title))')
        .in_('status', ['exceeds_threshold', 'pending_approval'])
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  // ── Daily Log Detail for Reconciliation ──

  Future<List<Map<String, dynamic>>> getDailyReportLogsForPeriod(
      String projectId, String quoteServiceId, String startDate, String endDate) async {
    final result = await _supabase
        .from('daily_reports')
        .select('id, report_date, status')
        .eq('project_id', projectId)
        .gte('report_date', startDate)
        .lte('report_date', endDate)
        .order('report_date');

    final reports = List<Map<String, dynamic>>.from(result ?? []);

    final enriched = <Map<String, dynamic>>[];
    for (final report in reports) {
      final reportId = report['id'] as String;

      final machLogs = await _supabase
          .from('report_machinery_logs')
          .select(
              'id, production_value, production_unit, total_hours, machinery!inner(description), project_machinery!inner(machinery_name)')
          .eq('daily_report_id', reportId)
          .eq('project_machinery.quote_service_id', quoteServiceId);

      final matUsage = await _supabase
          .from('report_material_usage')
          .select(
              'id, quantity_used, area_installed, unit, materials!inner(description), project_materials!inner(material_name)')
          .eq('daily_report_id', reportId)
          .eq('project_materials.quote_service_id', quoteServiceId);

      enriched.add({
        'report_id': reportId,
        'report_date': report['report_date'],
        'status': report['status'],
        'machinery_logs':
            List<Map<String, dynamic>>.from(machLogs ?? []),
        'material_usage':
            List<Map<String, dynamic>>.from(matUsage ?? []),
      });
    }

    return enriched;
  }

  // ── Reconciliation & Adjustments ──

  Future<void> proposeAdjustments(
      String comparisonId, List<Map<String, dynamic>> adjustments, String notes) async {
    final currentUserId = _supabase.auth.currentUser?.id;

    // Save each proposed adjustment
    for (final adj in adjustments) {
      await _supabase.from('progress_adjustments').insert({
        'comparison_id': comparisonId,
        'daily_report_id': adj['daily_report_id'],
        'resource_type': adj['resource_type'],
        'log_id': adj['log_id'],
        'field_name': adj['field_name'] ?? 'production_value',
        'original_value': adj['original_value'],
        'adjusted_value': adj['adjusted_value'],
        'adjustment_reason': adj['adjustment_reason'],
        'adjusted_by': currentUserId,
      });
    }

    // Update comparison status
    await _supabase.from('progress_comparisons').update({
      'status': 'pending_approval',
      'reconciliation_notes': notes,
      'proposed_by': currentUserId,
      'proposed_at': DateTime.now().toIso8601String(),
    }).eq('id', comparisonId);
  }

  Future<void> approveReconciliation(String comparisonId) async {
    final currentUserId = _supabase.auth.currentUser?.id;

    final adjustments = await _supabase
        .from('progress_adjustments')
        .select()
        .eq('comparison_id', comparisonId);

    // Apply adjustments to actual log tables
    for (final adj in adjustments ?? []) {
      final resourceType = adj['resource_type'] as String;
      final logId = adj['log_id'] as String;
      final fieldName = adj['field_name'] as String? ?? 'production_value';
      final adjustedValue = (adj['adjusted_value'] as num).toDouble();

      final table = resourceType == 'machinery'
          ? 'report_machinery_logs'
          : resourceType == 'material'
              ? 'report_material_usage'
              : 'report_labor_logs';

      await _supabase.from(table).update({
        fieldName: adjustedValue,
      }).eq('id', logId);
    }

    // Mark comparison as reconciled
    await _supabase.from('progress_comparisons').update({
      'status': 'reconciled',
      'approved_by': currentUserId,
      'approved_at': DateTime.now().toIso8601String(),
    }).eq('id', comparisonId);

    // Mark inspection as reconciled if all comparisons are reconciled
    final comparison = await _supabase
        .from('progress_comparisons')
        .select('inspection_id')
        .eq('id', comparisonId)
        .maybeSingle();
    if (comparison != null) {
      final pendingCount = await _supabase
          .from('progress_comparisons')
          .select('id')
          .eq('inspection_id', comparison['inspection_id'])
          .neq('status', 'reconciled');
      if ((pendingCount ?? []).isEmpty) {
        await _supabase.from('weekly_inspections').update({
          'status': 'reconciled',
        }).eq('id', comparison['inspection_id']);
      }
    }
  }

  Future<void> rejectReconciliation(String comparisonId, String reason) async {
    final currentNotes = await _supabase
        .from('progress_comparisons')
        .select('reconciliation_notes')
        .eq('id', comparisonId)
        .maybeSingle();

    final existing = currentNotes?['reconciliation_notes'] as String? ?? '';
    final updatedNotes =
        existing.isNotEmpty ? '$existing\n\nRejected: $reason' : 'Rejected: $reason';

    await _supabase.from('progress_comparisons').update({
      'status': 'exceeds_threshold',
      'reconciliation_notes': updatedNotes,
    }).eq('id', comparisonId);

    // Remove proposed adjustments
    await _supabase
        .from('progress_adjustments')
        .delete()
        .eq('comparison_id', comparisonId);
  }

  Future<List<Map<String, dynamic>>> getAdjustmentsForComparison(
      String comparisonId) async {
    final response = await _supabase
        .from('progress_adjustments')
        .select('*, daily_reports(report_date)')
        .eq('comparison_id', comparisonId)
        .order('adjusted_at');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  // ── Dashboard stats ──

  Future<Map<String, dynamic>> getInspectionDashboardStats() async {
    final pendingApproval = await _supabase
        .from('progress_comparisons')
        .select('id')
        .eq('status', 'pending_approval');

    final exceedsThreshold = await _supabase
        .from('progress_comparisons')
        .select('id')
        .eq('status', 'exceeds_threshold');

    return {
      'pending_approval_count': (pendingApproval ?? []).length,
      'exceeds_threshold_count': (exceedsThreshold ?? []).length,
    };
  }
}
