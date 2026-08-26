enum DeliveryStatus {
  pending,
  sent,
  failed,
  skipped;

  static DeliveryStatus fromString(String value) => switch (value) {
    'pending' => DeliveryStatus.pending,
    'sent' => DeliveryStatus.sent,
    'failed' => DeliveryStatus.failed,
    'skipped' => DeliveryStatus.skipped,
    _ => DeliveryStatus.pending,
  };

  String toBackendString() => name;
}
