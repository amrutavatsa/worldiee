import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_radius.dart';
import '../../theme/world_companion_spacing.dart';
import '../../theme/world_companion_typography.dart';

class WorldCompanionBottomSheet extends StatelessWidget {
  const WorldCompanionBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.showHandle = true,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final bool showHandle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          WorldCompanionSpacing.mobilePage,
          WorldCompanionSpacing.sm,
          WorldCompanionSpacing.mobilePage,
          WorldCompanionSpacing.lg,
        ),
        decoration: const BoxDecoration(
          color: WorldCompanionColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(
              WorldCompanionRadius.extraLarge,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHandle)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(
                    bottom: WorldCompanionSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: WorldCompanionColors.border,
                    borderRadius: BorderRadius.circular(
                      WorldCompanionRadius.pill,
                    ),
                  ),
                ),
              ),
            if (title != null)
              Text(
                title!,
                style: WorldCompanionTypography
                    .textTheme
                    .headlineSmall,
              ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: WorldCompanionTypography
                    .textTheme
                    .bodyMedium,
              ),
            ],
            if (title != null || subtitle != null)
              const SizedBox(
                height: WorldCompanionSpacing.md,
              ),
            child,
          ],
        ),
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    String? subtitle,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return WorldCompanionBottomSheet(
          title: title,
          subtitle: subtitle,
          child: child,
        );
      },
    );
  }
}