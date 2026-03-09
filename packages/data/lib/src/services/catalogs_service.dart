import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../remote/supabase_client.dart';

part 'catalogs_service.g.dart';

@riverpod
CatalogsService catalogsService(CatalogsServiceRef ref) {
  return CatalogsService(ref.watch(supabaseClientProvider));
}

class CatalogsService {
  final SupabaseClient _supabase;

  CatalogsService(this._supabase);

  // ── Labor Roles ──
  Future<List<Map<String, dynamic>>> getLaborRoles() async {
    final response = await _supabase.from('labor_roles').select().order('description');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<Map<String, dynamic>> createLaborRole(Map<String, dynamic> data) async {
    final response = await _supabase.from('labor_roles').insert(data).select().single();
    return response;
  }

  Future<void> updateLaborRole(String id, Map<String, dynamic> data) async {
    await _supabase.from('labor_roles').update(data).eq('id', id);
  }

  Future<void> deleteLaborRole(String id) async {
    await _supabase.from('labor_roles').delete().eq('id', id);
  }

  // ── Machinery ──
  Future<List<Map<String, dynamic>>> getMachinery() async {
    final response = await _supabase.from('machinery').select().order('description');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<Map<String, dynamic>> createMachinery(Map<String, dynamic> data) async {
    final response = await _supabase.from('machinery').insert(data).select().single();
    return response;
  }

  Future<void> updateMachinery(String id, Map<String, dynamic> data) async {
    await _supabase.from('machinery').update(data).eq('id', id);
  }

  Future<void> deleteMachinery(String id) async {
    await _supabase.from('machinery').delete().eq('id', id);
  }

  // ── Services ──
  Future<List<Map<String, dynamic>>> getServices() async {
    final response = await _supabase.from('services').select().order('description');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<Map<String, dynamic>> createService(Map<String, dynamic> data) async {
    final response = await _supabase.from('services').insert(data).select().single();
    return response;
  }

  Future<void> updateService(String id, Map<String, dynamic> data) async {
    await _supabase.from('services').update(data).eq('id', id);
  }

  Future<void> deleteService(String id) async {
    await _supabase.from('services').delete().eq('id', id);
  }
}
