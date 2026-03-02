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
  Future<void> play30SecBell() async {
    calls.add('play30SecBell');
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
  Future<void> playCount30Seconds(SavageLevel level, bool enableMotivationalSound) async {
    calls.add('playCount30Seconds');
  }

  @override
  Future<void> play30SecBellThenCount(SavageLevel level, bool enableMotivationalSound) async {
    calls.add('play30SecBell');
    calls.add('playCount30Seconds');
  }

  @override
  Future<void> startKeepAlive() async {
    calls.add('startKeepAlive');
  }

  @override
  Future<void> stopKeepAlive() async {
    calls.add('stopKeepAlive');
  }

  @override
  Future<void> stopVoice() async {
    calls.add('stopVoice');
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }

  @override
  void resetQuoteCooldown() {
    calls.add('resetQuoteCooldown');
  }

  double lastVolume = 0.8;

  @override
  Future<void> setVolume(double volume) async {
    lastVolume = volume;
    calls.add('setVolume');
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

/// A fake VibrationService that records method calls for verification.
class FakeVibrationService implements VibrationService {
  final List<String> calls = [];

  @override
  Future<void> roundStart() async { calls.add('roundStart'); }
  @override
  Future<void> roundEnd() async { calls.add('roundEnd'); }
  @override
  Future<void> lastSecondsAlert() async { calls.add('lastSecondsAlert'); }
  @override
  Future<void> restEnd() async { calls.add('restEnd'); }
  @override
  Future<void> sessionComplete() async { calls.add('sessionComplete'); }

  void clearCalls() => calls.clear();

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
    bool enableLastSecondsAlert = true,
    int lastSecondsThreshold = 30,
    Random? random,
    int preparationSeconds = 0,
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
        enableLastSecondsAlert: enableLastSecondsAlert,
        lastSecondsThreshold: lastSecondsThreshold,
      ),
      random: random,
      preparationSeconds: preparationSeconds,
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
          enableLastSecondsAlert: false,
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
            enableLastSecondsAlert: false,
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
          enableLastSecondsAlert: false,
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
    test('30sec bell fires during round with lastSecondsAlert enabled', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          totalRounds: 1,
          enableMotivationalSound: true,
        );

        service.start();
        fakeAudio.clearCounters();

        // Advance to exactly the lastSecondsThreshold (default 30)
        // At tick 30, remainingSeconds becomes 30 → triggers 30sec bell
        async.elapse(const Duration(seconds: 30));
        expect(fakeAudio.calls, contains('play30SecBell'));

        service.reset();
      });
    });

    test('30sec bell fires even when motivational sound is off', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          totalRounds: 1,
          enableMotivationalSound: false,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 30));
        expect(fakeAudio.calls, contains('play30SecBell'));

        // But no voices
        expect(fakeAudio.startVoiceCount, 0);
        expect(fakeAudio.exerciseVoiceCount, 0);

        service.reset();
      });
    });

    test('30sec bell does not fire when lastSecondsAlert is disabled', () {
      fakeAsync((async) {
        final service = TimerService(
          audioService: fakeAudio,
          vibrationService: fakeVibration,
          settings: const TimerSettings(
            roundDurationSeconds: 60,
            totalRounds: 1,
            enableLastSecondsAlert: false,
          ),
          preparationSeconds: 0,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 60));
        expect(fakeAudio.calls, isNot(contains('play30SecBell')));

        service.reset();
      });
    });

    test('30sec bell fires only once per round', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          totalRounds: 1,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 60));
        final bellCount =
            fakeAudio.calls.where((c) => c == 'play30SecBell').length;
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

  group('TimerService volume changes while running', () {
    test('volume change applies to audio service without stopping timer', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          restDuration: 10,
          totalRounds: 2,
        );

        service.start();
        async.elapse(const Duration(seconds: 10));
        fakeAudio.calls.clear();

        service.updateSettings(const TimerSettings(
          roundDurationSeconds: 60,
          restDurationSeconds: 10,
          totalRounds: 2,
          volume: 0.5,
        ));

        // Timer should still be running
        expect(service.state.state, SessionState.running);
        expect(service.state.remainingSeconds, 50); // 60 - 10

        // Volume should have been applied to audio service
        expect(fakeAudio.calls, contains('setVolume'));
        expect(fakeAudio.lastVolume, 0.5);

        service.reset();
      });
    });

    test('setVolume is not called when volume has not changed', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          restDuration: 10,
          totalRounds: 2,
        );

        service.start();
        async.elapse(const Duration(seconds: 5));
        fakeAudio.calls.clear();

        // Update settings with same default volume (0.8)
        service.updateSettings(const TimerSettings(
          roundDurationSeconds: 120,
        ));

        expect(fakeAudio.calls, isNot(contains('setVolume')));

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

  group('TimerService vibration toggle', () {
    TimerService makeService({
      required bool enableVibration,
      int roundDuration = 20,
      int restDuration = 5,
      int totalRounds = 2,
      bool enableLastSecondsAlert = true,
      int lastSecondsThreshold = 10,
    }) {
      return TimerService(
        audioService: fakeAudio,
        vibrationService: fakeVibration,
        settings: TimerSettings(
          roundDurationSeconds: roundDuration,
          restDurationSeconds: restDuration,
          totalRounds: totalRounds,
          enableVibration: enableVibration,
          enableLastSecondsAlert: enableLastSecondsAlert,
          lastSecondsThreshold: lastSecondsThreshold,
        ),
        preparationSeconds: 0,
      );
    }

    test('calls roundStart vibration when enableVibration is true', () {
      fakeAsync((async) {
        fakeVibration.clearCalls();
        final service = makeService(enableVibration: true);
        service.start();
        expect(fakeVibration.calls, contains('roundStart'));
        service.reset();
      });
    });

    test('skips roundStart vibration when enableVibration is false', () {
      fakeAsync((async) {
        fakeVibration.clearCalls();
        final service = makeService(enableVibration: false);
        service.start();
        expect(fakeVibration.calls, isNot(contains('roundStart')));
        service.reset();
      });
    });

    test('calls roundEnd vibration when round ends and enabled', () {
      fakeAsync((async) {
        final service = makeService(enableVibration: true, totalRounds: 2);
        service.start();
        fakeVibration.clearCalls();
        async.elapse(const Duration(seconds: 20));
        expect(fakeVibration.calls, contains('roundEnd'));
        service.reset();
      });
    });

    test('skips roundEnd vibration when disabled', () {
      fakeAsync((async) {
        final service = makeService(enableVibration: false, totalRounds: 2);
        service.start();
        fakeVibration.clearCalls();
        async.elapse(const Duration(seconds: 20));
        expect(fakeVibration.calls, isNot(contains('roundEnd')));
        service.reset();
      });
    });

    test('calls restEnd vibration when rest ends and enabled', () {
      fakeAsync((async) {
        final service = makeService(enableVibration: true, totalRounds: 2);
        service.start();
        async.elapse(const Duration(seconds: 20)); // round ends → rest
        fakeVibration.clearCalls();
        async.elapse(const Duration(seconds: 5)); // rest ends
        expect(fakeVibration.calls, contains('restEnd'));
        service.reset();
      });
    });

    test('skips restEnd vibration when disabled', () {
      fakeAsync((async) {
        final service = makeService(enableVibration: false, totalRounds: 2);
        service.start();
        async.elapse(const Duration(seconds: 20)); // round ends → rest
        fakeVibration.clearCalls();
        async.elapse(const Duration(seconds: 5)); // rest ends
        expect(fakeVibration.calls, isNot(contains('restEnd')));
        service.reset();
      });
    });

    test('calls sessionComplete vibration on last round end when enabled', () {
      fakeAsync((async) {
        final service = makeService(enableVibration: true, totalRounds: 1);
        service.start();
        fakeVibration.clearCalls();
        async.elapse(const Duration(seconds: 20));
        expect(fakeVibration.calls, contains('sessionComplete'));
        service.reset();
      });
    });

    test('skips sessionComplete vibration when disabled', () {
      fakeAsync((async) {
        final service = makeService(enableVibration: false, totalRounds: 1);
        service.start();
        fakeVibration.clearCalls();
        async.elapse(const Duration(seconds: 20));
        expect(fakeVibration.calls, isNot(contains('sessionComplete')));
        service.reset();
      });
    });

    test('calls lastSecondsAlert vibration when both flags are enabled', () {
      fakeAsync((async) {
        final service = makeService(
          enableVibration: true,
          totalRounds: 1,
          enableLastSecondsAlert: true,
          lastSecondsThreshold: 10,
        );
        service.start();
        fakeVibration.clearCalls();
        // At 10s elapsed, remainingSeconds drops to 10 → triggers alert
        async.elapse(const Duration(seconds: 10));
        expect(fakeVibration.calls, contains('lastSecondsAlert'));
        service.reset();
      });
    });

    test('skips lastSecondsAlert vibration when enableVibration is false', () {
      fakeAsync((async) {
        final service = makeService(
          enableVibration: false,
          totalRounds: 1,
          enableLastSecondsAlert: true,
          lastSecondsThreshold: 10,
        );
        service.start();
        fakeVibration.clearCalls();
        async.elapse(const Duration(seconds: 20));
        expect(fakeVibration.calls, isNot(contains('lastSecondsAlert')));
        service.reset();
      });
    });

    test('no vibration calls at all when enableVibration is false', () {
      fakeAsync((async) {
        final service = makeService(
          enableVibration: false,
          totalRounds: 2,
          enableLastSecondsAlert: true,
          lastSecondsThreshold: 10,
        );
        fakeVibration.clearCalls();
        service.start();
        async.elapse(const Duration(seconds: 20)); // round 1 ends
        async.elapse(const Duration(seconds: 5));  // rest ends
        async.elapse(const Duration(seconds: 20)); // round 2 ends (session complete)
        expect(fakeVibration.calls, isEmpty);
        service.reset();
      });
    });
  });

  group('TimerService keepalive lifecycle', () {
    test('start calls startKeepAlive', () {
      fakeAsync((async) {
        final service = createService(roundDuration: 60);

        service.start();
        expect(fakeAudio.calls, contains('startKeepAlive'));

        service.reset();
      });
    });

    test('pause calls stopKeepAlive', () {
      fakeAsync((async) {
        final service = createService(roundDuration: 60);

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 5));
        service.pause();
        expect(fakeAudio.calls, contains('stopKeepAlive'));

        service.reset();
      });
    });

    test('resume calls startKeepAlive', () {
      fakeAsync((async) {
        final service = createService(roundDuration: 60);

        service.start();
        async.elapse(const Duration(seconds: 5));
        service.pause();
        fakeAudio.clearCounters();

        service.resume();
        expect(fakeAudio.calls, contains('startKeepAlive'));

        service.reset();
      });
    });

    test('reset calls stopKeepAlive', () {
      fakeAsync((async) {
        final service = createService(roundDuration: 60);

        service.start();
        async.elapse(const Duration(seconds: 5));
        fakeAudio.clearCounters();

        service.reset();
        expect(fakeAudio.calls, contains('stopKeepAlive'));
      });
    });

    test('session completion calls stopKeepAlive', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 5,
          totalRounds: 1,
        );

        service.start();
        fakeAudio.clearCounters();

        async.elapse(const Duration(seconds: 5));
        expect(service.state.state, SessionState.completed);
        expect(fakeAudio.calls, contains('stopKeepAlive'));

        service.reset();
      });
    });

    test('keepalive not restarted during running phase transitions', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 5,
          restDuration: 5,
          totalRounds: 2,
        );

        service.start();
        fakeAudio.clearCounters();

        // Round 1 ends → rest starts (no new startKeepAlive)
        async.elapse(const Duration(seconds: 5));
        expect(fakeAudio.calls, isNot(contains('startKeepAlive')));

        // Rest ends → round 2 starts (no new startKeepAlive)
        fakeAudio.clearCounters();
        async.elapse(const Duration(seconds: 5));
        expect(fakeAudio.calls, isNot(contains('startKeepAlive')));

        service.reset();
      });
    });
  });

  group('TimerService skip', () {
    test('skip during round transitions to rest', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          restDuration: 10,
          totalRounds: 2,
        );

        service.start();
        async.elapse(const Duration(seconds: 20));

        service.skip();
        expect(service.state.phase, SessionPhase.rest);
        expect(service.state.remainingSeconds, 10);

        service.reset();
      });
    });

    test('skip during last round completes session', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          totalRounds: 1,
        );

        service.start();
        async.elapse(const Duration(seconds: 20));

        service.skip();
        expect(service.state.state, SessionState.completed);
        expect(service.state.remainingSeconds, 0);

        service.reset();
      });
    });

    test('skip during rest transitions to next round', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 5,
          restDuration: 30,
          totalRounds: 3,
        );

        service.start();
        async.elapse(const Duration(seconds: 5)); // finish round → rest
        expect(service.state.phase, SessionPhase.rest);

        service.skip();
        expect(service.state.phase, SessionPhase.round);
        expect(service.state.currentRound, 2);
        expect(service.state.remainingSeconds, 5);

        service.reset();
      });
    });

    test('skip does not call audioService.stop() to avoid race condition', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          totalRounds: 2,
        );

        service.start();
        async.elapse(const Duration(seconds: 10));
        fakeAudio.clearCounters();

        service.skip();
        // stop() must NOT be called — it races with the transition sound
        expect(fakeAudio.calls, isNot(contains('stop')));

        service.reset();
      });
    });

    test('skip plays count_rest when skipping non-last round', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          restDuration: 10,
          totalRounds: 2,
        );

        service.start();
        async.elapse(const Duration(seconds: 10));
        fakeAudio.clearCounters();

        service.skip();
        expect(fakeAudio.calls, contains('playCountRest'));

        service.reset();
      });
    });

    test('skip plays count_finish when skipping last round', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          totalRounds: 1,
        );

        service.start();
        async.elapse(const Duration(seconds: 10));
        fakeAudio.clearCounters();

        service.skip();
        expect(fakeAudio.calls, contains('playCountFinish'));

        service.reset();
      });
    });

    test('skip plays count_start when skipping rest', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 5,
          restDuration: 30,
          totalRounds: 2,
        );

        service.start();
        async.elapse(const Duration(seconds: 5)); // finish round → rest
        fakeAudio.clearCounters();

        service.skip();
        expect(fakeAudio.calls, contains('playCountStart'));

        service.reset();
      });
    });

    test('skip from paused state transitions correctly', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          restDuration: 10,
          totalRounds: 2,
        );

        service.start();
        async.elapse(const Duration(seconds: 20));
        service.pause();
        expect(service.state.state, SessionState.paused);

        service.skip();
        expect(service.state.phase, SessionPhase.rest);
        expect(service.state.state, SessionState.running);
        expect(service.state.remainingSeconds, 10);

        service.reset();
      });
    });

    test('skip when idle is a no-op', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          totalRounds: 2,
        );

        final stateBefore = service.state;
        service.skip();
        expect(service.state.state, stateBefore.state);
        expect(service.state.remainingSeconds, stateBefore.remainingSeconds);
      });
    });

    test('skip when completed is a no-op', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 5,
          totalRounds: 1,
        );

        service.start();
        async.elapse(const Duration(seconds: 5));
        expect(service.state.state, SessionState.completed);

        fakeAudio.clearCounters();
        service.skip();
        // Should still be completed, no new audio calls
        expect(service.state.state, SessionState.completed);
        expect(fakeAudio.calls, isEmpty);
      });
    });

    test('skip cancels pending voice timers from current phase', () {
      fakeAsync((async) {
        final seeded = SeededRandom([0, 0, 0, 0, 0]);
        final service = createService(
          roundDuration: 60,
          restDuration: 10,
          totalRounds: 2,
          random: seeded,
        );

        service.start();
        fakeAudio.clearCounters();

        // Skip before any exercise voices fire (at 5s into 60s round)
        async.elapse(const Duration(seconds: 5));
        service.skip();

        // Original round's exercise voices should not fire during rest
        fakeAudio.exerciseVoiceCount = 0;
        fakeAudio.startVoiceCount = 0;
        async.elapse(const Duration(seconds: 5)); // still in rest
        expect(fakeAudio.exerciseVoiceCount, 0);

        service.reset();
      });
    });
  });

  group('Preparation countdown', () {
    test('start enters preparing state with 3-second countdown', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          preparationSeconds: 3,
        );

        service.start();
        expect(service.state.state, SessionState.preparing);
        expect(service.state.remainingSeconds, 3);
        expect(service.state.preparationCountdown, '3');
        expect(service.state.phaseLabel, 'GET READY');
        expect(service.state.progress, 0.0);
        expect(service.state.elapsedSeconds, 0);
        expect(service.state.nextPhaseLabel, isNull);

        service.reset();
      });
    });

    test('countdown ticks 3 -> 2 -> 1 -> running', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          preparationSeconds: 3,
        );

        service.start();
        expect(service.state.state, SessionState.preparing);
        expect(service.state.remainingSeconds, 3);

        async.elapse(const Duration(seconds: 1));
        expect(service.state.state, SessionState.preparing);
        expect(service.state.remainingSeconds, 2);

        async.elapse(const Duration(seconds: 1));
        expect(service.state.state, SessionState.preparing);
        expect(service.state.remainingSeconds, 1);

        async.elapse(const Duration(seconds: 1));
        expect(service.state.state, SessionState.running);
        expect(service.state.remainingSeconds, 60);

        service.reset();
      });
    });

    test('plays countdown audio at each tick', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          preparationSeconds: 3,
        );

        service.start();
        // playCount(3) on start
        expect(fakeAudio.calls, contains('playCount_3'));

        async.elapse(const Duration(seconds: 1));
        expect(fakeAudio.calls, contains('playCount_2'));

        async.elapse(const Duration(seconds: 1));
        expect(fakeAudio.calls, contains('playCount_1'));

        async.elapse(const Duration(seconds: 1));
        // playCountStart when transitioning to running
        expect(fakeAudio.calls, contains('playCountStart'));

        service.reset();
      });
    });

    test('vibrates on transition to running', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          preparationSeconds: 3,
        );

        service.start();
        fakeVibration.clearCalls();

        async.elapse(const Duration(seconds: 3));
        expect(fakeVibration.calls, contains('roundStart'));

        service.reset();
      });
    });

    test('pause during preparation', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          preparationSeconds: 3,
        );

        service.start();
        async.elapse(const Duration(seconds: 1));
        expect(service.state.remainingSeconds, 2);

        service.pause();
        expect(service.state.state, SessionState.paused);
        expect(service.state.remainingSeconds, 2);

        // Time should not advance while paused
        async.elapse(const Duration(seconds: 5));
        expect(service.state.state, SessionState.paused);

        service.reset();
      });
    });

    test('resume after pause during preparation', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          preparationSeconds: 3,
        );

        service.start();
        async.elapse(const Duration(seconds: 1));
        expect(service.state.remainingSeconds, 2);

        service.pause();
        service.resume();
        expect(service.state.state, SessionState.preparing);
        expect(service.state.remainingSeconds, 2);

        // Should continue countdown from where it left off
        async.elapse(const Duration(seconds: 2));
        expect(service.state.state, SessionState.running);
        expect(service.state.remainingSeconds, 60);

        service.reset();
      });
    });

    test('skip during preparation goes to running', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          preparationSeconds: 3,
        );

        service.start();
        async.elapse(const Duration(seconds: 1));

        service.skip();
        expect(service.state.state, SessionState.running);
        expect(service.state.remainingSeconds, 60);
        expect(fakeAudio.calls, contains('playCountStart'));

        service.reset();
      });
    });

    test('reset during preparation', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          preparationSeconds: 3,
        );

        service.start();
        async.elapse(const Duration(seconds: 1));

        service.reset();
        expect(service.state.state, SessionState.idle);
        expect(service.state.remainingSeconds, 60);

        // Prep timer should not fire
        async.elapse(const Duration(seconds: 5));
        expect(service.state.state, SessionState.idle);
      });
    });

    test('preparationSeconds 0 skips preparation entirely', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          preparationSeconds: 0,
        );

        service.start();
        expect(service.state.state, SessionState.running);
        expect(service.state.remainingSeconds, 60);

        service.reset();
      });
    });

    test('double start during preparing is a no-op', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          preparationSeconds: 3,
        );

        service.start();
        expect(service.state.state, SessionState.preparing);
        expect(service.state.remainingSeconds, 3);

        // Calling start again should not restart
        service.start();
        expect(service.state.state, SessionState.preparing);
        expect(service.state.remainingSeconds, 3);

        service.reset();
      });
    });

    test('start after completed enters preparation', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 10,
          totalRounds: 1,
          preparationSeconds: 3,
        );

        service.start();
        // Advance through prep (3s) + full round (10s)
        async.elapse(const Duration(seconds: 13));
        expect(service.state.state, SessionState.completed);

        // Start again should enter preparing
        service.start();
        expect(service.state.state, SessionState.preparing);
        expect(service.state.remainingSeconds, 3);

        service.reset();
      });
    });

    test('skip while paused during preparation goes to running', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          preparationSeconds: 3,
        );

        service.start();
        async.elapse(const Duration(seconds: 1));
        service.pause();
        expect(service.state.state, SessionState.paused);

        service.skip();
        expect(service.state.state, SessionState.running);
        expect(service.state.remainingSeconds, 60);

        service.reset();
      });
    });

    test('reconcile during preparing is a no-op', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          preparationSeconds: 3,
        );

        service.start();
        expect(service.state.state, SessionState.preparing);
        expect(service.state.remainingSeconds, 3);

        service.reconcile();
        // Should remain unchanged
        expect(service.state.state, SessionState.preparing);
        expect(service.state.remainingSeconds, 3);

        service.reset();
      });
    });

    test('startKeepAlive is called when preparation begins', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 60,
          preparationSeconds: 3,
        );

        fakeAudio.calls.clear();
        service.start();
        expect(fakeAudio.calls, contains('startKeepAlive'));

        service.reset();
      });
    });

    test('preparation flows into normal round timer correctly', () {
      fakeAsync((async) {
        final service = createService(
          roundDuration: 10,
          restDuration: 5,
          totalRounds: 2,
          preparationSeconds: 3,
        );

        service.start();
        // Advance through prep
        async.elapse(const Duration(seconds: 3));
        expect(service.state.state, SessionState.running);
        expect(service.state.phase, SessionPhase.round);
        expect(service.state.currentRound, 1);

        // Advance through round 1
        async.elapse(const Duration(seconds: 10));
        expect(service.state.phase, SessionPhase.rest);

        // Advance through rest
        async.elapse(const Duration(seconds: 5));
        expect(service.state.phase, SessionPhase.round);
        expect(service.state.currentRound, 2);

        // Advance through round 2
        async.elapse(const Duration(seconds: 10));
        expect(service.state.state, SessionState.completed);

        service.reset();
      });
    });

    test('nextPhaseDurationSeconds is null during preparing', () {
      final session = const WorkoutSession(
        state: SessionState.preparing,
        remainingSeconds: 2,
      );
      expect(session.nextPhaseDurationSeconds, isNull);
    });

    test('preparationCountdown returns null for non-preparing states', () {
      expect(
        const WorkoutSession(state: SessionState.idle).preparationCountdown,
        isNull,
      );
      expect(
        const WorkoutSession(state: SessionState.running, remainingSeconds: 30)
            .preparationCountdown,
        isNull,
      );
      expect(
        const WorkoutSession(state: SessionState.paused, remainingSeconds: 30)
            .preparationCountdown,
        isNull,
      );
      expect(
        const WorkoutSession(state: SessionState.completed).preparationCountdown,
        isNull,
      );
    });
  });

  group('30-second count voice', () {
    test('plays count_30seconds immediately with bell when last seconds alert triggers', () {
      fakeAsync((async) {
        final service = createService(roundDuration: 60, totalRounds: 1);

        service.start();
        fakeAudio.calls.clear();

        // Advance to the point where remainingSeconds == 30
        async.elapse(const Duration(seconds: 30));
        // Both should play on the same tick — bell on _warningPlayer,
        // count_30seconds on _countPlayer (no delay needed).
        expect(fakeAudio.calls, contains('play30SecBell'));
        expect(fakeAudio.calls, contains('playCount30Seconds'));

        service.reset();
      });
    });

    test('stops voice player when 30sec bell triggers to prevent overlap', () {
      fakeAsync((async) {
        final service = createService(roundDuration: 60, totalRounds: 1);

        service.start();
        fakeAudio.calls.clear();

        // Advance to the point where remainingSeconds == 30
        async.elapse(const Duration(seconds: 30));
        expect(fakeAudio.calls, contains('play30SecBell'));
        expect(fakeAudio.calls, contains('stopVoice'));

        service.reset();
      });
    });

    test('no exercise voices fire after 30sec alert triggers', () {
      fakeAsync((async) {
        // Use a 60s round so exercise voices would normally be scheduled
        // in the middle of the round and could overlap with the last 30s.
        final service = createService(
          roundDuration: 60,
          totalRounds: 1,
          enableMotivationalSound: true,
        );

        service.start();

        // Advance to just before the 30-sec threshold
        async.elapse(const Duration(seconds: 29));
        fakeAudio.exerciseVoiceCount = 0;

        // Trigger the 30-sec alert (remaining goes from 31 to 30)
        async.elapse(const Duration(seconds: 1));
        expect(fakeAudio.calls, contains('play30SecBell'));

        // From this point on, no exercise voices should play for the
        // rest of the round (the remaining 30 seconds).
        fakeAudio.exerciseVoiceCount = 0;
        async.elapse(const Duration(seconds: 30));
        expect(fakeAudio.exerciseVoiceCount, 0);

        service.reset();
      });
    });

  });
}
