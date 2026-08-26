enum BreachedBound {
  minOk,
  maxOk;

  /// Parses a snake_case string from the backend into a [BreachedBound].
  /// Falls back to [minOk] for unrecognized values.
  static BreachedBound fromString(String value) => switch (value) {
    'min_ok' => BreachedBound.minOk,
    'max_ok' => BreachedBound.maxOk,
    _ => BreachedBound.minOk,
  };

  /// Converts to the backend snake_case format.
  String toBackendString() => switch (this) {
    BreachedBound.minOk => 'min_ok',
    BreachedBound.maxOk => 'max_ok',
  };
}
