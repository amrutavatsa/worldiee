import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_radius.dart';
import '../../theme/world_companion_typography.dart';

enum WorldCompanionBadgeVariant {
  neutral,
  info,
  success,
  warning,
  error,
}

class WorldCompanionBadge extends StatelessWidget {
  const WorldCompanionBadge({
    super.key,
    required this.label,
    this.variant = WorldCompanionBadgeVariant.neutral,
    this.icon,
  });

  final String label;
  final WorldCompanionBadgeVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = _colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.pill,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: colors.foreground,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: WorldCompanionTypography
                .textTheme
                .labelSmall
                ?.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeColors get _colors {
    return switch (variant) {
      WorldCompanionBadgeVariant.neutral =>
        const _BadgeColors(
          WorldCompanionColors.softWhite,
          WorldCompanionColors.secondaryText,
        ),
      WorldCompanionBadgeVariant.info =>
        const _BadgeColors(
          WorldCompanionColors.infoSurface,
          WorldCompanionColors.info,
        ),
      WorldCompanionBadgeVariant.success =>
        const _BadgeColors(
          WorldCompanionColors.successSurface,
          WorldCompanionColors.success,
        ),
      WorldCompanionBadgeVariant.warning =>
        const _BadgeColors(
          WorldCompanionColors.warningSurface,
          WorldCompanionColors.warning,
        ),
      WorldCompanionBadgeVariant.error =>
        const _BadgeColors(
          WorldCompanionColors.errorSurface,
          WorldCompanionColors.error,
        ),
    };
  }
}

class _BadgeColors {
  const _BadgeColors(
    this.background,
    this.foreground,
  );

  final Color background;
  final Color foreground;
}