import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_typography.dart';

class WorldCompanionSectionHeader extends StatelessWidget {
  const WorldCompanionSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
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
                      .bodySmall,
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: WorldCompanionTypography
                  .textTheme
                  .labelMedium
                  ?.copyWith(
                color: WorldCompanionColors.deepOcean,
              ),
            ),
          ),
      ],
    );
  }
}