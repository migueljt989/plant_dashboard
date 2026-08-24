import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/device.dart';
import '../../../domain/entities/device_type.dart';
import '../../providers/device/device_providers.dart';

/// Página de gestión de dispositivos.
///
/// Muestra la lista de dispositivos registrados con su estado,
/// permite registrar nuevos dispositivos y revocar los existentes.
class DevicesPage extends ConsumerWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesControllerProvider);

    return Scaffold(
      body: devicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(error: error),
        data: (devices) => _DevicesList(devices: devices),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegistrationDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registrar dispositivo'),
      ),
    );
  }

  Future<void> _showRegistrationDialog(
      BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_RegistrationResult>(
      context: context,
      builder: (_) => const _RegistrationDialog(),
    );

    if (result == null || !context.mounted) return;

    try {
      final registration = await ref
          .read(devicesControllerProvider.notifier)
          .registerDevice(result.name, result.type);

      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ApiKeyDialog(apiKey: registration.apiKey),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar dispositivo: $e')),
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
                  Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No se pudo cargar la lista de dispositivos.\n\nDetalle: $error',
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
              onPressed: () =>
                  ref.invalidate(devicesControllerProvider),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lista de dispositivos
// ─────────────────────────────────────────────────────────────────────────────

class _DevicesList extends StatelessWidget {
  const _DevicesList({required this.devices});

  final List<Device> devices;

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return const Center(
        child: Text('No hay dispositivos registrados.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Dispositivos',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ...devices.map((device) => _DeviceCard(device: device)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de dispositivo individual
// ─────────────────────────────────────────────────────────────────────────────

class _DeviceCard extends ConsumerWidget {
  const _DeviceCard({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icono del tipo de dispositivo
            Icon(
              _iconForType(device.type),
              size: 32,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 16),

            // Información del dispositivo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Creado: ${_formatDate(device.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Chip de estado
            Chip(
              label: Text(
                device.isActive ? 'Activo' : 'Revocado',
                style: TextStyle(
                  color: device.isActive
                      ? Colors.green.shade900
                      : Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
              backgroundColor: device.isActive
                  ? Colors.green.shade100
                  : Colors.grey.shade200,
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            const SizedBox(width: 8),

            // Botón de revocar
            TextButton(
              onPressed:
                  device.isActive ? () => _confirmRevoke(context, ref) : null,
              child: const Text('Revocar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRevoke(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revocar dispositivo'),
        content: Text(
          '¿Estás seguro de revocar "${device.name}"?\n\n'
          'El dispositivo dejará de poder enviar datos y no podrá reactivarse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Revocar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(devicesControllerProvider.notifier)
          .revokeDevice(device.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al revocar dispositivo: $e')),
      );
    }
  }

  IconData _iconForType(DeviceType type) {
    switch (type) {
      case DeviceType.sensor:
        return Icons.sensors;
      case DeviceType.camera:
        return Icons.videocam;
      case DeviceType.irrigation:
        return Icons.water_drop;
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day/$month/$year';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Diálogo de registro de dispositivo
// ─────────────────────────────────────────────────────────────────────────────

class _RegistrationResult {
  final String name;
  final DeviceType type;

  const _RegistrationResult({required this.name, required this.type});
}

class _RegistrationDialog extends StatefulWidget {
  const _RegistrationDialog();

  @override
  State<_RegistrationDialog> createState() => _RegistrationDialogState();
}

class _RegistrationDialogState extends State<_RegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DeviceType _selectedType = DeviceType.sensor;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar dispositivo'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del dispositivo',
                hintText: 'Ej: Sensor principal',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DeviceType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo de dispositivo',
              ),
              items: DeviceType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_labelForType(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Registrar'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(
        _RegistrationResult(
          name: _nameController.text.trim(),
          type: _selectedType,
        ),
      );
    }
  }

  String _labelForType(DeviceType type) {
    switch (type) {
      case DeviceType.sensor:
        return 'Sensor';
      case DeviceType.camera:
        return 'Cámara';
      case DeviceType.irrigation:
        return 'Riego';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Diálogo de API key (post-registro)
// ─────────────────────────────────────────────────────────────────────────────

class _ApiKeyDialog extends StatelessWidget {
  const _ApiKeyDialog({required this.apiKey});

  final String apiKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Dispositivo registrado'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Clave API del dispositivo:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              apiKey,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: apiKey));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clave copiada al portapapeles')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copiar'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.amber.shade800, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta clave solo se muestra una vez',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendido'),
        ),
      ],
    );
  }
}
