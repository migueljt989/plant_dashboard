import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_theme.dart';
import '../../domain/entities/alert_threshold.dart';
import '../../domain/entities/sensor_reading.dart';

/// Gráfica histórica de temperatura y humedad de suelo.
///
/// Widget puro (StatelessWidget): no usa providers ni repositorios.
/// Recibe los datos ya resueltos y los renderiza.
///
/// Requisito 3.1: muestra lecturas del rango seleccionado.
/// Requisito 3.2: si no hay datos, muestra mensaje explicativo.
/// Requisito 3.3: temperatura y humedad de suelo en la misma vista,
///   diferenciadas por color (naranja vs azul) y leyenda.
class HistoryChart extends StatelessWidget {
  const HistoryChart({
    required this.readings,
    required this.temperatureThreshold,
    required this.soilMoistureThreshold,
    super.key,
  });

  final List<SensorReading> readings;
  final AlertThreshold temperatureThreshold;
  final AlertThreshold soilMoistureThreshold;

  // ── Colores de las series ────────────────────────────────────────────────
  static const _tempColor = Color(0xFFE65100); // naranja oscuro
  static const _moistureColor = Color(0xFF0277BD); // azul oscuro

  @override
  Widget build(BuildContext context) {
    // ── Requisito 3.2: sin datos → mensaje en lugar de gráfica vacía ───────
    if (readings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Builder(
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bar_chart_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sin datos para el rango seleccionado',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Ordenar por fecha ascendente para que el eje X tenga sentido
    final sorted = [...readings]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    final tempSpots = sorted
        .map((r) =>
            FlSpot(r.recordedAt.millisecondsSinceEpoch.toDouble(), r.temperature))
        .toList();

    final moistureSpots = sorted
        .map((r) =>
            FlSpot(r.recordedAt.millisecondsSinceEpoch.toDouble(), r.soilMoisture))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Leyenda ────────────────────────────────────────────────────────
        _Legend(),
        const SizedBox(height: 12),

        // ── Gráfica ────────────────────────────────────────────────────────
        SizedBox(
          height: 260,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 8),
            child: LineChart(
              _buildChartData(sorted, tempSpots, moistureSpots),
            ),
          ),
        ),

        // ── Rangos saludables (referencia textual) ─────────────────────────
        const SizedBox(height: 8),
        _ThresholdNote(
          temperatureThreshold: temperatureThreshold,
          soilMoistureThreshold: soilMoistureThreshold,
        ),
      ],
    );
  }

  LineChartData _buildChartData(
    List<SensorReading> sorted,
    List<FlSpot> tempSpots,
    List<FlSpot> moistureSpots,
  ) {
    // Calcular extremos del eje Y con algo de margen
    final allValues = sorted
        .expand((r) => [r.temperature, r.soilMoisture])
        .toList();
    final minY = (allValues.reduce((a, b) => a < b ? a : b) - 5)
        .clamp(0.0, double.infinity);
    final maxY = allValues.reduce((a, b) => a > b ? a : b) + 5;

    return LineChartData(
      // ── Líneas de umbral horizontal (referencia visual) ──────────────────
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: temperatureThreshold.max,
            color: _tempColor.withValues(alpha: 0.35),
            strokeWidth: 1,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topRight,
              labelResolver: (_) =>
                  'T max ${temperatureThreshold.max.toStringAsFixed(0)}°',
              style: const TextStyle(
                fontSize: 10,
                color: _tempColor,
              ),
            ),
          ),
          HorizontalLine(
            y: temperatureThreshold.min,
            color: _tempColor.withValues(alpha: 0.35),
            strokeWidth: 1,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.bottomRight,
              labelResolver: (_) =>
                  'T min ${temperatureThreshold.min.toStringAsFixed(0)}°',
              style: const TextStyle(
                fontSize: 10,
                color: _tempColor,
              ),
            ),
          ),
          HorizontalLine(
            y: soilMoistureThreshold.max,
            color: _moistureColor.withValues(alpha: 0.35),
            strokeWidth: 1,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.topLeft,
              labelResolver: (_) =>
                  'H max ${soilMoistureThreshold.max.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 10,
                color: _moistureColor,
              ),
            ),
          ),
          HorizontalLine(
            y: soilMoistureThreshold.min,
            color: _moistureColor.withValues(alpha: 0.35),
            strokeWidth: 1,
            dashArray: [6, 4],
            label: HorizontalLineLabel(
              show: true,
              alignment: Alignment.bottomLeft,
              labelResolver: (_) =>
                  'H min ${soilMoistureThreshold.min.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 10,
                color: _moistureColor,
              ),
            ),
          ),
        ],
      ),

      minY: minY,
      maxY: maxY,

      // ── Líneas de datos ──────────────────────────────────────────────────
      lineBarsData: [
        _buildLine(
          spots: tempSpots,
          color: _tempColor,
          dotColor: _tempColor,
        ),
        _buildLine(
          spots: moistureSpots,
          color: _moistureColor,
          dotColor: _moistureColor,
        ),
      ],

      // ── Eje X: etiquetas de fecha/hora ───────────────────────────────────
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: _xInterval(sorted),
            getTitlesWidget: (value, meta) {
              final dt =
                  DateTime.fromMillisecondsSinceEpoch(value.toInt()).toLocal();
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  _formatAxisDate(dt),
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => SideTitleWidget(
              meta: meta,
              child: Text(
                value.toStringAsFixed(0),
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),

      // ── Grid ─────────────────────────────────────────────────────────────
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (_) => FlLine(
          color: AppColors.surfaceAlt,
          strokeWidth: 1,
        ),
        getDrawingVerticalLine: (_) => FlLine(
          color: AppColors.surfaceAlt,
          strokeWidth: 1,
        ),
      ),

      // ── Borde ─────────────────────────────────────────────────────────────
      borderData: FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(color: AppColors.surfaceAlt),
          left: BorderSide(color: AppColors.surfaceAlt),
        ),
      ),

      // ── Tooltip al tocar ─────────────────────────────────────────────────
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final isTemp = spot.barIndex == 0;
              final label = isTemp
                  ? '${spot.y.toStringAsFixed(1)} °C'
                  : '${spot.y.toStringAsFixed(1)} %';
              return LineTooltipItem(
                label,
                TextStyle(
                  color: isTemp ? _tempColor : _moistureColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  LineChartBarData _buildLine({
    required List<FlSpot> spots,
    required Color color,
    required Color dotColor,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: 3,
          color: dotColor,
          strokeWidth: 1.5,
          strokeColor: AppColors.background,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.07),
      ),
    );
  }

  /// Calcula el intervalo de etiquetas en el eje X para no saturarlo.
  double _xInterval(List<SensorReading> sorted) {
    if (sorted.length < 2) return 1;
    final spanMs = sorted.last.recordedAt.millisecondsSinceEpoch -
        sorted.first.recordedAt.millisecondsSinceEpoch;
    // Queremos ~4-6 etiquetas
    return (spanMs / 5).ceilToDouble();
  }

  /// Formatea una fecha para el eje X: "dd/mm HH:mm".
  static String _formatAxisDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month\n$hour:$minute';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Leyenda de la gráfica
// ─────────────────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 20,
      runSpacing: 6,
      children: [
        _LegendItem(
          color: HistoryChart._tempColor,
          label: 'Temperatura (°C)',
        ),
        _LegendItem(
          color: HistoryChart._moistureColor,
          label: 'Humedad de suelo (%)',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nota de rangos saludables
// ─────────────────────────────────────────────────────────────────────────────

class _ThresholdNote extends StatelessWidget {
  const _ThresholdNote({
    required this.temperatureThreshold,
    required this.soilMoistureThreshold,
  });

  final AlertThreshold temperatureThreshold;
  final AlertThreshold soilMoistureThreshold;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        Text(
          'Rango saludable — Temperatura: '
          '${temperatureThreshold.min.toStringAsFixed(0)}–'
          '${temperatureThreshold.max.toStringAsFixed(0)} °C',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          'Humedad de suelo: '
          '${soilMoistureThreshold.min.toStringAsFixed(0)}–'
          '${soilMoistureThreshold.max.toStringAsFixed(0)} %',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
