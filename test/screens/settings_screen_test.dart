import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:savage_timer/models/timer_settings.dart';
import 'package:savage_timer/models/workout_session.dart';
import 'package:savage_timer/screens/settings_screen.dart';
import 'package:savage_timer/services/audio_service.dart';
import 'package:savage_timer/services/settings_service.dart';
import 'package:savage_timer/services/timer_service.dart';
import 'package:savage_timer/services/vibration_service.dart';

/// A minimal fake AudioService so we don't need real audio players in tests.
class FakeAudioService extends AudioService {
  @override
  Future<void> initialize() async {}
  @override
  Future<void> playExampleVoice(SavageLevel level) async {}
}

/// A minimal fake VibrationService so we don't trigger platform vibration.
class _FakeVibrationService extends VibrationService {
  @override
  Future<void> roundStart() async {}
  @override
  Future<void> roundEnd() async {}
  @override
  Future<void> lastSecondsAlert() async {}
  @override
  Future<void> restEnd() async {}
  @override
  Future<void> sessionComplete() async {}
}

/// A [TimerService] that starts in the running state, used to test the
/// settings guard dialog.
class _RunningTimerService extends TimerService {
  _RunningTimerService(TimerSettings settings)
      : super(
          audioService: FakeAudioService(),
          vibrationService: _FakeVibrationService(),
          settings: settings,
        ) {
    state = state.copyWith(state: SessionState.running);
  }

  @override
  void reset() {
    state = state.copyWith(state: SessionState.idle);
  }
}

/// Builds a testable [SettingsScreen] wrapped with the required providers.
Widget buildSettingsScreen(SharedPreferences prefs) {
  final fakeAudio = FakeAudioService();

  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      audioServiceProvider.overrideWithValue(fakeAudio),
    ],
    child: const MaterialApp(
      home: SettingsScreen(),
    ),
  );
}

/// Builds a [SettingsScreen] where the timer is already running, so the
/// guard dialog is triggered when settings are changed.
Widget buildSettingsScreenWithRunningTimer(SharedPreferences prefs) {
  final fakeAudio = FakeAudioService();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      audioServiceProvider.overrideWithValue(fakeAudio),
      timerServiceProvider.overrideWith((ref) {
        final settings = ref.read(settingsServiceProvider);
        return _RunningTimerService(settings);
      }),
    ],
    child: const MaterialApp(
      home: SettingsScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('SettingsScreen legal links section', () {
    testWidgets('displays LEGAL section header', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('LEGAL'),
        find.byType(ListView),
        const Offset(0, -200),
      );

      expect(find.text('LEGAL'), findsOneWidget);
    });

    testWidgets('displays Privacy Policy tile', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      // Scroll to bottom to ensure the legal section is visible
      await tester.dragUntilVisible(
        find.text('Privacy Policy'),
        find.byType(ListView),
        const Offset(0, -200),
      );

      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('displays Terms of Service tile', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Terms of Service'),
        find.byType(ListView),
        const Offset(0, -200),
      );

      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('legal tiles show open_in_new icon', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Privacy Policy'),
        find.byType(ListView),
        const Offset(0, -200),
      );

      // open_in_new icon should appear for both tiles
      expect(find.byIcon(Icons.open_in_new_rounded), findsNWidgets(2));
    });

    testWidgets('legal tiles show correct icons', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Privacy Policy'),
        find.byType(ListView),
        const Offset(0, -200),
      );

      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    });

    testWidgets('legal section is separated by a divider', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('LEGAL'),
        find.byType(ListView),
        const Offset(0, -200),
      );

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('legal tiles are tappable (InkWell)', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Privacy Policy'),
        find.byType(ListView),
        const Offset(0, -200),
      );

      // Both tiles should be wrapped in InkWell, making them tappable.
      // We find InkWell widgets that are descendants of containers holding legal text.
      final privacyTile = find.ancestor(
        of: find.text('Privacy Policy'),
        matching: find.byType(InkWell),
      );
      expect(privacyTile, findsOneWidget);

      final tosTile = find.ancestor(
        of: find.text('Terms of Service'),
        matching: find.byType(InkWell),
      );
      expect(tosTile, findsOneWidget);
    });

    testWidgets('gavel icon is shown for LEGAL header', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('LEGAL'),
        find.byType(ListView),
        const Offset(0, -200),
      );

      expect(find.byIcon(Icons.gavel_rounded), findsOneWidget);
    });
  });

  group('SettingsScreen vibration toggle', () {
    testWidgets('displays Vibration label in AUDIO section', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Vibration'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.text('Vibration'), findsOneWidget);
    });

    testWidgets('Vibration toggle is on by default', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Vibration'),
        find.byType(ListView),
        const Offset(0, -200),
      );

      final row = find.ancestor(
        of: find.text('Vibration'),
        matching: find.byType(Row),
      ).first;
      final switchWidget = tester.widget<Switch>(
        find.descendant(of: row, matching: find.byType(Switch)),
      );
      expect(switchWidget.value, isTrue);
    });

    testWidgets('tapping Vibration toggle turns it off', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Vibration'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      final row = find.ancestor(
        of: find.text('Vibration'),
        matching: find.byType(Row),
      ).first;
      final switchFinder = find.descendant(
        of: row,
        matching: find.byType(Switch),
      );

      await tester.tap(switchFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(container.read(settingsServiceProvider).enableVibration, isFalse);
    });
  });

  group('SettingsScreen keep screen on toggle', () {
    testWidgets('displays DISPLAY section header', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('DISPLAY'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.text('DISPLAY'), findsOneWidget);
    });

    testWidgets('displays phone icon for DISPLAY header', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('DISPLAY'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.byIcon(Icons.phone_android_outlined), findsOneWidget);
    });

    testWidgets('displays Keep Screen On label', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Keep Screen On'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.text('Keep Screen On'), findsOneWidget);
    });

    testWidgets('Keep Screen On toggle is on by default', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Keep Screen On'),
        find.byType(ListView),
        const Offset(0, -200),
      );

      final row = find.ancestor(
        of: find.text('Keep Screen On'),
        matching: find.byType(Row),
      ).first;
      final switchWidget = tester.widget<Switch>(
        find.descendant(of: row, matching: find.byType(Switch)),
      );
      expect(switchWidget.value, isTrue);
    });

    testWidgets('tapping Keep Screen On toggle turns it off', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Keep Screen On'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      final row = find.ancestor(
        of: find.text('Keep Screen On'),
        matching: find.byType(Row),
      ).first;
      final switchFinder = find.descendant(
        of: row,
        matching: find.byType(Switch),
      );

      await tester.tap(switchFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(
        container.read(settingsServiceProvider).enableKeepScreenOn,
        isFalse,
      );
    });
  });

  group('SettingsScreen existing sections', () {
    testWidgets('displays SETTINGS header', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      expect(find.text('SETTINGS'), findsOneWidget);
    });

    testWidgets('displays all section headers', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      expect(find.text('ROUND DURATION'), findsOneWidget);
      expect(find.text('REST DURATION'), findsOneWidget);
      expect(find.text('TOTAL ROUNDS'), findsOneWidget);

      // AUDIO and SAVAGE LEVEL may be offscreen, scroll to find them
      await tester.dragUntilVisible(
        find.text('AUDIO'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.text('AUDIO'), findsOneWidget);

      await tester.dragUntilVisible(
        find.text('SAVAGE LEVEL'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.text('SAVAGE LEVEL'), findsOneWidget);
    });

    testWidgets('displays Reset to Defaults button', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Reset to Defaults'),
        find.byType(ListView),
        const Offset(0, -200),
      );

      expect(find.text('Reset to Defaults'), findsOneWidget);
    });

    testWidgets('displays default round duration value', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      // Default is 180s = 3m
      expect(find.text('3m'), findsOneWidget);
    });

    testWidgets('displays default rest duration value', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      // Default rest is 30s — may appear more than once (value + slider label)
      expect(find.text('30s'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays default total rounds value', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      // Default is 3 rounds
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('SettingsScreen vibration toggle - timer guard dialog', () {
    Future<void> scrollToVibrationAndTap(WidgetTester tester) async {
      await tester.dragUntilVisible(
        find.text('Vibration'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();

      final row = find
          .ancestor(of: find.text('Vibration'), matching: find.byType(Row))
          .first;
      final switchFinder =
          find.descendant(of: row, matching: find.byType(Switch));
      await tester.tap(switchFinder, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    testWidgets('shows confirmation dialog when timer is running',
        (tester) async {
      await tester.pumpWidget(buildSettingsScreenWithRunningTimer(prefs));
      await tester.pumpAndSettle();

      await scrollToVibrationAndTap(tester);

      expect(find.text('TIMER IS RUNNING'), findsOneWidget);
      expect(
        find.text(
          'Changing this setting will stop the current timer. Continue?',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Stop & Change'), findsOneWidget);
    });

    testWidgets('does not change vibration when dialog is cancelled',
        (tester) async {
      await tester.pumpWidget(buildSettingsScreenWithRunningTimer(prefs));
      await tester.pumpAndSettle();

      await scrollToVibrationAndTap(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      // Vibration should still be enabled (its default value)
      expect(container.read(settingsServiceProvider).enableVibration, isTrue);
    });

    testWidgets('disables vibration and stops timer when Stop & Change tapped',
        (tester) async {
      await tester.pumpWidget(buildSettingsScreenWithRunningTimer(prefs));
      await tester.pumpAndSettle();

      await scrollToVibrationAndTap(tester);

      await tester.tap(find.text('Stop & Change'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SettingsScreen)),
      );
      expect(container.read(settingsServiceProvider).enableVibration, isFalse);
      expect(
        container.read(timerServiceProvider).state,
        SessionState.idle,
      );
    });
  });
}
