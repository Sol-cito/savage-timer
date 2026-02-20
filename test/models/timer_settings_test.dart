import 'package:flutter_test/flutter_test.dart';

import 'package:savage_timer/models/timer_settings.dart';

void main() {
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
      const a = TimerSettings(enableVibration: false, enableKeepScreenOn: false);
      const b = TimerSettings(enableVibration: false, enableKeepScreenOn: false);
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
