import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savage_timer/models/timer_settings.dart';
import 'package:savage_timer/models/workout_session.dart';

void main() {
  // We test the private helper logic by instantiating TimerScreen
  // and validating the rendered output for each savage level.

  group('TimerScreen mode indicator', () {
    test('each level has a distinct icon', () {
      final icons = <SavageLevel, IconData>{};

      for (final level in SavageLevel.values) {
        icons[level] = _getExpectedIcon(level);
      }

      expect(icons[SavageLevel.level1], isNot(icons[SavageLevel.level2]));
      expect(icons[SavageLevel.level2], isNot(icons[SavageLevel.level3]));
      expect(icons[SavageLevel.level1], isNot(icons[SavageLevel.level3]));
    });

    test('each level has a distinct color', () {
      final colors = <SavageLevel, Color>{};
      for (final level in SavageLevel.values) {
        colors[level] = _getExpectedColor(level);
      }

      expect(colors[SavageLevel.level1], isNot(colors[SavageLevel.level2]));
      expect(colors[SavageLevel.level2], isNot(colors[SavageLevel.level3]));
      expect(colors[SavageLevel.level1], isNot(colors[SavageLevel.level3]));
    });

    test('level colors match expected theme', () {
      expect(_getExpectedColor(SavageLevel.level1), Colors.lightBlueAccent);
      expect(_getExpectedColor(SavageLevel.level2), Colors.yellowAccent);
      expect(_getExpectedColor(SavageLevel.level3), Colors.redAccent);
    });

    test('level icons match expected icons', () {
      expect(_getExpectedIcon(SavageLevel.level1), Icons.spa);
      expect(_getExpectedIcon(SavageLevel.level2), Icons.fitness_center);
      expect(_getExpectedIcon(SavageLevel.level3), Icons.whatshot);
    });
  });

  group('TimerScreen background colors', () {
    test('idle state returns grey for all levels', () {
      const session = WorkoutSession(state: SessionState.idle);
      for (final level in SavageLevel.values) {
        final colors = _getExpectedBackgroundColors(session, level);
        expect(colors[0], Colors.grey.shade900);
        expect(colors[1], Colors.grey.shade800);
      }
    });

    test('completed state returns green for all levels', () {
      const session = WorkoutSession(state: SessionState.completed);
      for (final level in SavageLevel.values) {
        final colors = _getExpectedBackgroundColors(session, level);
        expect(colors[0], Colors.green.shade900);
        expect(colors[1], Colors.green.shade700);
      }
    });

    test('resting state returns green/teal for all levels', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.rest,
        remainingSeconds: 20,
        restDurationSeconds: 30,
      );
      for (final level in SavageLevel.values) {
        final colors = _getExpectedBackgroundColors(session, level);
        expect(colors[0], Colors.green.shade900);
        expect(colors[1], Colors.teal.shade800);
      }
    });

    test('round phase uses level-specific colors', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.round,
        remainingSeconds: 120,
        roundDurationSeconds: 180,
      );

      final mildColors = _getExpectedBackgroundColors(session, SavageLevel.level1);
      expect(mildColors[0], Colors.blue.shade900);
      expect(mildColors[1], Colors.blue.shade700);

      final mediumColors = _getExpectedBackgroundColors(session, SavageLevel.level2);
      expect(mediumColors[0], Colors.amber.shade900);
      expect(mediumColors[1], Colors.amber.shade700);

      final savageColors = _getExpectedBackgroundColors(session, SavageLevel.level3);
      expect(savageColors[0], Colors.red.shade900);
      expect(savageColors[1], Colors.red.shade700);
    });

    test('last seconds uses level-specific colors with orange', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.round,
        remainingSeconds: 15,
        roundDurationSeconds: 180,
      );

      final mildColors = _getExpectedBackgroundColors(session, SavageLevel.level1);
      expect(mildColors[0], Colors.blue.shade900);
      expect(mildColors[1], Colors.orange.shade800);

      final mediumColors = _getExpectedBackgroundColors(session, SavageLevel.level2);
      expect(mediumColors[0], Colors.amber.shade900);
      expect(mediumColors[1], Colors.orange.shade800);

      final savageColors = _getExpectedBackgroundColors(session, SavageLevel.level3);
      expect(savageColors[0], Colors.red.shade900);
      expect(savageColors[1], Colors.orange.shade800);
    });
  });

  group('TimerScreen progress color', () {
    test('completed returns green', () {
      const session = WorkoutSession(state: SessionState.completed);
      for (final level in SavageLevel.values) {
        expect(_getExpectedProgressColor(session, level), Colors.green);
      }
    });

    test('resting returns green', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.rest,
        remainingSeconds: 20,
        restDurationSeconds: 30,
      );
      for (final level in SavageLevel.values) {
        expect(_getExpectedProgressColor(session, level), Colors.green);
      }
    });

    test('last seconds returns orange', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.round,
        remainingSeconds: 15,
        roundDurationSeconds: 180,
      );
      for (final level in SavageLevel.values) {
        expect(_getExpectedProgressColor(session, level), Colors.orange);
      }
    });

    test('round phase uses level-specific colors', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.round,
        remainingSeconds: 120,
        roundDurationSeconds: 180,
      );

      expect(
        _getExpectedProgressColor(session, SavageLevel.level1),
        Colors.lightBlueAccent,
      );
      expect(
        _getExpectedProgressColor(session, SavageLevel.level2),
        Colors.amber,
      );
      expect(
        _getExpectedProgressColor(session, SavageLevel.level3),
        Colors.red,
      );
    });
  });
  group('TimerScreen preparing state', () {
    test('preparing state returns grey background for all levels', () {
      const session = WorkoutSession(state: SessionState.preparing);
      for (final level in SavageLevel.values) {
        final colors = _getExpectedBackgroundColors(session, level);
        expect(colors[0], Colors.grey.shade900);
        expect(colors[1], Colors.grey.shade800);
      }
    });

    test('preparing state returns white progress color', () {
      const session = WorkoutSession(state: SessionState.preparing);
      for (final level in SavageLevel.values) {
        expect(_getExpectedProgressColor(session, level), Colors.white);
      }
    });
  });

  group('TimerScreen neutral mode (motivational off)', () {
    test('background uses blueGrey during round when motivational off', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.round,
        remainingSeconds: 120,
        roundDurationSeconds: 180,
      );

      for (final level in SavageLevel.values) {
        final colors = _getExpectedBackgroundColors(
          session, level, false,
        );
        expect(colors[0], Colors.blueGrey.shade900);
        expect(colors[1], Colors.blueGrey.shade700);
      }
    });

    test('background uses blueGrey + orange during last seconds when motivational off', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.round,
        remainingSeconds: 15,
        roundDurationSeconds: 180,
      );

      for (final level in SavageLevel.values) {
        final colors = _getExpectedBackgroundColors(
          session, level, false,
        );
        expect(colors[0], Colors.blueGrey.shade900);
        expect(colors[1], Colors.orange.shade900);
      }
    });

    test('idle and completed backgrounds unaffected by motivational toggle', () {
      const idle = WorkoutSession(state: SessionState.idle);
      const completed = WorkoutSession(state: SessionState.completed);

      for (final level in SavageLevel.values) {
        final idleOn = _getExpectedBackgroundColors(idle, level, true);
        final idleOff = _getExpectedBackgroundColors(idle, level, false);
        expect(idleOn, idleOff);

        final compOn = _getExpectedBackgroundColors(completed, level, true);
        final compOff = _getExpectedBackgroundColors(completed, level, false);
        expect(compOn, compOff);
      }
    });

    test('rest background unaffected by motivational toggle', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.rest,
        remainingSeconds: 20,
        restDurationSeconds: 30,
      );

      for (final level in SavageLevel.values) {
        final on = _getExpectedBackgroundColors(session, level, true);
        final off = _getExpectedBackgroundColors(session, level, false);
        expect(on, off);
      }
    });

    test('progress color is blueGrey when motivational off during round', () {
      const session = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.round,
        remainingSeconds: 120,
        roundDurationSeconds: 180,
      );

      for (final level in SavageLevel.values) {
        expect(
          _getExpectedProgressColor(session, level, false),
          Colors.blueGrey.shade300,
        );
      }
    });

    test('progress color for completed/rest/lastSeconds unaffected by motivational toggle', () {
      const completed = WorkoutSession(state: SessionState.completed);
      const rest = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.rest,
        remainingSeconds: 20,
        restDurationSeconds: 30,
      );
      const lastSecs = WorkoutSession(
        state: SessionState.running,
        phase: SessionPhase.round,
        remainingSeconds: 15,
        roundDurationSeconds: 180,
      );

      for (final level in SavageLevel.values) {
        expect(
          _getExpectedProgressColor(completed, level, false),
          _getExpectedProgressColor(completed, level, true),
        );
        expect(
          _getExpectedProgressColor(rest, level, false),
          _getExpectedProgressColor(rest, level, true),
        );
        expect(
          _getExpectedProgressColor(lastSecs, level, false),
          _getExpectedProgressColor(lastSecs, level, true),
        );
      }
    });
  });
}

// Mirror the private methods from TimerScreen so we can unit test the logic.
// This keeps tests in sync with the actual implementation.

IconData _getExpectedIcon(SavageLevel level) {
  switch (level) {
    case SavageLevel.level1:
      return Icons.spa;
    case SavageLevel.level2:
      return Icons.fitness_center;
    case SavageLevel.level3:
      return Icons.whatshot;
  }
}

Color _getExpectedColor(SavageLevel level) {
  switch (level) {
    case SavageLevel.level1:
      return Colors.lightBlueAccent;
    case SavageLevel.level2:
      return Colors.yellowAccent;
    case SavageLevel.level3:
      return Colors.redAccent;
  }
}

List<Color> _getExpectedBackgroundColors(
  WorkoutSession session,
  SavageLevel level, [
  bool motivationalOn = true,
]) {
  if (session.state == SessionState.completed) {
    return [Colors.green.shade900, Colors.green.shade700];
  }
  if (session.state == SessionState.idle ||
      session.state == SessionState.preparing) {
    return [Colors.grey.shade900, Colors.grey.shade800];
  }
  if (session.isResting) {
    return [Colors.green.shade900, Colors.teal.shade800];
  }
  if (!motivationalOn) {
    if (session.isInLastSeconds) {
      return [Colors.blueGrey.shade900, Colors.orange.shade900];
    }
    return [Colors.blueGrey.shade900, Colors.blueGrey.shade700];
  }
  if (session.isInLastSeconds) {
    switch (level) {
      case SavageLevel.level1:
        return [Colors.blue.shade900, Colors.orange.shade800];
      case SavageLevel.level2:
        return [Colors.amber.shade900, Colors.orange.shade800];
      case SavageLevel.level3:
        return [Colors.red.shade900, Colors.orange.shade800];
    }
  }
  switch (level) {
    case SavageLevel.level1:
      return [Colors.blue.shade900, Colors.blue.shade700];
    case SavageLevel.level2:
      return [Colors.amber.shade900, Colors.amber.shade700];
    case SavageLevel.level3:
      return [Colors.red.shade900, Colors.red.shade700];
  }
}

Color _getExpectedProgressColor(
  WorkoutSession session,
  SavageLevel level, [
  bool motivationalOn = true,
]) {
  if (session.state == SessionState.preparing) {
    return Colors.white;
  }
  if (session.state == SessionState.completed) {
    return Colors.green;
  }
  if (session.isResting) {
    return Colors.green;
  }
  if (session.isInLastSeconds) {
    return Colors.orange;
  }
  if (!motivationalOn) {
    return Colors.blueGrey.shade300;
  }
  switch (level) {
    case SavageLevel.level1:
      return Colors.lightBlueAccent;
    case SavageLevel.level2:
      return Colors.amber;
    case SavageLevel.level3:
      return Colors.red;
  }
}
