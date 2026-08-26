enum AlertType {
  breach,
  recovery;

  static AlertType fromString(String value) => switch (value) {
    'breach' => AlertType.breach,
    'recovery' => AlertType.recovery,
    _ => AlertType.breach,
  };

  String toBackendString() => name;
}
