import 'package:flutter/material.dart';

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
    return Text(
      '$currentRound / $totalRounds',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.9),
        letterSpacing: 2,
      ),
    );
  }
}
