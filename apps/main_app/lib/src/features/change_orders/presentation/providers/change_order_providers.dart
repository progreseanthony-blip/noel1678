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
