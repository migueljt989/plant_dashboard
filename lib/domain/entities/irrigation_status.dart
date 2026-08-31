/// Estado actual del dispositivo de irrigación.
class IrrigationStatus {
  final bool connected;
  final bool irrigating;
  final DateTime? sessionStartedAt;

  const IrrigationStatus({
    required this.connected,
    required this.irrigating,
    this.sessionStartedAt,
  });
}
