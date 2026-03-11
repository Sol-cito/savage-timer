import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryAssetLoader extends AssetLoader {
  const _InMemoryAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return jsonDecode(_enTranslationsJson) as Map<String, dynamic>;
  }
}

const String _enTranslationsJson = '''
{
  "app": {
    "title": "Savage Timer",
    "tab": {
      "timer": "Timer",
      "settings": "Settings"
    }
  },
  "common": {
    "cancel": "Cancel",
    "reset": "Reset",
    "back": "Back",
    "off": "OFF",
    "seconds_short": "s",
    "minutes_short": "m",
    "minutes_label": "min"
  },
  "timer": {
    "summary": "Total {total} | Elapsed {elapsed}",
    "warm_up_badge": "WARM-UP ROUND IN PROGRESS",
    "control": {
      "reset": "Reset",
      "skip": "Skip",
      "start": "Start",
      "pause": "Pause"
    },
    "reset_dialog": {
      "title": "Reset Timer",
      "content": "Are you sure you want to reset? Current progress will be lost."
    },
    "phase": {
      "ready": "READY",
      "get_ready": "GET READY",
      "done": "DONE",
      "warm_up": "WARM-UP",
      "cool_down": "COOL-DOWN",
      "round": "ROUND {round}",
      "rest": "REST"
    },
    "round_indicator": "ROUND {current} OF {total}",
    "up_next": {
      "label": "UP NEXT",
      "rest": "Rest",
      "cool_down": "Cool-down",
      "finish": "Finish",
      "round": "Round {round}"
    },
    "level": {
      "mild": "Mild",
      "medium": "Medium",
      "savage": "Savage"
    }
  },
  "settings": {
    "guard": {
      "title": "TIMER IS RUNNING",
      "content": "Changing this setting will stop the current timer. Continue?",
      "confirm": "Stop & Change"
    },
    "header": "SETTINGS",
    "section": {
      "round_duration": "ROUND DURATION",
      "rest_duration": "REST DURATION",
      "total_rounds": "TOTAL ROUNDS",
      "audio": "AUDIO",
      "display": "DISPLAY",
      "language": "LANGUAGE",
      "savage_level": "SAVAGE LEVEL",
      "legal": "LEGAL",
      "separate_round_duration": "SEPARATE ROUND DURATION",
      "warm_up_set": "WARM-UP SET",
      "warm_up_duration": "WARM-UP DURATION",
      "cool_down_set": "COOL-DOWN SET",
      "cool_down_duration": "COOL-DOWN DURATION"
    },
    "label": {
      "separate_round_duration": "Separate Round Duration",
      "warm_up_set": "Warm-up Set",
      "cool_down_set": "Cool-down Set",
      "motivational_voice": "Motivational Voice",
      "last_30s_voice_alert": "Last 30s Voice Alert",
      "last_10s_clapping_alert": "Last 10s Clapping Alert",
      "vibration": "Vibration",
      "language": "Language",
      "keep_screen_on": "Keep Screen On",
      "privacy_policy": "Privacy Policy",
      "terms_of_service": "Terms of Service"
    },
    "language": {
      "select": "Select Language",
      "english": "English",
      "spanish": "Spanish",
      "korean": "Korean"
    },
    "hint": {
      "warm_up": "Runs once before Round 1 so you can ease in and lock your pace.",
      "cool_down": "Runs once after your final round so you can recover before finishing.",
      "enable_voice_to_change_level": "Enable Motivational Voice to change level",
      "set_duration_per_round": "Set a duration for each round",
      "warm_up_screen_description": "This one-time warm-up runs before your workout rounds begin.",
      "cool_down_screen_description": "This one-time cool-down runs after your final round before the workout completes."
    },
    "action": {
      "set_round_durations": "Set Round Durations",
      "configure_warm_up_set": "Configure Warm-up Set",
      "configure_cool_down_set": "Configure Cool-down Set",
      "reset_to_defaults": "Reset to Defaults"
    },
    "value": {
      "rounds_configured": "{rounds} rounds configured",
      "one_time_before_round": "One-time {duration} before Round {round}",
      "one_time_after_all_rounds": "One-time {duration} after all rounds",
      "round_title": "ROUND {round}"
    },
    "slider": {
      "min_30s": "30s",
      "max_5_min": "5 min",
      "min_10s": "10s",
      "max_60s": "60s"
    },
    "reset_dialog": {
      "title": "RESET SETTINGS",
      "content": "Are you sure you want to reset all settings to defaults?"
    }
  },
  "savage_level": {
    "description": {
      "mild": "Encouraging and supportive motivation",
      "medium": "Firm pushes with some edge",
      "savage": "No mercy - extreme motivation"
    }
  },
  "notification": {
    "channel_name": "Timer",
    "channel_description": "Savage Timer workout progress",
    "workout_complete_title": "Workout Complete!",
    "workout_complete_body": "Great work! All rounds finished.",
    "paused_title": "Savage Timer - Paused",
    "running_title": "Savage Timer - {phase}",
    "paused_body": "{phase} - {time} remaining",
    "running_body": "Round {current}/{total} - {time}"
  }
}
''';

Future<void> ensureLocalizationInitialized() async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
}

Widget wrapWithLocalization(Widget child) {
  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('es'), Locale('ko')],
    path: 'assets/translations',
    assetLoader: const _InMemoryAssetLoader(),
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useOnlyLangCode: true,
    saveLocale: false,
    child: child,
  );
}

Widget buildLocalizedMaterialApp({required Widget home}) {
  return Builder(
    builder:
        (context) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          home: home,
        ),
  );
}

Future<void> pumpLocalizedWidget(
  WidgetTester tester, {
  required Widget widget,
  required Finder readyFinder,
  Duration step = const Duration(milliseconds: 50),
  int maxPumps = 250,
}) async {
  await tester.pumpWidget(widget);
  await tester.pump();

  for (var i = 0; i < maxPumps; i++) {
    if (readyFinder.evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
    await tester.pump(step);
  }

  expect(
    readyFinder,
    findsWidgets,
    reason:
        'Localized widget did not become ready. EasyLocalization delegates may not have loaded.',
  );
  await tester.pumpAndSettle();
}
