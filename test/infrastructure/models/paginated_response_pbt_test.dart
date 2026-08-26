import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect;
import 'package:plant_dashboard/infrastructure/models/paginated_response.dart';

/// Feature: readings-and-alerts, Property 4: PaginatedResponse parsing preserves items and metadata
/// Feature: readings-and-alerts, Property 5: PaginatedResponse hasMore correctness
/// Validates: Requirements 4.1, 4.2, 4.3
void main() {
  // Property 4: Parsing preserves items and metadata
  Glados<int>().test(
    'Feature: readings-and-alerts, Property 4: PaginatedResponse parsing preserves items and metadata',
    (seed) {
      final itemCount = (seed.abs() % 20) + 1; // 1-20 items
      final total = itemCount + (seed.abs() % 100); // total >= itemCount
      final limit = (seed.abs() % 50) + 1; // 1-50
      final offset = seed.abs() % 100; // 0-99

      // Build items as simple JSON maps
      final items = List.generate(
        itemCount,
        (i) => {'id': 'item_${seed}_$i', 'value': i},
      );

      final json = {
        'items': items,
        'pagination': {
          'total': total,
          'limit': limit,
          'offset': offset,
        },
      };

      final parsed = PaginatedResponse.fromJson(
        json,
        (itemJson) => itemJson, // identity parser
      );

      expect(parsed.items.length, equals(itemCount));
      expect(parsed.total, equals(total));
      expect(parsed.limit, equals(limit));
      expect(parsed.offset, equals(offset));
    },
  );

  // Property 5: hasMore correctness
  Glados2<int, int>().test(
    'Feature: readings-and-alerts, Property 5: PaginatedResponse hasMore correctness',
    (seed1, seed2) {
      final itemCount = (seed1.abs() % 50) + 1;
      final offset = seed1.abs() % 100;
      final total = seed2.abs() % 200;

      final response = PaginatedResponse<String>(
        items: List.generate(itemCount, (i) => 'item_$i'),
        total: total,
        limit: 50,
        offset: offset,
      );

      expect(response.hasMore, equals(offset + itemCount < total));
    },
  );
}
