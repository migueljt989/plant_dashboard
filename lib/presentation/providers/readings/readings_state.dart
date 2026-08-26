import 'package:plant_dashboard/domain/entities/reading.dart';
import 'package:plant_dashboard/presentation/providers/readings/readings_filter.dart';

/// State model for the readings controller.
///
/// Holds the accumulated list of readings, pagination metadata,
/// the current filter, and a loading flag for "load more" operations.
class ReadingsState {
  final List<Reading> items;
  final int total;
  final int limit;
  final int offset;
  final ReadingsFilter filter;
  final bool isLoadingMore;

  const ReadingsState({
    this.items = const [],
    this.total = 0,
    this.limit = 50,
    this.offset = 0,
    this.filter = const ReadingsFilter(),
    this.isLoadingMore = false,
  });

  /// Whether there are more items to fetch beyond the current page.
  bool get hasMore => offset + items.length < total;

  /// Creates a copy of this state with the given fields replaced.
  ReadingsState copyWith({
    List<Reading>? items,
    int? total,
    int? limit,
    int? offset,
    ReadingsFilter? filter,
    bool? isLoadingMore,
  }) =>
      ReadingsState(
        items: items ?? this.items,
        total: total ?? this.total,
        limit: limit ?? this.limit,
        offset: offset ?? this.offset,
        filter: filter ?? this.filter,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}
