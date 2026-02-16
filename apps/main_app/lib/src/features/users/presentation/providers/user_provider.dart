import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:noel_data/noel_data.dart';

part 'user_provider.g.dart';

@riverpod
Future<List<Map<String, dynamic>>> userList(UserListRef ref) {
  return ref.watch(userServiceProvider).getUsers();
}
