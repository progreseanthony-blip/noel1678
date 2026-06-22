import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:noel_data/noel_data.dart';

part 'billing_providers.g.dart';

@riverpod
Future<List<Map<String, dynamic>>> invoiceList(InvoiceListRef ref, String projectId) {
  return ref.watch(billingServiceProvider).getInvoices(projectId);
}

@riverpod
Future<Map<String, dynamic>> invoiceDetail(InvoiceDetailRef ref, String invoiceId) {
  return ref.watch(billingServiceProvider).getInvoice(invoiceId);
}

@riverpod
Future<Map<String, dynamic>> payApplicationData(PayApplicationDataRef ref, {
  required String projectId,
  required String periodStart,
  required String periodEnd,
  String? excludeInvoiceId,
}) {
  return ref.watch(billingServiceProvider).getPayApplicationData(
    projectId: projectId,
    periodStart: periodStart,
    periodEnd: periodEnd,
    excludeInvoiceId: excludeInvoiceId,
  );
}
