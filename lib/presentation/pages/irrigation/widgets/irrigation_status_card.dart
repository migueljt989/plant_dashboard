import 'package:flutter/material.dart';

import '../../../../core/config/app_theme.dart';
import '../../../../domain/entities/irrigation_status.dart';

/// Tarjeta que muestra el estado actual del dispositivo de riego.
///
/// El widget es puro: no toca ningún provider ni repositorio. Toda su
/// apariencia es función del [status] recibido. El re-render periódico que
/// actualiza la duración transcurrida lo dispara el `IrrigationController` al
/// re-emitir el estado cada segundo (timer de duración); este widget solo
/// recalcula el tiempo relativo a `DateTime.now()` en cada `build`.
///
/// Estados representados:
/// - Desconectado (`connected == false`): punto rojo + "Dispositivo
///   desconectado" (Requirements 6.1, 6.7).
/// - Conectado + regando: punto verde, ícono de gota pulsante animado, y la
///   duración de la sesión formateada "MM:SS" (Requirements 6.1, 6.2, 6.3).
/// - Conectado + inactivo: punto verde, ícono de gota gris estático + "Listo"
///   (Requirements 6.1, 6.4).
class IrrigationStatusCard extends StatelessWidget {
  const IrrigationStatusCard({
    required this.status,
    super.key,
  });

  final IrrigationStatus status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final bool connected = status.connected;
    final bool irrigating = connected && status.irrigating;

    // Requirement 6.1: punto verde si conectado, rojo si desconectado.
    final Color dotColor = connected ? AppColors.ok : AppColors.error;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // ── Indicador de conexión ────────────────────────────────────
            _ConnectionDot(color: dotColor),
            const SizedBox(width: 16),

            // ── Ícono de gota (animado si riega, gris si no) ──────────────
            if (irrigating)
              const _PulsingWaterDrop()
            else
              Icon(
                Icons.water_drop_outlined,
                size: 40,
                color: connected
                    ? AppColors.textSecondary
                    : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
            const SizedBox(width: 16),

            // ── Texto de estado ───────────────────────────────────────────
            Expanded(
              child: _buildStatusText(context, textTheme, connected,
                  irrigating),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusText(
    BuildContext context,
    TextTheme textTheme,
    bool connected,
    bool irrigating,
  ) {
    // Requirement 6.7: dispositivo desconectado.
    if (!connected) {
      return Text(
        'Dispositivo desconectado',
        style: textTheme.titleMedium?.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    // Requirement 6.2 / 6.3: regando → etiqueta + duración "MM:SS".
    if (irrigating) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Regando',
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatElapsed(status.sessionStartedAt),
            style: textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      );
    }

    // Requirement 6.4: conectado e inactivo → "Listo".
    return Text(
      'Listo',
      style: textTheme.titleMedium?.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Formatea la duración transcurrida desde [startedAt] hasta ahora como
  /// "MM:SS" (Requirement 6.3). Si [startedAt] es null o está en el futuro,
  /// devuelve "00:00".
  static String _formatElapsed(DateTime? startedAt) {
    if (startedAt == null) return '00:00';
    final elapsed = DateTime.now().difference(startedAt);
    final totalSeconds = elapsed.inSeconds < 0 ? 0 : elapsed.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Punto de color que indica el estado de conexión del dispositivo.
class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Ícono de gota de agua que pulsa continuamente mientras el riego está activo
/// (Requirement 6.2).
class _PulsingWaterDrop extends StatefulWidget {
  const _PulsingWaterDrop();

  @override
  State<_PulsingWaterDrop> createState() => _PulsingWaterDropState();
}

class _PulsingWaterDropState extends State<_PulsingWaterDrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: const Icon(
        Icons.water_drop,
        size: 40,
        color: AppColors.primaryLight,
      ),
    );
  }
}
