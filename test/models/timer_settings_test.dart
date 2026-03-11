import 'package:flutter_test/flutter_test.dart';

import 'package:savage_timer/models/timer_settings.dart';

void main() {
  group('TimerSettings separate round durations', () {
    test('defaults to disabled with empty per-round durations', () {
      const settings = TimerSettings();
      expect(settings.enableSeparateRoundDurations, false);
      expect(settings.roundDurationsSeconds, isEmpty);
      expect(settings.enableWarmUpSet, false);
      expect(settings.warmUpDurationSeconds, 60);
      expect(settings.enableCoolDownSet, false);
      expect(settings.coolDownDurationSeconds, 60);
    });

    test('copyWith can enable and set per-round durations', () {
      const settings = TimerSettings();
      final copy = settings.copyWith(
        enableSeparateRoundDurations: true,
        roundDurationsSeconds: [120, 90, 150],
      );
      expect(copy.enableSeparateRoundDurations, true);
      expect(copy.roundDurationsSeconds, [120, 90, 150]);
    });

    test('toJson includes separate duration fields', () {
      const settings = TimerSettings(
        enableSeparateRoundDurations: true,
        roundDurationsSeconds: [120, 90, 150],
      );
      final json = settings.toJson();
      expect(json.containsKey('enableSeparateRoundDurations'), true);
      expect(json.containsKey('roundDurationsSeconds'), true);
      expect(json['enableSeparateRoundDurations'], true);
      expect(json['roundDurationsSeconds'], [120, 90, 150]);
    });

    test('fromJson reads separate duration fields', () {
      const original = TimerSettings(
        enableSeparateRoundDurations: true,
        roundDurationsSeconds: [120, 90, 150],
      );
      final restored = TimerSettings.fromJson(original.toJson());
      expect(restored.enableSeparateRoundDurations, true);
      expect(restored.roundDurationsSeconds, [120, 90, 150]);
    });

    test('fromJson defaults separate duration fields when missing', () {
      final json =
          const TimerSettings().toJson()
            ..remove('enableSeparateRoundDurations')
            ..remove('roundDurationsSeconds');
      final restored = TimerSettings.fromJson(json);
      expect(restored.enableSeparateRoundDurations, false);
      expect(restored.roundDurationsSeconds, isEmpty);
    });
  });

  group('TimerSettings warm-up set', () {
    test('copyWith can enable warm-up set and change duration', () {
      const settings = TimerSettings();
      final copy = settings.copyWith(
        enableWarmUpSet: true,
        warmUpDurationSeconds: 90,
      );
      expect(copy.enableWarmUpSet, true);
      expect(copy.warmUpDurationSeconds, 90);
    });

    test('toJson includes warm-up fields', () {
      const settings = TimerSettings(
        enableWarmUpSet: true,
        warmUpDurationSeconds: 75,
      );
      final json = settings.toJson();
      expect(json['enableWarmUpSet'], true);
      expect(json['warmUpDurationSeconds'], 75);
    });

    test('fromJson defaults warm-up fields when missing', () {
      final json =
          const TimerSettings().toJson()
            ..remove('enableWarmUpSet')
            ..remove('warmUpDurationSeconds');
      final restored = TimerSettings.fromJson(json);
      expect(restored.enableWarmUpSet, false);
      expect(restored.warmUpDurationSeconds, 60);
    });
  });

  group('TimerSettings cool-down set', () {
    test('copyWith can enable cool-down set and change duration', () {
      const settings = TimerSettings();
      final copy = settings.copyWith(
        enableCoolDownSet: true,
        coolDownDurationSeconds: 90,
      );
      expect(copy.enableCoolDownSet, true);
      expect(copy.coolDownDurationSeconds, 90);
    });

    test('toJson includes cool-down fields', () {
      const settings = TimerSettings(
        enableCoolDownSet: true,
        coolDownDurationSeconds: 75,
      );
      final json = settings.toJson();
      expect(json['enableCoolDownSet'], true);
      expect(json['coolDownDurationSeconds'], 75);
    });

    test('fromJson defaults cool-down fields when missing', () {
      final json =
          const TimerSettings().toJson()
            ..remove('enableCoolDownSet')
            ..remove('coolDownDurationSeconds');
      final restored = TimerSettings.fromJson(json);
      expect(restored.enableCoolDownSet, false);
      expect(restored.coolDownDurationSeconds, 60);
    });
  });

  group('TimerSettings last 10s clapping alert', () {
    test('defaults to false', () {
      const settings = TimerSettings();
      expect(settings.enableLast10SecondsClappingAlert, false);
    });

    test('copyWith can override to true', () {
      const settings = TimerSettings();
      final copy = settings.copyWith(enableLast10SecondsClappingAlert: true);
      expect(copy.enableLast10SecondsClappingAlert, true);
    });

    test('toJson includes enableLast10SecondsClappingAlert', () {
      const settings = TimerSettings(enableLast10SecondsClappingAlert: true);
      final json = settings.toJson();
      expect(json.containsKey('enableLast10SecondsClappingAlert'), true);
      expect(json['enableLast10SecondsClappingAlert'], true);
    });

    test('fromJson reads enableLast10SecondsClappingAlert', () {
      const original = TimerSettings(enableLast10SecondsClappingAlert: true);
      final restored = TimerSettings.fromJson(original.toJson());
      expect(restored.enableLast10SecondsClappingAlert, true);
    });

    test('fromJson defaults to false when key is missing', () {
      final json =
          const TimerSettings().toJson()
            ..remove('enableLast10SecondsClappingAlert');
      final restored = TimerSettings.fromJson(json);
      expect(restored.enableLast10SecondsClappingAlert, false);
    });
  });

  group('TimerSettings enableVibration', () {
    test('defaults to true', () {
      const settings = TimerSettings();
      expect(settings.enableVibration, true);
    });

    test('copyWith preserves value when not specified', () {
      const settings = TimerSettings(enableVibration: false);
      final copy = settings.copyWith(totalRounds: 5);
      expect(copy.enableVibration, false);
    });

    test('copyWith can override to false', () {
      const settings = TimerSettings(enableVibration: true);
      final copy = settings.copyWith(enableVibration: false);
      expect(copy.enableVibration, false);
    });

    test('copyWith can override to true', () {
      const settings = TimerSettings(enableVibration: false);
      final copy = settings.copyWith(enableVibration: true);
      expect(copy.enableVibration, true);
    });

    test('toJson includes enableVibration', () {
      const settings = TimerSettings(enableVibration: false);
      final json = settings.toJson();
      expect(json.containsKey('enableVibration'), true);
      expect(json['enableVibration'], false);
    });

    test('fromJson reads enableVibration', () {
      const original = TimerSettings(enableVibration: false);
      final restored = TimerSettings.fromJson(original.toJson());
      expect(restored.enableVibration, false);
    });

    test('fromJson defaults to true when key is missing', () {
      final json = const TimerSettings().toJson()..remove('enableVibration');
      final restored = TimerSettings.fromJson(json);
      expect(restored.enableVibration, true);
    });
  });

  group('TimerSettings enableKeepScreenOn', () {
    test('defaults to true', () {
      const settings = TimerSettings();
      expect(settings.enableKeepScreenOn, true);
    });

    test('copyWith preserves value when not specified', () {
      const settings = TimerSettings(enableKeepScreenOn: false);
      final copy = settings.copyWith(totalRounds: 5);
      expect(copy.enableKeepScreenOn, false);
    });

    test('copyWith can override to false', () {
      const settings = TimerSettings(enableKeepScreenOn: true);
      final copy = settings.copyWith(enableKeepScreenOn: false);
      expect(copy.enableKeepScreenOn, false);
    });

    test('copyWith can override to true', () {
      const settings = TimerSettings(enableKeepScreenOn: false);
      final copy = settings.copyWith(enableKeepScreenOn: true);
      expect(copy.enableKeepScreenOn, true);
    });

    test('toJson includes enableKeepScreenOn', () {
      const settings = TimerSettings(enableKeepScreenOn: false);
      final json = settings.toJson();
      expect(json.containsKey('enableKeepScreenOn'), true);
      expect(json['enableKeepScreenOn'], false);
    });

    test('fromJson reads enableKeepScreenOn', () {
      const original = TimerSettings(enableKeepScreenOn: false);
      final restored = TimerSettings.fromJson(original.toJson());
      expect(restored.enableKeepScreenOn, false);
    });

    test('fromJson defaults to true when key is missing', () {
      final json = const TimerSettings().toJson()..remove('enableKeepScreenOn');
      final restored = TimerSettings.fromJson(json);
      expect(restored.enableKeepScreenOn, true);
    });
  });

  group('TimerSettings equality', () {
    test('two instances with same values are equal', () {
      const a = TimerSettings(
        enableVibration: false,
        enableKeepScreenOn: false,
      );
      const b = TimerSettings(
        enableVibration: false,
        enableKeepScreenOn: false,
      );
      expect(a, equals(b));
    });

    test('differ when enableVibration differs', () {
      const a = TimerSettings(enableVibration: true);
      const b = TimerSettings(enableVibration: false);
      expect(a, isNot(equals(b)));
    });

    test('differ when enableKeepScreenOn differs', () {
      const a = TimerSettings(enableKeepScreenOn: true);
      const b = TimerSettings(enableKeepScreenOn: false);
      expect(a, isNot(equals(b)));
    });
  });
}
