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
    // El backend es inconsistente en cómo expone los metadatos de paginación:
    // algunos endpoints (readings, alerts) los anidan bajo la clave
    // `pagination`, mientras que otros (irrigation history, cameras photos) los
    // devuelven planos al nivel raíz. Soportamos ambos formatos: si existe el
    // objeto `pagination` se leen de ahí, si no, se leen del nivel raíz.
    final pagination = json['pagination'] as Map<String, dynamic>? ?? json;
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
