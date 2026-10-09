
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_radius.dart';
import '../../theme/world_companion_spacing.dart';

class WorldCompanionAction {
  const WorldCompanionAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

class WorldCompanionActionRow extends StatelessWidget {
  const WorldCompanionActionRow({
    super.key,
    required this.actions,
    this.scrollable = true,
  });

  final List<WorldCompanionAction> actions;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final items = actions.map(_buildAction).toList();

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                const SizedBox(width: WorldCompanionSpacing.xs),
              items[i],
            ],
          ],
        ),
      );
    }

    return Wrap(
      spacing: WorldCompanionSpacing.xs,
      runSpacing: WorldCompanionSpacing.xs,
      children: items,
    );
  }

  Widget _buildAction(WorldCompanionAction action) {
    return OutlinedButton.icon(
      onPressed: action.onPressed,
      icon: Icon(action.icon, size: 18),
      label: Text(action.label),
      style: OutlinedButton.styleFrom(
        foregroundColor: WorldCompanionColors.deepOcean,
        side: const BorderSide(color: WorldCompanionColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(WorldCompanionRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: WorldCompanionSpacing.md,
          vertical: WorldCompanionSpacing.sm,
        ),
      ),
    );
  }
}
