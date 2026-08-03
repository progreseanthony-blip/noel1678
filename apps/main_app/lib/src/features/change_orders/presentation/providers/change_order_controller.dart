import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:noel_data/noel_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'change_order_providers.dart';

part 'change_order_controller.g.dart';

@riverpod
class ChangeOrderController extends _$ChangeOrderController {
  @override
  FutureOr<void> build() {}

  Future<Map<String, dynamic>> createChangeOrder(Map<String, dynamic> data) async {
    final svc = ref.read(billingServiceProvider);
    final co = await svc.createChangeOrder(data);
    return co;
  }

  Future<void> updateChangeOrder(String id, Map<String, dynamic> data) async {
    final svc = ref.read(billingServiceProvider);
    await svc.updateChangeOrder(id, data);
    ref.invalidate(changeOrderDetailProvider(id));
  }

  Future<List<Map<String, dynamic>>> saveDetails(
    String coId,
    List<Map<String, dynamic>> details,
  ) async {
    final svc = ref.read(billingServiceProvider);
    final saved = await svc.saveChangeOrderDetails(coId, details);
    ref.invalidate(changeOrderDetailProvider(coId));
    return saved;
  }

  Future<void> submitChangeOrder(String id) async {
    final svc = ref.read(billingServiceProvider);
    await svc.updateChangeOrder(id, {'status': 'submitted'});
    ref.invalidate(changeOrderListProvider);
    ref.invalidate(changeOrderDetailProvider(id));
  }

  Future<Map<String, dynamic>?> approveChangeOrder(String id) async {
    final svc = ref.read(billingServiceProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final co = await svc.getChangeOrder(id);
    await svc.approveChangeOrder(id, user?.id ?? '');
    await svc.applyBaselineImpact(id);
    if (co['co_type'] == 'disruption') {
      final result = await svc.applyScheduleImpact(id);
      final conflicts = (result['conflicts'] as List?) ?? [];
      if (conflicts.isNotEmpty) return result;
    } else if (co['co_type'] == 'scope_change') {
      final result = await svc.applyScopeScheduleImpact(id);
      final conflicts = (result['conflicts'] as List?) ?? [];
      if (conflicts.isNotEmpty) return result;
    }
    ref.invalidate(changeOrderListProvider);
    ref.invalidate(changeOrderDetailProvider(id));
    return null;
  }

  Future<void> saveResourcePlans(
    String coDetailId,
    List<Map<String, dynamic>> plans,
  ) async {
    final svc = ref.read(billingServiceProvider);
    await svc.saveResourcePlans(coDetailId, plans);
  }

  Future<void> rejectChangeOrder(String id, String reason) async {
    final svc = ref.read(billingServiceProvider);
    await svc.rejectChangeOrder(id, reason);
    ref.invalidate(changeOrderListProvider);
    ref.invalidate(changeOrderDetailProvider(id));
  }

  Future<void> deleteChangeOrder(String id) async {
    final svc = ref.read(billingServiceProvider);
    await svc.deleteChangeOrder(id);
    ref.invalidate(changeOrderListProvider);
  }

  // ── Disruption / Standby ──

  Future<void> saveDisruptionRecords(
      String coId, List<Map<String, dynamic>> records) async {
    final svc = ref.read(billingServiceProvider);
    await svc.deleteDisruptionRecords(coId);
    if (records.isEmpty) return;
    final batch = records.map((r) {
      r['change_order_id'] = coId;
      return r;
    }).toList();
    for (final r in batch) {
      await svc.createDisruptionRecord(r);
    }
  }

  Future<void> saveDisruptionServices(
    String coId,
    List<Map<String, dynamic>> services,
  ) async {
    final svc = ref.read(billingServiceProvider);
    await svc.saveDisruptionServices(coId, services);
    ref.invalidate(changeOrderDetailProvider(coId));
  }
}
