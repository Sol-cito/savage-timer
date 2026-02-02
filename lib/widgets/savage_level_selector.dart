import 'package:flutter/material.dart';

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
    return SegmentedButton<SavageLevel>(
      segments: const [
        ButtonSegment(
          value: SavageLevel.level1,
          label: Text('Mild'),
          icon: Icon(Icons.sentiment_satisfied),
        ),
        ButtonSegment(
          value: SavageLevel.level2,
          label: Text('Medium'),
          icon: Icon(Icons.sentiment_neutral),
        ),
        ButtonSegment(
          value: SavageLevel.level3,
          label: Text('Savage'),
          icon: Icon(Icons.whatshot),
        ),
      ],
      selected: {selectedLevel},
      onSelectionChanged: (Set<SavageLevel> newSelection) {
        onChanged(newSelection.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return _getLevelColor(selectedLevel);
          }
          return null;
        }),
      ),
    );
  }

  Color _getLevelColor(SavageLevel level) {
    switch (level) {
      case SavageLevel.level1:
        return Colors.green.withValues(alpha: 0.3);
      case SavageLevel.level2:
        return Colors.orange.withValues(alpha: 0.3);
      case SavageLevel.level3:
        return Colors.red.withValues(alpha: 0.3);
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
      style: TextStyle(color: Colors.grey[400], fontSize: 14),
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
        return 'No mercy - extreme motivation';
    }
  }
}
