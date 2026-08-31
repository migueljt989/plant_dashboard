import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/irrigation/irrigation_providers.dart';
import '../../../providers/irrigation/irrigation_state.dart';

/// Controles de inicio/paro del riego.
///
/// Muestra:
/// - "Iniciar Riego" cuando el dispositivo está conectado y no está regando
///   (Requirement 7.1).
/// - "Detener Riego" cuando el dispositivo está conectado y está regando
///   (Requirement 7.2).
/// - Un diálogo de confirmación antes de iniciar el riego, para prevenir la
///   activación accidental de la bomba (Requirement 7.3).
/// - Un indicador de carga dentro del botón mientras un comando está en curso,
///   con el botón deshabilitado para evitar envíos duplicados (Requirement 7.6).
/// - Los controles deshabilitados cuando el dispositivo está desconectado
///   (Requirement 7.7, y coherente con 6.7).
/// - Un SnackBar de error si el comando falla, visible hasta 8 segundos o hasta
///   que el usuario lo descarte, restaurando el botón a su estado previo
///   (Requirements 7.9, 7.10).
class IrrigationControls extends ConsumerWidget {
  const IrrigationControls({super.key});

  /// Duración máxima que permanece visible la notificación de error
  /// (Requirement 7.9).
  static const _errorSnackBarDuration = Duration(seconds: 8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(irrigationControllerProvider);

    // Solo renderizamos los controles cuando hay un estado de datos válido.
    // Los estados de carga/error de la página los maneja el widget superior.
    return asyncState.maybeWhen(
      data: (state) => _ControlsView(state: state),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _ControlsView extends ConsumerWidget {
  const _ControlsView({required this.state});

  final IrrigationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connected = state.status.connected;
    final irrigating = state.status.irrigating;
    final commandInProgress = state.isCommandInProgress;

    // Requirement 7.7: si el dispositivo está desconectado, los controles se
    // deshabilitan por completo.
    final enabled = connected && !commandInProgress;

    if (irrigating) {
      // Requirement 7.2: botón "Detener Riego" cuando está regando.
      return _CommandButton(
        label: 'Detener Riego',
        icon: Icons.stop_circle_outlined,
        loading: commandInProgress,
        onPressed: enabled ? () => _onStopPressed(context, ref) : null,
        isStop: true,
      );
    }

    // Requirement 7.1: botón "Iniciar Riego" cuando no está regando.
    return _CommandButton(
      label: 'Iniciar Riego',
      icon: Icons.play_circle_outline,
      loading: commandInProgress,
      onPressed: enabled ? () => _onStartPressed(context, ref) : null,
      isStop: false,
    );
  }

  /// Maneja la pulsación de "Iniciar Riego": muestra un diálogo de confirmación
  /// antes de enviar el comando (Requirement 7.3, 7.4).
  Future<void> _onStartPressed(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Iniciar riego'),
        content: const Text(
          '¿Confirmas que quieres iniciar el riego?\n\n'
          'Esto activará la bomba de agua del dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await _runCommand(
      context,
      ref,
      () => ref.read(irrigationControllerProvider.notifier).startIrrigation(),
      errorPrefix: 'No se pudo iniciar el riego',
    );
  }

  /// Maneja la pulsación de "Detener Riego": envía el comando directamente sin
  /// confirmación (detener siempre es seguro) (Requirement 7.5).
  Future<void> _onStopPressed(BuildContext context, WidgetRef ref) async {
    await _runCommand(
      context,
      ref,
      () => ref.read(irrigationControllerProvider.notifier).stopIrrigation(),
      errorPrefix: 'No se pudo detener el riego',
    );
  }

  /// Ejecuta un comando de riego y muestra un SnackBar de error si falla
  /// (Requirements 7.9, 7.10). El estado de carga y la restauración del botón
  /// los gestiona el controlador vía `isCommandInProgress`.
  Future<void> _runCommand(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() command, {
    required String errorPrefix,
  }) async {
    try {
      await command();
    } catch (error) {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        SnackBar(
          content: Text('$errorPrefix: $error'),
          duration: IrrigationControls._errorSnackBarDuration,
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Cerrar',
            textColor: Theme.of(context).colorScheme.onError,
            onPressed: messenger.hideCurrentSnackBar,
          ),
        ),
      );
    }
  }
}

/// Botón de comando con estado de carga integrado.
///
/// Cuando [loading] es true, muestra un [CircularProgressIndicator] en lugar del
/// icono y el botón queda deshabilitado (Requirement 7.6).
class _CommandButton extends StatelessWidget {
  const _CommandButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onPressed,
    required this.isStop,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback? onPressed;
  final bool isStop;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final child = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colorScheme.onPrimary,
            ),
          )
        : Icon(icon);

    final style = isStop
        ? FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          )
        : FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          );

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: child,
        label: Text(label),
      ),
    );
  }
}
