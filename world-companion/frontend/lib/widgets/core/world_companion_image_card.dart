import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_radius.dart';
import '../../theme/world_companion_typography.dart';

class WorldCompanionImageCard extends StatelessWidget {
  const WorldCompanionImageCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.subtitle,
    this.onTap,
    this.height = 220,
    this.borderRadius = WorldCompanionRadius.large,
    this.badge,
  });

  final String imageUrl;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final double height;
  final double borderRadius;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WorldCompanionColors.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (
                  context,
                  error,
                  stackTrace,
                ) {
                  return Container(
                    color: WorldCompanionColors.mapSurface,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported_outlined,
                      size: 36,
                      color:
                          WorldCompanionColors.mutedText,
                    ),
                  );
                },
              ),

              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xB3000000),
                    ],
                    stops: [0.45, 1],
                  ),
                ),
              ),

              if (badge != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: badge!,
                ),

              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: WorldCompanionTypography
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WorldCompanionTypography
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          color: Colors.white.withOpacity(0.88),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}