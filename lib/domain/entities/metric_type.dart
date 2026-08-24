enum MetricType {
  soilMoisture,
  airHumidity,
  temperature,
  uvIndex;

  /// Backend uses snake_case strings.
  static MetricType fromString(String value) {
    switch (value) {
      case 'soil_moisture':
        return MetricType.soilMoisture;
      case 'air_humidity':
        return MetricType.airHumidity;
      case 'temperature':
        return MetricType.temperature;
      case 'uv_index':
        return MetricType.uvIndex;
      default:
        return MetricType.temperature;
    }
  }

  /// Converts to the backend snake_case format.
  String toBackendString() {
    switch (this) {
      case MetricType.soilMoisture:
        return 'soil_moisture';
      case MetricType.airHumidity:
        return 'air_humidity';
      case MetricType.temperature:
        return 'temperature';
      case MetricType.uvIndex:
        return 'uv_index';
    }
  }

  /// Human-readable label for UI.
  String get label {
    switch (this) {
      case MetricType.soilMoisture:
        return 'Humedad de suelo';
      case MetricType.airHumidity:
        return 'Humedad ambiental';
      case MetricType.temperature:
        return 'Temperatura';
      case MetricType.uvIndex:
        return 'Índice UV';
    }
  }
}
