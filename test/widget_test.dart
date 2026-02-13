import 'package:flutter_test/flutter_test.dart';

import 'package:savage_timer/models/timer_settings.dart';
import 'package:savage_timer/models/workout_session.dart';

void main() {
  group('TimerSettings', () {
    test('default values are correct', () {
      const settings = TimerSettings();
      expect(settings.roundDurationSeconds, 180);
      expect(settings.restDurationSeconds, 30);
      expect(settings.totalRounds, 3);
      expect(settings.enableLastSecondsAlert, true);
      expect(settings.lastSecondsThreshold, 30);
      expect(settings.savageLevel, SavageLevel.level2);
      expect(settings.enableMotivationalSound, true);
    });

    test('copyWith creates a new instance with updated values', () {
      const settings = TimerSettings();
      final updated = settings.copyWith(
        roundDurationSeconds: 120,
        totalRounds: 5,
      );

      expect(updated.roundDurationSeconds, 120);
      expect(updated.totalRounds, 5);
      expect(updated.restDurationSeconds, settings.restDurationSeconds);
    });

    test('copyWith updates enableMotivationalSound', () {
      const settings = TimerSettings();
      expect(settings.enableMotivationalSound, true);

      final updated = settings.copyWith(enableMotivationalSound: false);
      expect(updated.enableMotivationalSound, false);
      // Other fields unchanged
      expect(updated.roundDurationSeconds, settings.roundDurationSeconds);
      expect(updated.savageLevel, settings.savageLevel);
    });

    test('fromJson uses defaults when keys are missing', () {
      final settings = TimerSettings.fromJson({});
      expect(settings.roundDurationSeconds, 180);
      expect(settings.restDurationSeconds, 30);
      expect(settings.totalRounds, 3);
      expect(settings.enableLastSecondsAlert, true);
      expect(settings.lastSecondsThreshold, 30);
      expect(settings.savageLevel, SavageLevel.level2);
      expect(settings.volume, 0.8);
      expect(settings.enableMotivationalSound, true);
    });

    test('fromJson backward compat: missing enableMotivationalSound defaults to true', () {
      final settings = TimerSettings.fromJson({
        'roundDurationSeconds': 120,
        'restDurationSeconds': 45,
        'totalRounds': 5,
        'savageLevel': 2,
        // enableMotivationalSound key intentionally omitted
      });
      expect(settings.enableMotivationalSound, true);
      expect(settings.roundDurationSeconds, 120);
    });

    test('volume default is 0.8', () {
      const settings = TimerSettings();
      expect(settings.volume, 0.8);
    });

    test('isMuted returns true when volume is 0', () {
      const settings = TimerSettings(volume: 0.0);
      expect(settings.isMuted, true);

      const notMuted = TimerSettings(volume: 0.5);
      expect(notMuted.isMuted, false);
    });

    test('JSON round-trip preserves values', () {
      const settings = TimerSettings(
        roundDurationSeconds: 120,
        restDurationSeconds: 45,
        totalRounds: 6,
        savageLevel: SavageLevel.level3,
        enableMotivationalSound: false,
      );

      final json = settings.toJson();
      final restored = TimerSettings.fromJson(json);

      expect(restored, settings);
      expect(restored.enableMotivationalSound, false);
    });
  });

  group('WorkoutSession', () {
    test('default values are correct', () {
      const session = WorkoutSession();
      expect(session.currentRound, 1);
      expect(session.phase, SessionPhase.round);
      expect(session.state, SessionState.idle);
      expect(session.isResting, false);
    });

    test('formattedTime formats correctly', () {
      const session = WorkoutSession(remainingSeconds: 125);
      expect(session.formattedTime, '02:05');
    });

    test('formattedTime handles zero', () {
      const session = WorkoutSession(remainingSeconds: 0);
      expect(session.formattedTime, '00:00');
    });

    test('isLastRound detects final round', () {
      const session = WorkoutSession(currentRound: 3, totalRounds: 3);
      expect(session.isLastRound, true);

      const notLast = WorkoutSession(currentRound: 2, totalRounds: 3);
      expect(notLast.isLastRound, false);
    });

    test('isInLastSeconds detects warning threshold', () {
      const inWarning = WorkoutSession(remainingSeconds: 25);
      expect(inWarning.isInLastSeconds, true);

      const notInWarning = WorkoutSession(remainingSeconds: 45);
      expect(notInWarning.isInLastSeconds, false);

      const atZero = WorkoutSession(remainingSeconds: 0);
      expect(atZero.isInLastSeconds, false);
    });

    test('progress calculates correctly', () {
      const session = WorkoutSession(
        remainingSeconds: 90,
        roundDurationSeconds: 180,
        phase: SessionPhase.round,
      );
      expect(session.progress, closeTo(0.5, 0.01));
    });

    test('totalDurationSeconds includes rest between rounds', () {
      // 3 rounds of 180s + 2 rests of 30s = 540 + 60 = 600
      const session = WorkoutSession(
        totalRounds: 3,
        roundDurationSeconds: 180,
        restDurationSeconds: 30,
      );
      expect(session.totalDurationSeconds, 600);
    });

    test('totalDurationSeconds with single round has no rest', () {
      const session = WorkoutSession(
        totalRounds: 1,
        roundDurationSeconds: 120,
        restDurationSeconds: 30,
      );
      expect(session.totalDurationSeconds, 120);
    });

    test('elapsedSeconds is 0 when idle', () {
      const session = WorkoutSession(state: SessionState.idle);
      expect(session.elapsedSeconds, 0);
    });

    test('elapsedSeconds equals totalDuration when completed', () {
      const session = WorkoutSession(
        state: SessionState.completed,
        totalRounds: 3,
        roundDurationSeconds: 180,
        restDurationSeconds: 30,
      );
      expect(session.elapsedSeconds, session.totalDurationSeconds);
    });

    test('elapsedSeconds during first round', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.round,
        currentRound: 1,
        remainingSeconds: 170,
        roundDurationSeconds: 180,
        restDurationSeconds: 30,
      );
      // 10 seconds into first round
      expect(session.elapsedSeconds, 10);
    });

    test('elapsedSeconds during rest after round 2', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.rest,
        currentRound: 2,
        remainingSeconds: 20,
        roundDurationSeconds: 180,
        restDurationSeconds: 30,
      );
      // 2 rounds done (360s) + 1 rest done (30s) + 10s into current rest
      expect(session.elapsedSeconds, 400);
    });

    test('formattedElapsed formats correctly', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.round,
        currentRound: 1,
        remainingSeconds: 55,
        roundDurationSeconds: 180,
        restDurationSeconds: 30,
      );
      // 125 seconds elapsed = 02:05
      expect(session.formattedElapsed, '02:05');
    });

    test('nextPhaseLabel returns null when idle', () {
      const session = WorkoutSession(state: SessionState.idle);
      expect(session.nextPhaseLabel, isNull);
    });

    test('nextPhaseLabel returns null when completed', () {
      const session = WorkoutSession(state: SessionState.completed);
      expect(session.nextPhaseLabel, isNull);
    });

    test('nextPhaseLabel returns Rest during non-last round', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.round,
        currentRound: 1,
        totalRounds: 3,
      );
      expect(session.nextPhaseLabel, 'Rest');
    });

    test('nextPhaseLabel returns Finish during last round', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.round,
        currentRound: 3,
        totalRounds: 3,
      );
      expect(session.nextPhaseLabel, 'Finish');
    });

    test('nextPhaseLabel returns next round number during rest', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.rest,
        currentRound: 2,
        totalRounds: 3,
      );
      expect(session.nextPhaseLabel, 'Round 3');
    });

    test('nextPhaseDurationSeconds returns rest duration during round', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.round,
        currentRound: 1,
        totalRounds: 3,
        restDurationSeconds: 45,
      );
      expect(session.nextPhaseDurationSeconds, 45);
    });

    test('nextPhaseDurationSeconds returns null during last round', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.round,
        currentRound: 3,
        totalRounds: 3,
      );
      expect(session.nextPhaseDurationSeconds, isNull);
    });

    test('nextPhaseDurationSeconds returns round duration during rest', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.rest,
        currentRound: 1,
        totalRounds: 3,
        roundDurationSeconds: 120,
      );
      expect(session.nextPhaseDurationSeconds, 120);
    });

    test('formattedNextPhaseDuration formats correctly', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.round,
        currentRound: 1,
        totalRounds: 3,
        restDurationSeconds: 90,
      );
      expect(session.formattedNextPhaseDuration, '01:30');
    });

    test('formattedNextPhaseDuration returns null for last round', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.round,
        currentRound: 3,
        totalRounds: 3,
      );
      expect(session.formattedNextPhaseDuration, isNull);
    });

    test('phaseLabel returns correct label', () {
      const idle = WorkoutSession(state: SessionState.idle);
      expect(idle.phaseLabel, 'READY');

      const completed = WorkoutSession(state: SessionState.completed);
      expect(completed.phaseLabel, 'DONE');

      const round = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.round,
        currentRound: 2,
      );
      expect(round.phaseLabel, 'ROUND 2');

      const rest = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.rest,
      );
      expect(rest.phaseLabel, 'REST');
    });
  });
}
