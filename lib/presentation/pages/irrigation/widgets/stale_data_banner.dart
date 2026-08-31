import 'package:flutter/material.dart';

/// Warning banner shown when the irrigation status data may be outdated.
///
/// Visible only when [isStale] is true, which the controller sets when 3 or
/// more consecutive polling requests have failed
/// (`IrrigationState.consecutiveFailures >= 3`). While stale, polling keeps
/// running in the background, so the banner disappears automatically once a
/// poll succeeds again. When not stale, this renders nothing.
///
/// _Requirements: 9.6_
class StaleDataBanner extends StatelessWidget {
  /// Whether the displayed data may be outdated.
  final bool isStale;

  const StaleDataBanner({super.key, required this.isStale});

  @override
  Widget build(BuildContext context) {
    if (!isStale) return const SizedBox.shrink();

    return Container(
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
              'Los datos podrían estar desactualizados. '
              'No se pudo actualizar el estado del riego.',
              style: TextStyle(
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
