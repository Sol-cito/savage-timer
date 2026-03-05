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
  Timer? _lastSecondsVoiceTimer;

  final List<Timer> _exerciseVoiceTimers = [];
  final AudioService _audioService;
  final VibrationService _vibrationService;
  TimerSettings _settings;
  final Random _random;

  bool _lastSecondsAlertTriggered = false;
  bool _last10SecondsAlertTriggered = false;
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
           roundDurationSeconds: settings.roundDurationForRound(1),
           enableSeparateRoundDurations: settings.enableSeparateRoundDurations,
           roundDurationsSeconds: settings.roundDurationsSeconds,
           restDurationSeconds: settings.restDurationSeconds,
           remainingSeconds: settings.roundDurationForRound(1),
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
        roundDurationSeconds: settings.roundDurationForRound(1),
        enableSeparateRoundDurations: settings.enableSeparateRoundDurations,
        roundDurationsSeconds: settings.roundDurationsSeconds,
        restDurationSeconds: settings.restDurationSeconds,
        remainingSeconds: settings.roundDurationForRound(1),
        pausedDuringPreparation: false,
      );
    }
  }

  int _roundDurationForRound(int roundNumber) {
    return _settings.roundDurationForRound(roundNumber);
  }

  int _currentRoundDuration() {
    return _roundDurationForRound(state.currentRound);
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

    // Stop any audio that may still be playing (e.g. example voice from
    // settings) so it doesn't overlap with the countdown.
    _audioService.stopVoice();

    _audioService.startKeepAlive();

    if (_preparationSeconds <= 0) {
      // Skip preparation, go straight to running
      state = state.copyWith(
        state: SessionState.running,
        roundDurationSeconds: _currentRoundDuration(),
        pausedDuringPreparation: false,
      );
      _startTimer();
      _playRoundStartCue();
      if (_settings.enableVibration) _vibrationService.roundStart();
      _scheduleStartVoice();
      _scheduleExerciseVoices();
      return;
    }

    // Enter preparation countdown
    state = state.copyWith(
      state: SessionState.preparing,
      remainingSeconds: _preparationSeconds,
      pausedDuringPreparation: false,
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
    _prepTimer = Timer.periodic(const Duration(seconds: 1), (_) => _prepTick());
  }

  void _prepTick() {
    if (state.state != SessionState.preparing) return;

    final newRemaining = state.remainingSeconds - 1;

    if (newRemaining <= 0) {
      // Preparation done — transition to running
      _prepTimer?.cancel();
      _playRoundStartCue();
      if (_settings.enableVibration) _vibrationService.roundStart();

      state = state.copyWith(
        state: SessionState.running,
        remainingSeconds: _currentRoundDuration(),
        pausedDuringPreparation: false,
      );
      _startTimer();

      _scheduleStartVoice();
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
      state = state.copyWith(
        state: SessionState.paused,
        pausedDuringPreparation: true,
      );
      return;
    }
    if (state.state != SessionState.running) return;
    _timer?.cancel();
    _startVoiceTimer?.cancel();
    _restVoiceTimer?.cancel();
    _lastSecondsVoiceTimer?.cancel();

    _cancelExerciseVoiceTimers();
    _audioService.stop();
    _audioService.stopKeepAlive();
    state = state.copyWith(
      state: SessionState.paused,
      pausedDuringPreparation: false,
    );
  }

  void resume() {
    if (state.state != SessionState.paused) return;
    if (_pausedDuringPreparation) {
      _pausedDuringPreparation = false;
      state = state.copyWith(
        state: SessionState.preparing,
        pausedDuringPreparation: false,
      );
      _audioService.startKeepAlive();
      _audioService.playCount(
        state.remainingSeconds,
        _settings.savageLevel,
        _settings.enableMotivationalSound,
      );
      _startPrepTimer();
      return;
    }
    state = state.copyWith(
      state: SessionState.running,
      pausedDuringPreparation: false,
    );
    _audioService.startKeepAlive();
    _startTimer();
  }

  void skip() {
    if (state.state == SessionState.idle ||
        state.state == SessionState.completed) {
      return;
    }

    // During preparation, skip straight to running
    if (state.state == SessionState.preparing || _pausedDuringPreparation) {
      _prepTimer?.cancel();
      _pausedDuringPreparation = false;

      state = state.copyWith(
        state: SessionState.running,
        remainingSeconds: _currentRoundDuration(),
        pausedDuringPreparation: false,
      );
      if (state.state == SessionState.running) {
        _audioService.startKeepAlive();
      }
      _playRoundStartCue();
      if (_settings.enableVibration) _vibrationService.roundStart();
      _startTimer();

      _scheduleStartVoice();
      _scheduleExerciseVoices();
      return;
    }

    _timer?.cancel();
    _startVoiceTimer?.cancel();
    _restVoiceTimer?.cancel();
    _lastSecondsVoiceTimer?.cancel();

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
    _last10SecondsAlertTriggered = false;
    _phaseStartedAt = null;
    _phaseStartedWithSeconds = 0;

    state = WorkoutSession(
      totalRounds: _settings.totalRounds,
      roundDurationSeconds: _settings.roundDurationForRound(1),
      enableSeparateRoundDurations: _settings.enableSeparateRoundDurations,
      roundDurationsSeconds: _settings.roundDurationsSeconds,
      restDurationSeconds: _settings.restDurationSeconds,
      remainingSeconds: _settings.roundDurationForRound(1),
      state: SessionState.idle,
      pausedDuringPreparation: false,
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

    // Check for last seconds alert sound + vibration.
    if (_settings.enableLastSecondsAlert &&
        !_lastSecondsAlertTriggered &&
        state.phase == SessionPhase.round &&
        newRemaining == _settings.lastSecondsThreshold) {
      _lastSecondsAlertTriggered = true;
      if (_settings.enableVibration) _vibrationService.lastSecondsAlert();

      // Cancel scheduled exercise voices and stop any currently playing
      // so nothing talks over the count_30seconds announcement.
      _cancelExerciseVoiceTimers();
      _playLastSecondsAlert();
      _scheduleLastSecondsVoice();
    }

    // Check for last 10 seconds clapping alert.
    if (_settings.enableLast10SecondsClappingAlert &&
        !_last10SecondsAlertTriggered &&
        state.phase == SessionPhase.round &&
        newRemaining == 10) {
      _last10SecondsAlertTriggered = true;
      _audioService.playCount10SecondsWithClapping(
        _settings.savageLevel,
        _settings.enableMotivationalSound,
      );
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

  /// Stops any exercise voice then plays count_30seconds.
  Future<void> _playLastSecondsAlert() async {
    await _audioService.stopVoice();
    _audioService.playCount30Seconds(
      _settings.savageLevel,
      _settings.enableMotivationalSound,
    );
  }

  /// Schedules one exercise voice during the last 30 seconds, placed after
  /// count_30seconds and finishing before the 3-2-1 countdown. The voice uses
  /// the duration-check to avoid overlap.
  void _scheduleLastSecondsVoice() {
    _lastSecondsVoiceTimer?.cancel();

    if (!_settings.enableMotivationalSound) return;

    final threshold = _settings.lastSecondsThreshold;
    // count_30seconds takes ~3s. Schedule voice after that.
    // The 3-2-1 countdown starts at remainingSeconds=3, so the voice must
    // finish by then. Pick a random delay between 4s and (threshold - 8)s
    // after the alert fires. The _voiceBufferSeconds (8) covers a voice clip
    // plus 1s margin before the countdown.
    final minDelay = _bellDurationSeconds + 1; // after count_30seconds
    final maxDelay = threshold - _voiceBufferSeconds - _bellDurationSeconds;

    if (maxDelay <= minDelay) return; // not enough room

    final delay = minDelay + _random.nextInt(maxDelay - minDelay);

    _lastSecondsVoiceTimer = Timer(Duration(seconds: delay), () {
      if (state.phase != SessionPhase.round ||
          state.state != SessionState.running) {
        return;
      }
      // Use duration-aware playback so the voice won't overlap with 3-2-1.
      // The countdown plays on _countPlayer at remainingSeconds 3,2,1 but
      // the voice uses _voicePlayer — however we still want it to finish
      // naturally, so pass a threshold of 3 (countdown start).
      _audioService.playRandomExerciseVoiceIfFits(
        _settings.savageLevel,
        _bellDurationSeconds, // treat the 3-2-1 countdown as the deadline
        () => state.remainingSeconds,
      );
    });
  }

  void _handlePhaseEnd() {
    if (state.phase == SessionPhase.round) {
      // Round ended — cancel any remaining voice timers
      _cancelExerciseVoiceTimers();
      _startVoiceTimer?.cancel();
      _lastSecondsVoiceTimer?.cancel();

      if (_settings.enableVibration) _vibrationService.roundEnd();

      if (state.isLastRound) {
        // Workout complete — play count_finish
        _playRoundFinishCue();
        _timer?.cancel();
        _audioService.stopKeepAlive();
        if (_settings.enableVibration) _vibrationService.sessionComplete();
        state = state.copyWith(
          state: SessionState.completed,
          remainingSeconds: 0,
        );
      } else {
        // Start rest period — play count_rest
        _playRoundEndToRestCue();
        _lastSecondsAlertTriggered = false;
        _last10SecondsAlertTriggered = false;
        state = state.copyWith(
          phase: SessionPhase.rest,
          remainingSeconds: _settings.restDurationSeconds,
          pausedDuringPreparation: false,
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
                // If 10s clapping alert is enabled, reserve the final 10
                // seconds so rest voice never overlaps that cue window.
                final restVoiceDeadlineThreshold =
                    _settings.enableLast10SecondsClappingAlert ? 10 : 3;
                _audioService.playRandomRestVoiceIfFits(
                  _settings.savageLevel,
                  restVoiceDeadlineThreshold,
                  () => state.remainingSeconds,
                );
              }
            },
          );
        }
      }
    } else {
      // Rest ended, start next round — play count_start
      _playRoundStartCue();
      if (_settings.enableVibration) _vibrationService.restEnd();
      _lastSecondsAlertTriggered = false;
      _last10SecondsAlertTriggered = false;
      state = state.copyWith(
        phase: SessionPhase.round,
        currentRound: state.currentRound + 1,
        roundDurationSeconds: _roundDurationForRound(state.currentRound + 1),
        remainingSeconds: _roundDurationForRound(state.currentRound + 1),
        pausedDuringPreparation: false,
      );
      _recordPhaseStart();

      _scheduleStartVoice();
      _scheduleExerciseVoices();
    }
  }

  /// Round start cue: ring bell_3times and play count_start concurrently.
  void _playRoundStartCue() {
    _audioService.playBell3Times();
    _audioService.playCountStart(
      _settings.savageLevel,
      _settings.enableMotivationalSound,
    );
  }

  /// Round end cue (non-final): ring bell_1time and play count_rest concurrently.
  void _playRoundEndToRestCue() {
    _audioService.playBell1Time();
    _audioService.playCountRest(
      _settings.savageLevel,
      _settings.enableMotivationalSound,
    );
  }

  /// Round end cue (final): ring bell_1time and play count_finish concurrently.
  void _playRoundFinishCue() {
    _audioService.playBell1Time();
    _audioService.playCountFinish(
      _settings.savageLevel,
      _settings.enableMotivationalSound,
    );
  }

  /// Schedules the start-of-round motivational voice after the bell finishes,
  /// but only if there is enough time before the 30-second alert.
  void _scheduleStartVoice() {
    if (!_settings.enableMotivationalSound) return;

    _startVoiceTimer?.cancel();
    _startVoiceTimer = Timer(const Duration(seconds: _bellDurationSeconds), () {
      if (state.state != SessionState.running ||
          state.phase != SessionPhase.round) {
        return;
      }
      // Skip if the voice would be cut off by the last-seconds bell.
      if (_settings.enableLastSecondsAlert &&
          state.remainingSeconds - _settings.lastSecondsThreshold <
              _voiceBufferSeconds) {
        return;
      }
      _audioService.playRandomStartVoice(_settings.savageLevel);
    });
  }

  /// Schedules 2–4 exercise voice clips at random times during the current
  /// round. The first clip starts after the bell + start voice gap. The last
  /// clip finishes before the round ends (using an 8-second buffer).
  void _scheduleExerciseVoices() {
    _cancelExerciseVoiceTimers();

    if (!_settings.enableMotivationalSound) return;

    final roundDuration = _currentRoundDuration();
    // Leave room for bell + start voice + voice buffer at the start
    final minStartDelay = _bellDurationSeconds + _voiceBufferSeconds;
    // Stop scheduling voices early enough so the last clip finishes before the
    // 30-second bell (or round end). The voice buffer accounts for clip length.
    final endBuffer =
        _settings.enableLastSecondsAlert
            ? _settings.lastSecondsThreshold + _voiceBufferSeconds
            : _voiceBufferSeconds;
    final maxPlayTime = roundDuration - endBuffer;

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
            if (_settings.enableLastSecondsAlert) {
              // Pass a callback so the audio service can re-check the
              // remaining time right before playback, after async asset
              // loading which may take several seconds.
              _audioService.playRandomExerciseVoiceIfFits(
                _settings.savageLevel,
                _settings.lastSecondsThreshold,
                () => state.remainingSeconds,
              );
            } else {
              _audioService.playRandomExerciseVoice(_settings.savageLevel);
            }
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
    _lastSecondsVoiceTimer?.cancel();

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
