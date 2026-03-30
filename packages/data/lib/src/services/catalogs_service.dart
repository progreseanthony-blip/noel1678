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

  // ── Machinery Applications ──
  Future<List<Map<String, dynamic>>> getMachineryApplications() async {
    final response = await _supabase.from('machinery_applications').select().order('name');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<Map<String, dynamic>> createMachineryApplication(String name) async {
    final response = await _supabase.from('machinery_applications').insert({'name': name}).select().single();
    return response;
  }

  Future<void> updateMachineryApplication(String id, String name) async {
    await _supabase.from('machinery_applications').update({'name': name}).eq('id', id);
  }

  Future<void> deleteMachineryApplication(String id) async {
    await _supabase.from('machinery_applications').delete().eq('id', id);
  }

  // ── Logistics Equipment ──
  Future<List<Map<String, dynamic>>> getLogisticsEquipment() async {
    final response = await _supabase.from('logistics_equipment').select().order('description');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<void> createLogisticsEquipment(Map<String, dynamic> data) async {
    await _supabase.from('logistics_equipment').insert(data);
  }

  Future<void> updateLogisticsEquipment(String id, Map<String, dynamic> data) async {
    await _supabase.from('logistics_equipment').update(data).eq('id', id);
  }

  Future<void> deleteLogisticsEquipment(String id) async {
    await _supabase.from('logistics_equipment').delete().eq('id', id);
  }

  // ── Logistics Applications ──
  Future<List<Map<String, dynamic>>> getLogisticsApplications() async {
    final response = await _supabase.from('logistics_applications').select().order('name');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<Map<String, dynamic>> createLogisticsApplication(String name) async {
    final response = await _supabase.from('logistics_applications').insert({'name': name}).select().single();
    return response;
  }

  Future<void> updateLogisticsApplication(String id, String name) async {
    await _supabase.from('logistics_applications').update({'name': name}).eq('id', id);
  }

  Future<void> deleteLogisticsApplication(String id) async {
    await _supabase.from('logistics_applications').delete().eq('id', id);
  }
}
