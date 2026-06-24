import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../remote/supabase_client.dart';

part 'incidents_service.g.dart';

@riverpod
IncidentsService incidentsService(IncidentsServiceRef ref) {
  return IncidentsService(ref.watch(supabaseClientProvider));
}

class IncidentsService {
  final SupabaseClient _supabase;

  IncidentsService(this._supabase);

  Future<List<Map<String, dynamic>>> getByProject(String projectId) async {
    final response = await _supabase
        .from('incidents')
        .select('*, incident_categories(name, icon, color), reported_by_profile:profiles!incidents_reported_by_fkey(name)')
        .eq('project_id', projectId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<Map<String, dynamic>> getById(String id) async {
    final response = await _supabase
        .from('incidents')
        .select('*, incident_categories(name, icon, color), reported_by_profile:profiles!incidents_reported_by_fkey(name), incident_affected_items(*), incident_actions(*)')
        .eq('id', id)
        .single();
    return response;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('incidents')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data) async {
    final response = await _supabase
        .from('incidents')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return response;
  }

  Future<void> delete(String id) async {
    await _supabase.from('incidents').delete().eq('id', id);
  }

  Future<Map<String, dynamic>> addAffectedItem(String incidentId, Map<String, dynamic> data) async {
    data['incident_id'] = incidentId;
    final response = await _supabase
        .from('incident_affected_items')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> removeAffectedItem(String itemId) async {
    await _supabase.from('incident_affected_items').delete().eq('id', itemId);
  }

  Future<Map<String, dynamic>> addAction(String incidentId, Map<String, dynamic> data) async {
    data['incident_id'] = incidentId;
    final response = await _supabase
        .from('incident_actions')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> completeAction(String actionId) async {
    await _supabase
        .from('incident_actions')
        .update({'status': 'completed', 'completed_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', actionId);
  }

  Future<void> deleteAction(String actionId) async {
    await _supabase.from('incident_actions').delete().eq('id', actionId);
  }

  Future<List<Map<String, dynamic>>> getAllOpen() async {
    final response = await _supabase
        .from('incidents')
        .select('*, incident_categories(name, icon, color), projects(title), reported_by_profile:profiles!incidents_reported_by_fkey(name)')
        .in_('status', ['open', 'in_progress'])
        .order('priority', ascending: false)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _supabase
        .from('incident_categories')
        .select()
        .eq('active', true)
        .order('name');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final response = await _supabase
        .from('incident_categories')
        .select()
        .order('name');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('incident_categories')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<Map<String, dynamic>> updateCategory(String id, Map<String, dynamic> data) async {
    final response = await _supabase
        .from('incident_categories')
        .update(data)
        .eq('id', id)
        .select()
        .single();
    return response;
  }

  Future<void> deleteCategory(String id) async {
    await _supabase.from('incident_categories').delete().eq('id', id);
  }
}
