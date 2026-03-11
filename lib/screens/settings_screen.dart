import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/workout_session.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../services/timer_service.dart';
import '../utils/app_locales.dart';
import '../widgets/savage_level_selector.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  bool _isTimerActive(WidgetRef ref) {
    final session = ref.read(timerServiceProvider);
    return session.state == SessionState.preparing ||
        session.state == SessionState.running ||
        session.state == SessionState.paused;
  }

  /// Wraps a timer-affecting change: if the timer is active, shows a
  /// confirmation dialog first. If the user confirms (or timer is idle),
  /// resets the timer and applies [onChange].
  void _guardTimerChange(
    BuildContext context,
    WidgetRef ref,
    FutureOr<void> Function() onChange,
  ) {
    if (!_isTimerActive(ref)) {
      final result = onChange();
      if (result is Future<void>) {
        unawaited(result);
      }
      return;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[850],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              context.tr('settings.guard.title'),
              style: GoogleFonts.oswald(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            content: Text(
              context.tr('settings.guard.content'),
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.tr('common.cancel'),
                  style: GoogleFonts.rajdhani(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(timerServiceProvider.notifier).reset();
                  final result = onChange();
                  if (result is Future<void>) {
                    unawaited(result);
                  }
                },
                child: Text(
                  context.tr('settings.guard.confirm'),
                  style: GoogleFonts.rajdhani(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    final settingsService = ref.read(settingsServiceProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // Header
            Text(
              context.tr('settings.header'),
              style: GoogleFonts.oswald(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 24),

            // Round Duration
            _SettingsCard(
              children: [
                _SectionHeader(
                  title: context.tr('settings.section.round_duration'),
                  icon: Icons.timer_outlined,
                ),
                const SizedBox(height: 6),
                _ToggleRow(
                  label: context.tr('settings.label.separate_round_duration'),
                  value: settings.enableSeparateRoundDurations,
                  onChanged: (value) {
                    _guardTimerChange(context, ref, () {
                      settingsService.updateSeparateRoundDurationsEnabled(
                        value,
                      );
                    });
                  },
                ),
                const SizedBox(height: 8),
                if (settings.enableSeparateRoundDurations) ...[
                  _NavigationTile(
                    title: context.tr('settings.action.set_round_durations'),
                    subtitle: context.tr(
                      'settings.value.rounds_configured',
                      namedArgs: {'rounds': '${settings.totalRounds}'},
                    ),
                    onTap: () {
                      _guardTimerChange(context, ref, () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => const SeparateRoundDurationsScreen(),
                          ),
                        );
                      });
                    },
                  ),
                ] else ...[
                  _ValueDisplay(
                    value: _formatDuration(
                      context,
                      settings.roundDurationSeconds,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: _sliderTheme(context),
                    child: Slider(
                      value: settings.roundDurationSeconds.toDouble(),
                      min: 30,
                      max: 300,
                      divisions: 54,
                      onChanged: (value) {
                        _guardTimerChange(context, ref, () {
                          settingsService.updateRoundDuration(value.toInt());
                        });
                      },
                    ),
                  ),
                  _SliderLabels(
                    left: context.tr('settings.slider.min_30s'),
                    right: context.tr('settings.slider.max_5_min'),
                  ),
                ],
                const SizedBox(height: 10),
                Divider(
                  color: Colors.white.withValues(alpha: 0.08),
                  height: 1,
                  thickness: 1,
                ),
                const SizedBox(height: 10),
                _ToggleRow(
                  label: context.tr('settings.label.warm_up_set'),
                  value: settings.enableWarmUpSet,
                  onChanged: (value) {
                    _guardTimerChange(context, ref, () {
                      settingsService.updateWarmUpSetEnabled(value);
                    });
                  },
                ),
                if (settings.enableWarmUpSet) ...[
                  Text(
                    context.tr('settings.hint.warm_up'),
                    style: GoogleFonts.rajdhani(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _NavigationTile(
                    title: context.tr('settings.action.configure_warm_up_set'),
                    subtitle: context.tr(
                      'settings.value.one_time_before_round',
                      namedArgs: {
                        'duration': _formatDuration(
                          context,
                          settings.warmUpDurationSeconds,
                        ),
                        'round': '1',
                      },
                    ),
                    onTap: () {
                      _guardTimerChange(context, ref, () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const WarmUpSetScreen(),
                          ),
                        );
                      });
                    },
                  ),
                ],
                const SizedBox(height: 8),
                _ToggleRow(
                  label: context.tr('settings.label.cool_down_set'),
                  value: settings.enableCoolDownSet,
                  onChanged: (value) {
                    _guardTimerChange(context, ref, () {
                      settingsService.updateCoolDownSetEnabled(value);
                    });
                  },
                ),
                if (settings.enableCoolDownSet) ...[
                  Text(
                    context.tr('settings.hint.cool_down'),
                    style: GoogleFonts.rajdhani(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _NavigationTile(
                    title: context.tr(
                      'settings.action.configure_cool_down_set',
                    ),
                    subtitle: context.tr(
                      'settings.value.one_time_after_all_rounds',
                      namedArgs: {
                        'duration': _formatDuration(
                          context,
                          settings.coolDownDurationSeconds,
                        ),
                      },
                    ),
                    onTap: () {
                      _guardTimerChange(context, ref, () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CoolDownSetScreen(),
                          ),
                        );
                      });
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Rest Duration
            _SettingsCard(
              children: [
                _SectionHeader(
                  title: context.tr('settings.section.rest_duration'),
                  icon: Icons.self_improvement_outlined,
                ),
                const SizedBox(height: 8),
                _ValueDisplay(
                  value:
                      '${settings.restDurationSeconds}${context.tr('common.seconds_short')}',
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: _sliderTheme(context),
                  child: Slider(
                    value: settings.restDurationSeconds.toDouble(),
                    min: 10,
                    max: 60,
                    divisions: 10,
                    onChanged: (value) {
                      _guardTimerChange(context, ref, () {
                        settingsService.updateRestDuration(value.toInt());
                      });
                    },
                  ),
                ),
                _SliderLabels(
                  left: context.tr('settings.slider.min_10s'),
                  right: context.tr('settings.slider.max_60s'),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Total Rounds
            _SettingsCard(
              children: [
                _SectionHeader(
                  title: context.tr('settings.section.total_rounds'),
                  icon: Icons.repeat_rounded,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundButton(
                      icon: Icons.remove_rounded,
                      onPressed:
                          settings.totalRounds > 1
                              ? () => _guardTimerChange(context, ref, () {
                                settingsService.updateTotalRounds(
                                  settings.totalRounds - 1,
                                );
                              })
                              : null,
                    ),
                    const SizedBox(width: 28),
                    _ValueDisplay(
                      value: '${settings.totalRounds}',
                      fontSize: 48,
                    ),
                    const SizedBox(width: 28),
                    _RoundButton(
                      icon: Icons.add_rounded,
                      onPressed:
                          settings.totalRounds < 20
                              ? () => _guardTimerChange(context, ref, () {
                                settingsService.updateTotalRounds(
                                  settings.totalRounds + 1,
                                );
                              })
                              : null,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
            const SizedBox(height: 14),

            // Audio section
            _SettingsCard(
              children: [
                _SectionHeader(
                  title: context.tr('settings.section.audio'),
                  icon: Icons.volume_up_outlined,
                ),
                const SizedBox(height: 14),

                // Volume
                Row(
                  children: [
                    Icon(
                      settings.isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 22,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SliderTheme(
                        data: _sliderTheme(context),
                        child: Slider(
                          value: settings.volume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          onChanged: (value) {
                            settingsService.updateVolume(value);
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      child: Text(
                        settings.isMuted
                            ? context.tr('common.off')
                            : '${(settings.volume * 100).round()}%',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.rajdhani(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Last 30s Voice Alert toggle
                _ToggleRow(
                  label: context.tr('settings.label.last_30s_voice_alert'),
                  value: settings.enableLastSecondsAlert,
                  onChanged: (value) {
                    _guardTimerChange(context, ref, () {
                      settingsService.updateLastSecondsAlert(value);
                    });
                  },
                ),

                // Last 10s Clapping Alert toggle
                _ToggleRow(
                  label: context.tr('settings.label.last_10s_clapping_alert'),
                  value: settings.enableLast10SecondsClappingAlert,
                  onChanged: (value) {
                    _guardTimerChange(context, ref, () {
                      settingsService.updateLast10SecondsClappingAlert(value);
                    });
                  },
                ),

                // Vibration toggle
                _ToggleRow(
                  label: context.tr('settings.label.vibration'),
                  value: settings.enableVibration,
                  onChanged: (value) {
                    _guardTimerChange(context, ref, () {
                      settingsService.updateVibration(value);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Savage Level
            _SettingsCard(
              children: [
                _SectionHeader(
                  title: context.tr('settings.section.savage_level'),
                  icon: Icons.whatshot_outlined,
                ),
                const SizedBox(height: 8),

                // Motivational voice belongs with savage level controls.
                _ToggleRow(
                  label: context.tr('settings.label.motivational_voice'),
                  value: settings.enableMotivationalSound,
                  onChanged: (value) {
                    _guardTimerChange(context, ref, () {
                      settingsService.updateMotivationalSound(value);
                    });
                  },
                ),
                const SizedBox(height: 6),
                Opacity(
                  opacity: settings.enableMotivationalSound ? 1.0 : 0.35,
                  child: IgnorePointer(
                    ignoring: !settings.enableMotivationalSound,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!settings.enableMotivationalSound) ...[
                          const SizedBox(height: 2),
                          Text(
                            context.tr(
                              'settings.hint.enable_voice_to_change_level',
                            ),
                            style: GoogleFonts.rajdhani(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        SavageLevelSelector(
                          selectedLevel: settings.savageLevel,
                          onChanged: (level) {
                            _guardTimerChange(context, ref, () {
                              settingsService.updateSavageLevel(level);
                              if (settings.enableMotivationalSound) {
                                ref
                                    .read(audioServiceProvider)
                                    .playExampleVoice(level);
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        SavageLevelDescription(level: settings.savageLevel),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Display
            _SettingsCard(
              children: [
                _SectionHeader(
                  title: context.tr('settings.section.display'),
                  icon: Icons.phone_android_outlined,
                ),
                const SizedBox(height: 6),
                _ToggleRow(
                  label: context.tr('settings.label.keep_screen_on'),
                  value: settings.enableKeepScreenOn,
                  onChanged: (value) {
                    _guardTimerChange(context, ref, () {
                      settingsService.updateKeepScreenOn(value);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Language
            _SettingsCard(
              children: [
                _SectionHeader(
                  title: context.tr('settings.section.language'),
                  icon: Icons.language_rounded,
                ),
                const SizedBox(height: 8),
                _NavigationTile(
                  title: context.tr('settings.label.language'),
                  subtitle: context.tr(localeLabelKey(context.locale)),
                  onTap: () => _showLanguagePicker(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Reset button
            Center(
              child: TextButton.icon(
                onPressed:
                    () => _showResetDialog(context, ref, settingsService),
                icon: Icon(
                  Icons.restore_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
                label: Text(
                  context.tr('settings.action.reset_to_defaults'),
                  style: GoogleFonts.rajdhani(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Legal links
            Divider(color: Colors.white.withValues(alpha: 0.08), thickness: 1),
            const SizedBox(height: 16),
            _SectionHeader(
              title: context.tr('settings.section.legal'),
              icon: Icons.gavel_rounded,
            ),
            const SizedBox(height: 12),
            _LegalLinkTile(
              icon: Icons.shield_outlined,
              label: context.tr('settings.label.privacy_policy'),
              url:
                  'https://sol-cito.github.io/savage-timer/privacy_policy.html',
            ),
            const SizedBox(height: 8),
            _LegalLinkTile(
              icon: Icons.description_outlined,
              label: context.tr('settings.label.terms_of_service'),
              url:
                  'https://sol-cito.github.io/savage-timer/terms_of_service.html',
            ),
          ],
        ),
      ),
    );
  }

  SliderThemeData _sliderTheme(BuildContext context) {
    return SliderTheme.of(context).copyWith(
      activeTrackColor: Colors.white.withValues(alpha: 0.9),
      inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
      thumbColor: Colors.white,
      overlayColor: Colors.white.withValues(alpha: 0.1),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
    );
  }

  Future<void> _showLanguagePicker(BuildContext context, WidgetRef ref) async {
    final currentLocale = context.locale;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetContext) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('settings.language.select'),
                    style: GoogleFonts.oswald(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final locale in kSupportedLocales)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        context.tr(localeLabelKey(locale)),
                        style: GoogleFonts.rajdhani(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      trailing:
                          locale.languageCode == currentLocale.languageCode
                              ? const Icon(
                                Icons.check_rounded,
                                color: Colors.redAccent,
                              )
                              : null,
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        if (locale.languageCode != currentLocale.languageCode) {
                          _guardTimerChange(context, ref, () async {
                            await context.setLocale(locale);
                          });
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
    );
  }

  String _formatDuration(BuildContext context, int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final secondsShort = context.tr('common.seconds_short');
    final minutesShort = context.tr('common.minutes_short');
    if (minutes == 0) return '$secs$secondsShort';
    if (secs == 0) return '$minutes$minutesShort';
    return '$minutes$minutesShort $secs$secondsShort';
  }

  void _showResetDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsService settingsService,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[850],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              context.tr('settings.reset_dialog.title'),
              style: GoogleFonts.oswald(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            content: Text(
              context.tr('settings.reset_dialog.content'),
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  context.tr('common.cancel'),
                  style: GoogleFonts.rajdhani(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _guardTimerChange(context, ref, () {
                    settingsService.resetToDefaults();
                  });
                },
                child: Text(
                  context.tr('common.reset'),
                  style: GoogleFonts.rajdhani(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

class SeparateRoundDurationsScreen extends ConsumerWidget {
  const SeparateRoundDurationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    final settingsService = ref.read(settingsServiceProvider.notifier);
    final roundDurations = settings.resolvedRoundDurationsSeconds;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: context.tr('common.back'),
        ),
        title: Text(
          context.tr('settings.section.separate_round_duration'),
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              context.tr('settings.hint.set_duration_per_round'),
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < settings.totalRounds; i++) ...[
              _SettingsCard(
                children: [
                  _SectionHeader(
                    title: context.tr(
                      'settings.value.round_title',
                      namedArgs: {'round': '${i + 1}'},
                    ),
                    icon: Icons.timer_outlined,
                  ),
                  const SizedBox(height: 8),
                  _ValueDisplay(
                    value: _formatDuration(context, roundDurations[i]),
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white.withValues(alpha: 0.9),
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withValues(alpha: 0.1),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                    ),
                    child: Slider(
                      value: roundDurations[i].toDouble(),
                      min: 30,
                      max: 300,
                      divisions: 54,
                      onChanged: (value) {
                        settingsService.updateRoundDurationForRound(
                          roundNumber: i + 1,
                          seconds: value.toInt(),
                        );
                      },
                    ),
                  ),
                  _SliderLabels(
                    left: context.tr('settings.slider.min_30s'),
                    right: context.tr('settings.slider.max_5_min'),
                  ),
                ],
              ),
              if (i != settings.totalRounds - 1) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(BuildContext context, int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final secondsShort = context.tr('common.seconds_short');
    final minutesShort = context.tr('common.minutes_short');
    if (minutes == 0) return '$secs$secondsShort';
    if (secs == 0) return '$minutes$minutesShort';
    return '$minutes$minutesShort $secs$secondsShort';
  }
}

class WarmUpSetScreen extends ConsumerWidget {
  const WarmUpSetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    final settingsService = ref.read(settingsServiceProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: context.tr('common.back'),
        ),
        title: Text(
          context.tr('settings.section.warm_up_set'),
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              context.tr('settings.hint.warm_up_screen_description'),
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 14),
            _SettingsCard(
              children: [
                _SectionHeader(
                  title: context.tr('settings.section.warm_up_duration'),
                  icon: Icons.local_fire_department_outlined,
                ),
                const SizedBox(height: 8),
                _ValueDisplay(
                  value: _formatDuration(
                    context,
                    settings.warmUpDurationSeconds,
                  ),
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white.withValues(alpha: 0.9),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withValues(alpha: 0.1),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                  ),
                  child: Slider(
                    value: settings.warmUpDurationSeconds.toDouble(),
                    min: 30,
                    max: 300,
                    divisions: 54,
                    onChanged: (value) {
                      settingsService.updateWarmUpDuration(value.toInt());
                    },
                  ),
                ),
                _SliderLabels(
                  left: context.tr('settings.slider.min_30s'),
                  right: context.tr('settings.slider.max_5_min'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(BuildContext context, int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final secondsShort = context.tr('common.seconds_short');
    final minutesShort = context.tr('common.minutes_short');
    if (minutes == 0) return '$secs$secondsShort';
    if (secs == 0) return '$minutes$minutesShort';
    return '$minutes$minutesShort $secs$secondsShort';
  }
}

class CoolDownSetScreen extends ConsumerWidget {
  const CoolDownSetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    final settingsService = ref.read(settingsServiceProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: context.tr('common.back'),
        ),
        title: Text(
          context.tr('settings.section.cool_down_set'),
          style: GoogleFonts.oswald(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              context.tr('settings.hint.cool_down_screen_description'),
              style: GoogleFonts.rajdhani(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 14),
            _SettingsCard(
              children: [
                _SectionHeader(
                  title: context.tr('settings.section.cool_down_duration'),
                  icon: Icons.ac_unit_rounded,
                ),
                const SizedBox(height: 8),
                _ValueDisplay(
                  value: _formatDuration(
                    context,
                    settings.coolDownDurationSeconds,
                  ),
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white.withValues(alpha: 0.9),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
                    thumbColor: Colors.white,
                    overlayColor: Colors.white.withValues(alpha: 0.1),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                  ),
                  child: Slider(
                    value: settings.coolDownDurationSeconds.toDouble(),
                    min: 30,
                    max: 300,
                    divisions: 54,
                    onChanged: (value) {
                      settingsService.updateCoolDownDuration(value.toInt());
                    },
                  ),
                ),
                _SliderLabels(
                  left: context.tr('settings.slider.min_30s'),
                  right: context.tr('settings.slider.max_5_min'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(BuildContext context, int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    final secondsShort = context.tr('common.seconds_short');
    final minutesShort = context.tr('common.minutes_short');
    if (minutes == 0) return '$secs$secondsShort';
    if (secs == 0) return '$minutes$minutesShort';
    return '$minutes$minutesShort $secs$secondsShort';
  }
}

// ── Reusable building blocks ──────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.rajdhani(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _ValueDisplay extends StatelessWidget {
  final String value;
  final double fontSize;

  const _ValueDisplay({required this.value, this.fontSize = 36});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        value,
        style: GoogleFonts.oswald(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _SliderLabels extends StatelessWidget {
  final String left;
  final String right;

  const _SliderLabels({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.rajdhani(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.white.withValues(alpha: 0.35),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(left, style: style), Text(right, style: style)],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _RoundButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: enabled ? 0.15 : 0.05),
            border: Border.all(
              color: Colors.white.withValues(alpha: enabled ? 0.3 : 0.1),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: enabled ? 0.9 : 0.25),
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.rajdhani(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: Colors.white.withValues(alpha: 0.35),
            inactiveThumbColor: Colors.white.withValues(alpha: 0.4),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavigationTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.rajdhani(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.rajdhani(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '>',
                style: GoogleFonts.rajdhani(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalLinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _LegalLinkTile({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.rajdhani(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                color: Colors.white.withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
