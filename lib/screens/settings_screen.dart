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
          _buildDivider(),

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
          _buildDivider(),

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
                      settings.totalRounds < 20
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
          _buildDivider(),

          // Last Seconds Alert
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Last 30s alert ${settings.enableLastSecondsAlert ? 'enabled' : 'disabled'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Switch(
                value: settings.enableLastSecondsAlert,
                onChanged: (value) {
                  settingsService.updateLastSecondsAlert(value);
                },
                activeColor: Colors.red,
              ),
            ],
          ),
          _buildDivider(),

          // Volume
          _buildSection(
            title: 'Volume',
            value: settings.isMuted ? 'Muted' : '${(settings.volume * 100).round()}%',
            child: Row(
              children: [
                Icon(
                  settings.isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 24,
                ),
                Expanded(
                  child: Slider(
                    value: settings.volume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: settings.isMuted ? 'Muted' : '${(settings.volume * 100).round()}%',
                    onChanged: (value) {
                      settingsService.updateVolume(value);
                    },
                  ),
                ),
              ],
            ),
          ),
          _buildDivider(),

          // Savage Level
          _buildSection(
            title: 'Savage Level',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
          _buildDivider(),

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

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(
        color: Colors.grey[700],
        thickness: 1,
      ),
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
