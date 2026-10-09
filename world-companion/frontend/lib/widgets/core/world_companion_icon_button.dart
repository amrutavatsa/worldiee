import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_radius.dart';

enum WorldCompanionIconButtonVariant {
  filled,
  outline,
  ghost,
}

class WorldCompanionIconButton extends StatelessWidget {
  const WorldCompanionIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.variant = WorldCompanionIconButtonVariant.ghost,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final WorldCompanionIconButtonVariant variant;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      width: size,
      height: size,
      child: switch (variant) {
        WorldCompanionIconButtonVariant.filled =>
          IconButton.filled(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            padding: EdgeInsets.zero,
          ),
        WorldCompanionIconButtonVariant.outline =>
          IconButton(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              backgroundColor: WorldCompanionColors.surface,
              foregroundColor: WorldCompanionColors.deepOcean,
              side: const BorderSide(
                color: WorldCompanionColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  WorldCompanionRadius.medium,
                ),
              ),
            ),
          ),
        WorldCompanionIconButtonVariant.ghost =>
          IconButton(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            padding: EdgeInsets.zero,
          ),
      },
    );

    if (tooltip == null) {
      return button;
    }

    return Tooltip(
      message: tooltip!,
      child: button,
    );
  }
}