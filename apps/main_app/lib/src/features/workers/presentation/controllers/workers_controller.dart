import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:noel_data/noel_data.dart'; // Ensure it exports WorkersService

part 'workers_controller.g.dart';

@riverpod
class WorkersController extends _$WorkersController {
  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    return _fetchWorkers();
  }

  Future<List<Map<String, dynamic>>> _fetchWorkers() async {
    final service = ref.read(workersServiceProvider);
    return await service.getWorkers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchWorkers());
  }

  Future<void> createWorker(Map<String, dynamic> data) async {
    final service = ref.read(workersServiceProvider);
    await service.createWorker(data);
    await refresh();
  }

  Future<void> updateWorker(String id, Map<String, dynamic> data) async {
    final service = ref.read(workersServiceProvider);
    await service.updateWorker(id, data);
    await refresh();
  }

  Future<void> deleteWorker(String id) async {
    final service = ref.read(workersServiceProvider);
    await service.deleteWorker(id);
    await refresh();
  }
}
