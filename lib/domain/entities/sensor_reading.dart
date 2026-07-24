class SensorReading {
  final String deviceId;
  final double temperature;
  final double soilMoisture;
  final DateTime recordedAt;

  const SensorReading({
    required this.deviceId,
    required this.temperature,
    required this.soilMoisture,
    required this.recordedAt,
  });
}
