
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_spacing.dart';

class WorldCompanionRating extends StatelessWidget {
  const WorldCompanionRating({
    super.key,
    required this.rating,
    this.reviewCount,
    this.starSize = 16,
    this.showStar = true,
    this.compact = false,
  });

  final double rating;
  final int? reviewCount;
  final double starSize;
  final bool showStar;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final safeRating = rating.clamp(0.0, 5.0).toDouble();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showStar) ...[
          Icon(
            Icons.star_rounded,
            size: starSize,
            color: WorldCompanionColors.warning,
          ),
          const SizedBox(width: WorldCompanionSpacing.xxs),
        ],
        Text(
          safeRating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: WorldCompanionColors.primaryText,
                fontWeight: FontWeight.w700,
              ),
        ),
        if (reviewCount != null) ...[
          const SizedBox(width: WorldCompanionSpacing.xs),
          Text(
            compact
                ? '(${_formatCount(reviewCount!)})'
                : '(${_formatCount(reviewCount!)} reviews)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: WorldCompanionColors.secondaryText,
                ),
          ),
        ],
      ],
    );
  }

  String _formatCount(int count) {
    if (count < 1000) return count.toString();

    if (count < 1000000) {
      final value = count / 1000;
      return '${value.toStringAsFixed(count % 1000 == 0 ? 0 : 1)}k';
    }

    final value = count / 1000000;
    return '${value.toStringAsFixed(count % 1000000 == 0 ? 0 : 1)}m';
  }
}
