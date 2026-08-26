class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int limit;
  final int offset;

  const PaginatedResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  bool get hasMore => offset + items.length < total;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    final itemsList = json['items'] as List<dynamic>;
    return PaginatedResponse(
      items: itemsList
          .map((e) => itemParser(e as Map<String, dynamic>))
          .toList(),
      total: pagination['total'] as int,
      limit: pagination['limit'] as int,
      offset: pagination['offset'] as int,
    );
  }
}
