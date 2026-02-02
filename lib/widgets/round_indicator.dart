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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalRounds, (index) {
        final roundNumber = index + 1;
        final isCompleted = roundNumber < currentRound;
        final isCurrent = roundNumber == currentRound;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isCurrent ? 16 : 12,
            height: isCurrent ? 16 : 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getColor(isCompleted, isCurrent),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow:
                  isCurrent
                      ? [
                        BoxShadow(
                          color: _getColor(
                            isCompleted,
                            isCurrent,
                          ).withValues(alpha: 0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                      : null,
            ),
          ),
        );
      }),
    );
  }

  Color _getColor(bool isCompleted, bool isCurrent) {
    if (isCompleted) {
      return Colors.green;
    } else if (isCurrent) {
      return isResting ? Colors.orange : Colors.red;
    } else {
      return Colors.grey.withValues(alpha: 0.5);
    }
  }
}
