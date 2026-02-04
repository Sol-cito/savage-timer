import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/timer_settings.dart';
import '../models/workout_session.dart';
import '../services/settings_service.dart';
import '../services/timer_service.dart';
import '../widgets/circular_timer.dart';
import '../widgets/control_button.dart';
import '../widgets/round_indicator.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(timerServiceProvider);
    final timerService = ref.read(timerServiceProvider.notifier);
    final settings = ref.watch(settingsServiceProvider);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _getBackgroundColors(session),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Total duration
                Text(
                  'Total ${session.formattedTotalDuration}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                // Phase label
                Text(
                  session.phaseLabel,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                // Round indicator
                RoundIndicator(
                  totalRounds: session.totalRounds,
                  currentRound: session.currentRound,
                  isResting: session.isResting,
                ),
                const SizedBox(height: 12),
                // Mode indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getSavageLevelIcon(settings.savageLevel),
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getSavageLevelName(settings.savageLevel),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Circular timer
                CircularTimer(
                  time: session.formattedTime,
                  progress: session.progress,
                  progressColor: _getProgressColor(session),
                  backgroundColor: Colors.white,
                ),
                const Spacer(),
                // Control buttons
                _buildControls(session, timerService),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(WorkoutSession session, TimerService timerService) {
    final isRunning = session.state == SessionState.running;
    final isPaused = session.state == SessionState.paused;
    final isIdle = session.state == SessionState.idle;
    final isCompleted = session.state == SessionState.completed;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Reset button
        ControlButton(
          icon: Icons.refresh,
          onPressed:
              (isRunning || isPaused || isCompleted)
                  ? () => timerService.reset()
                  : null,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          iconColor: Colors.white,
          size: 56,
          label: 'Reset',
        ),
        const SizedBox(width: 32),
        // Play/Pause button
        PlayPauseButton(
          isPlaying: isRunning,
          showLabel: true,
          onPressed: () {
            if (isIdle || isCompleted) {
              timerService.start();
            } else if (isRunning) {
              timerService.pause();
            } else if (isPaused) {
              timerService.resume();
            }
          },
        ),
        const SizedBox(width: 32),
        // Placeholder for symmetry (matching reset button width + label)
        const SizedBox(width: 56),
      ],
    );
  }

  List<Color> _getBackgroundColors(WorkoutSession session) {
    if (session.state == SessionState.completed) {
      return [Colors.green.shade900, Colors.green.shade700];
    }
    if (session.state == SessionState.idle) {
      return [Colors.grey.shade900, Colors.grey.shade800];
    }
    if (session.isResting) {
      return [Colors.green.shade900, Colors.teal.shade800];
    }
    // Round phase - red gradient, more intense in last seconds
    if (session.isInLastSeconds) {
      return [Colors.red.shade900, Colors.orange.shade800];
    }
    return [Colors.red.shade900, Colors.red.shade700];
  }

  Color _getProgressColor(WorkoutSession session) {
    if (session.state == SessionState.completed) {
      return Colors.green;
    }
    if (session.isResting) {
      return Colors.green;
    }
    if (session.isInLastSeconds) {
      return Colors.orange;
    }
    return Colors.red;
  }

  String _getSavageLevelName(SavageLevel level) {
    switch (level) {
      case SavageLevel.level1:
        return 'Mild';
      case SavageLevel.level2:
        return 'Medium';
      case SavageLevel.level3:
        return 'Savage';
    }
  }

  IconData _getSavageLevelIcon(SavageLevel level) {
    switch (level) {
      case SavageLevel.level1:
        return Icons.sentiment_satisfied;
      case SavageLevel.level2:
        return Icons.sentiment_neutral;
      case SavageLevel.level3:
        return Icons.whatshot;
    }
  }
}
