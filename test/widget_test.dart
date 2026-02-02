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

    test('JSON round-trip preserves values', () {
      const settings = TimerSettings(
        roundDurationSeconds: 120,
        restDurationSeconds: 45,
        totalRounds: 6,
        savageLevel: SavageLevel.level3,
      );

      final json = settings.toJson();
      final restored = TimerSettings.fromJson(json);

      expect(restored, settings);
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
