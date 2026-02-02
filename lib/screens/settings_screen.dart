import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings_service.dart';
import '../widgets/savage_level_selector.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    final settingsService = ref.read(settingsServiceProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Round Duration
          _buildSection(
            title: 'Round Duration',
            value: _formatDuration(settings.roundDurationSeconds),
            child: Slider(
              value: settings.roundDurationSeconds.toDouble(),
              min: 60,
              max: 300,
              divisions: 48,
              label: _formatDuration(settings.roundDurationSeconds),
              onChanged: (value) {
                settingsService.updateRoundDuration(value.toInt());
              },
            ),
          ),
          const SizedBox(height: 24),

          // Rest Duration
          _buildSection(
            title: 'Rest Duration',
            value: '${settings.restDurationSeconds}s',
            child: Slider(
              value: settings.restDurationSeconds.toDouble(),
              min: 10,
              max: 60,
              divisions: 10,
              label: '${settings.restDurationSeconds}s',
              onChanged: (value) {
                settingsService.updateRestDuration(value.toInt());
              },
            ),
          ),
          const SizedBox(height: 24),

          // Total Rounds
          _buildSection(
            title: 'Total Rounds',
            value: '${settings.totalRounds}',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed:
                      settings.totalRounds > 1
                          ? () => settingsService.updateTotalRounds(
                            settings.totalRounds - 1,
                          )
                          : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: 32,
                  color: Colors.white,
                ),
                Container(
                  width: 60,
                  alignment: Alignment.center,
                  child: Text(
                    '${settings.totalRounds}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed:
                      settings.totalRounds < 12
                          ? () => settingsService.updateTotalRounds(
                            settings.totalRounds + 1,
                          )
                          : null,
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 32,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Last Seconds Alert
          _buildSection(
            title: 'Last 30 Seconds Alert',
            child: SwitchListTile(
              value: settings.enableLastSecondsAlert,
              onChanged: (value) {
                settingsService.updateLastSecondsAlert(value);
              },
              title: Text(
                settings.enableLastSecondsAlert ? 'Enabled' : 'Disabled',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Alert when ${settings.lastSecondsThreshold} seconds remain',
                style: TextStyle(color: Colors.grey[400]),
              ),
              activeColor: Colors.red,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 24),

          // Savage Level
          _buildSection(
            title: 'Savage Level',
            child: Column(
              children: [
                SavageLevelSelector(
                  selectedLevel: settings.savageLevel,
                  onChanged: (level) {
                    settingsService.updateSavageLevel(level);
                  },
                ),
                const SizedBox(height: 12),
                SavageLevelDescription(level: settings.savageLevel),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Reset button
          OutlinedButton.icon(
            onPressed: () => _showResetDialog(context, settingsService),
            icon: const Icon(Icons.restore),
            label: const Text('Reset to Defaults'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey,
              side: const BorderSide(color: Colors.grey),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? value,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (value != null)
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[400],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (secs == 0) {
      return '${minutes}m';
    }
    return '${minutes}m ${secs}s';
  }

  void _showResetDialog(BuildContext context, SettingsService settingsService) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Settings'),
            content: const Text(
              'Are you sure you want to reset all settings to defaults?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  settingsService.resetToDefaults();
                  Navigator.pop(context);
                },
                child: const Text('Reset'),
              ),
            ],
          ),
    );
  }
}
