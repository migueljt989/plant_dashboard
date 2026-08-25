import 'package:flutter/material.dart';

import '../../domain/entities/metric_type.dart';
import '../../domain/entities/sensor.dart';

/// Widget compacto reutilizable que muestra la info básica de un sensor.
///
/// Se usa en:
/// - La página de sensores (agrupados por dispositivo).
/// - La página de dispositivos (dentro de un ExpansionTile).
///
/// No incluye acciones (editar/revocar) — esas las agrega cada página
/// según su contexto.
class SensorTile extends StatelessWidget {
  const SensorTile({
    required this.sensor,
    this.trailing,
    this.onTap,
    super.key,
  });

  final Sensor sensor;

  /// Widget opcional a la derecha (ej. chip de estado, botón de editar).
  final Widget? trailing;

  /// Callback opcional al tocar la tile.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      leading: Icon(
        _iconForMetric(sensor.metric),
        color: colorScheme.primary,
      ),
      title: Text(
        sensor.name,
        style: textTheme.titleSmall,
      ),
      subtitle: Text(
        '${sensor.metric.label} (${sensor.unit})'
        '${_thresholdText(sensor)}',
      ),
      trailing: trailing ??
          Chip(
            label: Text(
              sensor.isActive ? 'Activo' : 'Inactivo',
              style: TextStyle(
                color: sensor.isActive
                    ? Colors.green.shade900
                    : Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
            backgroundColor: sensor.isActive
                ? Colors.green.shade100
                : Colors.grey.shade200,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
      onTap: onTap,
    );
  }

  String _thresholdText(Sensor sensor) {
    final min = _formatValue(sensor.minOk);
    final max = _formatValue(sensor.maxOk);
    if (min == '—' && max == '—') return '';
    return ' · Rango: $min – $max';
  }

  String _formatValue(double? value) {
    if (value == null) return '—';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  static IconData _iconForMetric(MetricType metric) {
    switch (metric) {
      case MetricType.soilMoisture:
        return Icons.water_drop;
      case MetricType.airHumidity:
        return Icons.cloud;
      case MetricType.temperature:
        return Icons.thermostat;
      case MetricType.uvIndex:
        return Icons.wb_sunny;
    }
  }
}
