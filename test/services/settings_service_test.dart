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

  group('SettingsService last 10s clapping alert', () {
    test('default enableLast10SecondsClappingAlert is false', () {
      final service = SettingsService(prefs);
      expect(service.state.enableLast10SecondsClappingAlert, false);
    });

    test('updateLast10SecondsClappingAlert sets to true', () {
      final service = SettingsService(prefs);
      service.updateLast10SecondsClappingAlert(true);
      expect(service.state.enableLast10SecondsClappingAlert, true);
    });

    test(
      'updateLast10SecondsClappingAlert persists across instances',
      () async {
        final service1 = SettingsService(prefs);
        service1.updateLast10SecondsClappingAlert(true);
        await Future<void>.delayed(Duration.zero);

        final service2 = SettingsService(prefs);
        expect(service2.state.enableLast10SecondsClappingAlert, true);
      },
    );
  });

  group('SettingsService vibration', () {
    test('default enableVibration is true', () {
      final service = SettingsService(prefs);
      expect(service.state.enableVibration, true);
    });

    test('updateVibration sets to false', () {
      final service = SettingsService(prefs);
      service.updateVibration(false);
      expect(service.state.enableVibration, false);
    });

    test('updateVibration sets to true', () {
      final service = SettingsService(prefs);
      service.updateVibration(false);
      service.updateVibration(true);
      expect(service.state.enableVibration, true);
    });

    test('updateVibration persists across instances', () async {
      final service1 = SettingsService(prefs);
      service1.updateVibration(false);
      await Future<void>.delayed(Duration.zero);

      final service2 = SettingsService(prefs);
      expect(service2.state.enableVibration, false);
    });
  });

  group('SettingsService keepScreenOn', () {
    test('default enableKeepScreenOn is true', () {
      final service = SettingsService(prefs);
      expect(service.state.enableKeepScreenOn, true);
    });

    test('updateKeepScreenOn sets to false', () {
      final service = SettingsService(prefs);
      service.updateKeepScreenOn(false);
      expect(service.state.enableKeepScreenOn, false);
    });

    test('updateKeepScreenOn sets to true', () {
      final service = SettingsService(prefs);
      service.updateKeepScreenOn(false);
      service.updateKeepScreenOn(true);
      expect(service.state.enableKeepScreenOn, true);
    });

    test('updateKeepScreenOn persists across instances', () async {
      final service1 = SettingsService(prefs);
      service1.updateKeepScreenOn(false);
      await Future<void>.delayed(Duration.zero);

      final service2 = SettingsService(prefs);
      expect(service2.state.enableKeepScreenOn, false);
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

    test('restores enableVibration to true', () {
      final service = SettingsService(prefs);
      service.updateVibration(false);
      expect(service.state.enableVibration, false);

      service.resetToDefaults();
      expect(service.state.enableVibration, true);
    });

    test('restores enableKeepScreenOn to true', () {
      final service = SettingsService(prefs);
      service.updateKeepScreenOn(false);
      expect(service.state.enableKeepScreenOn, false);

      service.resetToDefaults();
      expect(service.state.enableKeepScreenOn, true);
    });

    test('restores all settings to defaults', () {
      final service = SettingsService(prefs);
      service.updateRoundDuration(120);
      service.updateSeparateRoundDurationsEnabled(true);
      service.updateRoundDurationForRound(roundNumber: 2, seconds: 90);
      service.updateRestDuration(45);
      service.updateWarmUpSetEnabled(true);
      service.updateWarmUpDuration(90);
      service.updateCoolDownSetEnabled(true);
      service.updateCoolDownDuration(75);
      service.updateTotalRounds(6);
      service.updateSavageLevel(SavageLevel.level3);
      service.updateMotivationalSound(false);
      service.updateVibration(false);
      service.updateKeepScreenOn(false);

      service.resetToDefaults();

      const defaults = TimerSettings();
      expect(service.state, defaults);
    });
  });

  group('SettingsService persistence', () {
    test('loads saved settings on construction', () async {
      final settings = const TimerSettings(
        roundDurationSeconds: 120,
        enableSeparateRoundDurations: true,
        roundDurationsSeconds: [120, 90, 150, 90, 120],
        restDurationSeconds: 45,
        enableWarmUpSet: true,
        warmUpDurationSeconds: 90,
        enableCoolDownSet: true,
        coolDownDurationSeconds: 75,
        totalRounds: 5,
        savageLevel: SavageLevel.level3,
        enableMotivationalSound: false,
      );

      await prefs.setString('timer_settings', jsonEncode(settings.toJson()));

      final service = SettingsService(prefs);
      expect(service.state.roundDurationSeconds, 120);
      expect(service.state.enableSeparateRoundDurations, true);
      expect(service.state.roundDurationsSeconds, [120, 90, 150, 90, 120]);
      expect(service.state.restDurationSeconds, 45);
      expect(service.state.enableWarmUpSet, true);
      expect(service.state.warmUpDurationSeconds, 90);
      expect(service.state.enableCoolDownSet, true);
      expect(service.state.coolDownDurationSeconds, 75);
      expect(service.state.totalRounds, 5);
      expect(service.state.savageLevel, SavageLevel.level3);
      expect(service.state.enableMotivationalSound, false);
    });

    test('handles corrupt saved data gracefully', () async {
      await prefs.setString('timer_settings', 'not valid json');

      final service = SettingsService(prefs);
      expect(service.state, const TimerSettings());
    });

    test(
      'disables separate round durations when legacy persisted list is empty',
      () async {
        await prefs.setString(
          'timer_settings',
          jsonEncode({
            ...const TimerSettings().toJson(),
            'enableSeparateRoundDurations': true,
            'roundDurationsSeconds': <int>[],
          }),
        );

        final service = SettingsService(prefs);
        expect(service.state.enableSeparateRoundDurations, false);
        expect(service.state.roundDurationsSeconds, isEmpty);
      },
    );

    test(
      'disables warm-up set when legacy persisted warm-up duration is invalid',
      () async {
        await prefs.setString(
          'timer_settings',
          jsonEncode({
            ...const TimerSettings().toJson(),
            'enableWarmUpSet': true,
            'warmUpDurationSeconds': 0,
          }),
        );

        final service = SettingsService(prefs);
        expect(service.state.enableWarmUpSet, false);
        expect(service.state.warmUpDurationSeconds, 60);
      },
    );

    test(
      'disables cool-down set when legacy persisted cool-down duration is invalid',
      () async {
        await prefs.setString(
          'timer_settings',
          jsonEncode({
            ...const TimerSettings().toJson(),
            'enableCoolDownSet': true,
            'coolDownDurationSeconds': 0,
          }),
        );

        final service = SettingsService(prefs);
        expect(service.state.enableCoolDownSet, false);
        expect(service.state.coolDownDurationSeconds, 60);
      },
    );
  });

  group('SettingsService separate round durations', () {
    test('enabling seeds per-round durations from default round duration', () {
      final service = SettingsService(prefs);

      service.updateTotalRounds(4);
      service.updateRoundDuration(150);
      service.updateSeparateRoundDurationsEnabled(true);

      expect(service.state.enableSeparateRoundDurations, true);
      expect(service.state.roundDurationsSeconds, [150, 150, 150, 150]);
    });

    test('updateRoundDurationForRound updates only target round', () {
      final service = SettingsService(prefs);

      service.updateTotalRounds(3);
      service.updateSeparateRoundDurationsEnabled(true);
      service.updateRoundDurationForRound(roundNumber: 2, seconds: 90);

      expect(service.state.roundDurationsSeconds, [180, 90, 180]);
    });

    test(
      'updateTotalRounds expands and truncates per-round durations when enabled',
      () {
        final service = SettingsService(prefs);

        service.updateTotalRounds(3);
        service.updateSeparateRoundDurationsEnabled(true);
        service.updateRoundDurationForRound(roundNumber: 1, seconds: 120);
        service.updateRoundDurationForRound(roundNumber: 2, seconds: 90);
        service.updateRoundDurationForRound(roundNumber: 3, seconds: 150);

        service.updateTotalRounds(5);
        expect(service.state.roundDurationsSeconds, [120, 90, 150, 180, 180]);

        service.updateTotalRounds(2);
        expect(service.state.roundDurationsSeconds, [120, 90]);
      },
    );
  });

  group('SettingsService warm-up set', () {
    test('enableWarmUpSet defaults to false', () {
      final service = SettingsService(prefs);
      expect(service.state.enableWarmUpSet, false);
    });

    test('updateWarmUpSetEnabled sets to true', () {
      final service = SettingsService(prefs);
      service.updateWarmUpSetEnabled(true);
      expect(service.state.enableWarmUpSet, true);
    });

    test('updateWarmUpDuration updates duration seconds', () {
      final service = SettingsService(prefs);
      service.updateWarmUpDuration(120);
      expect(service.state.warmUpDurationSeconds, 120);
    });

    test('warm-up settings persist across instances', () async {
      final service1 = SettingsService(prefs);
      service1.updateWarmUpSetEnabled(true);
      service1.updateWarmUpDuration(75);
      await Future<void>.delayed(Duration.zero);

      final service2 = SettingsService(prefs);
      expect(service2.state.enableWarmUpSet, true);
      expect(service2.state.warmUpDurationSeconds, 75);
    });
  });

  group('SettingsService cool-down set', () {
    test('enableCoolDownSet defaults to false', () {
      final service = SettingsService(prefs);
      expect(service.state.enableCoolDownSet, false);
    });

    test('updateCoolDownSetEnabled sets to true', () {
      final service = SettingsService(prefs);
      service.updateCoolDownSetEnabled(true);
      expect(service.state.enableCoolDownSet, true);
    });

    test('updateCoolDownDuration updates duration seconds', () {
      final service = SettingsService(prefs);
      service.updateCoolDownDuration(120);
      expect(service.state.coolDownDurationSeconds, 120);
    });

    test('cool-down settings persist across instances', () async {
      final service1 = SettingsService(prefs);
      service1.updateCoolDownSetEnabled(true);
      service1.updateCoolDownDuration(75);
      await Future<void>.delayed(Duration.zero);

      final service2 = SettingsService(prefs);
      expect(service2.state.enableCoolDownSet, true);
      expect(service2.state.coolDownDurationSeconds, 75);
    });
  });
}
