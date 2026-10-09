import 'package:flutter/material.dart';

import '../theme/world_companion_colors.dart';
import '../theme/world_companion_elevation.dart';
import '../theme/world_companion_radius.dart';
import '../theme/world_companion_spacing.dart';
import '../theme/world_companion_typography.dart';
import '../widgets/world_map.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorldCompanionColors.mapSurface,
      appBar: AppBar(
        backgroundColor: WorldCompanionColors.surface,
        foregroundColor: WorldCompanionColors.deepOcean,
        elevation: WorldCompanionElevation.none,
        scrolledUnderElevation: WorldCompanionElevation.none,
        titleSpacing: WorldCompanionSpacing.lg,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: WorldCompanionColors.infoSurface,
                borderRadius: BorderRadius.circular(
                  WorldCompanionRadius.medium,
                ),
              ),
              child: const Icon(
                Icons.public_rounded,
                color: WorldCompanionColors.oceanBlue,
                size: 23,
              ),
            ),
            const SizedBox(width: WorldCompanionSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'WorldCompanion',
                    style: WorldCompanionTypography.textTheme.titleMedium
                        ?.copyWith(
                      color: WorldCompanionColors.deepOcean,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Explore the world',
                    style: WorldCompanionTypography.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: WorldCompanionColors.border,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(WorldCompanionSpacing.xs),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              WorldCompanionRadius.large,
            ),
            child: const WorldMap(),
          ),
        ),
      ),
    );
  }
}
