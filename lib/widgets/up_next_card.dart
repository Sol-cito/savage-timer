import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UpNextCard extends StatelessWidget {
  final String phaseLabel;
  final String? duration;

  const UpNextCard({
    super.key,
    required this.phaseLabel,
    this.duration,
  });

  IconData get _phaseIcon {
    if (phaseLabel == 'Finish') return Icons.emoji_events_rounded;
    if (phaseLabel.startsWith('Round')) return Icons.fitness_center_rounded;
    return Icons.self_improvement_rounded; // Rest
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withValues(alpha: 0.12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 260;
              return Row(
                children: [
                  Container(
                    width: compact ? 34 : 40,
                    height: compact ? 34 : 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      _phaseIcon,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: compact ? 18 : 20,
                    ),
                  ),
                  SizedBox(width: compact ? 10 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'UP NEXT',
                          style: GoogleFonts.rajdhani(
                            fontSize: compact ? 11 : 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.5),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          phaseLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.rajdhani(
                            fontSize: compact ? 18 : 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (duration != null) ...[
                    SizedBox(width: compact ? 8 : 14),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: compact ? 70 : 90),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 8 : 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            duration!,
                            style: GoogleFonts.rajdhani(
                              fontSize: compact ? 18 : 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
