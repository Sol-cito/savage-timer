import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/timer_settings.dart';
import '../models/workout_session.dart';
import '../services/settings_service.dart';
import '../services/timer_service.dart';
import '../utils/session_labels.dart';
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
    final upNext = localizedUpNextPhase(session, context: context);
    final hasUpNext = upNext != null;

    // Scale factor based on screen height (designed for ~852pt)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final needsDenseCompactLayout =
        screenHeight < 620 && (hasUpNext || session.isWarmUp);
    final compactScale =
        screenHeight < 620 ? (needsDenseCompactLayout ? 0.76 : 0.88) : 1.0;
    final s = ((screenHeight / 852).clamp(0.65, 1.0) * compactScale).clamp(
      0.55,
      1.0,
    );
    final horizontalPadding = screenWidth < 360 ? 16.0 : 24.0;
    final availableContentWidth = screenWidth - (horizontalPadding * 2);
    final timerSize = math.min(220 * s + 30, availableContentWidth);

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
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 12 * s,
            ),
            child: Column(
              children: [
                // Total duration and elapsed
                Text(
                  context.tr(
                    'timer.summary',
                    namedArgs: {
                      'total': session.formattedTotalDuration,
                      'elapsed': session.formattedElapsed,
                    },
                  ),
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
                  localizedPhaseLabel(session, context: context),
                  style: GoogleFonts.oswald(
                    fontSize: 36 * s + 4,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
                ),
                if (session.isWarmUp) ...[
                  SizedBox(height: 6 * s),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      context.tr('timer.warm_up_badge'),
                      style: GoogleFonts.rajdhani(
                        fontSize: 13 * s + 1,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.92),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
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
                        _getSavageLevelName(context, settings.savageLevel),
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
                  isCountdown:
                      session.state == SessionState.preparing ||
                      session.pausedDuringPreparation,
                  progressColor: _getProgressColor(
                    session,
                    settings.savageLevel,
                    settings.enableMotivationalSound,
                  ),
                  backgroundColor: Colors.white,
                  size: timerSize,
                  strokeWidth: 14 * s + 2,
                ),
                if (upNext != null) ...[
                  SizedBox(height: 14 * s),
                  SizedBox(
                    width: timerSize,
                    child: UpNextCard(
                      phaseType: upNext.type,
                      phaseLabel: upNext.label,
                      duration: session.formattedNextPhaseDuration,
                    ),
                  ),
                ],
                const Spacer(),
                // Control buttons
                _buildControls(context, session, timerService, s),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
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
    final resetLabel = context.tr('timer.control.reset');
    final skipLabel = context.tr('timer.control.skip');
    final playLabel =
        isRunning
            ? context.tr('timer.control.pause')
            : context.tr('timer.control.start');

    final sideLabelWidth = math.max(
      _measureControlLabelWidth(context, resetLabel),
      _measureControlLabelWidth(context, skipLabel),
    );
    final centerLabelWidth = _measureControlLabelWidth(context, playLabel);
    final slotPadding = 12 * s + 2;
    final sideSlotWidth = math.max(resetSize, sideLabelWidth + slotPadding);
    final centerSlotWidth = math.max(playSize, centerLabelWidth + slotPadding);
    final spacing = 12 * s + 2;

    Widget inSlot(Widget child, double width) {
      return SizedBox(width: width, child: Center(child: child));
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Reset button
          inSlot(
            ControlButton(
              icon: Icons.refresh,
              onPressed:
                  (isRunning || isPaused || isCompleted)
                      ? () {
                        if (isRunning || isPaused) {
                          _showResetConfirmDialog(context, timerService);
                        } else {
                          timerService.reset();
                        }
                      }
                      : null,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              iconColor: Colors.white,
              size: resetSize,
              label: resetLabel,
            ),
            sideSlotWidth,
          ),
          SizedBox(width: spacing),
          // Play/Pause button
          inSlot(
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
            centerSlotWidth,
          ),
          SizedBox(width: spacing),
          // Skip button
          inSlot(
            ControlButton(
              icon: Icons.skip_next,
              onPressed:
                  (isRunning || isPaused) ? () => timerService.skip() : null,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              iconColor: Colors.white,
              size: resetSize,
              label: skipLabel,
            ),
            sideSlotWidth,
          ),
        ],
      ),
    );
  }

  double _measureControlLabelWidth(BuildContext context, String label) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();

    return painter.width;
  }

  void _showResetConfirmDialog(
    BuildContext context,
    TimerService timerService,
  ) {
    showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(context.tr('timer.reset_dialog.title')),
            content: Text(context.tr('timer.reset_dialog.content')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.tr('common.cancel')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  timerService.reset();
                },
                child: Text(context.tr('common.reset')),
              ),
            ],
          ),
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
        session.state == SessionState.preparing ||
        session.pausedDuringPreparation) {
      return [Colors.grey.shade900, Colors.grey.shade800];
    }
    if (session.isWarmUp) {
      return [Colors.deepOrange.shade900, Colors.brown.shade700];
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
    if (session.state == SessionState.preparing ||
        session.pausedDuringPreparation) {
      return Colors.white;
    }
    if (session.state == SessionState.completed) {
      return Colors.green;
    }
    if (session.isWarmUp) {
      return Colors.deepOrangeAccent;
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

  String _getSavageLevelName(BuildContext context, SavageLevel level) {
    switch (level) {
      case SavageLevel.level1:
        return context.tr('timer.level.mild');
      case SavageLevel.level2:
        return context.tr('timer.level.medium');
      case SavageLevel.level3:
        return context.tr('timer.level.savage');
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
