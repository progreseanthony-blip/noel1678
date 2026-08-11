import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:noel_data/noel_data.dart';

part 'change_order_providers.g.dart';

@riverpod
Future<List<Map<String, dynamic>>> changeOrderList(ChangeOrderListRef ref, String projectId) {
  return ref.watch(billingServiceProvider).getChangeOrders(projectId);
}

@riverpod
Future<Map<String, dynamic>> changeOrderDetail(ChangeOrderDetailRef ref, String coId) {
  return ref.watch(billingServiceProvider).getChangeOrder(coId);
}

@riverpod
Future<List<Map<String, dynamic>>> quoteServiceList(QuoteServiceListRef ref, String projectId) {
  return ref.watch(billingServiceProvider).getQuoteServicesForProject(projectId);
}

@riverpod
Future<List<Map<String, dynamic>>> servicesCatalog(ServicesCatalogRef ref) {
  return ref.watch(billingServiceProvider).getServicesCatalog();
}

@riverpod
Future<List<Map<String, dynamic>>> disruptionReasonList(DisruptionReasonListRef ref) {
  return ref.watch(billingServiceProvider).getDisruptionReasons();
}

@riverpod
Future<List<Map<String, dynamic>>> projectMachineryForStandby(
    ProjectMachineryForStandbyRef ref, String projectId,
    [List<String>? quoteServiceIds, List<String>? projectServiceIds]) {
  return ref.watch(billingServiceProvider).getProjectMachineryForStandby(
      projectId,
      quoteServiceIds: quoteServiceIds,
      projectServiceIds: projectServiceIds);
}

@riverpod
Future<List<Map<String, dynamic>>> projectLaborForStandby(
    ProjectLaborForStandbyRef ref, String projectId,
    [List<String>? quoteServiceIds, List<String>? projectServiceIds]) {
  return ref.watch(billingServiceProvider).getProjectLaborForStandby(
      projectId,
      quoteServiceIds: quoteServiceIds,
      projectServiceIds: projectServiceIds);
}

@riverpod
Future<List<Map<String, dynamic>>> projectMaterialsForStandby(
    ProjectMaterialsForStandbyRef ref, String projectId,
    [List<String>? quoteServiceIds, List<String>? projectServiceIds]) {
  return ref.watch(billingServiceProvider).getProjectMaterialsForStandby(
      projectId,
      quoteServiceIds: quoteServiceIds,
      projectServiceIds: projectServiceIds);
}
