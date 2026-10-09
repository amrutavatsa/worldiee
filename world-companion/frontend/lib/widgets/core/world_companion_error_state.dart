
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_radius.dart';
import '../../theme/world_companion_spacing.dart';
import 'world_companion_button.dart';

class WorldCompanionErrorState extends StatelessWidget {
  const WorldCompanionErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'We couldn’t load this information. Please try again.',
    this.onRetry,
    this.retryLabel = 'Try again',
    this.icon = Icons.cloud_off_outlined,
    this.compact = false,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final spacing = compact
        ? WorldCompanionSpacing.sm
        : WorldCompanionSpacing.lg;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(
                compact
                    ? WorldCompanionSpacing.sm
                    : WorldCompanionSpacing.md,
              ),
              decoration: BoxDecoration(
                color: WorldCompanionColors.errorSurface,
                borderRadius: BorderRadius.circular(
                  WorldCompanionRadius.large,
                ),
              ),
              child: Icon(
                icon,
                size: compact ? 28 : 36,
                color: WorldCompanionColors.error,
              ),
            ),
            const SizedBox(height: WorldCompanionSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: WorldCompanionColors.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: WorldCompanionSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: WorldCompanionColors.secondaryText,
                  ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: WorldCompanionSpacing.lg),
              WorldCompanionButton(
                label: retryLabel,
                onPressed: onRetry,
                variant: WorldCompanionButtonVariant.secondary,
                icon: Icons.refresh,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
