import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/workout_session.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../services/timer_service.dart';
import '../widgets/savage_level_selector.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  bool _isTimerActive(WidgetRef ref) {
    final session = ref.read(timerServiceProvider);
    return session.state == SessionState.running ||
        session.state == SessionState.paused;
  }

  /// Wraps a timer-affecting change: if the timer is active, shows a
  /// confirmation dialog first. If the user confirms (or timer is idle),
  /// resets the timer and applies [onChange].
  void _guardTimerChange(
    BuildContext context,
    WidgetRef ref,
    VoidCallback onChange,
  ) {
    if (!_isTimerActive(ref)) {
      onChange();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'TIMER IS RUNNING',
          style: GoogleFonts.oswald(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        content: Text(
          'Changing this setting will stop the current timer. Continue?',
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
              'Cancel',
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
              onChange();
            },
            child: Text(
              'Stop & Change',
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
              'SETTINGS',
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
                  title: 'ROUND DURATION',
                  icon: Icons.timer_outlined,
                ),
                const SizedBox(height: 8),
                _ValueDisplay(value: _formatDuration(settings.roundDurationSeconds)),
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
                _SliderLabels(left: '30s', right: '5 min'),
              ],
            ),
            const SizedBox(height: 14),

            // Rest Duration
            _SettingsCard(
              children: [
                _SectionHeader(
                  title: 'REST DURATION',
                  icon: Icons.self_improvement_outlined,
                ),
                const SizedBox(height: 8),
                _ValueDisplay(value: '${settings.restDurationSeconds}s'),
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
                _SliderLabels(left: '10s', right: '60s'),
              ],
            ),
            const SizedBox(height: 14),

            // Total Rounds
            _SettingsCard(
              children: [
                _SectionHeader(
                  title: 'TOTAL ROUNDS',
                  icon: Icons.repeat_rounded,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundButton(
                      icon: Icons.remove_rounded,
                      onPressed: settings.totalRounds > 1
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
                      onPressed: settings.totalRounds < 20
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
                  title: 'AUDIO',
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
                            ? 'OFF'
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

                // Motivational Sound toggle
                _ToggleRow(
                  label: 'Motivational Voice',
                  value: settings.enableMotivationalSound,
                  onChanged: (value) {
                    _guardTimerChange(context, ref, () {
                      settingsService.updateMotivationalSound(value);
                    });
                  },
                ),

                // Last 30s Alert toggle
                _ToggleRow(
                  label: 'Last 30s Alert',
                  value: settings.enableLastSecondsAlert,
                  onChanged: (value) {
                    _guardTimerChange(context, ref, () {
                      settingsService.updateLastSecondsAlert(value);
                    });
                  },
                ),

                // Vibration toggle
                _ToggleRow(
                  label: 'Vibration',
                  value: settings.enableVibration,
                  onChanged: (value) {
                    settingsService.updateVibration(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Display
            _SettingsCard(
              children: [
                _SectionHeader(
                  title: 'DISPLAY',
                  icon: Icons.phone_android_outlined,
                ),
                const SizedBox(height: 6),
                _ToggleRow(
                  label: 'Keep Screen On',
                  value: settings.enableKeepScreenOn,
                  onChanged: (value) {
                    settingsService.updateKeepScreenOn(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Savage Level
            Opacity(
              opacity: settings.enableMotivationalSound ? 1.0 : 0.35,
              child: IgnorePointer(
                ignoring: !settings.enableMotivationalSound,
                child: _SettingsCard(
                  children: [
                    _SectionHeader(
                      title: 'SAVAGE LEVEL',
                      icon: Icons.whatshot_outlined,
                    ),
                    if (!settings.enableMotivationalSound) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Enable Motivational Voice to change level',
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
                            ref.read(audioServiceProvider).playExampleVoice(level);
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
            const SizedBox(height: 24),

            // Reset button
            Center(
              child: TextButton.icon(
                onPressed: () => _showResetDialog(context, ref, settingsService),
                icon: Icon(
                  Icons.restore_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
                label: Text(
                  'Reset to Defaults',
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
            Divider(
              color: Colors.white.withValues(alpha: 0.08),
              thickness: 1,
            ),
            const SizedBox(height: 16),
            _SectionHeader(
              title: 'LEGAL',
              icon: Icons.gavel_rounded,
            ),
            const SizedBox(height: 12),
            _LegalLinkTile(
              icon: Icons.shield_outlined,
              label: 'Privacy Policy',
              url: 'https://sol-cito.github.io/savage-timer/privacy_policy.html',
            ),
            const SizedBox(height: 8),
            _LegalLinkTile(
              icon: Icons.description_outlined,
              label: 'Terms of Service',
              url: 'https://sol-cito.github.io/savage-timer/terms_of_service.html',
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes == 0) return '${secs}s';
    if (secs == 0) return '${minutes}m';
    return '${minutes}m ${secs}s';
  }

  void _showResetDialog(BuildContext context, WidgetRef ref, SettingsService settingsService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'RESET SETTINGS',
          style: GoogleFonts.oswald(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        content: Text(
          'Are you sure you want to reset all settings to defaults?',
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
              'Cancel',
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
              'Reset',
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
        children: [
          Text(left, style: style),
          Text(right, style: style),
        ],
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
          launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
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
              Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.5),
                size: 20,
              ),
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
