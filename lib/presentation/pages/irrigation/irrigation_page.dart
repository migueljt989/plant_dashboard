import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/irrigation/irrigation_providers.dart';
import '../../providers/irrigation/irrigation_state.dart';
import 'widgets/camera_stream_link.dart';
import 'widgets/irrigation_controls.dart';
import 'widgets/irrigation_history_list.dart';
import 'widgets/irrigation_status_card.dart';
import 'widgets/stale_data_banner.dart';

/// Página principal de control de riego (ruta `/riego`).
///
/// Observa el `irrigationControllerProvider` y despacha entre los tres estados
/// del `AsyncValue`:
/// - `loading`: [CircularProgressIndicator] centrado (Requirement 6.5).
/// - `error`: si el error indica que no hay dispositivo de riego registrado,
///   muestra un mensaje informativo (Requirement 6.8); en cualquier otro caso
///   muestra un error de página completa con botón de reintento que invalida el
///   provider para re-obtener el estado (Requirement 6.6).
/// - `data`: compone verticalmente los widgets del feature dentro de un
///   [SingleChildScrollView] (Requirement 10.8, y la composición general de la
///   página):
///     1. [StaleDataBanner] — advertencia de datos obsoletos.
///     2. [IrrigationStatusCard] — estado de conexión / riego / duración.
///     3. [IrrigationControls] — botones iniciar / detener.
///     4. [CameraStreamLink] — enlace a la cámara en vivo (si aplica).
///     5. [IrrigationHistoryList] — historial paginado de sesiones.
///
/// El `Scaffold` lo aporta el `ShellRoute` del router, por lo que la página
/// devuelve directamente el contenido, siguiendo el patrón del resto de páginas
/// del proyecto (p. ej. `AlertsPage`).
class IrrigationPage extends ConsumerWidget {
  const IrrigationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(irrigationControllerProvider);

    return asyncState.when(
      // Requirement 6.5: indicador de carga centrado.
      loading: () => const Center(child: CircularProgressIndicator()),
      // Requirements 6.6 / 6.8: estado de error (o "sin dispositivo").
      error: (error, _) => _IrrigationError(error: error),
      // Composición de la vista de datos.
      data: (state) => _IrrigationDataView(state: state),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vista de datos: composición de sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _IrrigationDataView extends StatelessWidget {
  const _IrrigationDataView({required this.state});

  final IrrigationState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Riego',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              // Banner de datos obsoletos (visible solo si state.isStale).
              StaleDataBanner(isStale: state.isStale),
              if (state.isStale) const SizedBox(height: 16),
              // Tarjeta de estado del dispositivo.
              IrrigationStatusCard(status: state.status),
              const SizedBox(height: 16),
              // Controles iniciar / detener.
              const IrrigationControls(),
              // Enlace a cámara en vivo (se colapsa solo si no aplica).
              const CameraStreamLink(),
              const SizedBox(height: 24),
              // Historial paginado de sesiones.
              const IrrigationHistoryList(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estado de error / sin dispositivo
// ─────────────────────────────────────────────────────────────────────────────

class _IrrigationError extends ConsumerWidget {
  const _IrrigationError({required this.error});

  final Object error;

  /// Determina si el error corresponde a la ausencia de un dispositivo de riego
  /// registrado (Requirement 6.8). El controller lanza un `Exception` con este
  /// texto cuando `irrigationDeviceProvider` devuelve null.
  bool get _isNoDevice =>
      error.toString().toLowerCase().contains('dispositivo de riego');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Requirement 6.8: no hay dispositivo de riego registrado → mensaje
    // informativo, sin botón de reintento (no hay nada que reintentar).
    if (_isNoDevice) {
      return const _NoDeviceMessage();
    }

    // Requirement 6.6: error genérico con botón de reintento que re-obtiene el
    // estado invalidando el provider.
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
                      'No se pudo cargar el estado del riego.\n\nDetalle: $error',
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
              onPressed: () => ref.invalidate(irrigationControllerProvider),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mensaje mostrado cuando no existe ningún dispositivo de riego registrado
/// (Requirement 6.8).
class _NoDeviceMessage extends StatelessWidget {
  const _NoDeviceMessage();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 48,
              color: theme.disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay dispositivo de riego registrado',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Registra un dispositivo de tipo riego para controlar el sistema '
              'desde aquí.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
