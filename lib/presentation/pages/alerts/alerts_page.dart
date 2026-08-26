import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/alert.dart';
import '../../../domain/entities/alert_type.dart';
import '../../../domain/entities/metric_type.dart';
import '../../providers/alerts/alerts_filter.dart';
import '../../providers/alerts/alerts_providers.dart';
import '../../providers/alerts/alerts_state.dart';
import '../../providers/device/device_providers.dart';
import '../../providers/sensor/sensor_management_providers.dart';

/// Página de alertas.
///
/// Muestra filtros por dispositivo/sensor/métrica/tipo de alerta/fecha
/// y una tabla paginada con las alertas registradas, coloreadas según tipo.
class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({super.key});

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  String? _selectedDeviceId;
  String? _selectedSensorId;
  MetricType? _selectedMetric;
  AlertType? _selectedAlertType;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(alertsControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Alertas',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildFilterRow(context),
              const SizedBox(height: 24),
              alertsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(error: error),
                data: (state) => _AlertsDataView(state: state),
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
                    loading: () =>
                        const _DropdownPlaceholder(label: 'Dispositivo'),
                    error: (_, _) =>
                        const _DropdownPlaceholder(label: 'Dispositivo'),
                    data: (devices) => DropdownButtonFormField<String>(
                      initialValue: _selectedDeviceId,
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
                        initialValue: _selectedSensorId,
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
                    initialValue: _selectedMetric,
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
                // Alert type dropdown
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<AlertType>(
                    initialValue: _selectedAlertType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de alerta',
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<AlertType>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      ...AlertType.values.map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              _alertTypeLabel(type),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedAlertType = value);
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
    final filter = AlertsFilter(
      deviceId: _selectedDeviceId,
      sensorId: _selectedSensorId,
      metric: _selectedMetric,
      alertType: _selectedAlertType,
      from: _fromDate,
      to: _toDate,
    );
    ref.read(alertsControllerProvider.notifier).applyFilters(filter);
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

  String _alertTypeLabel(AlertType type) {
    return switch (type) {
      AlertType.breach => 'Violación',
      AlertType.recovery => 'Recuperación',
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vista de datos (tabla + botón cargar más)
// ─────────────────────────────────────────────────────────────────────────────

class _AlertsDataView extends ConsumerWidget {
  const _AlertsDataView({required this.state});

  final AlertsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No se encontraron alertas.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Sensor')),
              DataColumn(label: Text('Métrica')),
              DataColumn(label: Text('Tipo')),
              DataColumn(label: Text('Valor'), numeric: true),
              DataColumn(label: Text('Umbrales')),
              DataColumn(label: Text('Fecha')),
            ],
            rows: state.items.map((alert) {
              return DataRow(
                color: WidgetStateProperty.all(
                  _rowColor(alert.alertType, colorScheme),
                ),
                cells: [
                  DataCell(Text(alert.sensorName)),
                  DataCell(Text(alert.metric.label)),
                  DataCell(Text(_alertTypeLabel(alert.alertType))),
                  DataCell(Text('${alert.value} ${alert.unit}')),
                  DataCell(Text(_breachedBoundInfo(alert))),
                  DataCell(Text(_formatDateTime(alert.triggeredAt))),
                ],
              );
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
                        .read(alertsControllerProvider.notifier)
                        .loadMore(),
                    child: const Text('Cargar más'),
                  ),
          ),
        ],
      ],
    );
  }

  Color _rowColor(AlertType type, ColorScheme colorScheme) {
    return switch (type) {
      AlertType.breach => colorScheme.errorContainer,
      AlertType.recovery => Colors.green.withValues(alpha: 0.08),
    };
  }

  String _alertTypeLabel(AlertType type) {
    return switch (type) {
      AlertType.breach => 'Violación',
      AlertType.recovery => 'Recuperación',
    };
  }

  String _breachedBoundInfo(Alert alert) {
    if (alert.breachedBound == null) return '-';
    return 'Mín: ${alert.minOk} / Máx: ${alert.maxOk}';
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
                      'No se pudieron cargar las alertas.\n\nDetalle: $error',
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
              onPressed: () => ref.invalidate(alertsControllerProvider),
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
