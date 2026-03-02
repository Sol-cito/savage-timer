import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/timer_settings.dart';
import '../models/workout_session.dart';
import '../services/settings_service.dart';
import '../services/timer_service.dart';
import '../widgets/circular_timer.dart';
import '../widgets/control_button.dart';
import '../widgets/round_indicator.dart';
import '../widgets/up_next_card.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(timerServiceProvider);
    final timerService = ref.read(timerServiceProvider.notifier);
    final settings = ref.watch(settingsServiceProvider);
    final hasUpNext = session.nextPhaseLabel != null;

    // Scale factor based on screen height (designed for ~852pt)
    final screenHeight = MediaQuery.sizeOf(context).height;
    final s = (screenHeight / 852).clamp(0.65, 1.0);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _getBackgroundColors(
              session,
              settings.savageLevel,
              settings.enableMotivationalSound,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12 * s),
            child: Column(
              children: [
                // Total duration and elapsed
                Text(
                  'Total ${session.formattedTotalDuration} | Elapsed ${session.formattedElapsed}',
                  style: GoogleFonts.rajdhani(
                    fontSize: 18 * s + 2,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: (hasUpNext ? 4 : 10) * s,
                ),
                // Phase label
                Text(
                  session.phaseLabel,
                  style: GoogleFonts.oswald(
                    fontSize: 36 * s + 4,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: (hasUpNext ? 10 : 20) * s,
                ),
                // Round indicator
                RoundIndicator(
                  totalRounds: session.totalRounds,
                  currentRound: session.currentRound,
                  isResting: session.isResting,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: (hasUpNext ? 12 : 24) * s,
                ),
                // Mode indicator (only when motivational voice is on)
                if (settings.enableMotivationalSound)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getSavageLevelIcon(settings.savageLevel),
                        color: _getSavageLevelColor(settings.savageLevel),
                        size: 28 * s + 4,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getSavageLevelName(settings.savageLevel),
                        style: GoogleFonts.oswald(
                          fontSize: 18 * s + 4,
                          fontWeight: FontWeight.w600,
                          color: _getSavageLevelColor(settings.savageLevel),
                        ),
                      ),
                    ],
                  ),
                const Spacer(),
                // Circular timer — scales with screen
                CircularTimer(
                  time: session.preparationCountdown ?? session.formattedTime,
                  progress: session.progress,
                  isCountdown: session.state == SessionState.preparing,
                  progressColor: _getProgressColor(
                    session,
                    settings.savageLevel,
                    settings.enableMotivationalSound,
                  ),
                  backgroundColor: Colors.white,
                  size: 220 * s + 30,
                  strokeWidth: 14 * s + 2,
                ),
                if (session.nextPhaseLabel != null) ...[
                  SizedBox(height: 14 * s),
                  UpNextCard(
                    phaseLabel: session.nextPhaseLabel!,
                    duration: session.formattedNextPhaseDuration,
                  ),
                ],
                const Spacer(),
                // Control buttons
                _buildControls(session, timerService, s),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(
    WorkoutSession session,
    TimerService timerService,
    double s,
  ) {
    final isPreparing = session.state == SessionState.preparing;
    final isRunning = session.state == SessionState.running || isPreparing;
    final isPaused = session.state == SessionState.paused;
    final isIdle = session.state == SessionState.idle;
    final isCompleted = session.state == SessionState.completed;

    final resetSize = 40 * s + 12;
    final playSize = 56 * s + 18;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
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
          size: resetSize,
          label: 'Reset',
        ),
        SizedBox(width: 24 * s + 4),
        // Play/Pause button
        PlayPauseButton(
          isPlaying: isRunning,
          showLabel: true,
          size: playSize,
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
        SizedBox(width: 24 * s + 4),
        // Skip button
        ControlButton(
          icon: Icons.skip_next,
          onPressed:
              (isRunning || isPaused) ? () => timerService.skip() : null,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          iconColor: Colors.white,
          size: resetSize,
          label: 'Skip',
        ),
      ],
    );
  }

  List<Color> _getBackgroundColors(
    WorkoutSession session,
    SavageLevel level,
    bool motivationalOn,
  ) {
    if (session.state == SessionState.completed) {
      return [Colors.green.shade900, Colors.green.shade700];
    }
    if (session.state == SessionState.idle ||
        session.state == SessionState.preparing) {
      return [Colors.grey.shade900, Colors.grey.shade800];
    }
    if (session.isResting) {
      return [Colors.green.shade900, Colors.teal.shade800];
    }
    // Neutral mode — muted blue-grey
    if (!motivationalOn) {
      if (session.isInLastSeconds) {
        return [Colors.blueGrey.shade900, Colors.orange.shade900];
      }
      return [Colors.blueGrey.shade900, Colors.blueGrey.shade700];
    }
    // Round phase - gradient based on savage level
    if (session.isInLastSeconds) {
      switch (level) {
        case SavageLevel.level1:
          return [Colors.blue.shade900, Colors.orange.shade800];
        case SavageLevel.level2:
          return [Colors.amber.shade900, Colors.orange.shade800];
        case SavageLevel.level3:
          return [Colors.red.shade900, Colors.orange.shade800];
      }
    }
    switch (level) {
      case SavageLevel.level1:
        return [Colors.blue.shade900, Colors.blue.shade700];
      case SavageLevel.level2:
        return [Colors.amber.shade900, Colors.amber.shade700];
      case SavageLevel.level3:
        return [Colors.red.shade900, Colors.red.shade700];
    }
  }

  Color _getProgressColor(
    WorkoutSession session,
    SavageLevel level,
    bool motivationalOn,
  ) {
    if (session.state == SessionState.preparing) {
      return Colors.white;
    }
    if (session.state == SessionState.completed) {
      return Colors.green;
    }
    if (session.isResting) {
      return Colors.green;
    }
    if (session.isInLastSeconds) {
      return Colors.orange;
    }
    if (!motivationalOn) {
      return Colors.blueGrey.shade300;
    }
    switch (level) {
      case SavageLevel.level1:
        return Colors.lightBlueAccent;
      case SavageLevel.level2:
        return Colors.amber;
      case SavageLevel.level3:
        return Colors.red;
    }
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
        return Icons.spa;
      case SavageLevel.level2:
        return Icons.fitness_center;
      case SavageLevel.level3:
        return Icons.whatshot;
    }
  }

  Color _getSavageLevelColor(SavageLevel level) {
    switch (level) {
      case SavageLevel.level1:
        return Colors.lightBlueAccent;
      case SavageLevel.level2:
        return Colors.yellowAccent;
      case SavageLevel.level3:
        return Colors.redAccent;
    }
  }
}
