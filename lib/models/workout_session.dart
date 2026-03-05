import 'package:equatable/equatable.dart';

enum SessionState { idle, preparing, running, paused, completed }

enum SessionPhase { round, rest }

class WorkoutSession extends Equatable {
  final int currentRound;
  final SessionPhase phase;
  final int remainingSeconds;
  final SessionState state;
  final int totalRounds;
  final int roundDurationSeconds;
  final bool enableSeparateRoundDurations;
  final List<int> roundDurationsSeconds;
  final int restDurationSeconds;
  final bool pausedDuringPreparation;

  const WorkoutSession({
    this.currentRound = 1,
    this.phase = SessionPhase.round,
    this.remainingSeconds = 0,
    this.state = SessionState.idle,
    this.totalRounds = 3,
    this.roundDurationSeconds = 180,
    this.enableSeparateRoundDurations = false,
    this.roundDurationsSeconds = const [],
    this.restDurationSeconds = 30,
    this.pausedDuringPreparation = false,
  });

  bool get isResting => phase == SessionPhase.rest;

  bool get isLastRound => currentRound == totalRounds;

  bool get isInLastSeconds => remainingSeconds <= 30 && remainingSeconds > 0;

  /// Returns the countdown number ("3", "2", "1") during preparation, null otherwise.
  String? get preparationCountdown {
    if (state != SessionState.preparing && !pausedDuringPreparation) {
      return null;
    }
    return '$remainingSeconds';
  }

  double get progress {
    if (state == SessionState.preparing || pausedDuringPreparation) return 0.0;
    final totalSeconds =
        phase == SessionPhase.round
            ? roundDurationForRound(currentRound)
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
    if (state == SessionState.preparing || pausedDuringPreparation) {
      return 'GET READY';
    }
    if (state == SessionState.completed) return 'DONE';
    return phase == SessionPhase.round ? 'ROUND $currentRound' : 'REST';
  }

  int roundDurationForRound(int roundNumber) {
    if (roundNumber <= 0) return roundDurationSeconds;
    final roundIndex = roundNumber - 1;
    if (enableSeparateRoundDurations &&
        roundIndex < roundDurationsSeconds.length) {
      return roundDurationsSeconds[roundIndex];
    }
    return roundDurationSeconds;
  }

  int _sumRoundDurationsThroughRound(int roundNumberInclusive) {
    if (roundNumberInclusive <= 0) return 0;

    var sum = 0;
    final upperBound =
        roundNumberInclusive > totalRounds ? totalRounds : roundNumberInclusive;
    for (var round = 1; round <= upperBound; round++) {
      sum += roundDurationForRound(round);
    }
    return sum;
  }

  int get totalDurationSeconds =>
      _sumRoundDurationsThroughRound(totalRounds) +
      (totalRounds - 1) * restDurationSeconds;

  String get formattedTotalDuration {
    final minutes = totalDurationSeconds ~/ 60;
    final seconds = totalDurationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int get elapsedSeconds {
    if (state == SessionState.idle ||
        state == SessionState.preparing ||
        pausedDuringPreparation) {
      return 0;
    }
    if (state == SessionState.completed) return totalDurationSeconds;
    if (phase == SessionPhase.round) {
      final elapsedInCurrentRound =
          roundDurationForRound(currentRound) - remainingSeconds;
      return _sumRoundDurationsThroughRound(currentRound - 1) +
          (currentRound - 1) * restDurationSeconds +
          elapsedInCurrentRound;
    } else {
      return _sumRoundDurationsThroughRound(currentRound) +
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
    if (state == SessionState.idle ||
        state == SessionState.preparing ||
        pausedDuringPreparation ||
        state == SessionState.completed) {
      return null;
    }
    if (phase == SessionPhase.round) {
      return isLastRound ? 'Finish' : 'Rest';
    }
    return 'Round ${currentRound + 1}';
  }

  int? get nextPhaseDurationSeconds {
    if (state == SessionState.idle ||
        state == SessionState.preparing ||
        pausedDuringPreparation ||
        state == SessionState.completed) {
      return null;
    }
    if (phase == SessionPhase.round) {
      return isLastRound ? null : restDurationSeconds;
    }
    return roundDurationForRound(currentRound + 1);
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
    bool? enableSeparateRoundDurations,
    List<int>? roundDurationsSeconds,
    int? restDurationSeconds,
    bool? pausedDuringPreparation,
  }) {
    return WorkoutSession(
      currentRound: currentRound ?? this.currentRound,
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      state: state ?? this.state,
      totalRounds: totalRounds ?? this.totalRounds,
      roundDurationSeconds: roundDurationSeconds ?? this.roundDurationSeconds,
      enableSeparateRoundDurations:
          enableSeparateRoundDurations ?? this.enableSeparateRoundDurations,
      roundDurationsSeconds:
          roundDurationsSeconds ?? this.roundDurationsSeconds,
      restDurationSeconds: restDurationSeconds ?? this.restDurationSeconds,
      pausedDuringPreparation:
          pausedDuringPreparation ?? this.pausedDuringPreparation,
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
    enableSeparateRoundDurations,
    roundDurationsSeconds,
    restDurationSeconds,
    pausedDuringPreparation,
  ];
}
