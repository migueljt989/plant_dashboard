import '../../domain/entities/irrigation_status.dart';

/// DTO para el estado actual del dispositivo de irrigación.
///
/// Mapea las claves snake_case del backend (`connected`, `irrigating`,
/// `session_started_at`) a campos camelCase. `sessionStartedAt` se guarda como
/// String ISO-8601 (o null) y se convierte a DateTime en [toEntity].
class IrrigationStatusDto {
  final bool connected;
  final bool irrigating;
  final String? sessionStartedAt;

  const IrrigationStatusDto({
    required this.connected,
    required this.irrigating,
    this.sessionStartedAt,
  });

  factory IrrigationStatusDto.fromJson(Map<String, dynamic> json) {
    final connected = json['connected'];
    if (connected == null) {
      throw const FormatException('Missing required field: connected');
    }
    if (connected is! bool) {
      throw FormatException(
        'Field "connected" must be a bool, got ${connected.runtimeType}',
      );
    }

    final irrigating = json['irrigating'];
    if (irrigating == null) {
      throw const FormatException('Missing required field: irrigating');
    }
    if (irrigating is! bool) {
      throw FormatException(
        'Field "irrigating" must be a bool, got ${irrigating.runtimeType}',
      );
    }

    final sessionStartedAt = json['session_started_at'];
    if (sessionStartedAt != null) {
      if (sessionStartedAt is! String) {
        throw FormatException(
          'Field "session_started_at" must be a String, '
          'got ${sessionStartedAt.runtimeType}',
        );
      }
      if (DateTime.tryParse(sessionStartedAt) == null) {
        throw FormatException(
          'Field "session_started_at" is not a valid ISO-8601 datetime: '
          '$sessionStartedAt',
        );
      }
    }

    return IrrigationStatusDto(
      connected: connected,
      irrigating: irrigating,
      sessionStartedAt: sessionStartedAt as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'connected': connected,
        'irrigating': irrigating,
        'session_started_at': sessionStartedAt,
      };

  IrrigationStatus toEntity() => IrrigationStatus(
        connected: connected,
        irrigating: irrigating,
        sessionStartedAt:
            sessionStartedAt != null ? DateTime.parse(sessionStartedAt!) : null,
      );
}
