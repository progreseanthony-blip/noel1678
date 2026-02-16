import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../remote/supabase_client.dart';

part 'user_service.g.dart';

@riverpod
UserService userService(UserServiceRef ref) {
  return UserService(ref.watch(supabaseClientProvider));
}

class UserService {
  final SupabaseClient _supabase;

  UserService(this._supabase);

  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await _supabase.from('profiles').select().order('name');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> getProfile(String id) async {
    final response = await _supabase.from('profiles').select().eq('id', id).single();
    return response;
  }
}
