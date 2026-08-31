import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/irrigation_command_response.dart';
import '../../../domain/entities/irrigation_session.dart';
import '../../../domain/entities/irrigation_status.dart';
import '../../../domain/repositories/irrigation_repository.dart';
import '../../../infrastructure/models/paginated_response.dart';
import 'irrigation_providers.dart';
import 'irrigation_state.dart';

/// Intervalo del polling de estado (Requirement 9.1).
const _pollInterval = Duration(seconds: 10);

/// Intervalo del timer que refresca la duración transcurrida (Requirement 6.3).
const _durationTickInterval = Duration(seconds: 1);

/// Cantidad de items por página del historial (Requirements 10.3, 11.8).
const _historyPageSize = 20;

/// Error emitido cuando la lista de dispositivos cargó correctamente pero no
/// contiene ningún dispositivo de tipo riego (Requirement 6.8 / 11.6).
///
/// Es un tipo propio (y no un `Exception` genérico con un mensaje) para que la
/// UI pueda distinguir este caso con `is NoIrrigationDeviceException` en lugar
/// de inspeccionar el texto del error, que se rompe con cualquier cambio de
/// redacción o de idioma.
class NoIrrigationDeviceException implements Exception {
  const NoIrrigationDeviceException();

  @override
  String toString() => 'No hay ningún dispositivo de riego registrado';
}

/// Controlador del feature de riego.
///
/// Es `autoDispose`: al salir de la página se cancelan los timers de polling y
/// de duración, y el estado se limpia. Gestiona en un único estado inmutable el
/// status del dispositivo, la última respuesta de comando, el historial
/// paginado, el flag de datos obsoletos y el flag de comando en curso.
class IrrigationController extends AsyncNotifier<IrrigationState> {
  Timer? _pollTimer;
  Timer? _durationTimer;

  IrrigationRepository get _repo => ref.read(irrigationRepositoryProvider);

  /// Id del dispositivo de riego activo. Se resuelve en [build] y se conserva
  /// para las operaciones posteriores (comandos, polling, paginación).
  late String _deviceId;

  @override
  Future<IrrigationState> build() async {
    // Se usa `watch(...future)` y no `read`: así este controller espera de
    // verdad a que la lista de dispositivos cargue (en vez de interpretar
    // "todavía cargando" como "no hay dispositivo") y se reconstruye si la
    // lista cambia. Si la carga falla, el error se propaga y la UI muestra el
    // estado de error con reintento, no el mensaje de "sin dispositivo".
    final device = await ref.watch(irrigationDeviceProvider.future);

    // Guarda defensiva (Requirement 11.6). En la práctica es inalcanzable:
    // `IrrigationPage` solo construye este controller cuando ya confirmó que
    // hay un dispositivo de riego, precisamente para no lanzar desde el `build`
    // de un provider autoDispose.
    if (device == null) {
      throw const NoIrrigationDeviceException();
    }
    _deviceId = device.id;

    // Requirement 9.4 / 11.9: cancelar los timers al desmontar el provider.
    ref.onDispose(() {
      _pollTimer?.cancel();
      _durationTimer?.cancel();
    });

    // Requirements 10.8 / 11.5: status e historial se obtienen concurrentemente.
    final results = await Future.wait([
      _repo.getStatus(_deviceId),
      _repo.getHistory(_deviceId, limit: _historyPageSize, offset: 0),
    ]);

    final status = results[0] as IrrigationStatus;
    final historyResponse =
        results[1] as PaginatedResponse<IrrigationSession>;

    // Requirement 9.1: arrancar el polling tras el build exitoso.
    _startPolling();
    // Requirement 6.3: si ya está regando, arrancar el timer de duración.
    if (status.irrigating) {
      _startDurationTimer();
    }

    return IrrigationState(
      status: status,
      history: historyResponse.items,
      hasMore: historyResponse.hasMore,
    );
  }

  /// Arranca (o reinicia) el timer periódico de polling de estado.
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  /// Arranca el timer de 1s que fuerza un re-render para recalcular la duración
  /// transcurrida de la sesión activa. No cambia el status, solo re-emite el
  /// estado actual para que la UI recalcule el tiempo relativo a `now`.
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(_durationTickInterval, (_) {
      final current = state.value;
      if (current == null) return;
      // Re-emite una copia para disparar la reconstrucción de los listeners.
      state = AsyncData(current.copyWith());
    });
  }

  /// Cancela el timer de duración (cuando se detiene el riego).
  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  /// Ejecuta un ciclo de polling del estado (Requirements 9.2, 9.5, 9.6).
  Future<void> _poll() async {
    final current = state.value;
    if (current == null) return;

    try {
      final newStatus = await _repo.getStatus(_deviceId);

      // Requirement 9.5: éxito → resetear contador de fallos.
      final wasIrrigating = current.status.irrigating;
      state = AsyncData(current.copyWith(
        status: newStatus,
        consecutiveFailures: 0,
      ));

      // Requirement 9.2: gestionar la transición de `irrigating`.
      if (newStatus.irrigating && !wasIrrigating) {
        _startDurationTimer();
      } else if (!newStatus.irrigating && wasIrrigating) {
        _stopDurationTimer();
      }
    } catch (_) {
      // Requirements 9.5 / 9.6: fallo individual → mantener el último status,
      // incrementar el contador de fallos consecutivos. No se propaga error a
      // la UI y el polling sigue activo en el intervalo normal.
      state = AsyncData(current.copyWith(
        consecutiveFailures: current.consecutiveFailures + 1,
      ));
    }
  }

  /// Inicia el riego (Requirements 7.4, 7.7, 9.3, 11.7).
  ///
  /// Guarda la respuesta del comando, refresca el status inmediatamente y
  /// reinicia el timer de polling desde ese punto. Lanza la excepción al caller
  /// si el comando falla, para que la UI muestre la notificación de error.
  Future<void> startIrrigation() async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(isCommandInProgress: true));
    try {
      final response = await _repo.startIrrigation(_deviceId);
      await _applyCommandResponse(response);
    } finally {
      final latest = state.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(isCommandInProgress: false));
      }
    }
  }

  /// Detiene el riego (Requirements 7.5, 7.8, 9.3, 11.7).
  ///
  /// Guarda la respuesta del comando, refresca el status inmediatamente,
  /// reinicia el timer de polling y cancela el timer de duración.
  Future<void> stopIrrigation() async {
    final current = state.value;
    if (current == null) return;

    state = AsyncData(current.copyWith(isCommandInProgress: true));
    try {
      final response = await _repo.stopIrrigation(_deviceId);
      await _applyCommandResponse(response);
    } finally {
      final latest = state.value;
      if (latest != null) {
        state = AsyncData(latest.copyWith(isCommandInProgress: false));
      }
    }
  }

  /// Guarda la respuesta del comando, refresca el status dentro de 1s
  /// (Requirement 9.3), reinicia el timer de polling y sincroniza el timer de
  /// duración con el nuevo estado de `irrigating`.
  Future<void> _applyCommandResponse(
      IrrigationCommandResponse response) async {
    final base = state.value;
    if (base == null) return;

    // Refresco inmediato del status tras el comando exitoso.
    final newStatus = await _repo.getStatus(_deviceId);

    state = AsyncData(base.copyWith(
      status: newStatus,
      lastCommandResponse: response,
      consecutiveFailures: 0,
    ));

    // Requirement 9.3: reiniciar el timer de polling desde este punto.
    _startPolling();

    // Sincronizar el timer de duración con el nuevo estado.
    if (newStatus.irrigating) {
      _startDurationTimer();
    } else {
      _stopDurationTimer();
    }
  }

  /// Carga la siguiente página del historial y la anexa a la lista existente
  /// (Requirements 10.3, 11.8).
  Future<void> loadMoreHistory() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;

    final nextOffset = current.history.length;
    final page = await _repo.getHistory(
      _deviceId,
      limit: _historyPageSize,
      offset: nextOffset,
    );

    final latest = state.value;
    if (latest == null) return;

    state = AsyncData(latest.copyWith(
      history: [...latest.history, ...page.items],
      hasMore: page.hasMore,
    ));
  }
}
