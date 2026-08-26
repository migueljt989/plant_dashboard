import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/reading.dart';
import '../../../domain/repositories/readings_repository.dart';
import '../../../infrastructure/datasources/readings/readings_remote_datasource.dart';
import '../../../infrastructure/datasources/readings/readings_remote_datasource_backend.dart';
import '../../../infrastructure/network/dio_provider.dart';
import '../../../infrastructure/repositories/readings_repository_impl.dart';
import 'readings_filter.dart';
import 'readings_state.dart';

final readingsDataSourceProvider = Provider<ReadingsRemoteDataSource>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return ReadingsRemoteDataSourceBackend(dio);
});

final readingsRepositoryProvider = Provider<ReadingsRepository>((ref) {
  return ReadingsRepositoryImpl(ref.watch(readingsDataSourceProvider));
});

final readingsControllerProvider =
    AsyncNotifierProvider<ReadingsController, ReadingsState>(
        () => ReadingsController());

class ReadingsController extends AsyncNotifier<ReadingsState> {
  @override
  Future<ReadingsState> build() async {
    const filter = ReadingsFilter();
    final response = await ref.read(readingsRepositoryProvider).getReadings(
          limit: 50,
          offset: 0,
        );
    return ReadingsState(
      items: response.items,
      total: response.total,
      limit: response.limit,
      offset: response.offset,
      filter: filter,
    );
  }

  Future<void> applyFilters(ReadingsFilter filter) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await ref.read(readingsRepositoryProvider).getReadings(
            sensorId: filter.sensorId,
            deviceId: filter.deviceId,
            metric: filter.metric,
            from: filter.from,
            to: filter.to,
            limit: 50,
            offset: 0,
          );
      return ReadingsState(
        items: response.items,
        total: response.total,
        limit: response.limit,
        offset: 0,
        filter: filter,
      );
    });
  }

  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore) return;

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final nextOffset = currentState.offset + currentState.items.length;
      final filter = currentState.filter;
      final response = await ref.read(readingsRepositoryProvider).getReadings(
            sensorId: filter.sensorId,
            deviceId: filter.deviceId,
            metric: filter.metric,
            from: filter.from,
            to: filter.to,
            limit: currentState.limit,
            offset: nextOffset,
          );
      state = AsyncValue.data(currentState.copyWith(
        items: [...currentState.items, ...response.items],
        total: response.total,
        offset: nextOffset,
        isLoadingMore: false,
      ));
    } catch (e, st) {
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: false));
      // Re-throw so callers can handle if needed
      Error.throwWithStackTrace(e, st);
    }
  }
}

final latestReadingProvider = FutureProvider.autoDispose<Reading?>((ref) async {
  final controllerState = ref.watch(readingsControllerProvider);
  final filter = controllerState.value?.filter ?? const ReadingsFilter();

  try {
    return await ref.read(readingsRepositoryProvider).getLatestReading(
          sensorId: filter.sensorId,
          deviceId: filter.deviceId,
          metric: filter.metric,
        );
  } catch (_) {
    return null;
  }
});
