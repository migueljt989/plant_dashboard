import '../../domain/entities/irrigation_session.dart';

/// DTO para una sesión de riego. Serialización JSON manual siguiendo el
/// esquema del backend (claves en snake_case), con mapeo a la entidad de
/// dominio [IrrigationSession] vía [toEntity].
class IrrigationSessionDto {
  final String id;
  final String deviceId;
  final String startedAt; // ISO-8601
  final String? endedAt; // ISO-8601 o null
  final int? durationSeconds;
  final String? stopReason;

  const IrrigationSessionDto({
    required this.id,
    required this.deviceId,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
    this.stopReason,
  });

  factory IrrigationSessionDto.fromJson(Map<String, dynamic> json) {
    final id = _requireString(json, 'id');
    final deviceId = _requireString(json, 'device_id');
    final startedAt = _requireString(json, 'started_at');
    final endedAt = _optionalString(json, 'ended_at');
    final durationSeconds = _optionalInt(json, 'duration_seconds');
    final stopReason = _optionalString(json, 'stop_reason');

    return IrrigationSessionDto(
      id: id,
      deviceId: deviceId,
      startedAt: startedAt,
      endedAt: endedAt,
      durationSeconds: durationSeconds,
      stopReason: stopReason,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_id': deviceId,
        'started_at': startedAt,
        'ended_at': endedAt,
        'duration_seconds': durationSeconds,
        'stop_reason': stopReason,
      };

  IrrigationSession toEntity() => IrrigationSession(
        id: id,
        deviceId: deviceId,
        startedAt: DateTime.parse(startedAt),
        endedAt: endedAt != null ? DateTime.parse(endedAt!) : null,
        durationSeconds: durationSeconds,
        stopReason: stopReason,
      );

  // --- Helpers de parseo con validación fail-fast (FormatException) ---

  static String _requireString(Map<String, dynamic> json, String key) {
    if (!json.containsKey(key) || json[key] == null) {
      throw FormatException('IrrigationSessionDto: campo requerido ausente: "$key"');
    }
    final value = json[key];
    if (value is! String) {
      throw FormatException(
          'IrrigationSessionDto: el campo "$key" debe ser String, se recibió ${value.runtimeType}');
    }
    return value;
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException(
          'IrrigationSessionDto: el campo "$key" debe ser String o null, se recibió ${value.runtimeType}');
    }
    return value;
  }

  static int? _optionalInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! int) {
      throw FormatException(
          'IrrigationSessionDto: el campo "$key" debe ser int o null, se recibió ${value.runtimeType}');
    }
    return value;
  }
}
