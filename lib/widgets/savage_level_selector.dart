import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/timer_settings.dart';

class SavageLevelSelector extends StatelessWidget {
  final SavageLevel selectedLevel;
  final ValueChanged<SavageLevel> onChanged;

  const SavageLevelSelector({
    super.key,
    required this.selectedLevel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: SavageLevel.values.map((level) {
        final isSelected = level == selectedLevel;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: level.index == 0 ? 0 : 5,
              right: level.index == 2 ? 0 : 5,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(level),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? _getLevelColor(level).withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: isSelected
                          ? _getLevelColor(level).withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.1),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getLevelIcon(level),
                        color: isSelected
                            ? _getLevelColor(level)
                            : Colors.white.withValues(alpha: 0.4),
                        size: 24,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getLevelName(level).toUpperCase(),
                        style: GoogleFonts.rajdhani(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? _getLevelColor(level)
                              : Colors.white.withValues(alpha: 0.4),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getLevelColor(SavageLevel level) {
    switch (level) {
      case SavageLevel.level1:
        return Colors.lightBlueAccent;
      case SavageLevel.level2:
        return Colors.amber;
      case SavageLevel.level3:
        return Colors.redAccent;
    }
  }

  IconData _getLevelIcon(SavageLevel level) {
    switch (level) {
      case SavageLevel.level1:
        return Icons.spa_rounded;
      case SavageLevel.level2:
        return Icons.fitness_center_rounded;
      case SavageLevel.level3:
        return Icons.whatshot_rounded;
    }
  }

  String _getLevelName(SavageLevel level) {
    switch (level) {
      case SavageLevel.level1:
        return 'Mild';
      case SavageLevel.level2:
        return 'Medium';
      case SavageLevel.level3:
        return 'Savage';
    }
  }
}

class SavageLevelDescription extends StatelessWidget {
  final SavageLevel level;

  const SavageLevelDescription({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Text(
      _getDescription(level),
      style: GoogleFonts.rajdhani(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }

  String _getDescription(SavageLevel level) {
    switch (level) {
      case SavageLevel.level1:
        return 'Encouraging and supportive motivation';
      case SavageLevel.level2:
        return 'Firm pushes with some edge';
      case SavageLevel.level3:
        return 'No mercy — extreme motivation';
    }
  }
}
