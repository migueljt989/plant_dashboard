import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/repositories/alerts_repository.dart';
import '../../../infrastructure/datasources/alerts/alerts_remote_datasource.dart';
import '../../../infrastructure/datasources/alerts/alerts_remote_datasource_backend.dart';
import '../../../infrastructure/network/dio_provider.dart';
import '../../../infrastructure/repositories/alerts_repository_impl.dart';
import 'alerts_filter.dart';
import 'alerts_state.dart';

final alertsDataSourceProvider = Provider<AlertsRemoteDataSource>((ref) {
  final dio = ref.watch(authenticatedDioProvider);
  return AlertsRemoteDataSourceBackend(dio);
});

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepositoryImpl(ref.watch(alertsDataSourceProvider));
});

/// AsyncNotifierProvider for the alerts page with pagination and filtering.
final alertsControllerProvider =
    AsyncNotifierProvider<AlertsController, AlertsState>(
        () => AlertsController());

class AlertsController extends AsyncNotifier<AlertsState> {
  @override
  Future<AlertsState> build() async {
    const filter = AlertsFilter();
    final response = await ref.read(alertsRepositoryProvider).getAlerts(
          limit: 50,
          offset: 0,
        );
    return AlertsState(
      items: response.items,
      total: response.total,
      limit: response.limit,
      offset: response.offset,
      filter: filter,
    );
  }

  /// Applies new filters, resets offset to 0, and replaces current items.
  Future<void> applyFilters(AlertsFilter filter) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final response = await ref.read(alertsRepositoryProvider).getAlerts(
            sensorId: filter.sensorId,
            deviceId: filter.deviceId,
            metric: filter.metric,
            alertType: filter.alertType,
            from: filter.from,
            to: filter.to,
            limit: 50,
            offset: 0,
          );
      return AlertsState(
        items: response.items,
        total: response.total,
        limit: response.limit,
        offset: 0,
        filter: filter,
      );
    });
  }

  /// Loads the next page of results and appends items to the current list.
  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || !currentState.hasMore) return;

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final nextOffset = currentState.offset + currentState.items.length;
      final filter = currentState.filter;
      final response = await ref.read(alertsRepositoryProvider).getAlerts(
            sensorId: filter.sensorId,
            deviceId: filter.deviceId,
            metric: filter.metric,
            alertType: filter.alertType,
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
