import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers/irrigation/irrigation_providers.dart';

/// Botón "Ver Cámara en Vivo" que enlaza al stream de la cámara vinculada al
/// dispositivo de riego.
///
/// Visibilidad (Requirements 8.1, 8.3, 8.4, 8.5): el botón se muestra únicamente
/// cuando el dispositivo está regando (`status.irrigating == true`) y la última
/// respuesta de comando almacenada en el estado indica que el streaming está
/// disponible (`cameraStreamingAvailable == true`) con un `cameraDeviceId` no
/// nulo. En cualquier otro caso el widget se colapsa (no renderiza nada).
///
/// Como el `cameraDeviceId` se lee del estado del controller
/// (`lastCommandResponse`), el botón persiste al navegar de vuelta a la página
/// mientras el riego siga activo (Requirement 8.5).
///
/// Al pulsarlo navega a `/camaras/stream/:cameraDeviceId` (Requirement 8.2).
class CameraStreamLink extends ConsumerWidget {
  const CameraStreamLink({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(irrigationControllerProvider);
    final state = stateAsync.value;

    // Sin datos aún: nada que mostrar.
    if (state == null) return const SizedBox.shrink();

    final response = state.lastCommandResponse;
    final cameraDeviceId = response?.cameraDeviceId;

    // Requirements 8.1 / 8.3 / 8.4 / 8.5: mostrar solo si está regando, el
    // streaming está disponible y hay un cameraDeviceId no nulo.
    final shouldShow = state.status.irrigating &&
        response != null &&
        response.cameraStreamingAvailable &&
        cameraDeviceId != null &&
        cameraDeviceId.isNotEmpty;

    if (!shouldShow) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: OutlinedButton.icon(
        onPressed: () => context.push('/camaras/stream/$cameraDeviceId'),
        icon: const Icon(Icons.videocam_outlined),
        label: const Text('Ver Cámara en Vivo'),
      ),
    );
  }
}
