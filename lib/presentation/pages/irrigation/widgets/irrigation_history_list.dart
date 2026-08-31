import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/irrigation_session.dart';
import '../../../providers/irrigation/irrigation_providers.dart';

/// Sección de historial de sesiones de riego (Requirement 10).
///
/// Muestra las sesiones en orden cronológico inverso (la más reciente primero),
/// un botón "Cargar más" cuando hay páginas adicionales, un indicador de carga
/// mientras se obtiene la siguiente página, un estado de error con botón de
/// reintento, y un mensaje de estado vacío cuando no hay sesiones.
///
/// El historial y el flag `hasMore` provienen del `irrigationControllerProvider`.
/// El estado local de carga/error corresponde únicamente a la operación de
/// "cargar más" (Requirements 10.5, 10.6), ya que el controller no lo expone.
class IrrigationHistoryList extends ConsumerStatefulWidget {
  const IrrigationHistoryList({super.key});

  @override
  ConsumerState<IrrigationHistoryList> createState() =>
      _IrrigationHistoryListState();
}

class _IrrigationHistoryListState
    extends ConsumerState<IrrigationHistoryList> {
  /// Si la petición de "cargar más" está en curso (Requirement 10.5).
  bool _isLoadingMore = false;

  /// Mensaje de error de la última petición de "cargar más", o null si no hubo
  /// error (Requirement 10.6).
  String? _loadMoreError;

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });

    try {
      await ref.read(irrigationControllerProvider.notifier).loadMoreHistory();
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    } catch (e) {
      if (!mounted) return;
      // Requirement 10.5: el indicador se oculta inmediatamente al fallar.
      setState(() {
        _isLoadingMore = false;
        _loadMoreError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(irrigationControllerProvider).value;

    final history = state?.history ?? const <IrrigationSession>[];
    final hasMore = state?.hasMore ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Historial de riego',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (history.isEmpty && !_isLoadingMore)
          const _EmptyState()
        else
          ...[
            // Requirement 10.1: sesiones en orden cronológico inverso.
            for (final session in history)
              _SessionTile(session: session),
          ],
        const SizedBox(height: 8),
        _buildFooter(context, hasMore),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, bool hasMore) {
    // Requirement 10.6: estado de error con botón de reintento que reenvía la
    // última petición preservando el offset actual.
    if (_loadMoreError != null) {
      return _LoadMoreError(
        message: _loadMoreError!,
        onRetry: _loadMore,
      );
    }

    // Requirement 10.5: indicador de carga mientras se obtiene la página.
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Requirement 10.4: botón "Cargar más" visible sólo si hay más páginas.
    if (hasMore) {
      return Align(
        alignment: Alignment.center,
        child: TextButton.icon(
          onPressed: _loadMore,
          icon: const Icon(Icons.expand_more),
          label: const Text('Cargar más'),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Mensaje de estado vacío cuando no existen sesiones (Requirement 10.7).
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 40,
            color: Theme.of(context).disabledColor,
          ),
          const SizedBox(height: 8),
          Text(
            'No hay historial de riego disponible',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Estado de error de la carga de historial con botón de reintento
/// (Requirement 10.6).
class _LoadMoreError extends StatelessWidget {
  const _LoadMoreError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            'No se pudo cargar el historial: $message',
            style: TextStyle(color: colors.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

/// Fila que representa una sesión de riego individual (Requirement 10.2).
class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final IrrigationSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final endLabel = session.endedAt != null
        ? _formatDateTime(session.endedAt!)
        : 'En progreso';
    final durationLabel = _formatDuration(session.durationSeconds);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDateTime(session.startedAt),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  durationLabel,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Fin: $endLabel',
              style: theme.textTheme.bodySmall,
            ),
            // La razón de paro se muestra sólo si es no nula (Requirement 10.2).
            if (session.stopReason != null) ...[
              const SizedBox(height: 2),
              Text(
                'Motivo: ${session.stopReason}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Formatea un [DateTime] como "dd/MM/yyyy HH:mm" en hora local.
  ///
  /// No requiere el paquete `intl` — usa los métodos estándar de [DateTime],
  /// siguiendo el patrón del resto del proyecto.
  static String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  /// Formatea la duración como "Xm Ys", o "—" si es null (Requirement 10.2).
  static String _formatDuration(int? seconds) {
    if (seconds == null) return '—';
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes}m ${remaining}s';
  }
}
