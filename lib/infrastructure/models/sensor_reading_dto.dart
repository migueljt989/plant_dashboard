import '../../domain/entities/sensor_reading.dart';

class SensorReadingDto {
  final String deviceId;
  final double temperature;
  final double soilMoisture;
  final String recordedAt; // ISO-8601

  const SensorReadingDto({
    required this.deviceId,
    required this.temperature,
    required this.soilMoisture,
    required this.recordedAt,
  });

  factory SensorReadingDto.fromJson(Map<String, dynamic> json) =>
      SensorReadingDto(
        deviceId: json['device_id'] as String,
        temperature: (json['temperature'] as num).toDouble(),
        soilMoisture: (json['soil_moisture'] as num).toDouble(),
        recordedAt: json['recorded_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'temperature': temperature,
        'soil_moisture': soilMoisture,
        'recorded_at': recordedAt,
      };

  SensorReading toEntity() => SensorReading(
        deviceId: deviceId,
        temperature: temperature,
        soilMoisture: soilMoisture,
        recordedAt: DateTime.parse(recordedAt),
      );
}
