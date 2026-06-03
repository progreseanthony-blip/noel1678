import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workers_service.g.dart';

@riverpod
WorkersService workersService(WorkersServiceRef ref) {
  return WorkersService(Supabase.instance.client);
}

class WorkersService {
  final SupabaseClient _client;

  WorkersService(this._client);

  Future<List<Map<String, dynamic>>> getWorkers() async {
    final workersResponse = await _client
        .from('workers')
        .select()
        .order('full_name');
    final workers = List<Map<String, dynamic>>.from(workersResponse ?? []);

    final rolesResponse = await _client
        .from('labor_roles')
        .select('id, description, hourly_rate');
    final rolesMap = <String, Map<String, dynamic>>{};
    for (final r in List<Map<String, dynamic>>.from(rolesResponse ?? [])) {
      rolesMap[r['id'] as String] = r;
    }

    for (final w in workers) {
      final roleId = w['role_id'] as String?;
      w['role'] = roleId != null ? rolesMap[roleId] : null;
    }

    return workers;
  }

  Future<Map<String, dynamic>> getWorkerDetails(String id) async {
    final response = await _client
        .from('workers')
        .select()
        .eq('id', id)
        .single();
    final worker = Map<String, dynamic>.from(response as Map<String, dynamic>);

    final roleId = worker['role_id'] as String?;
    if (roleId != null) {
      final roleResponse = await _client
          .from('labor_roles')
          .select('id, description, hourly_rate')
          .eq('id', roleId)
          .maybeSingle();
      worker['role'] = roleResponse;
    }

    return worker;
  }

  Future<List<Map<String, dynamic>>> getWorkerHistory(String workerId) async {
    final response = await _client
        .from('worker_role_history')
        .select('''
          *,
          prev_role:previous_role_id(description),
          new_role:new_role_id(description)
        ''')
        .eq('worker_id', workerId)
        .order('changed_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createWorker(Map<String, dynamic> data) async {
    await _client.from('workers').insert(data);
  }

  Future<void> updateWorker(String id, Map<String, dynamic> data) async {
    await _client.from('workers').update(data).eq('id', id);
  }

  Future<void> deleteWorker(String id) async {
    await _client.from('workers').delete().eq('id', id);
  }
}
