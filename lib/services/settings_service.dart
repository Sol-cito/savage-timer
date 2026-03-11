import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/timer_settings.dart';

const _settingsKey = 'timer_settings';

class SettingsService extends StateNotifier<TimerSettings> {
  final SharedPreferences _prefs;

  SettingsService(this._prefs) : super(const TimerSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    final jsonString = _prefs.getString(_settingsKey);
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        var loaded = TimerSettings.fromJson(json);
        if (loaded.enableSeparateRoundDurations &&
            loaded.roundDurationsSeconds.isEmpty) {
          loaded = loaded.copyWith(enableSeparateRoundDurations: false);
        }
        if (loaded.enableWarmUpSet && loaded.warmUpDurationSeconds <= 0) {
          loaded = loaded.copyWith(
            enableWarmUpSet: false,
            warmUpDurationSeconds: 60,
          );
        }
        if (loaded.enableCoolDownSet && loaded.coolDownDurationSeconds <= 0) {
          loaded = loaded.copyWith(
            enableCoolDownSet: false,
            coolDownDurationSeconds: 60,
          );
        }
        state = loaded;
      } catch (e) {
        state = const TimerSettings();
      }
    }
  }

  Future<void> _saveSettings() async {
    final jsonString = jsonEncode(state.toJson());
    await _prefs.setString(_settingsKey, jsonString);
  }

  void updateRoundDuration(int seconds) {
    state = state.copyWith(roundDurationSeconds: seconds);
    _saveSettings();
  }

  void updateSeparateRoundDurationsEnabled(bool enabled) {
    if (enabled) {
      state = state.copyWith(
        enableSeparateRoundDurations: true,
        roundDurationsSeconds: state.resolvedRoundDurationsSeconds,
      );
    } else {
      state = state.copyWith(enableSeparateRoundDurations: false);
    }
    _saveSettings();
  }

  void updateRoundDurationForRound({
    required int roundNumber,
    required int seconds,
  }) {
    if (roundNumber <= 0) return;

    final nextDurations = state.resolvedRoundDurationsSeconds;
    if (roundNumber > nextDurations.length) return;

    nextDurations[roundNumber - 1] = seconds;
    state = state.copyWith(
      enableSeparateRoundDurations: true,
      roundDurationsSeconds: nextDurations,
    );
    _saveSettings();
  }

  void updateRestDuration(int seconds) {
    state = state.copyWith(restDurationSeconds: seconds);
    _saveSettings();
  }

  void updateWarmUpSetEnabled(bool enabled) {
    state = state.copyWith(enableWarmUpSet: enabled);
    _saveSettings();
  }

  void updateWarmUpDuration(int seconds) {
    state = state.copyWith(warmUpDurationSeconds: seconds);
    _saveSettings();
  }

  void updateCoolDownSetEnabled(bool enabled) {
    state = state.copyWith(enableCoolDownSet: enabled);
    _saveSettings();
  }

  void updateCoolDownDuration(int seconds) {
    state = state.copyWith(coolDownDurationSeconds: seconds);
    _saveSettings();
  }

  void updateTotalRounds(int rounds) {
    var nextDurations = state.roundDurationsSeconds;

    if (state.enableSeparateRoundDurations) {
      final resolved = state.resolvedRoundDurationsSeconds;
      if (rounds > resolved.length) {
        nextDurations = <int>[
          ...resolved,
          ...List<int>.filled(
            rounds - resolved.length,
            state.roundDurationSeconds,
          ),
        ];
      } else {
        nextDurations = resolved.take(rounds).toList();
      }
    }

    state = state.copyWith(
      totalRounds: rounds,
      roundDurationsSeconds: nextDurations,
    );
    _saveSettings();
  }

  void updateLastSecondsAlert(bool enabled) {
    state = state.copyWith(enableLastSecondsAlert: enabled);
    _saveSettings();
  }

  void updateLast10SecondsClappingAlert(bool enabled) {
    state = state.copyWith(enableLast10SecondsClappingAlert: enabled);
    _saveSettings();
  }

  void updateLastSecondsThreshold(int seconds) {
    state = state.copyWith(lastSecondsThreshold: seconds);
    _saveSettings();
  }

  void updateSavageLevel(SavageLevel level) {
    state = state.copyWith(savageLevel: level);
    _saveSettings();
  }

  void updateVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
    _saveSettings();
  }

  void updateMotivationalSound(bool enabled) {
    state = state.copyWith(enableMotivationalSound: enabled);
    _saveSettings();
  }

  void updateVibration(bool enabled) {
    state = state.copyWith(enableVibration: enabled);
    _saveSettings();
  }

  void updateKeepScreenOn(bool enabled) {
    state = state.copyWith(enableKeepScreenOn: enabled);
    _saveSettings();
  }

  void resetToDefaults() {
    state = const TimerSettings();
    _saveSettings();
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

final settingsServiceProvider =
    StateNotifierProvider<SettingsService, TimerSettings>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return SettingsService(prefs);
    });
