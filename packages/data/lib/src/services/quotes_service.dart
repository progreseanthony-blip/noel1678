import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../remote/supabase_client.dart';

part 'quotes_service.g.dart';

@riverpod
QuotesService quotesService(QuotesServiceRef ref) {
  return QuotesService(ref.watch(supabaseClientProvider));
}

class QuotesService {
  final SupabaseClient _supabase;

  QuotesService(this._supabase);

  // ── Quotes ──
  Future<List<Map<String, dynamic>>> getQuotes() async {
    final response = await _supabase.from('quotes').select().order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> getQuoteById(String id) async {
    final response = await _supabase.from('quotes').select().eq('id', id).single();
    return response;
  }

  Future<Map<String, dynamic>> createQuote(Map<String, dynamic> quoteData) async {
    final response = await _supabase.from('quotes').insert(quoteData).select().single();
    return response;
  }

  Future<void> updateQuote(String id, Map<String, dynamic> data) async {
    await _supabase.from('quotes').update(data).eq('id', id);
  }

  Future<void> deleteQuote(String id) async {
    await _supabase.from('quotes').delete().eq('id', id);
  }

  // ── Quote Services ──
  Future<List<Map<String, dynamic>>> getServicesForQuote(String quoteId) async {
    final response = await _supabase.from('quote_services').select().eq('quote_id', quoteId).order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createQuoteService(Map<String, dynamic> serviceData) async {
    final response = await _supabase.from('quote_services').insert(serviceData).select().single();
    return response;
  }

  Future<void> updateQuoteService(String id, Map<String, dynamic> data) async {
    await _supabase.from('quote_services').update(data).eq('id', id);
  }

  Future<void> deleteQuoteService(String id) async {
    await _supabase.from('quote_services').delete().eq('id', id);
  }

  // ── Quote Service Machineries ──
  Future<List<Map<String, dynamic>>> getMachineriesForService(String quoteServiceId) async {
    final response = await _supabase.from('quote_service_machineries').select().eq('quote_service_id', quoteServiceId).order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createMachinery(Map<String, dynamic> machineryData) async {
    final response = await _supabase.from('quote_service_machineries').insert(machineryData).select().single();
    return response;
  }

  Future<void> updateMachinery(String id, Map<String, dynamic> data) async {
    await _supabase.from('quote_service_machineries').update(data).eq('id', id);
  }

  Future<void> deleteMachinery(String id) async {
    await _supabase.from('quote_service_machineries').delete().eq('id', id);
  }

  // ── Quote Service Labors ──
  Future<List<Map<String, dynamic>>> getLaborsForService(String quoteServiceId) async {
    // using a join to get the role if needed
    final response = await _supabase.from('quote_service_labors')
      .select('*, roles(name)')
      .eq('quote_service_id', quoteServiceId)
      .order('created_at');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createLabor(Map<String, dynamic> laborData) async {
    final response = await _supabase.from('quote_service_labors').insert(laborData).select().single();
    return response;
  }

  Future<void> updateLabor(String id, Map<String, dynamic> data) async {
    await _supabase.from('quote_service_labors').update(data).eq('id', id);
  }

  Future<void> deleteLabor(String id) async {
    await _supabase.from('quote_service_labors').delete().eq('id', id);
  }
}
