import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:savage_timer/models/timer_settings.dart';
import 'package:savage_timer/models/workout_session.dart';
import 'package:savage_timer/services/audio_service.dart';
import 'package:savage_timer/services/timer_service.dart';
import 'package:savage_timer/services/vibration_service.dart';

/// A fake AudioService that records method calls for verification.
class FakeAudioService implements AudioService {
  final List<String> calls = [];
  SavageLevel? lastRestVoiceLevel;
  SavageLevel? lastExerciseVoiceLevel;
  SavageLevel? lastStartVoiceLevel;
  int exerciseVoiceCount = 0;
  int startVoiceCount = 0;
  int restVoiceCount = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> playBell() async {
    calls.add('playBell');
  }

  @override
  Future<void> playWarning() async {
    calls.add('playWarning');
  }

  @override
  Future<void> speakQuote(String quote) async {
    calls.add('speakQuote');
  }

  @override
  Future<void> speakQuoteForced(String quote) async {
    calls.add('speakQuoteForced');
  }

  @override
  Future<void> playRandomRestVoice(SavageLevel level) async {
    calls.add('playRandomRestVoice');
    lastRestVoiceLevel = level;
    restVoiceCount++;
  }

  @override
  Future<void> playRandomExerciseVoice(SavageLevel level) async {
    calls.add('playRandomExerciseVoice');
    lastExerciseVoiceLevel = level;
    exerciseVoiceCount++;
  }

  @override
  Future<void> playRandomStartVoice(SavageLevel level) async {
    calls.add('playRandomStartVoice');
    lastStartVoiceLevel = level;
    startVoiceCount++;
  }

  @override
  Future<void> playExampleVoice(SavageLevel level) async {
    calls.add('playExampleVoice');
  }

  @override
  Future<void> playMotivationVoice(String assetPath) async {
    calls.add('playMotivationVoice');
  }

  @override
  Future<void> playCount(int number, SavageLevel level, bool enableMotivationalSound) async {
    calls.add('playCount_$number');
  }

  @override
  Future<void> playCountFinish(SavageLevel level, bool enableMotivationalSound) async {
    calls.add('playCountFinish');
  }

  @override
  Future<void> playCountRest(SavageLevel level, bool enableMotivationalSound) async {
    calls.add('playCountRest');
  }

  @override
  Future<void> playCountStart(SavageLevel level, bool enableMotivationalSound) async {
    calls.add('playCountStart');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  void resetQuoteCooldown() {
    calls.add('resetQuoteCooldown');
  }

  @override
  Future<void> dispose() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  void clearCounters() {
    calls.clear();
    exerciseVoiceCount = 0;
    startVoiceCount = 0;
    restVoiceCount = 0;
  }
}

/// A fake VibrationService that does nothing.
class FakeVibrationService implements VibrationService {
  @override
  Future<void> roundStart() async {}
  @override
  Future<void> roundEnd() async {}
  @override
  Future<void> lastSecondsAlert() async {}
  @override
  Future<void> restEnd() async {}
  @override
  Future<void> sessionComplete() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A seeded Random for deterministic tests.
class SeededRandom implements Random {
  int _callCount = 0;
  final List<int> _values;

  SeededRandom(this._values);

  @override
  int nextInt(int max) {
    final value = _values[_callCount % _values.length];
    _callCount++;
    return value % max;
  }

  @override
  double nextDouble() => 0.5;

  @override
  bool nextBool() => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAudioService fakeAudio;
  late FakeVibrationService fakeVibration;

  setUp(() {
    fakeAudio = FakeAudioService();
    fakeVibration = FakeVibrationService();
  });

  TimerService createService({
    SavageLevel level = SavageLevel.level2,
    int roundDuration = 60,
    int restDuration = 10,
    int totalRounds = 2,
    bool enableMotivationalSound = true,
    Random? random,
  }) {
    return TimerService(
      audioService: fakeAudio,
      vibrationService: fakeVibration,
      settings: TimerSettings(
        roundDurationSeconds: roundDuration,
        restDurationSeconds: restDuration,
        totalRounds: totalRounds,
        savageLevel: level,
        enableMotivationalSound: enableMotivationalSound,
      ),
      random: random,
    );
  }

  group('TimerService start voice', () {
    test('plays start voice after bell delay on start', () {
      fakeAsync((async) {
        final service = createService(roundDuration: 60);

        service.start();
        // Count start plays immediately
        expect(fakeAudio.calls, contains('playCountStart'));

        fakeAudio.clearCounters();

        // Before bell delay (3s), no start voice
        async.elapse(const Duration(seconds: 2));
        expect(fakeAudio.startVoiceCount, 0);

        // After bell delay, start voice plays
        async.elapse(const Duration(seconds: 1));
        expect(fakeAudio.startVoiceCount, 1);

        service.reset();
      });
    });

    test('does not play start voice when motivational sound is off', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          enableMotivationalSound: false,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 5));
        expect(fakeAudio.startVoiceCount, 0);

        service.reset();
      });
    });

    test('passes correct savage level to start voice', () {
      fakeAsync((async) {
        final service = createService(
          level: SavageLevel.level3,
          roundDuration: 60,
        );

        service.start();
        async.elapse(const Duration(seconds: 3));
        expect(fakeAudio.lastStartVoiceLevel, SavageLevel.level3);

        service.reset();
      });
    });

    test('cancels start voice on pause before delay', () {
      fakeAsync((async) {
        final service = createService(roundDuration: 60);

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 1));
        service.pause();

        async.elapse(const Duration(seconds: 5));
        expect(fakeAudio.startVoiceCount, 0);

        service.reset();
      });
    });

    test('plays start voice at beginning of each new round', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          restDuration: 10,
          totalRounds: 3,
        );

        service.start();
        async.elapse(const Duration(seconds: 3)); // bell delay
        expect(fakeAudio.startVoiceCount, 1);

        // Complete round 1 + rest
        async.elapse(const Duration(seconds: 57)); // finish round
        async.elapse(const Duration(seconds: 10)); // finish rest

        fakeAudio.startVoiceCount = 0;
        async.elapse(const Duration(seconds: 3)); // bell delay for round 2
        expect(fakeAudio.startVoiceCount, 1);

        service.reset();
      });
    });
  });

  group('TimerService rest voice', () {
    test('plays rest voice after bell delay when round ends', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 10,
          restDuration: 15,
          totalRounds: 2,
        );

        service.start();

        // Finish round
        async.elapse(const Duration(seconds: 10));
        expect(service.state.phase, SessionPhase.rest);

        fakeAudio.clearCounters();

        // Before bell delay (3s), no rest voice
        async.elapse(const Duration(seconds: 2));
        expect(fakeAudio.restVoiceCount, 0);

        // After bell delay, rest voice plays
        async.elapse(const Duration(seconds: 1));
        expect(fakeAudio.restVoiceCount, 1);

        service.reset();
      });
    });

    for (final level in SavageLevel.values) {
      test('passes correct level for rest voice (${level.name})', () {
        fakeAsync((async) {
          final service = createService(
            level: level,
            roundDuration: 5,
            restDuration: 15,
            totalRounds: 2,
          );

          service.start();
          async.elapse(const Duration(seconds: 5)); // finish round
          async.elapse(const Duration(seconds: 3)); // bell delay

          expect(fakeAudio.lastRestVoiceLevel, level);

          service.reset();
        });
      });
    }

    test('does not play rest voice if paused before bell delay', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 5,
          restDuration: 15,
          totalRounds: 2,
        );

        service.start();
        async.elapse(const Duration(seconds: 5)); // finish round
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 1));
        service.pause();

        async.elapse(const Duration(seconds: 5));
        expect(fakeAudio.restVoiceCount, 0);

        service.reset();
      });
    });

    test('does not play rest voice when motivational sound is off', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 5,
          restDuration: 15,
          totalRounds: 2,
          enableMotivationalSound: false,
        );

        service.start();
        async.elapse(const Duration(seconds: 5)); // finish round
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 5));
        expect(fakeAudio.restVoiceCount, 0);

        service.reset();
      });
    });

    test('no rest voice on last round (session completes)', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 5,
          restDuration: 10,
          totalRounds: 1,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 5));
        expect(service.state.state, SessionState.completed);

        async.elapse(const Duration(seconds: 10));
        expect(fakeAudio.restVoiceCount, 0);

        service.reset();
      });
    });
  });

  group('TimerService exercise voice scheduling', () {
    test('schedules exercise voices during round', () {
      fakeAsync((async) {
        final seeded = SeededRandom([0, 0, 0, 0, 0]);
        final service = createService(
          roundDuration: 60,
          totalRounds: 1,
          random: seeded,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 60));
        // 60s round → target 2 voices
        expect(fakeAudio.exerciseVoiceCount, 2);

        service.reset();
      });
    });

    test('schedules 3 voices for 180s round', () {
      fakeAsync((async) {
        final seeded = SeededRandom([0, 0, 0, 0, 0]);
        final service = createService(
          roundDuration: 180,
          totalRounds: 1,
          random: seeded,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 180));
        expect(fakeAudio.exerciseVoiceCount, 3);

        service.reset();
      });
    });

    test('schedules 4 voices for 300s round', () {
      fakeAsync((async) {
        final seeded = SeededRandom([0, 0, 0, 0, 0]);
        final service = createService(
          roundDuration: 300,
          totalRounds: 1,
          random: seeded,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 300));
        expect(fakeAudio.exerciseVoiceCount, 4);

        service.reset();
      });
    });

    test('plays exercise voices with correct savage level', () {
      fakeAsync((async) {
        final seeded = SeededRandom([0, 0, 0, 0, 0]);
        final service = createService(
          level: SavageLevel.level3,
          roundDuration: 60,
          totalRounds: 1,
          random: seeded,
        );

        service.start();
        async.elapse(const Duration(seconds: 60));
        expect(fakeAudio.lastExerciseVoiceLevel, SavageLevel.level3);

        service.reset();
      });
    });

    for (final level in SavageLevel.values) {
      test('schedules exercise voices for ${level.name}', () {
        fakeAsync((async) {
          final seeded = SeededRandom([0, 0, 0, 0, 0]);
          final service = createService(
            level: level,
            roundDuration: 60,
            totalRounds: 1,
            random: seeded,
          );

          service.start();
          fakeAudio.clearCounters();

          async.elapse(const Duration(seconds: 60));
          expect(fakeAudio.exerciseVoiceCount, greaterThanOrEqualTo(2));
          expect(fakeAudio.lastExerciseVoiceLevel, level);

          service.reset();
        });
      });
    }

    test('does not schedule exercise voices when motivational sound is off', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          totalRounds: 1,
          enableMotivationalSound: false,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 60));
        expect(fakeAudio.exerciseVoiceCount, 0);

        service.reset();
      });
    });

    test('does not schedule exercise voices for very short rounds', () {
      fakeAsync((async) {
        // Round is 15s. minStartDelay=11, maxPlayTime=7 → 7 <= 11, skip
        final service = createService(
          roundDuration: 15,
          restDuration: 5,
          totalRounds: 1,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 15));
        expect(fakeAudio.exerciseVoiceCount, 0);

        service.reset();
      });
    });

    test('cancels exercise voices on pause', () {
      fakeAsync((async) {
        final seeded = SeededRandom([0, 0, 0, 0, 0]);
        final service = createService(
          roundDuration: 60,
          totalRounds: 1,
          random: seeded,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 5));
        service.pause();

        async.elapse(const Duration(seconds: 60));
        expect(fakeAudio.exerciseVoiceCount, 0);

        service.reset();
      });
    });

    test('cancels exercise voices on reset', () {
      fakeAsync((async) {
        final seeded = SeededRandom([0, 0, 0, 0, 0]);
        final service = createService(
          roundDuration: 60,
          totalRounds: 1,
          random: seeded,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 5));
        service.reset();

        async.elapse(const Duration(seconds: 60));
        expect(fakeAudio.exerciseVoiceCount, 0);
      });
    });

    test('no exercise voices during rest phase', () {
      fakeAsync((async) {
        final seeded = SeededRandom([0, 0, 0, 0, 0]);
        final service = createService(
          roundDuration: 60,
          restDuration: 30,
          totalRounds: 2,
          random: seeded,
        );

        service.start();
        async.elapse(const Duration(seconds: 60)); // finish round
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 30)); // rest period
        expect(fakeAudio.exerciseVoiceCount, 0);

        service.reset();
      });
    });

    test('exercise voices re-scheduled for each new round', () {
      fakeAsync((async) {
        final seeded = SeededRandom([0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
        final service = createService(
          roundDuration: 60,
          restDuration: 5,
          totalRounds: 2,
          random: seeded,
        );

        service.start();
        fakeAudio.exerciseVoiceCount = 0;

        async.elapse(const Duration(seconds: 60)); // round 1
        final countRound1 = fakeAudio.exerciseVoiceCount;
        expect(countRound1, greaterThanOrEqualTo(2));

        async.elapse(const Duration(seconds: 5)); // rest
        fakeAudio.exerciseVoiceCount = 0;

        async.elapse(const Duration(seconds: 60)); // round 2
        expect(fakeAudio.exerciseVoiceCount, greaterThanOrEqualTo(2));

        service.reset();
      });
    });

    test('last exercise voice scheduled before buffer zone', () {
      fakeAsync((async) {
        final lateRandom = SeededRandom([999, 999, 999, 999, 999]);
        final service = createService(
          roundDuration: 60,
          totalRounds: 1,
          random: lateRandom,
        );

        service.start();
        fakeAudio.clearCounters();

        // Advance to buffer zone boundary (60 - 8 = 52s)
        async.elapse(const Duration(seconds: 52));
        final countAtBoundary = fakeAudio.exerciseVoiceCount;

        // No new voices in the buffer zone
        async.elapse(const Duration(seconds: 8));
        expect(fakeAudio.exerciseVoiceCount, countAtBoundary);

        service.reset();
      });
    });
  });

  group('TimerService round transitions', () {
    test('transitions to next round after rest ends', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 5,
          restDuration: 5,
          totalRounds: 3,
        );

        service.start();
        expect(service.state.currentRound, 1);

        async.elapse(const Duration(seconds: 5)); // finish round 1
        expect(service.state.phase, SessionPhase.rest);

        async.elapse(const Duration(seconds: 5)); // finish rest
        expect(service.state.phase, SessionPhase.round);
        expect(service.state.currentRound, 2);

        service.reset();
      });
    });

    test('completes session on last round end', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 5,
          restDuration: 5,
          totalRounds: 1,
        );

        service.start();
        async.elapse(const Duration(seconds: 5));
        expect(service.state.state, SessionState.completed);

        service.reset();
      });
    });

    test('count sounds play at round start, round end, and rest end', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 5,
          restDuration: 5,
          totalRounds: 2,
        );

        service.start();
        // Count start on start
        expect(fakeAudio.calls.where((c) => c == 'playCountStart').length, 1);

        // Count rest on round end (starts rest)
        async.elapse(const Duration(seconds: 5));
        expect(fakeAudio.calls, contains('playCountRest'));

        // Count start on rest end (starts new round)
        async.elapse(const Duration(seconds: 5));
        expect(fakeAudio.calls.where((c) => c == 'playCountStart').length, 2);

        service.reset();
      });
    });
  });

  group('TimerService motivational sound toggle', () {
    test('no voices at all when motivational sound is off', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          restDuration: 10,
          totalRounds: 2,
          enableMotivationalSound: false,
        );

        service.start();
        fakeAudio.clearCounters();

        // Full round + rest + second round
        async.elapse(const Duration(seconds: 60)); // round 1
        async.elapse(const Duration(seconds: 10)); // rest
        async.elapse(const Duration(seconds: 60)); // round 2

        expect(fakeAudio.startVoiceCount, 0);
        expect(fakeAudio.exerciseVoiceCount, 0);
        expect(fakeAudio.restVoiceCount, 0);

        // But count sounds should still play (from neutral folder)
        expect(fakeAudio.calls, contains('playCountStart'));

        service.reset();
      });
    });

    test('count sounds play even when motivational sound is off', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          restDuration: 10,
          totalRounds: 2,
          enableMotivationalSound: false,
        );

        service.start();
        expect(fakeAudio.calls, contains('playCountStart'));

        service.reset();
      });
    });
  });

  group('TimerService start voice cancellation on reset', () {
    test('cancels start voice when reset before bell delay', () {
      fakeAsync((async) {
        final service = createService(roundDuration: 60);

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 1));
        service.reset();

        async.elapse(const Duration(seconds: 5));
        expect(fakeAudio.startVoiceCount, 0);
      });
    });
  });

  group('TimerService rest voice cancellation on reset', () {
    test('cancels rest voice when reset during rest before bell delay', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 5,
          restDuration: 15,
          totalRounds: 2,
        );

        service.start();
        async.elapse(const Duration(seconds: 5)); // finish round → rest
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 1));
        service.reset();

        async.elapse(const Duration(seconds: 5));
        expect(fakeAudio.restVoiceCount, 0);
      });
    });
  });

  group('TimerService last seconds alert', () {
    test('bell fires during round with lastSecondsAlert enabled', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          totalRounds: 1,
          enableMotivationalSound: true,
        );

        service.start();
        fakeAudio.clearCounters();

        // Advance to exactly the lastSecondsThreshold (default 30)
        // At tick 30, remainingSeconds becomes 30 → triggers bell
        async.elapse(const Duration(seconds: 30));
        expect(fakeAudio.calls, contains('playBell'));

        service.reset();
      });
    });

    test('bell fires even when motivational sound is off', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          totalRounds: 1,
          enableMotivationalSound: false,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 30));
        expect(fakeAudio.calls, contains('playBell'));

        // But no voices
        expect(fakeAudio.startVoiceCount, 0);
        expect(fakeAudio.exerciseVoiceCount, 0);

        service.reset();
      });
    });

    test('bell does not fire when lastSecondsAlert is disabled', () {
      fakeAsync((async) {
        final service = TimerService(
          audioService: fakeAudio,
          vibrationService: fakeVibration,
          settings: const TimerSettings(
            roundDurationSeconds: 60,
            totalRounds: 1,
            enableLastSecondsAlert: false,
          ),
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 60));
        expect(fakeAudio.calls, isNot(contains('playBell')));

        service.reset();
      });
    });

    test('bell fires only once per round', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          totalRounds: 1,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 60));
        final bellCount =
            fakeAudio.calls.where((c) => c == 'playBell').length;
        expect(bellCount, 1);

        service.reset();
      });
    });
  });

  group('TimerService rest voice count', () {
    test('rest voice plays exactly once per rest period', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 5,
          restDuration: 30,
          totalRounds: 2,
        );

        service.start();
        async.elapse(const Duration(seconds: 5)); // round ends → rest
        fakeAudio.clearCounters();

        // Full rest period
        async.elapse(const Duration(seconds: 30));
        expect(fakeAudio.restVoiceCount, 1);

        service.reset();
      });
    });
  });

  group('TimerService start voice guard conditions', () {
    test('start voice does not play if round ends before bell delay', () {
      fakeAsync((async) {
        // Round is 2s, bell delay is 3s → start voice timer fires after
        // round has already ended
        final service = createService(
          roundDuration: 2,
          restDuration: 10,
          totalRounds: 2,
        );

        service.start();
        fakeAudio.clearCounters();

        // Round ends at 2s, but bell delay is 3s
        async.elapse(const Duration(seconds: 2));
        expect(service.state.phase, SessionPhase.rest);

        // Bell delay fires at 3s — but we're in rest phase now
        async.elapse(const Duration(seconds: 1));
        // Guard: state.phase == SessionPhase.round should prevent it
        expect(fakeAudio.startVoiceCount, 0);

        service.reset();
      });
    });
  });

  group('TimerService exercise voice boundary durations', () {
    test('schedules 2 voices for exactly 90s round', () {
      fakeAsync((async) {
        final seeded = SeededRandom([0, 0, 0, 0, 0]);
        final service = createService(
          roundDuration: 90,
          totalRounds: 1,
          random: seeded,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 90));
        expect(fakeAudio.exerciseVoiceCount, 2);

        service.reset();
      });
    });

    test('schedules 3 voices for 91s round', () {
      fakeAsync((async) {
        final seeded = SeededRandom([0, 0, 0, 0, 0]);
        final service = createService(
          roundDuration: 91,
          totalRounds: 1,
          random: seeded,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 91));
        expect(fakeAudio.exerciseVoiceCount, 3);

        service.reset();
      });
    });

    test('schedules 3 voices for exactly 180s round', () {
      fakeAsync((async) {
        final seeded = SeededRandom([0, 0, 0, 0, 0]);
        final service = createService(
          roundDuration: 180,
          totalRounds: 1,
          random: seeded,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 180));
        expect(fakeAudio.exerciseVoiceCount, 3);

        service.reset();
      });
    });

    test('schedules 4 voices for 181s round', () {
      fakeAsync((async) {
        final seeded = SeededRandom([0, 0, 0, 0, 0]);
        final service = createService(
          roundDuration: 181,
          totalRounds: 1,
          random: seeded,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 181));
        expect(fakeAudio.exerciseVoiceCount, 4);

        service.reset();
      });
    });
  });

  group('TimerService full end-to-end workflow', () {
    test('3-round complete workout with all voice events', () {
      fakeAsync((async) {
        final seeded = SeededRandom([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
        final service = createService(
          roundDuration: 60,
          restDuration: 10,
          totalRounds: 3,
          random: seeded,
        );

        service.start();
        expect(service.state.state, SessionState.running);
        expect(service.state.currentRound, 1);
        expect(service.state.phase, SessionPhase.round);

        // Count start on start
        expect(fakeAudio.calls, contains('playCountStart'));

        // Start voice after 3s
        async.elapse(const Duration(seconds: 3));
        expect(fakeAudio.startVoiceCount, 1);

        // --- Round 1 finishes ---
        async.elapse(const Duration(seconds: 57));
        expect(service.state.phase, SessionPhase.rest);
        expect(service.state.currentRound, 1);

        // Rest voice after bell delay
        async.elapse(const Duration(seconds: 3));
        expect(fakeAudio.restVoiceCount, 1);

        // --- Rest 1 finishes ---
        async.elapse(const Duration(seconds: 7));
        expect(service.state.phase, SessionPhase.round);
        expect(service.state.currentRound, 2);

        // Start voice for round 2
        fakeAudio.startVoiceCount = 0;
        async.elapse(const Duration(seconds: 3));
        expect(fakeAudio.startVoiceCount, 1);

        // --- Round 2 finishes ---
        async.elapse(const Duration(seconds: 57));
        expect(service.state.phase, SessionPhase.rest);

        // Rest voice for rest 2
        fakeAudio.restVoiceCount = 0;
        async.elapse(const Duration(seconds: 3));
        expect(fakeAudio.restVoiceCount, 1);

        // --- Rest 2 finishes ---
        async.elapse(const Duration(seconds: 7));
        expect(service.state.phase, SessionPhase.round);
        expect(service.state.currentRound, 3);

        // --- Round 3 (last) finishes ---
        async.elapse(const Duration(seconds: 60));
        expect(service.state.state, SessionState.completed);
        expect(service.state.remainingSeconds, 0);

        // No rest voice after final round
        fakeAudio.restVoiceCount = 0;
        async.elapse(const Duration(seconds: 10));
        expect(fakeAudio.restVoiceCount, 0);

        service.reset();
      });
    });

    test('pause and resume preserves state correctly', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          restDuration: 10,
          totalRounds: 2,
        );

        service.start();
        async.elapse(const Duration(seconds: 20));
        expect(service.state.remainingSeconds, 40);

        service.pause();
        expect(service.state.state, SessionState.paused);

        // Time passes but remaining stays the same
        async.elapse(const Duration(seconds: 10));
        expect(service.state.remainingSeconds, 40);

        service.resume();
        expect(service.state.state, SessionState.running);

        async.elapse(const Duration(seconds: 5));
        expect(service.state.remainingSeconds, 35);

        service.reset();
      });
    });

    test('reset returns to idle state with correct durations', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 120,
          restDuration: 30,
          totalRounds: 5,
        );

        service.start();
        async.elapse(const Duration(seconds: 50));

        service.reset();
        expect(service.state.state, SessionState.idle);
        expect(service.state.currentRound, 1);
        expect(service.state.phase, SessionPhase.round);
        expect(service.state.remainingSeconds, 120);
        expect(service.state.totalRounds, 5);
      });
    });

    test('reset stops audio', () {
      fakeAsync((async) {
        final service = createService(roundDuration: 60);

        service.start();
        async.elapse(const Duration(seconds: 5));
        fakeAudio.clearCounters();

        service.reset();
        expect(fakeAudio.calls, contains('stop'));
      });
    });
  });

  group('TimerService updateSettings', () {
    test('updates settings when idle', () {
      final service = createService(
        roundDuration: 60,
        restDuration: 10,
        totalRounds: 2,
      );

      service.updateSettings(const TimerSettings(
        roundDurationSeconds: 120,
        restDurationSeconds: 30,
        totalRounds: 5,
      ));

      expect(service.state.roundDurationSeconds, 120);
      expect(service.state.restDurationSeconds, 30);
      expect(service.state.totalRounds, 5);
      expect(service.state.remainingSeconds, 120);
    });

    test('does not reset state when running', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          restDuration: 10,
          totalRounds: 2,
        );

        service.start();
        async.elapse(const Duration(seconds: 10));

        service.updateSettings(const TimerSettings(
          roundDurationSeconds: 120,
        ));

        // State should still be running, not reset
        expect(service.state.state, SessionState.running);
        expect(service.state.remainingSeconds, 50); // 60 - 10

        service.reset();
      });
    });
  });

  group('TimerService pause stops audio', () {
    test('pause calls audioService.stop()', () {
      fakeAsync((async) {
        final service = createService(roundDuration: 60);

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 5));
        service.pause();

        expect(fakeAudio.calls, contains('stop'));
      });
    });

    test('pause cancels pending voice timers', () {
      fakeAsync((async) {
        final service = createService(roundDuration: 60);

        service.start();
        fakeAudio.clearCounters();

        // Pause before bell delay (3s) so start voice shouldn't fire
        async.elapse(const Duration(seconds: 1));
        service.pause();

        async.elapse(const Duration(seconds: 10));
        expect(fakeAudio.startVoiceCount, 0);
        expect(fakeAudio.calls, contains('stop'));

        service.reset();
      });
    });
  });

  group('TimerService countdown sounds', () {
    test('plays count_3, count_2, count_1 at remaining seconds 3, 2, 1', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 10,
          totalRounds: 1,
        );

        service.start();
        fakeAudio.clearCounters();

        // Advance to remaining = 3 (7 seconds in)
        async.elapse(const Duration(seconds: 7));
        expect(fakeAudio.calls, contains('playCount_3'));

        // remaining = 2
        async.elapse(const Duration(seconds: 1));
        expect(fakeAudio.calls, contains('playCount_2'));

        // remaining = 1
        async.elapse(const Duration(seconds: 1));
        expect(fakeAudio.calls, contains('playCount_1'));

        service.reset();
      });
    });

    test('plays count sounds during rest countdown', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 5,
          restDuration: 10,
          totalRounds: 2,
        );

        service.start();

        // Finish round 1 → enter rest
        async.elapse(const Duration(seconds: 5));
        fakeAudio.clearCounters();

        // Advance to rest remaining = 3 (7 seconds into rest)
        async.elapse(const Duration(seconds: 7));
        expect(fakeAudio.calls, contains('playCount_3'));

        async.elapse(const Duration(seconds: 1));
        expect(fakeAudio.calls, contains('playCount_2'));

        async.elapse(const Duration(seconds: 1));
        expect(fakeAudio.calls, contains('playCount_1'));

        service.reset();
      });
    });

    test('plays countFinish when last round ends', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 5,
          totalRounds: 1,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 5));
        expect(service.state.state, SessionState.completed);
        expect(fakeAudio.calls, contains('playCountFinish'));

        service.reset();
      });
    });

    test('plays countRest when rest starts (non-last round)', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 5,
          restDuration: 10,
          totalRounds: 2,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 5));
        expect(service.state.phase, SessionPhase.rest);
        expect(fakeAudio.calls, contains('playCountRest'));

        service.reset();
      });
    });

    test('plays countStart when new round starts after rest', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 5,
          restDuration: 5,
          totalRounds: 2,
        );

        service.start();
        fakeAudio.clearCounters();

        // Finish round 1 + rest
        async.elapse(const Duration(seconds: 5)); // round ends
        async.elapse(const Duration(seconds: 5)); // rest ends

        expect(service.state.phase, SessionPhase.round);
        expect(service.state.currentRound, 2);
        expect(fakeAudio.calls, contains('playCountStart'));

        service.reset();
      });
    });

    test('count sounds play even when motivational sound is off', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 10,
          totalRounds: 1,
          enableMotivationalSound: false,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 7));
        expect(fakeAudio.calls, contains('playCount_3'));

        async.elapse(const Duration(seconds: 1));
        expect(fakeAudio.calls, contains('playCount_2'));

        async.elapse(const Duration(seconds: 1));
        expect(fakeAudio.calls, contains('playCount_1'));

        async.elapse(const Duration(seconds: 1));
        expect(fakeAudio.calls, contains('playCountFinish'));

        service.reset();
      });
    });
  });

  group('TimerService no TTS quotes', () {
    test('does not call speakQuote or speakQuoteForced', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          restDuration: 10,
          totalRounds: 2,
        );

        service.start();

        // Full round + rest + second round
        async.elapse(const Duration(seconds: 60));
        async.elapse(const Duration(seconds: 10));
        async.elapse(const Duration(seconds: 60));

        expect(fakeAudio.calls, isNot(contains('speakQuote')));
        expect(fakeAudio.calls, isNot(contains('speakQuoteForced')));

        service.reset();
      });
    });
  });
}
