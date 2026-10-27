import 'package:supabase_flutter/supabase_flutter.dart';

/// Operational daily-report API. These RPCs never return financial fields.
class DailyExecutionService {
  final SupabaseClient client;
  DailyExecutionService(this.client);
  String? get currentUserId => client.auth.currentUser?.id;

  Future<Map<String, dynamic>> ensureReport(
    String projectId,
    String day,
  ) async => Map<String, dynamic>.from(
    await client.rpc(
          'ensure_daily_report',
          params: {'p_project': projectId, 'p_day': day},
        )
        as Map,
  );

  static List<Map<String, dynamic>> rows(dynamic value) =>
      (value as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  Future<List<Map<String, dynamic>>> projects() async =>
      rows(await client.rpc('get_daily_operation_projects'));

  Future<List<Map<String, dynamic>>> reports(String projectId) async => rows(
    await client.rpc(
      'get_daily_operation_reports',
      params: {'p_project': projectId},
    ),
  );

  Future<Map<String, dynamic>> entry(
    String projectId,
    String day, {
    String? reportId,
  }) async => Map<String, dynamic>.from(
    await client.rpc(
          'get_daily_report_entry_context',
          params: {'p_project': projectId, 'p_day': day, 'p_report': reportId},
        )
        as Map,
  );

  Future<Map<String, dynamic>> workspace(
    String projectId,
    String day,
    String crewId,
  ) async => Map<String, dynamic>.from(
    await client.rpc(
          'get_daily_execution_planned_workspace',
          params: {'p_project': projectId, 'p_day': day, 'p_crew': crewId},
        )
        as Map,
  );

  Future<Map<String, dynamic>> machineryProgress(
    String projectId,
    String day,
  ) async => Map<String, dynamic>.from(
    await client.rpc(
          'get_daily_machinery_progress',
          params: {'p_project': projectId, 'p_day': day, 'p_crew': null},
        )
        as Map,
  );

  Future<Map<String, dynamic>> breakContext(
    String projectId,
    String day,
    String crew,
  ) async => Map<String, dynamic>.from(
    await client.rpc(
          'get_daily_break_context',
          params: {'p_project': projectId, 'p_day': day, 'p_crew': crew},
        )
        as Map,
  );

  Future<Map<String, dynamic>> open(
    String projectId,
    String day,
    String crewId,
  ) async => Map<String, dynamic>.from(
    await client.rpc(
          'open_daily_report_section',
          params: {'p_project': projectId, 'p_day': day, 'p_crew': crewId},
        )
        as Map,
  );

  Future<Map<String, dynamic>> save({
    required Map<String, dynamic> section,
    required String notes,
    required List<Map<String, dynamic>> labor,
    required List<Map<String, dynamic>> machinery,
    required List<Map<String, dynamic>> materials,
    required List<Map<String, dynamic>> signature,
    required List<String> photos,
    bool submit = false,
  }) async => Map<String, dynamic>.from(
    await client.rpc(
          'save_daily_report_section_v2',
          params: {
            'p_section': section['id'],
            'p_revision': section['revision'],
            'p_notes': notes,
            'p_labor': labor,
            'p_machinery': machinery,
            'p_materials': materials,
            'p_signature': signature,
            'p_photos': photos,
            'p_submit': submit,
          },
        )
        as Map,
  );

  Future<void> review(
    String sectionId, {
    required bool approve,
    String? reason,
  }) async {
    await client.rpc(
      'review_daily_report_section',
      params: {
        'p_section': sectionId,
        'p_approve': approve,
        'p_reason': reason,
      },
    );
  }

  Future<Map<String, dynamic>> transferContext(
    String project,
    String day,
    String? crew,
  ) async => Map<String, dynamic>.from(
    await client.rpc(
          'get_daily_transfer_context',
          params: {'p_project': project, 'p_day': day, 'p_crew': crew},
        )
        as Map,
  );

  Future<String> requestTransfer({
    required String report,
    required String worker,
    required String crew,
    required String labor,
    required String start,
    required String end,
    required String reason,
  }) async =>
      await client.rpc(
            'request_daily_worker_transfer',
            params: {
              'p_report': report,
              'p_worker': worker,
              'p_to_crew': crew,
              'p_labor': labor,
              'p_start': start,
              'p_end': end,
              'p_reason': reason,
            },
          )
          as String;

  Future<void> reviewTransfer(String transfer, bool approve) async {
    await client.rpc(
      'review_daily_worker_transfer',
      params: {'p_transfer': transfer, 'p_approve': approve},
    );
  }

  Future<void> cancelTransfer(String transfer, String reason) async {
    await client.rpc(
      'cancel_daily_worker_transfer',
      params: {'p_transfer': transfer, 'p_reason': reason},
    );
  }
}
