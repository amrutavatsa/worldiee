
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_radius.dart';
import '../../theme/world_companion_spacing.dart';
import '../core/world_companion_price.dart';
import '../core/world_companion_rating.dart';

class WorldCompanionPlacePreview extends StatelessWidget {
  const WorldCompanionPlacePreview({
    super.key,
    required this.name,
    required this.location,
    this.imageUrl,
    this.rating,
    this.reviewCount,
    this.category,
    this.price,
    this.pricePeriod,
    this.onTap,
    this.onDirections,
    this.onSave,
    this.isSaved = false,
  });

  final String name;
  final String location;
  final String? imageUrl;
  final double? rating;
  final int? reviewCount;
  final String? category;
  final num? price;
  final String? pricePeriod;
  final VoidCallback? onTap;
  final VoidCallback? onDirections;
  final VoidCallback? onSave;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WorldCompanionColors.surface,
      borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: WorldCompanionColors.border),
            borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl!.trim().isNotEmpty)
                SizedBox(
                  height: 168,
                  width: double.infinity,
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _imageFallback();
                    },
                  ),
                )
              else
                _imageFallback(),
              Padding(
                padding: const EdgeInsets.all(WorldCompanionSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (category != null)
                      Text(
                        category!.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: WorldCompanionColors.oceanBlue,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                      ),
                    const SizedBox(height: WorldCompanionSpacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: WorldCompanionColors.primaryText,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        if (onSave != null)
                          IconButton(
                            tooltip: isSaved ? 'Unsave place' : 'Save place',
                            onPressed: onSave,
                            icon: Icon(
                              isSaved
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: WorldCompanionColors.oceanBlue,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: WorldCompanionSpacing.xxs),
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color:
                                          WorldCompanionColors.secondaryText,
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
                    if (onDirections != null) ...[
                      const SizedBox(height: WorldCompanionSpacing.md),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: onDirections,
                          icon: const Icon(Icons.directions_outlined),
                          label: const Text('Get directions'),
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

  Widget _imageFallback() {
    return Container(
      width: double.infinity,
      height: 168,
      color: WorldCompanionColors.mapSurface,
      alignment: Alignment.center,
      child: const Icon(
        Icons.landscape_outlined,
        size: 42,
        color: WorldCompanionColors.softBlue,
      ),
    );
  }
}
