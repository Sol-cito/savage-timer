import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:savage_timer/models/timer_settings.dart';
import 'package:savage_timer/models/workout_session.dart';
import 'package:savage_timer/screens/timer_screen.dart';
import 'package:savage_timer/services/audio_service.dart';
import 'package:savage_timer/services/settings_service.dart';
import 'package:savage_timer/services/timer_service.dart';
import 'package:savage_timer/services/vibration_service.dart';
import 'package:savage_timer/widgets/up_next_card.dart';

class _FakeAudioService extends AudioService {}

class _FakeVibrationService extends VibrationService {
  @override
  Future<void> lastSecondsAlert() async {}

  @override
  Future<void> restEnd() async {}

  @override
  Future<void> roundEnd() async {}

  @override
  Future<void> roundStart() async {}

  @override
  Future<void> sessionComplete() async {}
}

class _FixedTimerService extends TimerService {
  _FixedTimerService({
    required super.settings,
    required WorkoutSession session,
  }) : super(
         audioService: _FakeAudioService(),
         vibrationService: _FakeVibrationService(),
       ) {
    state = session;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pumpTimerScreen(
    WidgetTester tester, {
    required TimerSettings settings,
    required WorkoutSession session,
    required Size size,
  }) async {
    await prefs.setString('timer_settings', jsonEncode(settings.toJson()));
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          timerServiceProvider.overrideWith((ref) {
            return _FixedTimerService(settings: settings, session: session);
          }),
        ],
        child: const MaterialApp(home: TimerScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('does not overflow on small phone with UpNext visible', (
    tester,
  ) async {
    const settings = TimerSettings(
      totalRounds: 3,
      roundDurationSeconds: 180,
      restDurationSeconds: 30,
    );
    const session = WorkoutSession(
      state: SessionState.running,
      phase: SessionPhase.round,
      currentRound: 1,
      totalRounds: 3,
      remainingSeconds: 120,
      roundDurationSeconds: 180,
      restDurationSeconds: 30,
    );

    await pumpTimerScreen(
      tester,
      settings: settings,
      session: session,
      size: const Size(320, 568), // iPhone SE (1st gen)
    );

    expect(find.byType(UpNextCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow on small phone during warm-up phase', (
    tester,
  ) async {
    const settings = TimerSettings(
      totalRounds: 3,
      roundDurationSeconds: 180,
      restDurationSeconds: 30,
      enableWarmUpSet: true,
      warmUpDurationSeconds: 60,
    );
    const session = WorkoutSession(
      state: SessionState.running,
      phase: SessionPhase.warmUp,
      currentRound: 1,
      totalRounds: 3,
      remainingSeconds: 45,
      roundDurationSeconds: 180,
      restDurationSeconds: 30,
      enableWarmUpSet: true,
      warmUpDurationSeconds: 60,
    );

    await pumpTimerScreen(
      tester,
      settings: settings,
      session: session,
      size: const Size(320, 568),
    );

    expect(find.text('WARM-UP ROUND IN PROGRESS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
