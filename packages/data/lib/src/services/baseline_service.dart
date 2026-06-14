import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../remote/supabase_client.dart';

part 'baseline_service.g.dart';

@riverpod
BaselineService baselineService(BaselineServiceRef ref) {
  return BaselineService(ref.watch(supabaseClientProvider));
}

class BaselineService {
  final SupabaseClient _supabase;
  BaselineService(this._supabase);

  /// Get all snapshots for a project, ordered by version DESC
  Future<List<Map<String, dynamic>>> getSnapshots(String projectId) async {
    return await _supabase
        .from('project_baseline_snapshots')
        .select('*')
        .eq('project_id', projectId)
        .order('version', ascending: false);
  }

  /// Get the latest active snapshot for a project
  Future<Map<String, dynamic>?> getLatestSnapshot(String projectId) async {
    return await _supabase
        .from('project_baseline_snapshots')
        .select('*')
        .eq('project_id', projectId)
        .order('version', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  /// Get next version number for a project
  Future<int> getNextVersion(String projectId) async {
    final latest = await getLatestSnapshot(projectId);
    return (latest?['version'] as int? ?? 0) + 1;
  }

  /// Create a new baseline snapshot and assign it to current resources.
  /// Returns the created snapshot.
  Future<Map<String, dynamic>> createSnapshot({
    required String projectId,
    required Map<String, dynamic> calculationMetadata,
    String? label,
    String? reason,
    String? userId,
  }) async {
    final version = await getNextVersion(projectId);

    final snapshot = await _supabase
        .from('project_baseline_snapshots')
        .insert({
          'project_id': projectId,
          'version': version,
          'label': label ?? 'v$version',
          'reason': reason,
          'frozen_by': userId,
          'calculation_metadata': calculationMetadata,
        })
        .select()
        .single();

    final snapshotId = snapshot['id'];

    // Assign snapshot to all current planning resources
    await _assignSnapshotToUnversionedResources(projectId, snapshotId);

    return snapshot;
  }

  /// Assign a baseline_snapshot_id to all resources that don't have one yet
  /// and have change_type = 'planning'
  Future<void> _assignSnapshotToUnversionedResources(
      String projectId, String snapshotId) async {
    final tables = [
      'project_machinery',
      'project_labor',
      'project_materials',
      'project_instruments',
    ];

    for (final table in tables) {
      await _supabase.from(table).update({
        'baseline_snapshot_id': snapshotId,
        'change_type': 'planning',
      }).eq('project_id', projectId).is_('baseline_snapshot_id', null);
    }
  }

  /// Get resources belonging to a specific snapshot
  Future<Map<String, List<Map<String, dynamic>>>> getSnapshotResources(
      String snapshotId) async {
    final tables = {
      'Machinery': 'project_machinery',
      'Labor': 'project_labor',
      'Materials': 'project_materials',
      'Instruments': 'project_instruments',
    };

    final result = <String, List<Map<String, dynamic>>>{};
    for (final entry in tables.entries) {
      final rows = await _supabase
          .from(entry.value)
          .select('*')
          .eq('baseline_snapshot_id', snapshotId);
      result[entry.key] = List<Map<String, dynamic>>.from(rows);
    }
    return result;
  }
}
