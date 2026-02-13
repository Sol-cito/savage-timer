import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:savage_timer/models/timer_settings.dart';
import 'package:savage_timer/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('SettingsService motivational sound', () {
    test('updateMotivationalSound sets to false', () {
      final service = SettingsService(prefs);
      expect(service.state.enableMotivationalSound, true);

      service.updateMotivationalSound(false);
      expect(service.state.enableMotivationalSound, false);
    });

    test('updateMotivationalSound sets to true', () {
      final service = SettingsService(prefs);
      service.updateMotivationalSound(false);
      expect(service.state.enableMotivationalSound, false);

      service.updateMotivationalSound(true);
      expect(service.state.enableMotivationalSound, true);
    });

    test('updateMotivationalSound persists across instances', () async {
      final service1 = SettingsService(prefs);
      service1.updateMotivationalSound(false);

      // Wait for save to complete
      await Future<void>.delayed(Duration.zero);

      final service2 = SettingsService(prefs);
      expect(service2.state.enableMotivationalSound, false);
    });
  });

  group('SettingsService resetToDefaults', () {
    test('restores enableMotivationalSound to true', () {
      final service = SettingsService(prefs);
      service.updateMotivationalSound(false);
      expect(service.state.enableMotivationalSound, false);

      service.resetToDefaults();
      expect(service.state.enableMotivationalSound, true);
    });

    test('restores all settings to defaults', () {
      final service = SettingsService(prefs);
      service.updateRoundDuration(120);
      service.updateRestDuration(45);
      service.updateTotalRounds(6);
      service.updateSavageLevel(SavageLevel.level3);
      service.updateMotivationalSound(false);

      service.resetToDefaults();

      const defaults = TimerSettings();
      expect(service.state, defaults);
    });
  });

  group('SettingsService persistence', () {
    test('loads saved settings on construction', () async {
      final settings = const TimerSettings(
        roundDurationSeconds: 120,
        restDurationSeconds: 45,
        totalRounds: 5,
        savageLevel: SavageLevel.level3,
        enableMotivationalSound: false,
      );

      await prefs.setString(
        'timer_settings',
        jsonEncode(settings.toJson()),
      );

      final service = SettingsService(prefs);
      expect(service.state.roundDurationSeconds, 120);
      expect(service.state.restDurationSeconds, 45);
      expect(service.state.totalRounds, 5);
      expect(service.state.savageLevel, SavageLevel.level3);
      expect(service.state.enableMotivationalSound, false);
    });

    test('handles corrupt saved data gracefully', () async {
      await prefs.setString('timer_settings', 'not valid json');

      final service = SettingsService(prefs);
      expect(service.state, const TimerSettings());
    });
  });
}
