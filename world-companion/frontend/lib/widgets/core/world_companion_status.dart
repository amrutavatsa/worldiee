import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_radius.dart';
import '../../theme/world_companion_spacing.dart';
import '../../theme/world_companion_typography.dart';

enum WorldCompanionStatusVariant {
  neutral,
  info,
  success,
  warning,
  error,
}

class WorldCompanionStatus extends StatelessWidget {
  const WorldCompanionStatus({
    super.key,
    required this.label,
    this.message,
    this.variant = WorldCompanionStatusVariant.neutral,
    this.icon,
  });

  final String label;
  final String? message;
  final WorldCompanionStatusVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = _colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        WorldCompanionSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.medium,
        ),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? _defaultIcon,
            size: 20,
            color: colors.foreground,
          ),
          const SizedBox(
            width: WorldCompanionSpacing.sm,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: WorldCompanionTypography
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                    color: colors.foreground,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    message!,
                    style: WorldCompanionTypography
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color:
                          WorldCompanionColors.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  ColorSet get _colors {
    return switch (variant) {
      WorldCompanionStatusVariant.neutral =>
        const ColorSet(
          background: WorldCompanionColors.softWhite,
          border: WorldCompanionColors.border,
          foreground:
              WorldCompanionColors.secondaryText,
        ),
      WorldCompanionStatusVariant.info =>
        const ColorSet(
          background:
              WorldCompanionColors.infoSurface,
          border: WorldCompanionColors.softBlue,
          foreground: WorldCompanionColors.info,
        ),
      WorldCompanionStatusVariant.success =>
        const ColorSet(
          background:
              WorldCompanionColors.successSurface,
          border: WorldCompanionColors.success,
          foreground: WorldCompanionColors.success,
        ),
      WorldCompanionStatusVariant.warning =>
        const ColorSet(
          background:
              WorldCompanionColors.warningSurface,
          border: WorldCompanionColors.warning,
          foreground: WorldCompanionColors.warning,
        ),
      WorldCompanionStatusVariant.error =>
        const ColorSet(
          background:
              WorldCompanionColors.errorSurface,
          border: WorldCompanionColors.error,
          foreground: WorldCompanionColors.error,
        ),
    };
  }

  IconData get _defaultIcon {
    return switch (variant) {
      WorldCompanionStatusVariant.neutral =>
        Icons.info_outline_rounded,
      WorldCompanionStatusVariant.info =>
        Icons.info_outline_rounded,
      WorldCompanionStatusVariant.success =>
        Icons.check_circle_outline_rounded,
      WorldCompanionStatusVariant.warning =>
        Icons.warning_amber_rounded,
      WorldCompanionStatusVariant.error =>
        Icons.error_outline_rounded,
    };
  }
}

class ColorSet {
  const ColorSet({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;
}