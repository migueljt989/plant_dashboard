import 'package:flutter/material.dart';

import '../../core/config/app_theme.dart';
import '../../domain/entities/alert_threshold.dart';

/// Tarjeta que muestra un valor de sensor con indicador visual de alerta.
///
/// El color del borde e ícono cambia según el estado del valor respecto al umbral:
/// - Verde   → dentro del rango saludable.
/// - Naranja → por encima del máximo.
/// - Rojo    → por debajo del mínimo.
///
/// El widget es puro: no toca ningún provider ni repositorio. Toda la lógica de
/// color/ícono es una función del `value` y el `threshold` recibidos.
///
/// Requisito 4.1: resalte visual cuando el valor está fuera de rango.
/// Requisito 4.2: los umbrales son configurables desde fuera (vienen de
///   [alertThresholdProvider], no están hardcodeados aquí).
class SensorValueCard extends StatelessWidget {
  const SensorValueCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.threshold,
    this.icon,
    super.key,
  });

  final String label;
  final double value;
  final String unit;
  final AlertThreshold threshold;

  /// Ícono opcional para identificar el tipo de sensor.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final _AlertStatus status = _evaluateStatus(value, threshold);

    final Color statusColor = switch (status) {
      _AlertStatus.ok => AppColors.ok,
      _AlertStatus.tooHigh => AppColors.warning,
      _AlertStatus.tooLow => AppColors.error,
    };

    final IconData statusIcon = switch (status) {
      _AlertStatus.ok => Icons.check_circle_outline,
      _AlertStatus.tooHigh => Icons.arrow_upward,
      _AlertStatus.tooLow => Icons.arrow_downward,
    };

    final String statusLabel = switch (status) {
      _AlertStatus.ok => 'Normal',
      _AlertStatus.tooHigh => 'Alto',
      _AlertStatus.tooLow => 'Bajo',
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Encabezado: ícono + etiqueta ─────────────────────────────
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: statusColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Valor principal ───────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value.toStringAsFixed(1),
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    unit,
                    style: textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Indicador de estado + rango ───────────────────────────────
            Row(
              children: [
                Icon(statusIcon, size: 16, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusLabel,
                  style: textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Rango: ${threshold.min.toStringAsFixed(0)}–${threshold.max.toStringAsFixed(0)} $unit',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Clasifica el estado del [value] respecto al [threshold].
  static _AlertStatus _evaluateStatus(double value, AlertThreshold threshold) {
    if (value < threshold.min) return _AlertStatus.tooLow;
    if (value > threshold.max) return _AlertStatus.tooHigh;
    return _AlertStatus.ok;
  }
}

/// Estado de alerta de un valor respecto a su umbral.
enum _AlertStatus { ok, tooHigh, tooLow }
