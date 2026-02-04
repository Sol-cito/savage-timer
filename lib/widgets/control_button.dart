import 'package:flutter/material.dart';

class ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final String? label;

  const ControlButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.black,
    this.size = 64,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                onPressed != null
                    ? backgroundColor
                    : backgroundColor.withValues(alpha: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color:
                onPressed != null
                    ? iconColor
                    : iconColor.withValues(alpha: 0.5),
            size: size * 0.5,
          ),
        ),
      ),
    );

    if (label == null) {
      return button;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        button,
        const SizedBox(height: 8),
        Text(
          label!,
          style: TextStyle(
            color:
                onPressed != null
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback? onPressed;
  final double size;
  final bool showLabel;

  const PlayPauseButton({
    super.key,
    required this.isPlaying,
    this.onPressed,
    this.size = 80,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return ControlButton(
      icon: isPlaying ? Icons.pause : Icons.play_arrow,
      onPressed: onPressed,
      backgroundColor: isPlaying ? Colors.orange : Colors.green,
      iconColor: Colors.white,
      size: size,
      label: showLabel ? (isPlaying ? 'Pause' : 'Start') : null,
    );
  }
}
