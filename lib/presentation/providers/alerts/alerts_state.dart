import 'package:plant_dashboard/domain/entities/alert.dart';
import 'package:plant_dashboard/presentation/providers/alerts/alerts_filter.dart';

/// State model for the alerts controller.
///
/// Holds the current list of alerts, pagination metadata, active filter,
/// and a flag indicating whether more items are being loaded.
class AlertsState {
  final List<Alert> items;
  final int total;
  final int limit;
  final int offset;
  final AlertsFilter filter;
  final bool isLoadingMore;

  const AlertsState({
    this.items = const [],
    this.total = 0,
    this.limit = 50,
    this.offset = 0,
    this.filter = const AlertsFilter(),
    this.isLoadingMore = false,
  });

  /// Whether there are more items available beyond the current page.
  bool get hasMore => offset + items.length < total;

  AlertsState copyWith({
    List<Alert>? items,
    int? total,
    int? limit,
    int? offset,
    AlertsFilter? filter,
    bool? isLoadingMore,
  }) =>
      AlertsState(
        items: items ?? this.items,
        total: total ?? this.total,
        limit: limit ?? this.limit,
        offset: offset ?? this.offset,
        filter: filter ?? this.filter,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}
