import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/metric_type.dart';
import '../../../domain/entities/reading.dart';
import '../../providers/device/device_providers.dart';
import '../../providers/readings/readings_filter.dart';
import '../../providers/readings/readings_providers.dart';
import '../../providers/readings/readings_state.dart';
import '../../providers/sensor/sensor_management_providers.dart';

/// Página de historial de lecturas.
///
/// Muestra la lectura más reciente, filtros por dispositivo/sensor/métrica/fecha
/// y una tabla paginada con las lecturas registradas.
class ReadingsPage extends ConsumerStatefulWidget {
  const ReadingsPage({super.key});

  @override
  ConsumerState<ReadingsPage> createState() => _ReadingsPageState();
}

class _ReadingsPageState extends ConsumerState<ReadingsPage> {
  String? _selectedDeviceId;
  String? _selectedSensorId;
  MetricType? _selectedMetric;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  Widget build(BuildContext context) {
    final readingsAsync = ref.watch(readingsControllerProvider);
    final latestAsync = ref.watch(latestReadingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Lecturas',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _LatestReadingCard(latestAsync: latestAsync),
              const SizedBox(height: 24),
              _buildFilterRow(context),
              const SizedBox(height: 24),
              readingsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(error: error),
                data: (state) => _ReadingsDataView(state: state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    final devicesAsync = ref.watch(devicesControllerProvider);
    final sensorsAsync = ref.watch(sensorsControllerProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtros',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // Device dropdown
                SizedBox(
                  width: 200,
                  child: devicesAsync.when(
                    loading: () => const _DropdownPlaceholder(
                        label: 'Dispositivo'),
                    error: (_, _) => const _DropdownPlaceholder(
                        label: 'Dispositivo'),
                    data: (devices) => DropdownButtonFormField<String>(
                      value: _selectedDeviceId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Dispositivo',
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        ...devices.map((device) => DropdownMenuItem(
                              value: device.id,
                              child: Text(
                                device.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDeviceId = value;
                          // Reset sensor if it doesn't belong to the new device
                          _selectedSensorId = null;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                ),
                // Sensor dropdown
                SizedBox(
                  width: 200,
                  child: sensorsAsync.when(
                    loading: () =>
                        const _DropdownPlaceholder(label: 'Sensor'),
                    error: (_, _) =>
                        const _DropdownPlaceholder(label: 'Sensor'),
                    data: (sensors) {
                      final filteredSensors = _selectedDeviceId != null
                          ? sensors
                              .where(
                                  (s) => s.deviceId == _selectedDeviceId)
                              .toList()
                          : sensors;
                      return DropdownButtonFormField<String>(
                        key: ValueKey('sensor-$_selectedDeviceId'),
                        value: _selectedSensorId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Sensor',
                          isDense: true,
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Todos'),
                          ),
                          ...filteredSensors
                              .map((sensor) => DropdownMenuItem(
                                    value: sensor.id,
                                    child: Text(
                                      sensor.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedSensorId = value);
                          _applyFilters();
                        },
                      );
                    },
                  ),
                ),
                // Metric dropdown
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<MetricType>(
                    value: _selectedMetric,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Métrica',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<MetricType>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ...MetricType.values.map((metric) => DropdownMenuItem(
                            value: metric,
                            child: Text(
                              metric.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedMetric = value);
                      _applyFilters();
                    },
                  ),
                ),
                // Date range picker button
                SizedBox(
                  width: 220,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.date_range, size: 18),
                    label: Text(
                      _fromDate != null && _toDate != null
                          ? '${_formatDate(_fromDate!)} – ${_formatDate(_toDate!)}'
                          : 'Rango de fechas',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () => _pickDateRange(context),
                  ),
                ),
                // Clear date filter
                if (_fromDate != null || _toDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: 'Limpiar fechas',
                    onPressed: () {
                      setState(() {
                        _fromDate = null;
                        _toDate = null;
                      });
                      _applyFilters();
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilters() {
    final filter = ReadingsFilter(
      deviceId: _selectedDeviceId,
      sensorId: _selectedSensorId,
      metric: _selectedMetric,
      from: _fromDate,
      to: _toDate,
    );
    ref.read(readingsControllerProvider.notifier).applyFilters(filter);
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      helpText: 'Seleccionar rango de fechas',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Guardar',
    );

    if (result != null) {
      setState(() {
        _fromDate = result.start;
        _toDate = result.end;
      });
      _applyFilters();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de última lectura
// ─────────────────────────────────────────────────────────────────────────────

class _LatestReadingCard extends StatelessWidget {
  const _LatestReadingCard({required this.latestAsync});

  final AsyncValue<Reading?> latestAsync;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sensors, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Última lectura',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            latestAsync.when(
              loading: () => Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cargando...',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              error: (_, _) => Text(
                'Sin datos',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              data: (reading) {
                if (reading == null) {
                  return Text(
                    'Sin datos',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reading.sensorName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${reading.metric.label}: ${reading.value} ${reading.unit}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDateTime(reading.recordedAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vista de datos (tabla + botón cargar más)
// ─────────────────────────────────────────────────────────────────────────────

class _ReadingsDataView extends ConsumerWidget {
  const _ReadingsDataView({required this.state});

  final ReadingsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No se encontraron lecturas.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Sensor')),
              DataColumn(label: Text('Métrica')),
              DataColumn(label: Text('Valor'), numeric: true),
              DataColumn(label: Text('Fecha')),
            ],
            rows: state.items.map((reading) {
              return DataRow(cells: [
                DataCell(Text(reading.sensorName)),
                DataCell(Text(reading.metric.label)),
                DataCell(Text('${reading.value} ${reading.unit}')),
                DataCell(Text(_formatDateTime(reading.recordedAt))),
              ]);
            }).toList(),
          ),
        ),
        if (state.hasMore) ...[
          const SizedBox(height: 16),
          Center(
            child: state.isLoadingMore
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  )
                : OutlinedButton(
                    onPressed: () => ref
                        .read(readingsControllerProvider.notifier)
                        .loadMore(),
                    child: const Text('Cargar más'),
                  ),
          ),
        ],
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estado de error con botón de reintento
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends ConsumerWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline,
                      color: colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No se pudieron cargar las lecturas.\n\nDetalle: $error',
                      style: TextStyle(color: colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: () => ref.invalidate(readingsControllerProvider),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placeholder para dropdowns mientras cargan
// ─────────────────────────────────────────────────────────────────────────────

class _DropdownPlaceholder extends StatelessWidget {
  const _DropdownPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
      ),
      child: const SizedBox(
        height: 20,
        child: Center(child: LinearProgressIndicator()),
      ),
    );
  }
}
