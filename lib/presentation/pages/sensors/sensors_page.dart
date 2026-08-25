import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/device.dart';
import '../../../domain/entities/device_type.dart';
import '../../../domain/entities/metric_type.dart';
import '../../../domain/entities/sensor.dart';
import '../../providers/device/device_providers.dart';
import '../../providers/sensor/sensor_management_providers.dart';
import '../../providers/sensor/sensors_by_device_provider.dart';
import '../../widgets/sensor_tile.dart';

/// Página de gestión de sensores.
///
/// Muestra los sensores agrupados por dispositivo, permite crear nuevos
/// sensores y editar los existentes.
class SensorsPage extends ConsumerWidget {
  const SensorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedAsync = ref.watch(sensorsByDeviceProvider);
    final devicesAsync = ref.watch(devicesControllerProvider);

    return Scaffold(
      body: groupedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(error: error),
        data: (grouped) {
          final deviceMap = <String, Device>{};
          devicesAsync.whenData((devices) {
            for (final device in devices) {
              deviceMap[device.id] = device;
            }
          });
          return _GroupedSensorsList(
            grouped: grouped,
            deviceMap: deviceMap,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Crear sensor'),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final devicesAsync = ref.read(devicesControllerProvider);
    final activeDevices = <Device>[];
    devicesAsync.whenData((devices) {
      activeDevices.addAll(devices.where((d) => d.isActive));
    });

    if (activeDevices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay dispositivos activos para asignar.')),
      );
      return;
    }

    final result = await showDialog<_CreateSensorResult>(
      context: context,
      builder: (_) => _CreateSensorDialog(activeDevices: activeDevices),
    );

    if (result == null || !context.mounted) return;

    try {
      await ref.read(sensorsControllerProvider.notifier).createSensor(
            deviceId: result.deviceId,
            name: result.name,
            metric: result.metric,
            minOk: result.minOk,
            maxOk: result.maxOk,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear sensor: $e')),
      );
    }
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
                      'No se pudo cargar la lista de sensores.\n\nDetalle: $error',
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
              onPressed: () => ref.invalidate(sensorsControllerProvider),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lista de sensores agrupados por dispositivo
// ─────────────────────────────────────────────────────────────────────────────

class _GroupedSensorsList extends ConsumerWidget {
  const _GroupedSensorsList({
    required this.grouped,
    required this.deviceMap,
  });

  final Map<String, List<Sensor>> grouped;
  final Map<String, Device> deviceMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (grouped.isEmpty) {
      return const Center(
        child: Text('No hay sensores registrados.'),
      );
    }

    final deviceIds = grouped.keys.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sensores',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ...deviceIds.map((deviceId) {
                final device = deviceMap[deviceId];
                final sensors = grouped[deviceId]!;
                return _DeviceGroup(
                  deviceName: device?.name ?? 'Dispositivo desconocido',
                  deviceType: device?.type,
                  sensors: sensors,
                  onEditSensor: (sensor) =>
                      _showEditDialog(context, ref, sensor),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
      BuildContext context, WidgetRef ref, Sensor sensor) async {
    final result = await showDialog<_EditSensorResult>(
      context: context,
      builder: (_) => _EditSensorDialog(sensor: sensor),
    );

    if (result == null || !context.mounted) return;

    String? newName;
    double? newMinOk;
    double? newMaxOk;
    bool hasChanges = false;

    if (result.name != sensor.name) {
      newName = result.name;
      hasChanges = true;
    }
    if (result.minOk != sensor.minOk) {
      newMinOk = result.minOk;
      hasChanges = true;
    }
    if (result.maxOk != sensor.maxOk) {
      newMaxOk = result.maxOk;
      hasChanges = true;
    }

    if (!hasChanges) return;

    try {
      await ref.read(sensorsControllerProvider.notifier).updateSensor(
            sensorId: sensor.id,
            name: newName,
            minOk: newMinOk,
            maxOk: newMaxOk,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar sensor: $e')),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grupo de sensores bajo un dispositivo
// ─────────────────────────────────────────────────────────────────────────────

class _DeviceGroup extends StatelessWidget {
  const _DeviceGroup({
    required this.deviceName,
    required this.deviceType,
    required this.sensors,
    required this.onEditSensor,
  });

  final String deviceName;
  final DeviceType? deviceType;
  final List<Sensor> sensors;
  final void Function(Sensor sensor) onEditSensor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header del dispositivo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _iconForDeviceType(deviceType),
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  deviceName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${sensors.length} ${sensors.length == 1 ? 'sensor' : 'sensores'})',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Lista de sensores
          ...sensors.map(
            (sensor) => SensorTile(
              sensor: sensor,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () => onEditSensor(sensor),
                    child: const Text('Editar'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForDeviceType(DeviceType? type) {
    switch (type) {
      case DeviceType.sensor:
        return Icons.sensors;
      case DeviceType.camera:
        return Icons.videocam;
      case DeviceType.irrigation:
        return Icons.water_drop;
      case null:
        return Icons.device_unknown;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Diálogo de creación de sensor
// ─────────────────────────────────────────────────────────────────────────────

class _CreateSensorResult {
  final String deviceId;
  final String name;
  final MetricType metric;
  final double? minOk;
  final double? maxOk;

  const _CreateSensorResult({
    required this.deviceId,
    required this.name,
    required this.metric,
    this.minOk,
    this.maxOk,
  });
}

class _CreateSensorDialog extends StatefulWidget {
  const _CreateSensorDialog({required this.activeDevices});

  final List<Device> activeDevices;

  @override
  State<_CreateSensorDialog> createState() => _CreateSensorDialogState();
}

class _CreateSensorDialogState extends State<_CreateSensorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minOkController = TextEditingController();
  final _maxOkController = TextEditingController();
  late String _selectedDeviceId;
  MetricType _selectedMetric = MetricType.temperature;

  @override
  void initState() {
    super.initState();
    _selectedDeviceId = widget.activeDevices.first.id;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minOkController.dispose();
    _maxOkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear sensor'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedDeviceId,
                  decoration: const InputDecoration(
                    labelText: 'Dispositivo',
                  ),
                  items: widget.activeDevices.map((device) {
                    return DropdownMenuItem(
                      value: device.id,
                      child: Text(device.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedDeviceId = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del sensor',
                    hintText: 'Ej: Sensor de temperatura principal',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    if (value.trim().length > 255) {
                      return 'El nombre no puede exceder 255 caracteres';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MetricType>(
                  initialValue: _selectedMetric,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de métrica',
                  ),
                  items: MetricType.values.map((metric) {
                    return DropdownMenuItem(
                      value: metric,
                      child: Text(metric.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedMetric = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minOkController,
                  decoration: const InputDecoration(
                    labelText: 'Mínimo aceptable (opcional)',
                    hintText: 'Ej: 18.0',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (double.tryParse(value.trim()) == null) {
                        return 'Ingresa un número válido';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxOkController,
                  decoration: const InputDecoration(
                    labelText: 'Máximo aceptable (opcional)',
                    hintText: 'Ej: 30.0',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (double.tryParse(value.trim()) == null) {
                        return 'Ingresa un número válido';
                      }
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Crear'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final minOkText = _minOkController.text.trim();
      final maxOkText = _maxOkController.text.trim();

      Navigator.of(context).pop(
        _CreateSensorResult(
          deviceId: _selectedDeviceId,
          name: _nameController.text.trim(),
          metric: _selectedMetric,
          minOk: minOkText.isNotEmpty ? double.parse(minOkText) : null,
          maxOk: maxOkText.isNotEmpty ? double.parse(maxOkText) : null,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Diálogo de edición de sensor
// ─────────────────────────────────────────────────────────────────────────────

class _EditSensorResult {
  final String name;
  final double? minOk;
  final double? maxOk;

  const _EditSensorResult({
    required this.name,
    this.minOk,
    this.maxOk,
  });
}

class _EditSensorDialog extends StatefulWidget {
  const _EditSensorDialog({required this.sensor});

  final Sensor sensor;

  @override
  State<_EditSensorDialog> createState() => _EditSensorDialogState();
}

class _EditSensorDialogState extends State<_EditSensorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _minOkController;
  late final TextEditingController _maxOkController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.sensor.name);
    _minOkController = TextEditingController(
      text: widget.sensor.minOk != null
          ? _formatDouble(widget.sensor.minOk!)
          : '',
    );
    _maxOkController = TextEditingController(
      text: widget.sensor.maxOk != null
          ? _formatDouble(widget.sensor.maxOk!)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minOkController.dispose();
    _maxOkController.dispose();
    super.dispose();
  }

  String _formatDouble(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar sensor'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del sensor',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  if (value.trim().length > 255) {
                    return 'El nombre no puede exceder 255 caracteres';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minOkController,
                decoration: const InputDecoration(
                  labelText: 'Mínimo aceptable (vacío = sin límite)',
                  hintText: 'Dejar vacío para quitar el límite',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (double.tryParse(value.trim()) == null) {
                      return 'Ingresa un número válido';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxOkController,
                decoration: const InputDecoration(
                  labelText: 'Máximo aceptable (vacío = sin límite)',
                  hintText: 'Dejar vacío para quitar el límite',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (double.tryParse(value.trim()) == null) {
                      return 'Ingresa un número válido';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final minOkText = _minOkController.text.trim();
      final maxOkText = _maxOkController.text.trim();

      Navigator.of(context).pop(
        _EditSensorResult(
          name: _nameController.text.trim(),
          minOk: minOkText.isNotEmpty ? double.parse(minOkText) : null,
          maxOk: maxOkText.isNotEmpty ? double.parse(maxOkText) : null,
        ),
      );
    }
  }
}
