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

  Future<void> saveDetails(String coId, List<Map<String, dynamic>> details) async {
    final svc = ref.read(billingServiceProvider);
    await svc.saveChangeOrderDetails(coId, details);
    ref.invalidate(changeOrderDetailProvider(coId));
  }

  Future<void> approveChangeOrder(String id) async {
    final svc = ref.read(billingServiceProvider);
    final user = Supabase.instance.client.auth.currentUser;
    await svc.approveChangeOrder(id, user?.id ?? '');
    ref.invalidate(changeOrderListProvider);
    ref.invalidate(changeOrderDetailProvider(id));
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
}
