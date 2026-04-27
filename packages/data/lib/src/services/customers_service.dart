import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../remote/supabase_client.dart';

part 'customers_service.g.dart';

@riverpod
CustomersService customersService(CustomersServiceRef ref) {
  return CustomersService(ref.watch(supabaseClientProvider));
}

class CustomersService {
  final SupabaseClient _supabase;

  CustomersService(this._supabase);

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final response = await _supabase.from('customers').select().order('name');
    return List<Map<String, dynamic>>.from(response ?? []);
  }

  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> data) async {
    final response = await _supabase.from('customers').insert(data).select().single();
    return response;
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    await _supabase.from('customers').update(data).eq('id', id);
  }

  Future<void> deleteCustomer(String id) async {
    await _supabase.from('customers').delete().eq('id', id);
  }
}
