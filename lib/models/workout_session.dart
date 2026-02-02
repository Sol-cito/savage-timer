import 'package:equatable/equatable.dart';

enum SessionState { idle, running, paused, completed }

enum SessionPhase { round, rest }

class WorkoutSession extends Equatable {
  final int currentRound;
  final SessionPhase phase;
  final int remainingSeconds;
  final SessionState state;
  final int totalRounds;
  final int roundDurationSeconds;
  final int restDurationSeconds;

  const WorkoutSession({
    this.currentRound = 1,
    this.phase = SessionPhase.round,
    this.remainingSeconds = 0,
    this.state = SessionState.idle,
    this.totalRounds = 3,
    this.roundDurationSeconds = 180,
    this.restDurationSeconds = 30,
  });

  bool get isResting => phase == SessionPhase.rest;

  bool get isLastRound => currentRound == totalRounds;

  bool get isInLastSeconds => remainingSeconds <= 30 && remainingSeconds > 0;

  double get progress {
    final totalSeconds =
        phase == SessionPhase.round
            ? roundDurationSeconds
            : restDurationSeconds;
    if (totalSeconds == 0) return 0;
    return 1 - (remainingSeconds / totalSeconds);
  }

  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get phaseLabel {
    if (state == SessionState.idle) return 'READY';
    if (state == SessionState.completed) return 'DONE';
    return phase == SessionPhase.round ? 'ROUND $currentRound' : 'REST';
  }

  WorkoutSession copyWith({
    int? currentRound,
    SessionPhase? phase,
    int? remainingSeconds,
    SessionState? state,
    int? totalRounds,
    int? roundDurationSeconds,
    int? restDurationSeconds,
  }) {
    return WorkoutSession(
      currentRound: currentRound ?? this.currentRound,
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      state: state ?? this.state,
      totalRounds: totalRounds ?? this.totalRounds,
      roundDurationSeconds: roundDurationSeconds ?? this.roundDurationSeconds,
      restDurationSeconds: restDurationSeconds ?? this.restDurationSeconds,
    );
  }

  @override
  List<Object?> get props => [
    currentRound,
    phase,
    remainingSeconds,
    state,
    totalRounds,
    roundDurationSeconds,
    restDurationSeconds,
  ];
}
