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
    final rpc = await _supabase.rpc('get_pay_application_data', params: {
      'p_project_id': projectId,
      'p_period_start': periodStart,
      'p_period_end': periodEnd,
      if (excludeInvoiceId != null) 'p_exclude_inv_id': excludeInvoiceId,
    });
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
    await _supabase.from('invoice_details').delete().eq('invoice_id', invoiceId);

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

  Future<Map<String, dynamic>> createChangeOrder(Map<String, dynamic> data) async {
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
    await _supabase.from('change_orders').update({
      'status': 'approved',
      'approved_by': approvedBy,
      'approved_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> rejectChangeOrder(String id, String reason) async {
    await _supabase.from('change_orders').update({
      'status': 'rejected',
      'rejected_at': DateTime.now().toUtc().toIso8601String(),
      'rejection_reason': reason,
    }).eq('id', id);
  }

  Future<void> deleteChangeOrder(String id) async {
    await _supabase.from('change_orders').delete().eq('id', id);
  }

  // ── Change Order Details ──

  Future<void> saveChangeOrderDetails(
    String changeOrderId,
    List<Map<String, dynamic>> details,
  ) async {
    await _supabase.from('change_order_details').delete().eq('change_order_id', changeOrderId);

    if (details.isEmpty) return;

    final batch = details.map((d) {
      d['change_order_id'] = changeOrderId;
      return d;
    }).toList();

    await _supabase.from('change_order_details').insert(batch);
  }

  // ── Invoice ↔ Change Order Links ──

  Future<void> linkChangeOrderToInvoice(String invoiceId, String changeOrderId) async {
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

  Future<List<Map<String, dynamic>>> getQuoteServicesForProject(String projectId) async {
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

  // ── Catalogs (for new service CO lines) ──

  Future<List<Map<String, dynamic>>> getServicesCatalog() async {
    final response = await _supabase
        .from('services')
        .select()
        .order('description');
    return List<Map<String, dynamic>>.from(response ?? []);
  }
}
