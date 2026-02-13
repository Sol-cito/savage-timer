import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoundIndicator extends StatelessWidget {
  final int totalRounds;
  final int currentRound;
  final bool isResting;

  const RoundIndicator({
    super.key,
    required this.totalRounds,
    required this.currentRound,
    this.isResting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // "Round X of Y" label
        Text(
          'ROUND $currentRound OF $totalRounds',
          style: GoogleFonts.rajdhani(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 10),
        // Segmented progress bar
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalRounds, (index) {
            final roundNumber = index + 1;
            final isCompleted = roundNumber < currentRound;
            final isCurrent = roundNumber == currentRound;

            return Flexible(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 48),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isCompleted
                      ? Colors.white.withValues(alpha: 0.9)
                      : isCurrent
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
