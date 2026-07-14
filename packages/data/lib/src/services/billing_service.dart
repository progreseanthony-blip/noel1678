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
    data['details'] = List<Map<String, dynamic>>.from(details ?? []);
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

  Future<void> saveChangeOrderDetails(
    String changeOrderId,
    List<Map<String, dynamic>> details,
  ) async {
    await _supabase
        .from('change_order_details')
        .delete()
        .eq('change_order_id', changeOrderId);

    if (details.isEmpty) return;

    final knownColumns = {
      'change_order_id',
      'line_type',
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
    };

    final batch = details.map((d) {
      d['change_order_id'] = changeOrderId;
      return Map<String, dynamic>.fromEntries(
        d.entries.where((e) => knownColumns.contains(e.key)),
      );
    }).toList();

    await _supabase.from('change_order_details').insert(batch);
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
    if (quoteId == null) return [];

    final response = await _supabase
        .from('quote_services')
        .select()
        .eq('quote_id', quoteId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response ?? []);
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
    final response = await _supabase
        .from('project_tasks')
        .select('id, name, status, quote_service_id')
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
  }) async {
    var query = _supabase
        .from('project_machinery')
        .select('''
          id, machinery_name,
          machinery!left(id, description, capacity_yards),
          quote_services!left(id, name),
          quote_service_machineries!inner(monthly_rent_cost, gallons_per_hour, gallon_cost)
        ''')
        .eq('project_id', projectId);
    if (quoteServiceIds != null && quoteServiceIds.isNotEmpty) {
      query = query.in_('quote_service_id', quoteServiceIds);
    }
    final response = await query.order('machinery_name');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<List<Map<String, dynamic>>> getProjectLaborForStandby(
    String projectId, {
    List<String>? quoteServiceIds,
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
    if (quoteServiceIds != null && quoteServiceIds.isNotEmpty) {
      query = query.in_('quote_service_id', quoteServiceIds);
    }
    final response = await query.order('role_name');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<List<Map<String, dynamic>>> getProjectMaterialsForStandby(
    String projectId, {
    List<String>? quoteServiceIds,
  }) async {
    var query = _supabase
        .from('project_materials')
        .select('''
          id, material_name, expected_quantity,
          materials!left(id, description, unit),
          quote_service_materials!inner(unit_price),
          quote_services!left(id, name)
        ''')
        .eq('project_id', projectId);
    if (quoteServiceIds != null && quoteServiceIds.isNotEmpty) {
      query = query.in_('quote_service_id', quoteServiceIds);
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
}
