/// Registro de una sesión de riego (completada o en curso).
class IrrigationSession {
  final String id;
  final String deviceId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final String? stopReason;

  const IrrigationSession({
    required this.id,
    required this.deviceId,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
    this.stopReason,
  });
}
