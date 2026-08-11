import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../remote/supabase_client.dart';

part 'billing_service.g.dart';

@riverpod
BillingService billingService(BillingServiceRef ref) {
  return BillingService(ref.watch(supabaseClientProvider));
}

class BillingService {
  final SupabaseClient _supabase;

  BillingService(this._supabase);

  // ── Pay Application Data ──

  Future<Map<String, dynamic>> getPayApplicationData({
    required String projectId,
    required String periodStart,
    required String periodEnd,
    String? excludeInvoiceId,
  }) async {
    final rpc = await _supabase.rpc(
      'get_pay_application_data',
      params: {
        'p_project_id': projectId,
        'p_period_start': periodStart,
        'p_period_end': periodEnd,
        if (excludeInvoiceId != null) 'p_exclude_inv_id': excludeInvoiceId,
      },
    );
    return rpc as Map<String, dynamic>;
  }

  // ── Invoices ──

  Future<List<Map<String, dynamic>>> getInvoices(String projectId) async {
    final response = await _supabase
        .from('invoices')
        .select()
        .eq('project_id', projectId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<Map<String, dynamic>> getInvoice(String id) async {
    final invoice = await _supabase
        .from('invoices')
        .select()
        .eq('id', id)
        .single();

    final details = await _supabase
        .from('invoice_details')
        .select()
        .eq('invoice_id', id)
        .order('sort_order');

    final cos = await _supabase
        .from('invoice_change_order_links')
        .select('change_orders(*)')
        .eq('invoice_id', id);

    final data = Map<String, dynamic>.from(invoice);
    data['details'] = List<Map<String, dynamic>>.from(details ?? []);
    data['change_orders'] = List<Map<String, dynamic>>.from(cos ?? []);
    return data;
  }

  Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('invoices')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateInvoice(String id, Map<String, dynamic> data) async {
    await _supabase.from('invoices').update(data).eq('id', id);
  }

  Future<void> updateInvoiceStatus(String id, String status) async {
    await _supabase.from('invoices').update({'status': status}).eq('id', id);
  }

  Future<void> deleteInvoice(String id) async {
    await _supabase.from('invoices').delete().eq('id', id);
  }

  // ── Invoice Details ──

  Future<List<Map<String, dynamic>>> getInvoiceDetails(String invoiceId) async {
    final response = await _supabase
        .from('invoice_details')
        .select()
        .eq('invoice_id', invoiceId)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<void> saveInvoiceDetails(
    String invoiceId,
    List<Map<String, dynamic>> details,
  ) async {
    // Delete existing details and re-insert
    await _supabase
        .from('invoice_details')
        .delete()
        .eq('invoice_id', invoiceId);

    if (details.isEmpty) return;

    final batch = details.map((d) {
      d['invoice_id'] = invoiceId;
      return d;
    }).toList();

    await _supabase.from('invoice_details').insert(batch);
  }

  // ── Change Orders ──

  Future<List<Map<String, dynamic>>> getChangeOrders(String projectId) async {
    final response = await _supabase
        .from('change_orders')
        .select()
        .eq('project_id', projectId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<Map<String, dynamic>> getChangeOrder(String id) async {
    final co = await _supabase
        .from('change_orders')
        .select()
        .eq('id', id)
        .single();

    final details = await _supabase
        .from('change_order_details')
        .select()
        .eq('change_order_id', id);

    final data = Map<String, dynamic>.from(co);

    // Load resource plans for each detail
    final detailList = List<Map<String, dynamic>>.from(details ?? []);
    for (final d in detailList) {
      final plans = await _supabase
          .from('change_order_resource_plans')
          .select()
          .eq('change_order_detail_id', d['id']);
      d['resource_plans'] = plans ?? [];
    }

    data['details'] = detailList;
    return data;
  }

  Future<List<Map<String, dynamic>>> getChangeOrderDetails(String coId) async {
    final response = await _supabase
        .from('change_order_details')
        .select()
        .eq('change_order_id', coId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<Map<String, dynamic>> createChangeOrder(
    Map<String, dynamic> data,
  ) async {
    final response = await _supabase
        .from('change_orders')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateChangeOrder(String id, Map<String, dynamic> data) async {
    await _supabase.from('change_orders').update(data).eq('id', id);
  }

  Future<void> approveChangeOrder(String id, String approvedBy) async {
    await _supabase
        .from('change_orders')
        .update({
          'status': 'approved',
          'approved_by': approvedBy,
          'approved_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> rejectChangeOrder(String id, String reason) async {
    await _supabase
        .from('change_orders')
        .update({
          'status': 'rejected',
          'rejected_at': DateTime.now().toUtc().toIso8601String(),
          'rejection_reason': reason,
        })
        .eq('id', id);
  }

  Future<void> deleteChangeOrder(String id) async {
    await _supabase.from('change_orders').delete().eq('id', id);
  }

  // ── Change Order Details ──

  Future<List<Map<String, dynamic>>> saveChangeOrderDetails(
    String changeOrderId,
    List<Map<String, dynamic>> details,
  ) async {
    await _supabase
        .from('change_order_details')
        .delete()
        .eq('change_order_id', changeOrderId);

    if (details.isEmpty) return [];

    final knownColumns = {
      'change_order_id',
      'line_type',
      'quote_service_id',
      'project_service_id',
      'catalog_service_id',
      'effective_date',
      'service_name',
      'unit_of_measure',
      'quantity_change',
      'unit_price',
      'standby_hours',
      'standby_rate',
      'material_id',
      'quantity_lost',
      'replacement_unit_cost',
      'disruption_reason_id',
      'estimation_metadata',
    };

    final batch = details.map((d) {
      d['change_order_id'] = changeOrderId;
      return Map<String, dynamic>.fromEntries(
        d.entries.where((e) => knownColumns.contains(e.key)),
      );
    }).toList();

    final response = await _supabase
        .from('change_order_details')
        .insert(batch)
        .select();
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  // ── Invoice ↔ Change Order Links ──

  Future<void> linkChangeOrderToInvoice(
    String invoiceId,
    String changeOrderId,
  ) async {
    await _supabase.from('invoice_change_order_links').insert({
      'invoice_id': invoiceId,
      'change_order_id': changeOrderId,
    });
  }

  Future<void> unlinkChangeOrder(String invoiceId, String changeOrderId) async {
    await _supabase
        .from('invoice_change_order_links')
        .delete()
        .eq('invoice_id', invoiceId)
        .eq('change_order_id', changeOrderId);
  }

  // ── Quote Services (for CO line item selection) ──

  Future<List<Map<String, dynamic>>> getQuoteServicesForProject(
    String projectId,
  ) async {
    final project = await _supabase
        .from('projects')
        .select('quote_id')
        .eq('id', projectId)
        .single();

    final quoteId = project['quote_id'] as String?;

    final List<Map<String, dynamic>> results = [];

    if (quoteId != null) {
      final qsResult = await _supabase
          .from('quote_services')
          .select()
          .eq('quote_id', quoteId)
          .order('created_at');
      results.addAll(List<Map<String, dynamic>>.from(qsResult ?? []));
    }

    final psResult = await _supabase
        .from('project_services')
        .select('id, name, unit_of_measure, quantity, direct_cost, target_price, source_co_id, quote_service_id, created_at, project_id')
        .eq('project_id', projectId)
        .order('created_at');
    for (final ps in psResult ?? []) {
      ps['is_project_service'] = true;
      results.add(Map<String, dynamic>.from(ps));
    }

    return results;
  }

  // ── Disruption Services (CO ↔ Project Tasks) ──

  Future<List<Map<String, dynamic>>> getDisruptionServices(
    String changeOrderId,
  ) async {
    final response = await _supabase
        .from('change_order_disruption_services')
        .select('*, project_tasks(id, name, status)')
        .eq('change_order_id', changeOrderId);
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<List<Map<String, dynamic>>> getProjectTasksForDisruption(
    String projectId,
  ) async {
    try {
      final coServices = await _supabase
          .from('project_services')
          .select('id, name, quote_service_id')
          .eq('project_id', projectId)
          .filter('source_co_id', 'not.is', 'null');

      final existingTasks = await _supabase
          .from('project_tasks')
          .select('quote_service_id, project_service_id')
          .eq('project_id', projectId);
      final existingQsIds = (existingTasks ?? [])
          .map((t) => t['quote_service_id']?.toString())
          .where((id) => id != null)
          .toSet();
      final existingPsIds = (existingTasks ?? [])
          .map((t) => t['project_service_id']?.toString())
          .where((id) => id != null)
          .toSet();

      for (final ps in coServices ?? []) {
        final psId = ps['id']?.toString();
        final qsId = ps['quote_service_id']?.toString();

        if (psId != null && !existingPsIds.contains(psId)) {
          await _supabase.from('project_tasks').insert({
            'project_id': projectId,
            'quote_service_id': qsId,
            'project_service_id': psId,
            'name': ps['name'] ?? 'CO Service',
            'status': 'pending',
          });
        } else if (qsId != null && !existingQsIds.contains(qsId)) {
          await _supabase.from('project_tasks').insert({
            'project_id': projectId,
            'quote_service_id': qsId,
            'name': ps['name'] ?? 'CO Service',
            'status': 'pending',
          });
        }
      }
    } catch (_) {}

    final response = await _supabase
        .from('project_tasks')
        .select('id, name, status, quote_service_id, project_service_id')
        .eq('project_id', projectId)
        .order('name');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<void> saveDisruptionServices(
    String changeOrderId,
    List<Map<String, dynamic>> services,
  ) async {
    await _supabase
        .from('change_order_disruption_services')
        .delete()
        .eq('change_order_id', changeOrderId);

    if (services.isEmpty) return;

    final batch = services.map((s) {
      return {
        'change_order_id': changeOrderId,
        'project_task_id': s['project_task_id'],
        'affectation_type': s['affectation_type'] ?? 'total_stop',
        'notes': s['notes'],
        'delay_days': s['delay_days'] ?? 0,
      };
    }).toList();

    await _supabase.from('change_order_disruption_services').insert(batch);
  }

  // ── Catalogs (for new service CO lines) ──

  Future<List<Map<String, dynamic>>> getServicesCatalog() async {
    final response = await _supabase
        .from('services')
        .select()
        .order('description');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  // ── Machinery Deductions ──

  Future<List<Map<String, dynamic>>> getServiceMachineryForBilling(
    String projectId,
  ) async {
    final rpc = await _supabase.rpc(
      'get_service_machinery_for_billing',
      params: {'p_project_id': projectId},
    );
    return List<Map<String, dynamic>>.from(rpc ?? []);
  }

  Future<List<Map<String, dynamic>>> getMachineryDeductions(
    String invoiceId,
  ) async {
    final response = await _supabase
        .from('invoice_machinery_deductions')
        .select()
        .eq('invoice_id', invoiceId)
        .order('machine_name');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<void> saveMachineryDeductions(
    String invoiceId,
    List<Map<String, dynamic>> deductions,
  ) async {
    await _supabase
        .from('invoice_machinery_deductions')
        .delete()
        .eq('invoice_id', invoiceId);

    if (deductions.isEmpty) return;

    final batch = deductions.map((d) {
      d['invoice_id'] = invoiceId;
      d.remove('id');
      return d;
    }).toList();

    await _supabase.from('invoice_machinery_deductions').insert(batch);
  }

  // ── Disruption / Standby ──

  Future<List<Map<String, dynamic>>> getDisruptionReasons() async {
    final response = await _supabase
        .from('disruption_reasons')
        .select()
        .order('category')
        .order('code');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<List<Map<String, dynamic>>> getProjectMachineryForStandby(
    String projectId, {
    List<String>? quoteServiceIds,
    List<String>? projectServiceIds,
  }) async {
    var query = _supabase
        .from('project_machinery')
        .select('''
          id, machinery_name,
          machinery!left(id, description, capacity_yards, photo_url),
          quote_services!left(id, name),
          quote_service_machineries!left(id, monthly_rent_cost)
        ''')
        .eq('project_id', projectId);
    final orParts = <String>[];
    if (quoteServiceIds != null && quoteServiceIds.isNotEmpty) {
      orParts.add('quote_service_id.in.(${quoteServiceIds.join(',')})');
    }
    if (projectServiceIds != null && projectServiceIds.isNotEmpty) {
      orParts.add('project_service_id.in.(${projectServiceIds.join(',')})');
    }
    if (orParts.isNotEmpty) {
      query = query.or(orParts.join(','));
    }
    final response = await query.order('machinery_name');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<List<Map<String, dynamic>>> getProjectLaborForStandby(
    String projectId, {
    List<String>? quoteServiceIds,
    List<String>? projectServiceIds,
  }) async {
    var query = _supabase
        .from('project_labor')
        .select('''
          id, role_name, expected_employees,
          quote_services!left(id, name),
          quote_service_labors!left(id, role_name, hourly_rate),
          labor_roles!left(id, description, hourly_rate)
        ''')
        .eq('project_id', projectId);
    final orParts = <String>[];
    if (quoteServiceIds != null && quoteServiceIds.isNotEmpty) {
      orParts.add('quote_service_id.in.(${quoteServiceIds.join(',')})');
    }
    if (projectServiceIds != null && projectServiceIds.isNotEmpty) {
      orParts.add('project_service_id.in.(${projectServiceIds.join(',')})');
    }
    if (orParts.isNotEmpty) {
      query = query.or(orParts.join(','));
    }
    final response = await query.order('role_name');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<List<Map<String, dynamic>>> getProjectMaterialsForStandby(
    String projectId, {
    List<String>? quoteServiceIds,
    List<String>? projectServiceIds,
  }) async {
    var query = _supabase
        .from('project_materials')
        .select('''
          id, material_name, expected_quantity,
          materials!left(id, description, unit),
          quote_service_materials!left(unit_price),
          quote_services!left(id, name)
        ''')
        .eq('project_id', projectId);
    final orParts = <String>[];
    if (quoteServiceIds != null && quoteServiceIds.isNotEmpty) {
      orParts.add('quote_service_id.in.(${quoteServiceIds.join(',')})');
    }
    if (projectServiceIds != null && projectServiceIds.isNotEmpty) {
      orParts.add('project_service_id.in.(${projectServiceIds.join(',')})');
    }
    if (orParts.isNotEmpty) {
      query = query.or(orParts.join(','));
    }
    final response = await query.order('material_name');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<Map<String, dynamic>> createDisruptionRecord(
    Map<String, dynamic> data,
  ) async {
    final response = await _supabase
        .from('change_order_disruptions')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> deleteDisruptionRecords(String changeOrderId) async {
    await _supabase
        .from('change_order_disruptions')
        .delete()
        .eq('change_order_id', changeOrderId);
  }

  Future<List<Map<String, dynamic>>> getDisruptionRecords(
    String changeOrderId,
  ) async {
    final response = await _supabase
        .from('change_order_disruptions')
        .select()
        .eq('change_order_id', changeOrderId)
        .order('start_date');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  // ── Baseline Impact (Resource Plans) ──

  Future<List<Map<String, dynamic>>> getResourcePlans(String coDetailId) async {
    final response = await _supabase
        .from('change_order_resource_plans')
        .select()
        .eq('change_order_detail_id', coDetailId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<void> saveResourcePlans(
    String coDetailId,
    List<Map<String, dynamic>> plans,
  ) async {
    await _supabase
        .from('change_order_resource_plans')
        .delete()
        .eq('change_order_detail_id', coDetailId);

    if (plans.isEmpty) return;

    final batch = plans.map((p) {
      p['change_order_detail_id'] = coDetailId;
      p.remove('id');
      return p;
    }).toList();

    await _supabase.from('change_order_resource_plans').insert(batch);
  }

  Future<Map<String, dynamic>> createQuoteServiceFromCO(
    String changeOrderId,
    Map<String, dynamic> serviceData,
  ) async {
    final co = await _supabase
        .from('change_orders')
        .select('project_id')
        .eq('id', changeOrderId)
        .maybeSingle();
    final projectId = co?['project_id'] as String?;

    final response = await _supabase
        .from('project_services')
        .insert({
          'project_id': projectId,
          'name': serviceData['name'],
          'unit_of_measure': serviceData['unit_of_measure'] ?? 'und',
          'quantity': serviceData['quantity'] ?? 1,
          'direct_cost': serviceData['direct_cost'] ?? 0,
          'target_price': serviceData['target_price'] ?? 0,
          'source_co_id': changeOrderId,
        })
        .select()
        .single();
    return response;
  }

  Future<void> applyBaselineImpact(String changeOrderId) async {
    final co = await _supabase
        .from('change_orders')
        .select('project_id')
        .eq('id', changeOrderId)
        .single();

    final details = await _supabase
        .from('change_order_details')
        .select('*, change_order_resource_plans(*)')
        .eq('change_order_id', changeOrderId);

    final projectId = co['project_id'] as String;

    for (final detail in (details as List<dynamic>).cast<Map<String, dynamic>>()) {
      final lineType = detail['line_type'] as String? ?? '';
      final plans = (detail['change_order_resource_plans'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      final quoteServiceId = detail['quote_service_id'] as String?;

      if (lineType == 'existing_service' && plans.isNotEmpty) {
        for (final plan in plans) {
          final factor = (plan['proportional_factor'] as num?)?.toDouble() ?? 1;
          if (factor <= 0) continue;
          final resourceType = plan['resource_type'] as String? ?? '';

          // Clone existing resources with proportional factor
          switch (resourceType) {
            case 'labor':
              final existing = await _supabase
                  .from('project_labor')
                  .select()
                  .eq('quote_service_id', quoteServiceId)
                  .eq('project_id', projectId);
              for (final e in (existing as List<dynamic>).cast<Map<String, dynamic>>()) {
                final expected = ((e['expected_employees'] as num?)?.toDouble() ?? 1) * factor;
                if (expected <= 0) continue;
                for (int j = 0; j < expected.ceil(); j++) {
                  await _supabase.from('project_labor').insert({
                    'project_id': projectId,
                    'quote_service_id': quoteServiceId,
                    'quote_service_labor_id': e['quote_service_labor_id'],
                    'role_name': e['role_name'] ?? 'Additional Labor',
                    'expected_employees': 1,
                    'active_employees': 0,
                    'is_unplanned': true,
                    'change_type': 'change_order',
                    'source_co_id': changeOrderId,
                  });
                }
              }
              break;
            case 'machinery':
              final existing = await _supabase
                  .from('project_machinery')
                  .select()
                  .eq('quote_service_id', quoteServiceId)
                  .eq('project_id', projectId);
              for (final e in (existing as List<dynamic>).cast<Map<String, dynamic>>()) {
                final qty = ((e['expected_quantity'] as num?)?.toDouble() ?? 0) * factor;
                if (qty <= 0) continue;
                await _supabase.from('project_machinery').insert({
                  'project_id': projectId,
                  'quote_service_id': quoteServiceId,
                  'machinery_name': _nonEmpty(e['machinery_name'], 'Additional Machinery'),
                  'expected_quantity': qty,
                  'is_unplanned': true,
                  'change_type': 'change_order',
                  'source_co_id': changeOrderId,
                });
              }
              break;
            case 'material':
              final existing = await _supabase
                  .from('project_materials')
                  .select()
                  .eq('quote_service_id', quoteServiceId)
                  .eq('project_id', projectId);
              for (final e in (existing as List<dynamic>).cast<Map<String, dynamic>>()) {
                final qty = ((e['expected_quantity'] as num?)?.toDouble() ?? 0) * factor;
                if (qty <= 0) continue;
                await _supabase.from('project_materials').insert({
                  'project_id': projectId,
                  'quote_service_id': quoteServiceId,
                  'material_name': e['material_name'] ?? 'Additional Material',
                  'expected_quantity': qty,
                  'is_unplanned': true,
                  'change_type': 'change_order',
                  'source_co_id': changeOrderId,
                });
              }
              break;
            case 'instrument':
              final existing = await _supabase
                  .from('project_instruments')
                  .select()
                  .eq('quote_service_id', quoteServiceId)
                  .eq('project_id', projectId);
              for (final e in (existing as List<dynamic>).cast<Map<String, dynamic>>()) {
                final qty = ((e['expected_quantity'] as num?)?.toDouble() ?? 0) * factor;
                if (qty <= 0) continue;
                await _supabase.from('project_instruments').insert({
                  'project_id': projectId,
                  'quote_service_id': quoteServiceId,
                  'instrument_name': e['instrument_name'] ?? 'Additional Equipment',
                  'expected_quantity': qty,
                  'is_unplanned': true,
                  'change_type': 'change_order',
                  'source_co_id': changeOrderId,
                });
              }
              break;
          }
        }
      } else if (lineType == 'new_service' && plans.isNotEmpty) {
        // Reuse an existing project_service created for this CO (by the DB trigger
        // or a previous run) to avoid duplicates.
        String? newServiceId = detail['project_service_id'] as String? ?? quoteServiceId;
        if (newServiceId == null) {
          final existing = await _supabase
              .from('project_services')
              .select('id')
              .eq('project_id', projectId)
              .eq('source_co_id', changeOrderId)
              .maybeSingle();
          newServiceId = existing?['id'] as String?;
        }
        if (newServiceId == null) {
          final created = await _supabase
              .from('project_services')
              .insert({
                'project_id': projectId,
                'name': detail['service_name'] ?? 'New Service',
                'unit_of_measure': detail['unit_of_measure'] ?? 'und',
                'quantity': (detail['quantity_change'] as num?)?.toDouble() ?? 1,
                'direct_cost': 0,
                'target_price': (detail['unit_price'] as num?)?.toDouble() ?? 0,
                'source_co_id': changeOrderId,
              })
              .select()
              .single();
          newServiceId = created['id'] as String;
        }

        for (final plan in plans) {
          final resourceType = plan['resource_type'] as String? ?? '';
          switch (resourceType) {
            case 'labor':
              final empCount = (plan['employees_quantity'] as num?)?.toInt() ??
                  (plan['quantity'] as num?)?.toInt() ?? 1;
              for (int j = 0; j < empCount; j++) {
                await _supabase.from('project_labor').insert({
                  'project_id': projectId,
                  'project_service_id': newServiceId,
                  'role_name': plan['resource_name'] ?? 'Additional Labor',
                  'expected_employees': 1,
                  'active_employees': 0,
                  'is_unplanned': true,
                  'change_type': 'change_order',
                  'source_co_id': changeOrderId,
                });
              }
              break;
            case 'machinery':
              await _supabase.from('project_machinery').insert({
                'project_id': projectId,
                'project_service_id': newServiceId,
                'machinery_name':
                    plan['resource_name'] ?? 'Additional Machinery',
                'expected_quantity':
                    (plan['quantity'] as num?)?.toDouble() ?? 1,
                'is_unplanned': true,
                'change_type': 'change_order',
                'source_co_id': changeOrderId,
              });
              break;
            case 'material':
              await _supabase.from('project_materials').insert({
                'project_id': projectId,
                'project_service_id': newServiceId,
                'material_name':
                    plan['resource_name'] ?? 'Additional Material',
                'expected_quantity':
                    (plan['quantity'] as num?)?.toDouble() ?? 1,
                'is_unplanned': true,
                'change_type': 'change_order',
                'source_co_id': changeOrderId,
              });
              break;
            case 'instrument':
              await _supabase.from('project_instruments').insert({
                'project_id': projectId,
                'project_service_id': newServiceId,
                'instrument_name':
                    plan['resource_name'] ?? 'Additional Equipment',
                'expected_quantity':
                    (plan['quantity'] as num?)?.toDouble() ?? 1,
                'is_unplanned': true,
                'change_type': 'change_order',
                'source_co_id': changeOrderId,
              });
              break;
          }
        }
      } else if (lineType == 'deduction') {
        // Deduction: mark existing resources with reduced quantity
        if (quoteServiceId != null) {
          await _supabase
              .from('project_labor')
              .update({'change_type': 'change_order', 'source_co_id': changeOrderId})
              .eq('quote_service_id', quoteServiceId)
              .eq('project_id', projectId)
              .is_('source_co_id', null);
          await _supabase
              .from('project_machinery')
              .update({'change_type': 'change_order', 'source_co_id': changeOrderId})
              .eq('quote_service_id', quoteServiceId)
              .eq('project_id', projectId)
              .is_('source_co_id', null);
          await _supabase
              .from('project_materials')
              .update({'change_type': 'change_order', 'source_co_id': changeOrderId})
              .eq('quote_service_id', quoteServiceId)
              .eq('project_id', projectId)
              .is_('source_co_id', null);
          await _supabase
              .from('project_instruments')
              .update({'change_type': 'change_order', 'source_co_id': changeOrderId})
              .eq('quote_service_id', quoteServiceId)
              .eq('project_id', projectId)
              .is_('source_co_id', null);
        }
      }
    }
  }

  // ── Schedule Impact (Disruption COs) ──

  Future<Map<String, dynamic>> applyScheduleImpact(String changeOrderId) async {
    final results = <String, dynamic>{
      'conflicts': <Map<String, dynamic>>[],
      'resolved_auto': 0,
      'resolved_manual': 0,
      'schedule_extended': false,
    };

    final disruptionResult = await _supabase
        .from('change_order_disruptions')
        .select('*, change_orders!inner(project_id)')
        .eq('change_order_id', changeOrderId)
        .maybeSingle();

    if (disruptionResult == null) {
      debugPrint('[applyScheduleImpact] NO disruption record found for CO $changeOrderId');
      return results;
    }
    final projectId = disruptionResult['change_orders']?['project_id'] as String?;
    if (projectId == null) {
      debugPrint('[applyScheduleImpact] no project_id for CO $changeOrderId');
      return results;
    }

    final nonWorkingDates = await _loadNonWorkingDates(projectId);

    if (disruptionResult['schedule_impact_applied_at'] != null) {
      debugPrint('[applyScheduleImpact] ALREADY APPLIED for CO $changeOrderId, skipping');
      results['schedule_extended'] = true;
      results['already_applied'] = true;
      return results;
    }

    final startDateStr = disruptionResult['start_date']?.toString();
    final endDateStr = disruptionResult['end_date']?.toString();
    final DateTime? disruptionStartDate = disruptionResult['start_date'] is DateTime
        ? disruptionResult['start_date'] as DateTime
        : (startDateStr != null ? DateTime.tryParse(startDateStr) : null);

    final affectedServices = await _supabase
        .from('change_order_disruption_services')
        .select('*, project_tasks!inner(quote_service_id)')
        .eq('change_order_id', changeOrderId);

    debugPrint('[applyScheduleImpact] disruption $changeOrderId start=$startDateStr end=$endDateStr affectedServices=${affectedServices?.length ?? 0}');

    if (affectedServices == null || affectedServices.isEmpty) return results;

    // 1. Sort affected services by planned_start_date
    final ordered = List<Map<String, dynamic>>.from(affectedServices);
    ordered.sort((a, b) {
      final aStart = a['project_tasks']?['planned_start_date']?.toString() ?? '';
      final bStart = b['project_tasks']?['planned_start_date']?.toString() ?? '';
      return aStart.compareTo(bStart);
    });

    final allServiceIds = <String>{};
    final Map<String, int> delayByServiceId = {};

    for (final svc in ordered) {
      final taskId = svc['project_task_id'] as String;
      final quoteServiceId = svc['project_tasks']?['quote_service_id'] as String?;
      if (quoteServiceId == null) continue;

      final delayDays = (svc['delay_days'] as num?)?.toInt() ?? 0;
      final affectationType = svc['affectation_type'] as String? ?? 'total_stop';
      final partialRatio = affectationType == 'partial' ? 0.5 : 1.0;

      debugPrint('[applyScheduleImpact] svc task=$taskId qs=$quoteServiceId affectation=$affectationType delayDays=$delayDays');

      if (delayDays <= 0) {
        debugPrint('[applyScheduleImpact]   -> SKIP (delayDays<=0)');
        continue;
      }

      allServiceIds.add(quoteServiceId);
      delayByServiceId[quoteServiceId] = delayDays;

      // a. Get the base end date to shift from
      final bool isReapplication = svc['original_end_date'] != null;
      final originalEndStr = isReapplication
          ? svc['original_end_date']?.toString()
          : (await _supabase
              .from('project_tasks')
              .select('planned_end_date')
              .eq('id', taskId)
              .maybeSingle())?['planned_end_date']?.toString();
      final originalEnd = originalEndStr != null ? DateTime.tryParse(originalEndStr) : null;
      final newEnd = _addWorkingDays(originalEnd, delayDays, nonWorkingDates: nonWorkingDates);

      // b. Update project_tasks
      await _supabase
          .from('project_tasks')
          .update({'planned_end_date': newEnd?.toIso8601String().split('T')[0]})
          .eq('id', taskId);

      // c. Update disruption_services with original/extended dates
      await _supabase
          .from('change_order_disruption_services')
          .update({
            'original_end_date': originalEndStr?.substring(0, 10),
            'extended_end_date': newEnd?.toIso8601String().split('T')[0],
          })
          .eq('id', svc['id'] as String);

      // d. Shift resources: if re-applying, undo first then redo
      if (isReapplication) {
        await _shiftServiceResources(quoteServiceId, projectId, delayDays,
            disruptionStartDate: disruptionStartDate,
            nonWorkingDates: nonWorkingDates,
            reverse: true);
      }
      await _shiftServiceResources(quoteServiceId, projectId, delayDays,
          disruptionStartDate: disruptionStartDate,
          nonWorkingDates: nonWorkingDates);
    }

    // 2. Cascade: shift downstream services that share resources
    if (allServiceIds.isNotEmpty) {
      await _cascadeDownstreamServices(projectId, allServiceIds, delayByServiceId, disruptionStartDate: disruptionStartDate, nonWorkingDates: nonWorkingDates);
    }

    // 3. Detect conflicts
    final conflicts = await detectResourceConflicts(projectId, allServiceIds);

    // 4. Auto-resolve simple conflicts
    for (final conflict in conflicts) {
      final resolved = await _autoResolveConflict(conflict);
      if (resolved) {
        results['resolved_auto'] = (results['resolved_auto'] as int) + 1;
      } else {
        (results['conflicts'] as List).add(conflict);
        results['resolved_manual'] = (results['resolved_manual'] as int) + 1;
      }
    }

    // 5. Update project dates
    final projectData = await _supabase
        .from('projects')
        .select('baseline_end_date, end_date, schedule_extension_days')
        .eq('id', projectId)
        .maybeSingle();

    final currentEndStr = projectData?['end_date']?.toString();
    final currentEnd = currentEndStr != null ? DateTime.tryParse(currentEndStr) : null;
    final baselineSet = projectData?['baseline_end_date'] != null;

    // Find max extended end date across affected services
    DateTime? maxNewEnd;
    for (final svc in ordered) {
      final extDate = svc['extended_end_date'] as String?;
      if (extDate != null) {
        final parsed = DateTime.tryParse(extDate);
        if (parsed != null && (maxNewEnd == null || parsed.isAfter(maxNewEnd))) {
          maxNewEnd = parsed;
        }
      }
    }

    final maxDelayDays = delayByServiceId.values.fold(0, (a, b) => a > b ? a : b);
    final newProjectEnd = (maxNewEnd != null && currentEnd != null && maxNewEnd.isAfter(currentEnd))
        ? maxNewEnd
        : _addWorkingDays(currentEnd, maxDelayDays, nonWorkingDates: nonWorkingDates);

    final existingExt = (projectData?['schedule_extension_days'] as num?)?.toInt() ?? 0;

    await _supabase.from('projects').update({
      if (!baselineSet) 'baseline_end_date': currentEndStr?.substring(0, 19),
      'end_date': newProjectEnd?.toIso8601String().substring(0, 19),
      'schedule_extension_days': existingExt + maxDelayDays,
    }).eq('id', projectId);

    results['schedule_extended'] = true;

    // 6. Create non_working_days for the disruption period
    if (startDateStr != null && endDateStr != null) {
      await _createDisruptionNonWorkingDays(projectId, changeOrderId, startDateStr, endDateStr, ordered);
    }

    // 7. Mark schedule impact as applied (idempotency)
    results['schedule_extended'] = true;
    await _supabase.from('change_order_disruptions').update({
      'schedule_impact_applied_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('change_order_id', changeOrderId);

    return results;
  }

  Future<void> _shiftServiceResources(String quoteServiceId, String projectId, int delayDays, {DateTime? disruptionStartDate, Set<DateTime>? nonWorkingDates, bool reverse = false}) async {
    DateTime? _shift(DateTime? d) => reverse
        ? _subtractWorkingDays(d, delayDays, nonWorkingDates: nonWorkingDates)
        : _addWorkingDays(d, delayDays, nonWorkingDates: nonWorkingDates);

    final tables = [
      'project_machinery',
      'project_labor',
      'project_instruments',
    ];

    for (final table in tables) {
      final resources = await _supabase
          .from(table)
          .select('id, start_date, end_date')
          .eq('quote_service_id', quoteServiceId)
          .eq('project_id', projectId);

      if (resources.isEmpty) continue;

      debugPrint('[_shiftServiceResources] table=$table qs=$quoteServiceId delay=$delayDays disruptionStart=${disruptionStartDate?.toIso8601String()} found=${resources.length}');

      final assignmentTable = table == 'project_machinery'
          ? 'project_machinery_assignments'
          : table == 'project_labor'
              ? 'project_labor_assignments'
              : 'project_instrument_assignments';

      final parentIdCol = table == 'project_machinery'
          ? 'project_machinery_id'
          : table == 'project_labor'
              ? 'project_labor_id'
              : 'project_instrument_id';

      // Collect all parent IDs for assignment lookup
      final allParentIds = resources.map((r) => r['id'].toString()).toList();

      // Load all assignments grouped by parent id
      final assignments = await _supabase
          .from(assignmentTable)
          .select('id, $parentIdCol, start_date, end_date')
          .in_(parentIdCol, allParentIds);

      final Map<String, List<Map<String, dynamic>>> assignmentsByParent = {};
      for (final a in assignments ?? <Map<String, dynamic>>[]) {
        final pid = a[parentIdCol]?.toString();
        if (pid == null) continue;
        (assignmentsByParent[pid] ??= []).add(a);
      }

      // Derive effective start/end for a parent, falling back to its assignments
      DateTime? effectiveStart(Map<String, dynamic> r, DateTime? currentStart) {
        if (currentStart != null) return currentStart;
        DateTime? minStart;
        for (final a in assignmentsByParent[r['id'].toString()] ?? []) {
          final s = a['start_date']?.toString();
          final parsed = s != null ? DateTime.tryParse(s) : null;
          if (parsed != null && (minStart == null || parsed.isBefore(minStart))) minStart = parsed;
        }
        return minStart;
      }

      DateTime? effectiveEnd(Map<String, dynamic> r, DateTime? currentEnd) {
        if (currentEnd != null) return currentEnd;
        DateTime? maxEnd;
        for (final a in assignmentsByParent[r['id'].toString()] ?? []) {
          final e = a['end_date']?.toString();
          final parsed = e != null ? DateTime.tryParse(e) : null;
          if (parsed != null && (maxEnd == null || parsed.isAfter(maxEnd))) maxEnd = parsed;
        }
        return maxEnd;
      }

      final shiftedIds = <String>[];

      for (final r in resources) {
        final startStr = r['start_date']?.toString();
        final endStr = r['end_date']?.toString();

        DateTime? currentStart = startStr != null ? DateTime.tryParse(startStr) : null;
        DateTime? currentEnd = endStr != null ? DateTime.tryParse(endStr) : null;

        // If parent has no dates, derive them from assignments so they can be shifted
        final derivedStart = effectiveStart(r, currentStart);
        final derivedEnd = effectiveEnd(r, currentEnd);
        if (currentStart == null && currentEnd == null && derivedStart == null && derivedEnd == null) {
          debugPrint('  [_shiftServiceResources] WARN id=${r['id']} has no dates AND no assignment dates — cannot shift');
          continue;
        }

        String? newStart;
        String? newEnd;

        if (disruptionStartDate != null && derivedStart != null && derivedStart.isBefore(disruptionStartDate)) {
          // Resource started before disruption — only shift end_date
          newStart = derivedStart.toIso8601String().split('T')[0];
          newEnd = _shift(derivedEnd)?.toIso8601String().split('T')[0];
        } else {
          // Resource starts after/on disruption, no disruption date, or no start date — shift both
          newStart = _shift(derivedStart)?.toIso8601String().split('T')[0];
          newEnd = _shift(derivedEnd)?.toIso8601String().split('T')[0];
        }

        debugPrint('  [_shiftServiceResources] id=${r['id']} start=$startStr (derived=$derivedStart) -> $newStart | end=$endStr (derived=$derivedEnd) -> $newEnd');

        final updates = <String, dynamic>{};
        if (newStart != null) updates['start_date'] = newStart;
        if (newEnd != null) updates['end_date'] = newEnd;
        if (updates.isNotEmpty) {
          await _supabase.from(table).update(updates).eq('id', r['id']);
          shiftedIds.add(r['id'].toString());
        } else {
          debugPrint('  [_shiftServiceResources] WARN no updates for id=${r['id']} (null start/end or delay<=0)');
        }

        // Shift unit-level assignments linked to this parent
        for (final a in assignmentsByParent[r['id'].toString()] ?? []) {
          final aStartStr = a['start_date']?.toString();
          final aEndStr = a['end_date']?.toString();
          DateTime? aCurrentStart = aStartStr != null ? DateTime.tryParse(aStartStr) : null;
          DateTime? aCurrentEnd = aEndStr != null ? DateTime.tryParse(aEndStr) : null;

          String? newAStart;
          String? newAEnd;

          if (disruptionStartDate != null && aCurrentStart != null && aCurrentStart.isBefore(disruptionStartDate)) {
            // Assignment started before disruption — only shift end_date
            newAStart = aStartStr;
            newAEnd = _shift(aCurrentEnd)?.toIso8601String().split('T')[0];
          } else {
            // Shift both (or no disruption date)
            newAStart = _shift(aCurrentStart)?.toIso8601String().split('T')[0];
            newAEnd = _shift(aCurrentEnd)?.toIso8601String().split('T')[0];
          }

          final aUpdates = <String, dynamic>{};
          if (newAStart != null) aUpdates['start_date'] = newAStart;
          if (newAEnd != null) aUpdates['end_date'] = newAEnd;
          if (aUpdates.isNotEmpty) {
            await _supabase.from(assignmentTable).update(aUpdates).eq('id', a['id']);
          }
        }
      }
    }
  }

  Future<void> _cascadeDownstreamServices(
    String projectId,
    Set<String> affectedServiceIds,
    Map<String, int> delayByServiceId, {
    DateTime? disruptionStartDate,
    Set<DateTime>? nonWorkingDates,
  }) async {
    // Find all services that start after affected ones and share resources
    for (final entry in delayByServiceId.entries) {
      final svcId = entry.key;
      final delayDays = entry.value;

      // Get resources of the affected service
      final resourceIds = <String, Map<String, String>>{}; // resource_id -> {type, table}

      for (final table in ['project_labor', 'project_machinery', 'project_instruments']) {
        final idField = table == 'project_labor'
            ? 'role_id'
            : table == 'project_machinery'
                ? 'machinery_id'
                : 'instrument_id';

        final resources = await _supabase
            .from(table)
            .select('$idField, start_date, end_date')
            .eq('quote_service_id', svcId)
            .eq('project_id', projectId);

        if (resources == null) continue;
        for (final r in resources) {
          final rid = r[idField]?.toString();
          if (rid != null && r['end_date'] != null) {
            resourceIds[rid] = {
              'end_date': r['end_date'].toString(),
              'table': table,
            };
          }
        }
      }

      // Find other services using the same resources after affected service ends
      for (final resEntry in resourceIds.entries) {
        final resId = resEntry.key;
        final resTable = resEntry.value['table'] as String;
        final resEndDate = resEntry.value['end_date']!;
        final idField = resTable == 'project_labor'
            ? 'role_id'
            : resTable == 'project_machinery'
                ? 'machinery_id'
                : 'instrument_id';

        final downstream = await _supabase
            .from(resTable)
            .select('id, quote_service_id, start_date, end_date')
            .eq(idField, resId)
            .eq('project_id', projectId)
            .neq('quote_service_id', svcId)
            .gt('start_date', resEndDate);

        if (downstream == null) continue;

        for (final d in downstream) {
          final dSvcId = d['quote_service_id']?.toString();
          if (dSvcId == null || affectedServiceIds.contains(dSvcId)) continue;
          if (delayByServiceId.containsKey(dSvcId)) continue;

          final overlapDays = delayDays; // cascade full delay

          await _shiftServiceResources(dSvcId, projectId, overlapDays, disruptionStartDate: disruptionStartDate, nonWorkingDates: nonWorkingDates);

          // Update task dates
          final taskData = await _supabase
              .from('project_tasks')
              .select('id, planned_end_date')
              .eq('quote_service_id', dSvcId)
              .eq('project_id', projectId)
              .maybeSingle();

          if (taskData != null) {
            final taskEnd = taskData['planned_end_date']?.toString();
            final parsedTaskEnd = taskEnd != null ? DateTime.tryParse(taskEnd) : null;
            final newEnd = _addWorkingDays(parsedTaskEnd, overlapDays, nonWorkingDates: nonWorkingDates)?.toIso8601String().split('T')[0];
            if (newEnd != null) {
              await _supabase
                  .from('project_tasks')
                  .update({'planned_end_date': newEnd})
                  .eq('id', taskData['id']);
            }
          }

          affectedServiceIds.add(dSvcId);
          delayByServiceId[dSvcId] = overlapDays;
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> detectResourceConflicts(
    String projectId,
    Set<String> affectedServiceIds,
  ) async {
    final conflicts = <Map<String, dynamic>>[];
    final configs = [
      {
        'table': 'project_labor_assignments',
        'id_field': 'worker_id',
        'name_field': 'workers!inner(name)',
        'label': 'Worker',
      },
      {
        'table': 'project_machinery_assignments',
        'id_field': 'machinery_id',
        'name_field': 'machinery!inner(internal_code, equipment_name)',
        'label': 'Machinery',
      },
      {
        'table': 'project_instrument_assignments',
        'id_field': 'instrument_id',
        'name_field': 'instruments!inner(name)',
        'label': 'Instrument',
      },
    ];

    for (final config in configs) {
      final table = config['table'] as String;
      final idField = config['id_field'] as String;
      final nameField = config['name_field'] as String;
      final label = config['label'] as String;

      try {
        final result = await _supabase
            .from(table)
            .select('id, $idField, quote_service_id, start_date, end_date')
            .eq('project_id', projectId)
            .in_('quote_service_id', affectedServiceIds.toList());

        if (result == null || result.isEmpty) continue;

        // For each affected service resource, check overlaps with non-affected services
        for (final a1 in result) {
          final resId = a1[idField]?.toString();
          final svcA = a1['quote_service_id']?.toString();
          final endA = a1['end_date']?.toString();

          if (resId == null || svcA == null || endA == null) continue;

          final others = await _supabase
              .from(table)
              .select('id, quote_service_id, start_date, end_date')
              .eq(idField, resId)
              .eq('project_id', projectId)
              .neq('quote_service_id', svcA);

          if (others == null) continue;

          for (final a2 in others) {
            final svcB = a2['quote_service_id']?.toString();
            final startB = a2['start_date']?.toString();
            final endB = a2['end_date']?.toString();

            if (svcB == null || startB == null) continue;

            final endADate = DateTime.tryParse(endA);
            final startBDate = DateTime.tryParse(startB);

            if (endADate == null || startBDate == null) continue;

            if (endADate.isAfter(startBDate) || endADate == startBDate) {
              final overlapDays = endADate.difference(startBDate).inDays + 1;
              if (overlapDays > 0) {
                conflicts.add({
                  'resource_type': label,
                  'resource_id': resId,
                  'resource_name': '$label #$resId',
                  'service_a_id': svcA,
                  'service_b_id': svcB,
                  'end_a': endA,
                  'start_b': startB,
                  'overlap_days': overlapDays,
                  'table': table,
                  'id_field': idField,
                });
              }
            }
          }
        }
      } catch (_) {}
    }

    return conflicts;
  }

  Future<bool> _autoResolveConflict(Map<String, dynamic> conflict) async {
    final overlapDays = (conflict['overlap_days'] as num?)?.toInt() ?? 0;
    final resourceType = conflict['resource_type'] as String? ?? '';

    if (overlapDays <= 2) {
      // Cascade: shift service B
      final svcBId = conflict['service_b_id'] as String;
      await _shiftServiceResources(svcBId, conflict['project_id'] as String? ?? '', overlapDays);
      return true;
    }

    if (resourceType == 'Instrument') {
      // Try to find a replacement
      final table = conflict['table'] as String;
      final idField = conflict['id_field'] as String;
      final resId = conflict['resource_id'] as String;
      final svcAId = conflict['service_a_id'] as String;
      final svcBId = conflict['service_b_id'] as String;
      final projectId = conflict['project_id'] as String?;

      if (projectId != null) {
        final altInstruments = await _supabase
            .from(table)
            .select('id')
            .eq('project_id', projectId)
            .eq('quote_service_id', svcBId)
            .eq(idField, resId);

        // Check if there are other instruments available for service B
        final allBInstruments = await _supabase
            .from(table)
            .select('$idField')
            .eq('project_id', projectId)
            .eq('quote_service_id', svcBId);

        if (allBInstruments != null && allBInstruments.length > 1) {
          // Service B has multiple instruments, keep resource in A
          return true;
        }
      }
    }

    if (resourceType == 'Machinery') {
      final table = conflict['table'] as String;
      final idField = conflict['id_field'] as String;
      final resId = conflict['resource_id'] as String;
      final svcBId = conflict['service_b_id'] as String;
      final projectId = conflict['project_id'] as String?;

      if (projectId != null) {
        // Check if there's another unit of the same machinery type available
        final machData = await _supabase
            .from('project_machinery')
            .select('machinery_id')
            .eq('id', resId)
            .maybeSingle();

        final machTypeId = machData?['machinery_id']?.toString();

        if (machTypeId != null) {
          final altUnits = await _supabase
              .from('project_machinery')
              .select('id')
              .eq('project_id', projectId)
              .eq('machinery_id', machTypeId)
              .neq('id', resId);

          if (altUnits != null && altUnits.isNotEmpty) {
            // Register the alt unit for service B
            final altId = altUnits.first['id']?.toString();
            if (altId != null) {
              await _supabase.from(table).update({
                'machinery_id': altId,
              }).eq('id', svcBId).eq(idField, resId);
              return true;
            }
          }
        }
      }
    }

    return false;
  }

  Future<void> resolveResourceConflict(
    String projectId,
    Map<String, dynamic> conflict,
    String strategy, // 'keep_on_a', 'reassign_to_b', 'cascade'
  ) async {
    final overlapDays = (conflict['overlap_days'] as num?)?.toInt() ?? 0;
    final svcAId = conflict['service_a_id'] as String;
    final svcBId = conflict['service_b_id'] as String;
    final table = conflict['table'] as String;
    final idField = conflict['id_field'] as String;
    final resId = conflict['resource_id'] as String;

    switch (strategy) {
      case 'keep_on_a':
        // Resource stays on service A. Try to find replacement for B.
        final altFound = await _autoResolveConflict(conflict);
        if (!altFound) {
          // Mark service B as needing resource
          await _supabase.from('project_tasks').update({
            'status': 'blocked',
          }).eq('quote_service_id', svcBId).eq('project_id', projectId);
        }
        break;

      case 'reassign_to_b':
        // Resource goes to service B on its original date. Find replacement for the tail of A.
        // Simply shift the resource from A's assignment to use the alt
        await _supabase.from(table).delete().eq(idField, resId).eq('quote_service_id', svcAId);
        // Mark service A as needing resource for remaining days
        await _supabase.from('project_tasks').update({
          'status': 'blocked',
        }).eq('quote_service_id', svcAId).eq('project_id', projectId);
        break;

      case 'cascade':
        await _shiftServiceResources(svcBId, projectId, overlapDays);
        break;
    }
  }

  Future<void> _createDisruptionNonWorkingDays(
    String projectId,
    String changeOrderId,
    String startDateStr,
    String endDateStr,
    List<Map<String, dynamic>> affectedServices,
  ) async {
    final start = DateTime.tryParse(startDateStr);
    final end = DateTime.tryParse(endDateStr);
    if (start == null || end == null) return;

    // Determine partial_ratio: if any service has total_stop → 0.0
    bool hasTotalStop = false;
    for (final svc in affectedServices) {
      if (svc['affectation_type'] == 'total_stop') {
        hasTotalStop = true;
        break;
      }
    }
    final partialRatio = hasTotalStop ? 0.0 : 0.5;

    var current = start;
    while (!current.isAfter(end)) {
      try {
        await _supabase.from('project_non_working_days').upsert({
          'project_id': projectId,
          'date': current.toIso8601String().split('T')[0],
          'reason': 'Disruption CO — $changeOrderId',
          'partial_ratio': partialRatio,
          'source': 'disruption',
          'source_id': changeOrderId,
        }, onConflict: 'project_id,date');
      } catch (_) {}

      current = current.add(const Duration(days: 1));
    }
  }
  // ── Scope Change Schedule Impact ──

  Future<Map<String, dynamic>> applyScopeScheduleImpact(String changeOrderId) async {
    final results = <String, dynamic>{
      'conflicts': <Map<String, dynamic>>[],
      'resolved_auto': 0,
      'resolved_manual': 0,
      'services_extended': 0,
    };

    final coData = await _supabase
        .from('change_orders')
        .select('project_id, schedule_days_change')
        .eq('id', changeOrderId)
        .maybeSingle();

    if (coData == null) return results;
    final projectId = coData['project_id'] as String?;
    if (projectId == null) return results;

    final nonWorkingDates = await _loadNonWorkingDates(projectId);

    final detailsResult = await _supabase
        .from('change_order_details')
        .select('*, quote_services(quantity)')
        .eq('change_order_id', changeOrderId)
        .eq('line_type', 'existing_service')
        .gt('quantity_change', 0);

    if (detailsResult == null || detailsResult.isEmpty) return results;

    final allServiceIds = <String>{};
    final Map<String, int> delayByServiceId = {};

    for (final detail in detailsResult) {
      final qsId = detail['quote_service_id'] as String?;
      if (qsId == null) continue;

      final qtyChange = (detail['quantity_change'] as num?)?.toDouble() ?? 0;
      if (qtyChange <= 0) continue;

      final originalQty = (detail['quote_services']?['quantity'] as num?)?.toDouble() ?? 1;
      final factor = qtyChange / originalQty;

      final estData = await _supabase
          .from('quote_service_estimations')
          .select('total_working_days, end_date')
          .eq('quote_service_id', qsId)
          .maybeSingle();

      final totalWorkingDays = (estData?['total_working_days'] as num?)?.toDouble() ?? 0;
      final additionalDays = (totalWorkingDays * factor).ceil();

      if (additionalDays <= 0) continue;

      allServiceIds.add(qsId);
      delayByServiceId[qsId] = additionalDays;

      // Update estimation
      final newTotalDays = totalWorkingDays + additionalDays;
      final currentEnd = estData?['end_date']?.toString();
      DateTime? newEnd;
      if (currentEnd != null) {
        final parsed = DateTime.tryParse(currentEnd);
        if (parsed != null) newEnd = _addWorkingDays(parsed, additionalDays, nonWorkingDates: nonWorkingDates);
      }

      await _supabase.from('quote_service_estimations').update({
        'total_working_days': newTotalDays,
        if (newEnd != null) 'end_date': newEnd.toIso8601String(),
      }).eq('quote_service_id', qsId);

      // Shift task dates
      final taskData = await _supabase
          .from('project_tasks')
          .select('id, planned_end_date')
          .eq('quote_service_id', qsId)
          .eq('project_id', projectId)
          .maybeSingle();

      if (taskData != null) {
        final taskEnd = taskData['planned_end_date']?.toString();
        DateTime? newTaskEnd;
        if (taskEnd != null) {
          final parsed = DateTime.tryParse(taskEnd);
          if (parsed != null) newTaskEnd = _addWorkingDays(parsed, additionalDays, nonWorkingDates: nonWorkingDates);
        }
        await _supabase.from('project_tasks').update({
          if (newTaskEnd != null) 'planned_end_date': newTaskEnd.toIso8601String().split('T')[0],
        }).eq('id', taskData['id']);
      }

      // Shift resources
      await _shiftServiceResources(qsId, projectId, additionalDays, nonWorkingDates: nonWorkingDates);

      results['services_extended'] = (results['services_extended'] as int) + 1;
    }

    if (allServiceIds.isNotEmpty) {
      await _cascadeDownstreamServices(projectId, allServiceIds, delayByServiceId, nonWorkingDates: nonWorkingDates);
    }

    final conflicts = await detectResourceConflicts(projectId, allServiceIds);

    for (final conflict in conflicts) {
      conflict['project_id'] = projectId;
      final resolved = await _autoResolveConflict(conflict);
      if (resolved) {
        results['resolved_auto'] = (results['resolved_auto'] as int) + 1;
      } else {
        (results['conflicts'] as List).add(conflict);
        results['resolved_manual'] = (results['resolved_manual'] as int) + 1;
      }
    }

    // Update project end_date if needed
    if (results['services_extended'] > 0) {
      final projectData = await _supabase
          .from('projects')
          .select('baseline_end_date, end_date')
          .eq('id', projectId)
          .maybeSingle();

      final currentEndStr = projectData?['end_date']?.toString();
      final baselineSet = projectData?['baseline_end_date'] != null;
      DateTime? currentEnd = currentEndStr != null ? DateTime.tryParse(currentEndStr) : null;

      if (currentEnd != null) {
        final maxDelay = delayByServiceId.values.fold(0, (a, b) => a > b ? a : b);
        final newProjectEnd = _addWorkingDays(currentEnd!, maxDelay, nonWorkingDates: nonWorkingDates)!;

        final updates = <String, dynamic>{
          'end_date': newProjectEnd.toIso8601String().substring(0, 19),
        };
        if (!baselineSet) {
          updates['baseline_end_date'] = currentEndStr?.substring(0, 19);
        }
        await _supabase.from('projects').update(updates).eq('id', projectId);
      }
    }

    return results;
  }

  String _nonEmpty(dynamic value, String fallback) {
    final s = value?.toString() ?? '';
    return s.isNotEmpty ? s : fallback;
  }

  Future<Set<DateTime>> _loadNonWorkingDates(String projectId) async {
    try {
      final result = await _supabase
          .from('project_non_working_days')
          .select('date, partial_ratio')
          .eq('project_id', projectId);
      return (result ?? [])
          .where((r) => (r['partial_ratio'] as num?)?.toDouble() ?? 0 >= 1.0)
          .map((r) {
            final d = r['date'];
            if (d is DateTime) return DateTime(d.year, d.month, d.day);
            final parsed = DateTime.tryParse(d?.toString() ?? '');
            return parsed != null ? DateTime(parsed.year, parsed.month, parsed.day) : null;
          })
          .whereType<DateTime>()
          .toSet();
    } catch (_) {
      return {};
    }
  }

  DateTime _stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  DateTime? _addWorkingDays(DateTime? date, int days, {Set<DateTime>? nonWorkingDates}) {
    if (date == null) return null;
    var remaining = days;
    var current = date;
    while (remaining > 0) {
      current = current.add(const Duration(days: 1));
      if (current.weekday == DateTime.sunday) continue;
      if (nonWorkingDates != null && nonWorkingDates.contains(_stripTime(current))) continue;
      remaining--;
    }
    return current;
  }

  DateTime? _subtractWorkingDays(DateTime? date, int days, {Set<DateTime>? nonWorkingDates}) {
    if (date == null) return null;
    var remaining = days;
    var current = date;
    while (remaining > 0) {
      current = current.subtract(const Duration(days: 1));
      if (current.weekday == DateTime.sunday) continue;
      if (nonWorkingDates != null && nonWorkingDates.contains(_stripTime(current))) continue;
      remaining--;
    }
    return current;
  }
}
