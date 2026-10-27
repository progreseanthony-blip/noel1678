import 'package:supabase_flutter/supabase_flutter.dart';

/// Both planning views save complete requests in one database transaction.
class MachineryPlanningService {
  final SupabaseClient client;
  MachineryPlanningService(this.client);

  static List<Map<String, dynamic>> snapshot(List<dynamic> assignments) {
    final rows =
        assignments
            .map(
              (a) => <String, dynamic>{
                'id': a['id'],
                'start_date': a['start_date']?.toString().split('T').first,
                'end_date': a['end_date']?.toString().split('T').first,
                'quantity': (a['quantity'] as num?)?.toInt() ?? 1,
              },
            )
            .toList()
          ..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));
    return rows;
  }

  Future<Map<String, dynamic>> save(
    String projectId,
    List<Map<String, dynamic>> rows,
  ) async => Map<String, dynamic>.from(
    await client.rpc(
      'save_machinery_planning',
      params: {'p_project': projectId, 'p_rows': rows},
    ),
  );
}
