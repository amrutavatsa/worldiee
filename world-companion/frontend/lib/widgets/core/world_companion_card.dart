import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_elevation.dart';
import '../../theme/world_companion_radius.dart';

class WorldCompanionCard extends StatelessWidget {
  const WorldCompanionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = WorldCompanionRadius.large,
    this.elevation = WorldCompanionElevation.none,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: backgroundColor ?? WorldCompanionColors.surface,
      elevation: elevation,
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? WorldCompanionColors.border,
            ),
          ),
          child: child,
        ),
      ),
    );

    return card;
  }
}