import 'package:flutter/material.dart';

class ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final double size;

  const ControlButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.black,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
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
  }
}

class PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback? onPressed;
  final double size;

  const PlayPauseButton({
    super.key,
    required this.isPlaying,
    this.onPressed,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return ControlButton(
      icon: isPlaying ? Icons.pause : Icons.play_arrow,
      onPressed: onPressed,
      backgroundColor: isPlaying ? Colors.orange : Colors.green,
      iconColor: Colors.white,
      size: size,
    );
  }
}
