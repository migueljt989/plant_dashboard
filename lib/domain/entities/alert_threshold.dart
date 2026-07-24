/// Rango saludable para UN tipo de sensor (temperatura O humedad de suelo).
/// Los valores concretos se definen en alertThresholdProvider (hardcoded en el MVP).
class AlertThreshold {
  final double min;
  final double max;

  const AlertThreshold({required this.min, required this.max});

  /// Devuelve true si el valor está FUERA del rango saludable.
  bool isOutOfRange(double value) => value < min || value > max;
}
