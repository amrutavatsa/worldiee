
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_radius.dart';
import '../../theme/world_companion_spacing.dart';
import '../core/world_companion_price.dart';
import '../core/world_companion_rating.dart';
import '../core/world_companion_button.dart';

class WorldCompanionMapPlacePreview extends StatelessWidget {
  const WorldCompanionMapPlacePreview({
    super.key,
    required this.name,
    required this.location,
    this.imageUrl,
    this.rating,
    this.reviewCount,
    this.price,
    this.pricePeriod,
    this.onDetails,
    this.onDirections,
    this.onSave,
    this.isSaved = false,
  });

  final String name;
  final String location;
  final String? imageUrl;
  final double? rating;
  final int? reviewCount;
  final num? price;
  final String? pricePeriod;
  final VoidCallback? onDetails;
  final VoidCallback? onDirections;
  final VoidCallback? onSave;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorldCompanionSpacing.md),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.extraLarge),
        border: Border.all(color: WorldCompanionColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(WorldCompanionRadius.medium),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: _buildImage(),
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.md),
              Expanded(
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
                    Text(
                      location,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: WorldCompanionColors.secondaryText,
                          ),
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
          const SizedBox(height: WorldCompanionSpacing.md),
          Row(
            children: [
              if (onDetails != null)
                Expanded(
                  child: WorldCompanionButton(
                    label: 'View details',
                    onPressed: onDetails,
                    variant: WorldCompanionButtonVariant.primary,
                    fullWidth: true,
                  ),
                ),
              if (onDetails != null && onDirections != null)
                const SizedBox(width: WorldCompanionSpacing.sm),
              if (onDirections != null)
                Expanded(
                  child: WorldCompanionButton(
                    label: 'Directions',
                    onPressed: onDirections,
                    variant: WorldCompanionButtonVariant.outline,
                    icon: Icons.directions_outlined,
                    fullWidth: true,
                  ),
                ),
            ],
          ),
        ],
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
        Icons.place_outlined,
        size: 32,
        color: WorldCompanionColors.softBlue,
      ),
    );
  }
}
