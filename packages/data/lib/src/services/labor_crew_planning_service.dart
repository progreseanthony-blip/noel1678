import 'package:supabase_flutter/supabase_flutter.dart';

class LaborCrewPlanningService {
  final SupabaseClient client;
  LaborCrewPlanningService(this.client);

  Future<Map<String, dynamic>> load(String projectId) async =>
      Map<String, dynamic>.from(
        await client.rpc(
              'get_labor_crew_planning_responsibilities',
              params: {'p_project': projectId},
            )
            as Map,
      );

  Future<List<Map<String, dynamic>>> workerBookings(
    String projectId,
    String from,
    String until,
  ) async => List<Map<String, dynamic>>.from(
    await client.rpc(
          'get_labor_worker_availability',
          params: {'p_project': projectId, 'p_from': from, 'p_until': until},
        )
        as List,
  );

  Future<Set<String>> busyWorkers(
    String projectId,
    String from,
    String until,
  ) async => (await workerBookings(
    projectId,
    from,
    until,
  )).map((r) => r['worker_id'] as String).toSet();

  Future<void> save({
    required String projectId,
    required String serviceKey,
    required List<Map<String, dynamic>> rows,
    String? crewId,
    String? crewName,
    String? foremanId,
  }) async {
    await client.rpc(
      'save_labor_crew_plan',
      params: {
        'p_project': projectId,
        'p_service': serviceKey,
        'p_rows': rows,
        'p_crew': crewId,
        'p_crew_name': crewName,
        'p_foreman': foremanId,
      },
    );
  }

  Future<void> dates(String assignmentId, String from, String until) async {
    await client.rpc(
      'update_labor_crew_dates',
      params: {'p_assignment': assignmentId, 'p_from': from, 'p_until': until},
    );
  }

  Future<void> end(String kind, String id, String until) async {
    await client.rpc(
      'end_labor_crew_period',
      params: {'p_kind': kind, 'p_id': id, 'p_until': until},
    );
  }

  Future<void> leader(
    String crewId,
    String profileId,
    String from,
    String until,
  ) async {
    await client.rpc(
      'assign_labor_crew_leader',
      params: {
        'p_crew': crewId,
        'p_profile': profileId,
        'p_from': from,
        'p_until': until,
      },
    );
  }

  Future<void> changeForeman(
    String leaderId,
    String profileId,
    String mode,
    String? from,
    String reason,
  ) async {
    await client.rpc(
      'change_labor_crew_foreman',
      params: {
        'p_leader': leaderId,
        'p_profile': profileId,
        'p_mode': mode,
        'p_from': from,
        'p_reason': reason,
      },
    );
  }

  Future<void> changeWorker(
    String assignmentId,
    String action,
    String? until,
    String reason,
  ) async {
    await client.rpc(
      'change_labor_worker_plan',
      params: {
        'p_assignment': assignmentId,
        'p_action': action,
        'p_until': until,
        'p_reason': reason,
      },
    );
  }
}
