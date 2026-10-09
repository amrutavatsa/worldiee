import 'package:flutter/material.dart';
import '../../theme/world_companion_spacing.dart';
import '../../theme/world_companion_typography.dart';

class WorldCompanionAppHeader extends StatelessWidget {
  const WorldCompanionAppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.showBrand = false,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: WorldCompanionSpacing.mobilePage,
        vertical: WorldCompanionSpacing.sm,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(
              width: WorldCompanionSpacing.sm,
            ),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showBrand)
                  Text(
                    'WORLD COMPANION',
                    style: WorldCompanionTypography.brand,
                  ),
                if (title != null)
                  Text(
                    title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WorldCompanionTypography
                        .textTheme
                        .titleLarge,
                  ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WorldCompanionTypography
                        .textTheme
                        .bodySmall,
                  ),
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(
              width: WorldCompanionSpacing.sm,
            ),
            ...actions,
          ],
        ],
      ),
    );
  }
}