import 'package:plant_dashboard/domain/entities/irrigation_command_response.dart';
import 'package:plant_dashboard/domain/entities/irrigation_session.dart';
import 'package:plant_dashboard/domain/entities/irrigation_status.dart';

/// State model for the irrigation controller.
///
/// Holds the current device status, the last start/stop command response,
/// the accumulated session history with a pagination flag, a counter of
/// consecutive polling failures, and a flag indicating whether a start/stop
/// command is currently in progress.
class IrrigationState {
  /// Current status of the irrigation device (connected / irrigating / since).
  final IrrigationStatus status;

  /// Response from the last start/stop command, or null if none has been
  /// issued in this session.
  final IrrigationCommandResponse? lastCommandResponse;

  /// Accumulated list of irrigation sessions (most recent first).
  final List<IrrigationSession> history;

  /// Whether more history pages are available beyond the current list.
  final bool hasMore;

  /// Number of consecutive polling requests that have failed.
  final int consecutiveFailures;

  /// Whether a start or stop command is currently in progress.
  final bool isCommandInProgress;

  const IrrigationState({
    required this.status,
    this.lastCommandResponse,
    required this.history,
    required this.hasMore,
    this.consecutiveFailures = 0,
    this.isCommandInProgress = false,
  });

  /// Whether the displayed data may be outdated because 3 or more consecutive
  /// polling requests have failed.
  bool get isStale => consecutiveFailures >= 3;

  /// Creates a copy of this state replacing the given fields.
  IrrigationState copyWith({
    IrrigationStatus? status,
    IrrigationCommandResponse? lastCommandResponse,
    List<IrrigationSession>? history,
    bool? hasMore,
    int? consecutiveFailures,
    bool? isCommandInProgress,
  }) =>
      IrrigationState(
        status: status ?? this.status,
        lastCommandResponse: lastCommandResponse ?? this.lastCommandResponse,
        history: history ?? this.history,
        hasMore: hasMore ?? this.hasMore,
        consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
        isCommandInProgress: isCommandInProgress ?? this.isCommandInProgress,
      );
}
