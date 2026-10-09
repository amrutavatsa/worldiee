import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_spacing.dart';
import '../../theme/world_companion_typography.dart';

class WorldCompanionLoading extends StatelessWidget {
  const WorldCompanionLoading({
    super.key,
    this.message,
    this.compact = false,
  });

  final String? message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: WorldCompanionColors.deepOcean,
            ),
          ),
          if (message != null) ...[
            const SizedBox(
              width: WorldCompanionSpacing.sm,
            ),
            Text(
              message!,
              style: WorldCompanionTypography
                  .textTheme
                  .bodySmall,
            ),
          ],
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          WorldCompanionSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: WorldCompanionColors.deepOcean,
              ),
            ),
            if (message != null) ...[
              const SizedBox(
                height: WorldCompanionSpacing.md,
              ),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: WorldCompanionTypography
                    .textTheme
                    .bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}