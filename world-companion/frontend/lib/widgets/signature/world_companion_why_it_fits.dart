
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_radius.dart';
import '../../theme/world_companion_spacing.dart';

class WorldCompanionWhyItFits extends StatelessWidget {
  const WorldCompanionWhyItFits({
    super.key,
    required this.reasons,
    this.title = 'Why this fits you',
    this.subtitle,
    this.icon = Icons.auto_awesome_rounded,
  });

  final List<String> reasons;
  final String title;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorldCompanionSpacing.md),
      decoration: BoxDecoration(
        color: WorldCompanionColors.aiSurface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
        border: Border.all(color: WorldCompanionColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 21,
                color: WorldCompanionColors.oceanBlue,
              ),
              const SizedBox(width: WorldCompanionSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: WorldCompanionColors.primaryText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: WorldCompanionSpacing.xs),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: WorldCompanionColors.secondaryText,
                  ),
            ),
          ],
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: WorldCompanionSpacing.md),
            for (var i = 0; i < reasons.length; i++) ...[
              if (i > 0)
                const SizedBox(height: WorldCompanionSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: WorldCompanionColors.success,
                  ),
                  const SizedBox(width: WorldCompanionSpacing.sm),
                  Expanded(
                    child: Text(
                      reasons[i],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: WorldCompanionColors.primaryText,
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
