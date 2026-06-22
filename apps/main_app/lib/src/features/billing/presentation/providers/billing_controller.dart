import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:noel_data/noel_data.dart';
import 'billing_providers.dart';

part 'billing_controller.g.dart';

@riverpod
class BillingController extends _$BillingController {
  @override
  FutureOr<void> build() {}

  Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> data) async {
    final svc = ref.read(billingServiceProvider);
    final invoice = await svc.createInvoice(data);
    return invoice;
  }

  Future<void> updateInvoice(String id, Map<String, dynamic> data) async {
    final svc = ref.read(billingServiceProvider);
    await svc.updateInvoice(id, data);
  }

  Future<void> submitInvoice(String id) async {
    final svc = ref.read(billingServiceProvider);
    await svc.updateInvoiceStatus(id, 'submitted');
    ref.invalidate(invoiceListProvider);
  }

  Future<void> saveInvoiceDetails(String invoiceId, List<Map<String, dynamic>> details) async {
    final svc = ref.read(billingServiceProvider);
    await svc.saveInvoiceDetails(invoiceId, details);
    ref.invalidate(invoiceDetailProvider(invoiceId));
  }

  Future<void> deleteInvoice(String id) async {
    final svc = ref.read(billingServiceProvider);
    await svc.deleteInvoice(id);
    ref.invalidate(invoiceListProvider);
  }
}
