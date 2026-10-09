
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_radius.dart';
import '../../theme/world_companion_spacing.dart';
import '../core/world_companion_price.dart';
import '../core/world_companion_rating.dart';

class WorldCompanionPlaceCard extends StatelessWidget {
  const WorldCompanionPlaceCard({
    super.key,
    required this.name,
    required this.location,
    this.imageUrl,
    this.category,
    this.rating,
    this.reviewCount,
    this.price,
    this.pricePeriod,
    this.onTap,
    this.onSave,
    this.isSaved = false,
    this.width = 260,
  });

  final String name;
  final String location;
  final String? imageUrl;
  final String? category;
  final double? rating;
  final int? reviewCount;
  final num? price;
  final String? pricePeriod;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final bool isSaved;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.large,
              ),
              border: Border.all(color: WorldCompanionColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 156,
                      child: _buildImage(),
                    ),
                    if (category != null)
                      Positioned(
                        top: WorldCompanionSpacing.sm,
                        left: WorldCompanionSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: WorldCompanionSpacing.sm,
                            vertical: WorldCompanionSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: WorldCompanionColors.surface.withOpacity(0.94),
                            borderRadius: BorderRadius.circular(
                              WorldCompanionRadius.pill,
                            ),
                          ),
                          child: Text(
                            category!,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: WorldCompanionColors.deepOcean,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ),
                    if (onSave != null)
                      Positioned(
                        top: WorldCompanionSpacing.xs,
                        right: WorldCompanionSpacing.xs,
                        child: Material(
                          color: WorldCompanionColors.surface.withOpacity(0.94),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: isSaved ? 'Unsave place' : 'Save place',
                            onPressed: onSave,
                            icon: Icon(
                              isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: WorldCompanionColors.deepOcean,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(WorldCompanionSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: WorldCompanionColors.primaryText,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: WorldCompanionSpacing.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: WorldCompanionColors.secondaryText,
                          ),
                          const SizedBox(width: WorldCompanionSpacing.xxs),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: WorldCompanionColors.secondaryText,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (rating != null) ...[
                        const SizedBox(height: WorldCompanionSpacing.sm),
                        WorldCompanionRating(
                          rating: rating!,
                          reviewCount: reviewCount,
                          compact: true,
                        ),
                      ],
                      if (price != null) ...[
                        const SizedBox(height: WorldCompanionSpacing.sm),
                        WorldCompanionPrice(
                          amount: price!,
                          period: pricePeriod,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imageFallback(),
      );
    }

    return _imageFallback();
  }

  Widget _imageFallback() {
    return Container(
      color: WorldCompanionColors.mapSurface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.landscape_outlined,
        size: 40,
        color: WorldCompanionColors.softBlue,
      ),
    );
  }
}
