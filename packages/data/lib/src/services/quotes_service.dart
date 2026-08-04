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
    return List<Map<String, dynamic>>.from(response ?? []);
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
    final response = await _supabase.from('quote_services').select().eq('quote_id', quoteId).is_('source_co_id', null).order('created_at');
    return List<Map<String, dynamic>>.from(response ?? []);
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
    return List<Map<String, dynamic>>.from(response ?? []);
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
    return List<Map<String, dynamic>>.from(response ?? []);
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

  // ── Quote Service Estimations ──
  Future<Map<String, dynamic>?> getEstimationForService(String quoteServiceId) async {
    final response = await _supabase.from('quote_service_estimations').select().eq('quote_service_id', quoteServiceId).maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>> upsertEstimation(Map<String, dynamic> data) async {
    final response = await _supabase.from('quote_service_estimations').upsert(data).select().single();
    return response;
  }

  // ── Quote Templates ──
  Future<List<Map<String, dynamic>>> getQuotesForTemplate() async {
    final response = await _supabase
        .from('quotes')
        .select('id, title, client_name, quote_date, total_amount, status')
        .order('created_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<Map<String, dynamic>?> getFullQuoteForTemplate(String quoteId) async {
    final quote = await _supabase.from('quotes').select().eq('id', quoteId).maybeSingle();
    if (quote == null) return null;

    final services = await _supabase
        .from('quote_services')
        .select()
        .eq('quote_id', quoteId)
        .order('created_at');

    final List<Map<String, dynamic>> servicesWithData = [];
    for (final svc in services ?? []) {
      final svcId = svc['id'] as String;

      final machineries = await getMachineriesForService(svcId);
      final labors = await getLaborsForService(svcId);
      final materials = await getMaterialsForService(svcId);
      final instruments = await getInstrumentsForService(svcId);

      final estimation = await getEstimationForService(svcId);
      List<Map<String, dynamic>> estimationResources = [];
      if (estimation != null) {
        estimationResources = await getResourcesForEstimation(estimation['id'] as String);
      }

      servicesWithData.add({
        ...svc,
        'machineries': machineries,
        'labors': labors,
        'materials': materials,
        'instruments': instruments,
        'estimation': estimation,
        'estimation_resources': estimationResources,
      });
    }

    return {
      ...quote,
      'services': servicesWithData,
    };
  }

  // ── Estimation Resources ──
  Future<List<Map<String, dynamic>>> getResourcesForEstimation(String estimationId) async {
    final response = await _supabase
        .from('quote_service_estimation_resources')
        .select('*, machinery(*)')
        .eq('estimation_id', estimationId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<void> saveResources(String estimationId, List<Map<String, dynamic>> resources) async {
    // Delete existing resources and insert new ones
    await _supabase.from('quote_service_estimation_resources').delete().eq('estimation_id', estimationId);
    if (resources.isEmpty) return;

    // Phase 1: Insert primary movers first to get real DB IDs
    // We need to map local temp IDs → real DB IDs for supports
    final primaries = resources.where((r) => r['is_primary_mover'] == true).toList();
    final supports  = resources.where((r) => r['is_primary_mover'] != true).toList();

    // Map: localId → dbId
    final Map<String, String> localToDbId = {};

    for (final r in primaries) {
      final localId = r['id'] as String?;
      final inserted = await _supabase
          .from('quote_service_estimation_resources')
          .insert({
            'estimation_id': estimationId,
            'machine_id': r['machine_id'],
            'quantity': r['quantity'],
            'trips_per_day': r['trips_per_day'],
            'capacity_per_trip': r['capacity_per_trip'],
            'performance_per_day': r['performance_per_day'] ?? 0,
            'is_primary_mover': true,
            'parent_resource_id': null,
          })
          .select()
          .single();
      if (localId != null) {
        localToDbId[localId] = inserted['id'] as String;
      }
    }

    // Phase 2: Insert supports, resolving parent_resource_id to real DB ID
    if (supports.isNotEmpty) {
      await _supabase.from('quote_service_estimation_resources').insert(
        supports.map((r) {
          final localParentId = r['parent_resource_id'] as String?;
          final dbParentId = localParentId != null ? localToDbId[localParentId] : null;
          return {
            'estimation_id': estimationId,
            'machine_id': r['machine_id'],
            'quantity': r['quantity'],
            'trips_per_day': r['trips_per_day'] ?? 0,
            'capacity_per_trip': r['capacity_per_trip'] ?? 0,
            'performance_per_day': r['performance_per_day'] ?? 0,
            'is_primary_mover': false,
            'parent_resource_id': dbParentId,
          };
        }).toList(),
      );
    }
  }

  // ── Quote Service Materials ──
  Future<List<Map<String, dynamic>>> getMaterialsForService(String quoteServiceId) async {
    final response = await _supabase.from('quote_service_materials')
      .select('*, materials(*)')
      .eq('quote_service_id', quoteServiceId)
      .order('created_at');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<void> saveMaterials(String quoteServiceId, List<Map<String, dynamic>> materials) async {
    // Delete existing and insert new
    await _supabase.from('quote_service_materials').delete().eq('quote_service_id', quoteServiceId);
    if (materials.isEmpty) return;

    await _supabase.from('quote_service_materials').insert(
      materials.map((m) => {
        'quote_service_id': quoteServiceId,
        'material_id': m['material_id'],
        'quantity': m['quantity'] ?? 0,
        'unit_price': m['unit_price'] ?? 0,
        'layer_type': m['layer_type'] ?? 'earth',
        'notes': m['notes'],
      }).toList()
    );
  }

  // ── Quote Service Instruments ──
  Future<List<Map<String, dynamic>>> getInstrumentsForService(String quoteServiceId) async {
    final response = await _supabase.from('quote_service_instruments')
      .select('*, logistics_equipment(*)')
      .eq('quote_service_id', quoteServiceId)
      .order('created_at');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<void> saveInstruments(String quoteServiceId, List<Map<String, dynamic>> instruments) async {
    // Delete existing and insert new
    await _supabase.from('quote_service_instruments').delete().eq('quote_service_id', quoteServiceId);
    if (instruments.isEmpty) return;

    await _supabase.from('quote_service_instruments').insert(
      instruments.map((i) => {
        'quote_service_id': quoteServiceId,
        'instrument_id': i['instrument_id'],
        'instrument_name': i['instrument_name'],
        'quantity': i['quantity'] ?? 1,
        'unit_price': i['unit_price'] ?? 0,
        'notes': i['notes'],
      }).toList(),
    );
  }
}
