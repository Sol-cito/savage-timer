import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/timer_settings.dart';
import '../models/workout_session.dart';
import 'audio_service.dart';
import 'settings_service.dart';
import 'vibration_service.dart';

class TimerService extends StateNotifier<WorkoutSession> {
  Timer? _timer;
  Timer? _prepTimer;
  Timer? _startVoiceTimer;
  Timer? _restVoiceTimer;

  final List<Timer> _exerciseVoiceTimers = [];
  final AudioService _audioService;
  final VibrationService _vibrationService;
  TimerSettings _settings;
  final Random _random;

  bool _lastSecondsAlertTriggered = false;
  bool _pausedDuringPreparation = false;

  final int _preparationSeconds;

  /// Wall-clock tracking for iOS background reconciliation.
  DateTime? _phaseStartedAt;
  int _phaseStartedWithSeconds = 0;

  /// Bell duration in seconds — voices are delayed by this to avoid overlap.
  static const _bellDurationSeconds = 3;

  /// Max assumed voice clip duration in seconds.
  static const _voiceBufferSeconds = 8;

  TimerService({
    required AudioService audioService,
    required VibrationService vibrationService,
    required TimerSettings settings,
    Random? random,
    int preparationSeconds = 3,
  }) : _audioService = audioService,
       _vibrationService = vibrationService,
       _settings = settings,
       _random = random ?? Random(),
       _preparationSeconds = preparationSeconds,
       super(
         WorkoutSession(
           totalRounds: settings.totalRounds,
           roundDurationSeconds: settings.roundDurationSeconds,
           restDurationSeconds: settings.restDurationSeconds,
           remainingSeconds: settings.roundDurationSeconds,
         ),
       );

  void updateSettings(TimerSettings settings) {
    final previous = _settings;
    _settings = settings;

    // Volume can be adjusted live without affecting the timer.
    if (previous.volume != settings.volume) {
      _audioService.setVolume(settings.volume);
    }

    if (state.state == SessionState.idle) {
      state = WorkoutSession(
        totalRounds: settings.totalRounds,
        roundDurationSeconds: settings.roundDurationSeconds,
        restDurationSeconds: settings.restDurationSeconds,
        remainingSeconds: settings.roundDurationSeconds,
      );
    }
  }

  void start() {
    if (state.state == SessionState.running ||
        state.state == SessionState.preparing) {
      return;
    }

    if (state.state == SessionState.idle ||
        state.state == SessionState.completed) {
      _resetState();
    }

    _audioService.startKeepAlive();

    if (_preparationSeconds <= 0) {
      // Skip preparation, go straight to running
      state = state.copyWith(state: SessionState.running);
      _startTimer();
      _audioService.playCountStart(
        _settings.savageLevel,
        _settings.enableMotivationalSound,
      );
      if (_settings.enableVibration) _vibrationService.roundStart();
      if (_settings.enableMotivationalSound) {
        _startVoiceTimer?.cancel();
        _startVoiceTimer = Timer(
          const Duration(seconds: _bellDurationSeconds),
          () {
            if (state.state == SessionState.running &&
                state.phase == SessionPhase.round) {
              _audioService.playRandomStartVoice(_settings.savageLevel);
            }
          },
        );
      }
      _scheduleExerciseVoices();
      return;
    }

    // Enter preparation countdown
    state = state.copyWith(
      state: SessionState.preparing,
      remainingSeconds: _preparationSeconds,
    );
    _audioService.playCount(
      _preparationSeconds,
      _settings.savageLevel,
      _settings.enableMotivationalSound,
    );
    _startPrepTimer();
  }

  void _startPrepTimer() {
    _prepTimer?.cancel();
    _prepTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _prepTick(),
    );
  }

  void _prepTick() {
    if (state.state != SessionState.preparing) return;

    final newRemaining = state.remainingSeconds - 1;

    if (newRemaining <= 0) {
      // Preparation done — transition to running
      _prepTimer?.cancel();
      _audioService.playCountStart(
        _settings.savageLevel,
        _settings.enableMotivationalSound,
      );
      if (_settings.enableVibration) _vibrationService.roundStart();

      state = state.copyWith(
        state: SessionState.running,
        remainingSeconds: _settings.roundDurationSeconds,
      );
      _startTimer();

      // Schedule start voice after count_start finishes
      if (_settings.enableMotivationalSound) {
        _startVoiceTimer?.cancel();
        _startVoiceTimer = Timer(
          const Duration(seconds: _bellDurationSeconds),
          () {
            if (state.state == SessionState.running &&
                state.phase == SessionPhase.round) {
              _audioService.playRandomStartVoice(_settings.savageLevel);
            }
          },
        );
      }

      _scheduleExerciseVoices();
    } else {
      _audioService.playCount(
        newRemaining,
        _settings.savageLevel,
        _settings.enableMotivationalSound,
      );
      state = state.copyWith(remainingSeconds: newRemaining);
    }
  }

  void pause() {
    if (state.state == SessionState.preparing) {
      _prepTimer?.cancel();
      _pausedDuringPreparation = true;
      _audioService.stop();
      _audioService.stopKeepAlive();
      state = state.copyWith(state: SessionState.paused);
      return;
    }
    if (state.state != SessionState.running) return;
    _timer?.cancel();
    _startVoiceTimer?.cancel();
    _restVoiceTimer?.cancel();

    _cancelExerciseVoiceTimers();
    _audioService.stop();
    _audioService.stopKeepAlive();
    state = state.copyWith(state: SessionState.paused);
  }

  void resume() {
    if (state.state != SessionState.paused) return;
    if (_pausedDuringPreparation) {
      _pausedDuringPreparation = false;
      state = state.copyWith(state: SessionState.preparing);
      _audioService.startKeepAlive();
      _audioService.playCount(
        state.remainingSeconds,
        _settings.savageLevel,
        _settings.enableMotivationalSound,
      );
      _startPrepTimer();
      return;
    }
    state = state.copyWith(state: SessionState.running);
    _audioService.startKeepAlive();
    _startTimer();
  }

  void skip() {
    if (state.state == SessionState.idle ||
        state.state == SessionState.completed) {
      return;
    }

    // During preparation, skip straight to running
    if (state.state == SessionState.preparing ||
        _pausedDuringPreparation) {
      _prepTimer?.cancel();
      _pausedDuringPreparation = false;

      state = state.copyWith(
        state: SessionState.running,
        remainingSeconds: _settings.roundDurationSeconds,
      );
      if (state.state == SessionState.running) {
        _audioService.startKeepAlive();
      }
      _audioService.playCountStart(
        _settings.savageLevel,
        _settings.enableMotivationalSound,
      );
      if (_settings.enableVibration) _vibrationService.roundStart();
      _startTimer();

      if (_settings.enableMotivationalSound) {
        _startVoiceTimer?.cancel();
        _startVoiceTimer = Timer(
          const Duration(seconds: _bellDurationSeconds),
          () {
            if (state.state == SessionState.running &&
                state.phase == SessionPhase.round) {
              _audioService.playRandomStartVoice(_settings.savageLevel);
            }
          },
        );
      }
      _scheduleExerciseVoices();
      return;
    }

    _timer?.cancel();
    _startVoiceTimer?.cancel();
    _restVoiceTimer?.cancel();

    _cancelExerciseVoiceTimers();

    if (state.state == SessionState.paused) {
      state = state.copyWith(state: SessionState.running);
      _audioService.startKeepAlive();
    }

    _handlePhaseEnd();

    if (state.state == SessionState.running) {
      _startTimer();
    }
  }

  void reset() {
    _timer?.cancel();
    _prepTimer?.cancel();
    _startVoiceTimer?.cancel();
    _restVoiceTimer?.cancel();

    _cancelExerciseVoiceTimers();
    _pausedDuringPreparation = false;
    _audioService.stop();
    _audioService.stopKeepAlive();
    _resetState();
  }

  /// Called when the app returns to foreground. Uses wall-clock time to
  /// catch up with any ticks that were missed while iOS suspended the isolate.
  void reconcile() {
    if (state.state == SessionState.preparing) return;
    if (state.state != SessionState.running) return;
    if (_phaseStartedAt == null) return;

    final now = DateTime.now();
    final elapsed = now.difference(_phaseStartedAt!).inSeconds;
    var remaining = _phaseStartedWithSeconds - elapsed;

    // Process phase transitions while time has overflowed.
    while (remaining <= 0 && state.state == SessionState.running) {
      final overflow = -remaining;
      _handlePhaseEnd();
      if (state.state != SessionState.running) break;
      remaining = state.remainingSeconds - overflow;
    }

    if (state.state == SessionState.running && remaining > 0) {
      state = state.copyWith(remainingSeconds: remaining);
    }

    _recordPhaseStart();
  }

  void _recordPhaseStart() {
    _phaseStartedAt = DateTime.now();
    _phaseStartedWithSeconds = state.remainingSeconds;
  }

  void _resetState() {
    _lastSecondsAlertTriggered = false;
    _phaseStartedAt = null;
    _phaseStartedWithSeconds = 0;

    state = WorkoutSession(
      totalRounds: _settings.totalRounds,
      roundDurationSeconds: _settings.roundDurationSeconds,
      restDurationSeconds: _settings.restDurationSeconds,
      remainingSeconds: _settings.roundDurationSeconds,
      state: SessionState.idle,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _recordPhaseStart();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (state.state != SessionState.running) return;

    final newRemaining = state.remainingSeconds - 1;

    // Check for last seconds alert (bell sound + vibration)
    if (_settings.enableLastSecondsAlert &&
        !_lastSecondsAlertTriggered &&
        state.phase == SessionPhase.round &&
        newRemaining == _settings.lastSecondsThreshold) {
      _lastSecondsAlertTriggered = true;
      if (_settings.enableVibration) _vibrationService.lastSecondsAlert();

      // Cancel scheduled exercise voices and stop any currently playing
      // so nothing talks over the bell + count_30seconds sequence.
      _cancelExerciseVoiceTimers();
      _playLastSecondsAlert();
    }

    // Countdown sounds at 3, 2, 1
    if (newRemaining >= 1 && newRemaining <= 3) {
      _audioService.playCount(
        newRemaining,
        _settings.savageLevel,
        _settings.enableMotivationalSound,
      );
    }

    if (newRemaining <= 0) {
      _handlePhaseEnd();
    } else {
      state = state.copyWith(remainingSeconds: newRemaining);
    }
  }

  /// Stops any exercise voice then plays 30sec bell followed immediately
  /// by the level-specific count_30seconds announcement.
  Future<void> _playLastSecondsAlert() async {
    await _audioService.stopVoice();
    _audioService.play30SecBellThenCount(
      _settings.savageLevel,
      _settings.enableMotivationalSound,
    );
  }

  void _handlePhaseEnd() {
    if (state.phase == SessionPhase.round) {
      // Round ended — cancel any remaining voice timers
      _cancelExerciseVoiceTimers();
      _startVoiceTimer?.cancel();
  
      if (_settings.enableVibration) _vibrationService.roundEnd();

      if (state.isLastRound) {
        // Workout complete — play count_finish
        _audioService.playCountFinish(
          _settings.savageLevel,
          _settings.enableMotivationalSound,
        );
        _timer?.cancel();
        _audioService.stopKeepAlive();
        if (_settings.enableVibration) _vibrationService.sessionComplete();
        state = state.copyWith(
          state: SessionState.completed,
          remainingSeconds: 0,
        );
      } else {
        // Start rest period — play count_rest
        _audioService.playCountRest(
          _settings.savageLevel,
          _settings.enableMotivationalSound,
        );
        _lastSecondsAlertTriggered = false;
        state = state.copyWith(
          phase: SessionPhase.rest,
          remainingSeconds: _settings.restDurationSeconds,
        );
        _recordPhaseStart();

        // Play a random rest voice after count_rest finishes
        if (_settings.enableMotivationalSound) {
          _restVoiceTimer?.cancel();
          _restVoiceTimer = Timer(
            const Duration(seconds: _bellDurationSeconds),
            () {
              if (state.phase == SessionPhase.rest &&
                  state.state == SessionState.running) {
                _audioService.playRandomRestVoice(_settings.savageLevel);
              }
            },
          );
        }
      }
    } else {
      // Rest ended, start next round — play count_start
      _audioService.playCountStart(
        _settings.savageLevel,
        _settings.enableMotivationalSound,
      );
      if (_settings.enableVibration) _vibrationService.restEnd();
      _lastSecondsAlertTriggered = false;
      state = state.copyWith(
        phase: SessionPhase.round,
        currentRound: state.currentRound + 1,
        remainingSeconds: _settings.roundDurationSeconds,
      );
      _recordPhaseStart();

      // Schedule start voice after count_start finishes
      if (_settings.enableMotivationalSound) {
        _startVoiceTimer?.cancel();
        _startVoiceTimer = Timer(
          const Duration(seconds: _bellDurationSeconds),
          () {
            if (state.state == SessionState.running &&
                state.phase == SessionPhase.round) {
              _audioService.playRandomStartVoice(_settings.savageLevel);
            }
          },
        );
      }

      _scheduleExerciseVoices();
    }
  }

  /// Schedules 2–4 exercise voice clips at random times during the current
  /// round. The first clip starts after the bell + start voice gap. The last
  /// clip finishes before the round ends (using an 8-second buffer).
  void _scheduleExerciseVoices() {
    _cancelExerciseVoiceTimers();

    if (!_settings.enableMotivationalSound) return;

    final roundDuration = _settings.roundDurationSeconds;
    // Leave room for bell + start voice + voice buffer at the start
    final minStartDelay = _bellDurationSeconds + _voiceBufferSeconds;
    final maxPlayTime = roundDuration - _voiceBufferSeconds;

    if (maxPlayTime <= minStartDelay) return; // round too short

    final availableWindow = maxPlayTime - minStartDelay;

    // Target voice count based on round duration:
    // ≤90s → 2, ≤180s → 3, >180s → 4
    int targetCount;
    if (roundDuration <= 90) {
      targetCount = 2;
    } else if (roundDuration <= 180) {
      targetCount = 3;
    } else {
      targetCount = 4;
    }

    // Limit by available space (need ≥12s per voice to avoid overlap)
    final voiceCount = min(targetCount, availableWindow ~/ 12);

    if (voiceCount <= 0) return;

    final segmentLength = availableWindow / voiceCount;

    for (int i = 0; i < voiceCount; i++) {
      final segmentStart = minStartDelay + (segmentLength * i).round();
      final segmentEnd = minStartDelay + (segmentLength * (i + 1)).round();
      final range = segmentEnd - segmentStart;
      final playTime = segmentStart + (range > 0 ? _random.nextInt(range) : 0);

      _exerciseVoiceTimers.add(
        Timer(Duration(seconds: playTime), () {
          if (state.phase == SessionPhase.round &&
              state.state == SessionState.running) {
            _audioService.playRandomExerciseVoice(_settings.savageLevel);
          }
        }),
      );
    }
  }

  void _cancelExerciseVoiceTimers() {
    for (final timer in _exerciseVoiceTimers) {
      timer.cancel();
    }
    _exerciseVoiceTimers.clear();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _prepTimer?.cancel();
    _startVoiceTimer?.cancel();
    _restVoiceTimer?.cancel();

    _cancelExerciseVoiceTimers();
    super.dispose();
  }
}

final timerServiceProvider =
    StateNotifierProvider<TimerService, WorkoutSession>((ref) {
      final audioService = ref.read(audioServiceProvider);
      final vibrationService = ref.read(vibrationServiceProvider);
      final settings = ref.read(settingsServiceProvider);

      final timerService = TimerService(
        audioService: audioService,
        vibrationService: vibrationService,
        settings: settings,
      );

      // Listen for settings changes
      ref.listen<TimerSettings>(settingsServiceProvider, (previous, next) {
        timerService.updateSettings(next);
      });

      return timerService;
    });
