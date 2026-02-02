import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/timer_settings.dart';
import '../models/workout_session.dart';
import '../utils/motivation_quotes.dart';
import 'audio_service.dart';
import 'settings_service.dart';
import 'vibration_service.dart';

class TimerService extends StateNotifier<WorkoutSession> {
  Timer? _timer;
  final AudioService _audioService;
  final VibrationService _vibrationService;
  TimerSettings _settings;

  bool _lastSecondsAlertTriggered = false;
  bool _midRoundQuoteTriggered = false;

  TimerService({
    required AudioService audioService,
    required VibrationService vibrationService,
    required TimerSettings settings,
  }) : _audioService = audioService,
       _vibrationService = vibrationService,
       _settings = settings,
       super(
         WorkoutSession(
           totalRounds: settings.totalRounds,
           roundDurationSeconds: settings.roundDurationSeconds,
           restDurationSeconds: settings.restDurationSeconds,
           remainingSeconds: settings.roundDurationSeconds,
         ),
       );

  void updateSettings(TimerSettings settings) {
    _settings = settings;
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
    if (state.state == SessionState.running) return;

    if (state.state == SessionState.idle ||
        state.state == SessionState.completed) {
      _resetState();
    }

    state = state.copyWith(state: SessionState.running);
    _startTimer();

    // Play round start sound and quote
    _audioService.playBell();
    _vibrationService.roundStart();
    _audioService.speakQuoteForced(
      MotivationQuotes.getRandomQuote(
        _settings.savageLevel,
        QuoteSituation.roundStart,
      ),
    );
  }

  void pause() {
    if (state.state != SessionState.running) return;
    _timer?.cancel();
    state = state.copyWith(state: SessionState.paused);
  }

  void resume() {
    if (state.state != SessionState.paused) return;
    state = state.copyWith(state: SessionState.running);
    _startTimer();
  }

  void reset() {
    _timer?.cancel();
    _audioService.stop();
    _resetState();
  }

  void _resetState() {
    _lastSecondsAlertTriggered = false;
    _midRoundQuoteTriggered = false;
    _audioService.resetQuoteCooldown();

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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (state.state != SessionState.running) return;

    final newRemaining = state.remainingSeconds - 1;

    // Check for last seconds alert
    if (_settings.enableLastSecondsAlert &&
        !_lastSecondsAlertTriggered &&
        state.phase == SessionPhase.round &&
        newRemaining == _settings.lastSecondsThreshold) {
      _lastSecondsAlertTriggered = true;
      _audioService.playWarning();
      _vibrationService.lastSecondsAlert();
      _audioService.speakQuoteForced(
        MotivationQuotes.getRandomQuote(
          _settings.savageLevel,
          QuoteSituation.roundFinal,
        ),
      );
    }

    // Check for mid-round quote (at 50% of round time)
    if (!_midRoundQuoteTriggered &&
        state.phase == SessionPhase.round &&
        newRemaining <= state.roundDurationSeconds ~/ 2 &&
        newRemaining > _settings.lastSecondsThreshold) {
      _midRoundQuoteTriggered = true;
      _audioService.speakQuote(
        MotivationQuotes.getRandomQuote(
          _settings.savageLevel,
          QuoteSituation.roundMid,
        ),
      );
    }

    if (newRemaining <= 0) {
      _handlePhaseEnd();
    } else {
      state = state.copyWith(remainingSeconds: newRemaining);
    }
  }

  void _handlePhaseEnd() {
    if (state.phase == SessionPhase.round) {
      // Round ended
      _audioService.playBell();
      _vibrationService.roundEnd();

      if (state.isLastRound) {
        // Workout complete
        _timer?.cancel();
        _vibrationService.sessionComplete();
        _audioService.speakQuoteForced("Workout complete! Great job!");
        state = state.copyWith(
          state: SessionState.completed,
          remainingSeconds: 0,
        );
      } else {
        // Start rest period
        _lastSecondsAlertTriggered = false;
        _midRoundQuoteTriggered = false;
        _audioService.speakQuote(
          MotivationQuotes.getRandomQuote(
            _settings.savageLevel,
            QuoteSituation.restTime,
          ),
        );
        state = state.copyWith(
          phase: SessionPhase.rest,
          remainingSeconds: _settings.restDurationSeconds,
        );
      }
    } else {
      // Rest ended, start next round
      _audioService.playBell();
      _vibrationService.restEnd();
      _lastSecondsAlertTriggered = false;
      _midRoundQuoteTriggered = false;
      _audioService.speakQuoteForced(
        MotivationQuotes.getRandomQuote(
          _settings.savageLevel,
          QuoteSituation.roundStart,
        ),
      );
      state = state.copyWith(
        phase: SessionPhase.round,
        currentRound: state.currentRound + 1,
        remainingSeconds: _settings.roundDurationSeconds,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final timerServiceProvider =
    StateNotifierProvider<TimerService, WorkoutSession>((ref) {
      final audioService = ref.watch(audioServiceProvider);
      final vibrationService = ref.watch(vibrationServiceProvider);
      final settings = ref.watch(settingsServiceProvider);

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
