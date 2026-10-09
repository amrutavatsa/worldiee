
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_radius.dart';
import '../../theme/world_companion_spacing.dart';

class WorldCompanionAiResponse extends StatelessWidget {
  const WorldCompanionAiResponse({
    super.key,
    required this.message,
    this.title = 'Your AI companion',
    this.subtitle,
    this.icon = Icons.auto_awesome_rounded,
    this.isHighlighted = false,
    this.trailing,
  });

  final String message;
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isHighlighted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorldCompanionSpacing.md),
      decoration: BoxDecoration(
        color: isHighlighted
            ? WorldCompanionColors.aiSurface
            : WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
        border: Border.all(color: WorldCompanionColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: WorldCompanionColors.infoSurface,
                  borderRadius:
                      BorderRadius.circular(WorldCompanionRadius.medium),
                ),
                child: Icon(
                  icon,
                  color: WorldCompanionColors.oceanBlue,
                  size: 19,
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: WorldCompanionColors.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: WorldCompanionSpacing.xxs),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: WorldCompanionColors.secondaryText,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: WorldCompanionColors.primaryText,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
