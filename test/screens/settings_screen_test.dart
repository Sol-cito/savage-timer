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

/// A minimal fake AudioService so we don't need real audio players in tests.
class FakeAudioService extends AudioService {
  @override
  Future<void> initialize() async {}
  @override
  Future<void> playExampleVoice(SavageLevel level) async {}
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

      // Default rest is 30s
      expect(find.text('30s'), findsOneWidget);
    });

    testWidgets('displays default total rounds value', (tester) async {
      await tester.pumpWidget(buildSettingsScreen(prefs));
      await tester.pumpAndSettle();

      // Default is 3 rounds
      expect(find.text('3'), findsOneWidget);
    });
  });
}
