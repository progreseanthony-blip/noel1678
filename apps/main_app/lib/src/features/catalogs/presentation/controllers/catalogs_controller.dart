import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:noel_data/noel_data.dart';

part 'catalogs_controller.g.dart';

@riverpod
Future<List<Map<String, dynamic>>> laborRolesController(LaborRolesControllerRef ref) async {
  final service = ref.watch(catalogsServiceProvider);
  return await service.getLaborRoles();
}
