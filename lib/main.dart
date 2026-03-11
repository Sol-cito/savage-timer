import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'models/workout_session.dart';
import 'screens/settings_screen.dart';
import 'screens/timer_screen.dart';
import 'services/audio_service.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'services/timer_service.dart';
import 'utils/app_locales.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();
  final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
  final startLocale = _resolveSupportedLocale(deviceLocale);

  runApp(
    EasyLocalization(
      supportedLocales: kSupportedLocales,
      path: 'assets/translations',
      fallbackLocale: kFallbackLocale,
      startLocale: startLocale,
      // Always follow device language on app launch.
      saveLocale: false,
      useOnlyLangCode: true,
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const SavageTimerApp(),
      ),
    ),
  );
}

Locale _resolveSupportedLocale(Locale locale) {
  for (final supported in kSupportedLocales) {
    if (supported.languageCode == locale.languageCode) {
      return supported;
    }
  }
  return kFallbackLocale;
}

class SavageTimerApp extends ConsumerStatefulWidget {
  const SavageTimerApp({super.key});

  @override
  ConsumerState<SavageTimerApp> createState() => _SavageTimerAppState();
}

class _SavageTimerAppState extends ConsumerState<SavageTimerApp>
    with WidgetsBindingObserver {
  String? _lastAudioLanguageCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = context.locale.languageCode;
    if (languageCode == _lastAudioLanguageCode) {
      return;
    }
    _lastAudioLanguageCode = languageCode;
    ref.read(audioServiceProvider).setVoiceLanguage(languageCode);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(timerServiceProvider.notifier).reconcile();
    }
  }

  Future<void> _initializeServices() async {
    final audioService = ref.read(audioServiceProvider);
    await audioService.initialize();

    await ref.read(notificationServiceProvider).initialize();

    final settings = ref.read(settingsServiceProvider);
    WakelockPlus.toggle(enable: settings.enableKeepScreenOn);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsServiceProvider, (previous, next) {
      if (previous?.enableKeepScreenOn != next.enableKeepScreenOn) {
        WakelockPlus.toggle(enable: next.enableKeepScreenOn);
      }
    });

    ref.listen<WorkoutSession>(timerServiceProvider, (prev, next) {
      final notificationService = ref.read(notificationServiceProvider);
      if (next.state == SessionState.idle) {
        notificationService.dismiss();
      } else if (prev?.state != next.state ||
          prev?.phase != next.phase ||
          prev?.currentRound != next.currentRound) {
        notificationService.update(next);
      }
    });

    return MaterialApp(
      title: 'app.title'.tr(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          elevation: 0,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.red,
          inactiveTrackColor: Colors.grey[700],
          thumbColor: Colors.red,
          overlayColor: Colors.red.withValues(alpha: 0.2),
          valueIndicatorColor: Colors.red,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _screens = const [TimerScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.timer),
            label: context.tr('app.tab.timer'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: context.tr('app.tab.settings'),
          ),
        ],
      ),
    );
  }
}
