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

  int get totalDurationSeconds =>
      totalRounds * roundDurationSeconds +
      (totalRounds - 1) * restDurationSeconds;

  String get formattedTotalDuration {
    final minutes = totalDurationSeconds ~/ 60;
    final seconds = totalDurationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int get elapsedSeconds {
    if (state == SessionState.idle) return 0;
    if (state == SessionState.completed) return totalDurationSeconds;
    if (phase == SessionPhase.round) {
      return (currentRound - 1) * (roundDurationSeconds + restDurationSeconds) +
          (roundDurationSeconds - remainingSeconds);
    } else {
      return currentRound * roundDurationSeconds +
          (currentRound - 1) * restDurationSeconds +
          (restDurationSeconds - remainingSeconds);
    }
  }

  String get formattedElapsed {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String? get nextPhaseLabel {
    if (state == SessionState.idle || state == SessionState.completed) {
      return null;
    }
    if (phase == SessionPhase.round) {
      return isLastRound ? 'Finish' : 'Rest';
    }
    return 'Round ${currentRound + 1}';
  }

  int? get nextPhaseDurationSeconds {
    if (state == SessionState.idle || state == SessionState.completed) {
      return null;
    }
    if (phase == SessionPhase.round) {
      return isLastRound ? null : restDurationSeconds;
    }
    return roundDurationSeconds;
  }

  String? get formattedNextPhaseDuration {
    final duration = nextPhaseDurationSeconds;
    if (duration == null) return null;
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
