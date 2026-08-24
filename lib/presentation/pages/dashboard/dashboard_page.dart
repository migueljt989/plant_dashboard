import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/alert_threshold.dart';
import '../../../domain/entities/sensor_reading.dart';
import '../../providers/sensor/sensor_providers.dart';
import '../../widgets/history_chart.dart';
import '../../widgets/sensor_value_card.dart';

/// ID del dispositivo usado en el MVP.
/// Coincide con el JSON fake (`assets/fake_sensor_data.json`).
const _deviceId = 'device-1';

/// Dashboard principal: muestra la última lectura de temperatura y humedad de
/// suelo en tiempo real, con indicadores visuales de alerta.
///
/// Requisito 2.1: muestra la última lectura disponible al abrir el dashboard.
/// Requisito 2.2: se actualiza automáticamente vía [latestReadingProvider] (stream).
/// Requisito 2.3: si el stream falla, muestra un [_ErrorBanner] explícito.
/// Requisito 2.4: muestra la fecha/hora de la última lectura ([SensorReading.recordedAt]).
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingAsync = ref.watch(latestReadingProvider(_deviceId));
    final thresholds = ref.watch(alertThresholdProvider);

    return readingAsync.when(
      // ── Estado de carga ────────────────────────────────────────────
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando lecturas…'),
          ],
        ),
      ),

      // ── Estado de error (Requisito 2.3) ────────────────────────────
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ErrorBanner(
                message: _resolveErrorMessage(error),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                onPressed: () {
                  // Invalida el provider para forzar una nueva suscripción
                  // al stream (Requisito 2.3 — vía de recuperación).
                  ref.invalidate(latestReadingProvider(_deviceId));
                },
              ),
            ],
          ),
        ),
      ),

      // ── Estado con datos ───────────────────────────────────────────
      data: (reading) => _DashboardBody(
        reading: reading,
        thresholds: thresholds,
      ),
    );
  }

  /// Devuelve un mensaje de error legible para el usuario.
  static String _resolveErrorMessage(Object error) {
    return 'No se pudo obtener la lectura del sensor. '
        'Verifica la conexión e intenta de nuevo.\n\n'
        'Detalle: ${error.toString()}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget interno: cuerpo del dashboard cuando hay datos disponibles
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({
    required this.reading,
    required this.thresholds,
  });

  final SensorReading reading;
  final ({AlertThreshold temperature, AlertThreshold soilMoisture}) thresholds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Encabezado de sección ─────────────────────────────────
              Row(
                children: [
                  Icon(Icons.sensors, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  Text(
                    'Lectura en tiempo real',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // ── Fecha/hora de la última lectura (Requisito 2.4) ───────
              Text(
                'Última actualización: ${_formatDateTime(reading.recordedAt)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),

              // ── Tarjetas de sensores ──────────────────────────────────
              // En pantallas anchas se muestran lado a lado; en estrechas
              // se apilan verticalmente.
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 480) {
                    // Diseño horizontal para tablets/desktop
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SensorValueCard(
                            label: 'Temperatura',
                            value: reading.temperature,
                            unit: '°C',
                            threshold: thresholds.temperature,
                            icon: Icons.thermostat_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SensorValueCard(
                            label: 'Humedad de suelo',
                            value: reading.soilMoisture,
                            unit: '%',
                            threshold: thresholds.soilMoisture,
                            icon: Icons.water_drop_outlined,
                          ),
                        ),
                      ],
                    );
                  }

                  // Diseño vertical para pantallas estrechas
                  return Column(
                    children: [
                      SensorValueCard(
                        label: 'Temperatura',
                        value: reading.temperature,
                        unit: '°C',
                        threshold: thresholds.temperature,
                        icon: Icons.thermostat_outlined,
                      ),
                      const SizedBox(height: 16),
                      SensorValueCard(
                        label: 'Humedad de suelo',
                        value: reading.soilMoisture,
                        unit: '%',
                        threshold: thresholds.soilMoisture,
                        icon: Icons.water_drop_outlined,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // ── Chip de dispositivo ───────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(Icons.memory, size: 16),
                  label: Text(
                    'Dispositivo: ${reading.deviceId}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),

              // ── Sección de histórico ──────────────────────────────────
              _HistorySection(thresholds: thresholds),
            ],
          ),
        ),
      ),
    );
  }

  /// Formatea un [DateTime] como "dd/mm/aaaa HH:MM:SS" en hora local.
  ///
  /// No requiere el paquete `intl` — usa los métodos estándar de [DateTime].
  static String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute:$second';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sección de histórico: selector de rango + gráfica
// ─────────────────────────────────────────────────────────────────────────────

/// Sección que muestra el selector de rango de fechas y la gráfica histórica.
///
/// Requisito 3.1: muestra gráfica al seleccionar un rango.
/// Requisito 3.2: mensaje cuando no hay datos en el rango.
/// Requisito 3.3: temperatura y humedad diferenciadas en la misma vista.
class _HistorySection extends ConsumerWidget {
  const _HistorySection({required this.thresholds});

  final ({AlertThreshold temperature, AlertThreshold soilMoisture}) thresholds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRange = ref.watch(selectedDateRangeProvider);
    final historyAsync = ref.watch(
      sensorHistoryProvider(
        (deviceId: _deviceId, range: selectedRange),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Encabezado de sección ─────────────────────────────────────
        Row(
          children: [
            Icon(Icons.show_chart, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Text(
              'Histórico',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Selector de rango de fechas ───────────────────────────────
        _DateRangePicker(
          selectedRange: selectedRange,
          onRangeSelected: (range) {
            ref.read(selectedDateRangeProvider.notifier).setRange(range);
          },
        ),
        const SizedBox(height: 16),

        // ── Contenido: carga / error / gráfica ───────────────────────
        historyAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => _ErrorBanner(
            message:
                'No se pudo cargar el histórico.\nDetalle: ${error.toString()}',
          ),
          data: (readings) => HistoryChart(
            readings: readings,
            temperatureThreshold: thresholds.temperature,
            soilMoistureThreshold: thresholds.soilMoisture,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botón/tile del selector de rango de fechas
// ─────────────────────────────────────────────────────────────────────────────

class _DateRangePicker extends StatelessWidget {
  const _DateRangePicker({
    required this.selectedRange,
    required this.onRangeSelected,
  });

  final DateTimeRange selectedRange;
  final ValueChanged<DateTimeRange> onRangeSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pickRange(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(Icons.date_range_outlined, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rango de fechas',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatDate(selectedRange.start)}  →  ${_formatDate(selectedRange.end)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: selectedRange,
      locale: const Locale('es', 'MX'),
      helpText: 'Selecciona el rango',
      saveText: 'Aplicar',
      cancelText: 'Cancelar',
      builder: (context, child) => Theme(
        data: Theme.of(context),
        child: child!,
      ),
    );
    if (picked != null) {
      onRangeSelected(picked);
    }
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day/$month/$year';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget compartido: banner de error
// ─────────────────────────────────────────────────────────────────────────────

/// Banner de error visible que informa al usuario que la fuente de datos falló.
///
/// Requisito 2.3: muestra estado de error explícito, nunca datos congelados.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.signal_wifi_off, color: colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error de conexión',
                  style: TextStyle(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
