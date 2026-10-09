import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_radius.dart';
import '../../theme/world_companion_typography.dart';

class WorldCompanionChip extends StatelessWidget {
  const WorldCompanionChip({
    super.key,
    required this.label,
    this.selected = false,
    this.icon,
    this.onSelected,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final ValueChanged<bool>? onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 16,
              color: selected
                  ? Colors.white
                  : WorldCompanionColors.secondaryText,
            ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      labelStyle:
          WorldCompanionTypography.textTheme.labelMedium
              ?.copyWith(
        color: selected
            ? Colors.white
            : WorldCompanionColors.secondaryText,
      ),
      backgroundColor: WorldCompanionColors.surface,
      selectedColor: WorldCompanionColors.deepOcean,
      side: const BorderSide(
        color: WorldCompanionColors.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.pill,
        ),
      ),
    );
  }
}