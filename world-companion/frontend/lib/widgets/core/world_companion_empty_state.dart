import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_spacing.dart';
import '../../theme/world_companion_typography.dart';
import 'world_companion_button.dart';

class WorldCompanionEmptyState extends StatelessWidget {
  const WorldCompanionEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.explore_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          WorldCompanionSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: WorldCompanionColors.softWhite,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.explore_outlined,
                size: 30,
                color: WorldCompanionColors.deepOcean,
              ),
            ),
            const SizedBox(
              height: WorldCompanionSpacing.lg,
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: WorldCompanionTypography
                  .textTheme
                  .headlineSmall,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                ),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: WorldCompanionTypography
                      .textTheme
                      .bodyMedium,
                ),
              ),
            ],
            if (actionLabel != null &&
                onAction != null) ...[
              const SizedBox(
                height: WorldCompanionSpacing.lg,
              ),
              WorldCompanionButton(
                label: actionLabel!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}