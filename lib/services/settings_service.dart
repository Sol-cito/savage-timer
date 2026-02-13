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
        state = TimerSettings.fromJson(json);
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

  void updateRestDuration(int seconds) {
    state = state.copyWith(restDurationSeconds: seconds);
    _saveSettings();
  }

  void updateTotalRounds(int rounds) {
    state = state.copyWith(totalRounds: rounds);
    _saveSettings();
  }

  void updateLastSecondsAlert(bool enabled) {
    state = state.copyWith(enableLastSecondsAlert: enabled);
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
