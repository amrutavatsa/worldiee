
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';

class WorldCompanionExperienceCard extends StatelessWidget {
  const WorldCompanionExperienceCard({
    super.key,
    required this.title,
    required this.location,
    required this.imageUrl,
    this.category,
    this.duration,
    this.price,
    this.rating,
    this.description,
    this.onTap,
    this.onSave,
    this.isSaved = false,
    this.width = 280,
  });

  final String title;
  final String location;
  final String imageUrl;
  final String? category;
  final String? duration;
  final String? price;
  final double? rating;
  final String? description;
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
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: WorldCompanionColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 175,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl.trim().isNotEmpty)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _imageFallback();
                          },
                        )
                      else
                        _imageFallback(),
                      if (category != null &&
                          category!.trim().isNotEmpty)
                        Positioned(
                          left: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.94),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              category!,
                              style: const TextStyle(
                                color: WorldCompanionColors.deepOcean,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      if (onSave != null)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Material(
                            color: Colors.white.withOpacity(0.94),
                            shape: const CircleBorder(),
                            child: IconButton(
                              onPressed: onSave,
                              tooltip: isSaved
                                  ? 'Remove saved experience'
                                  : 'Save experience',
                              icon: Icon(
                                isSaved
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                color: WorldCompanionColors.deepOcean,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WorldCompanionColors.deepOcean,
                          fontSize: 17,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: WorldCompanionColors.secondaryText,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: WorldCompanionColors.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (description != null &&
                          description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 9),
                        Text(
                          description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: WorldCompanionColors.secondaryText,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 13),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (rating != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFE5A11A),
                                  size: 17,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: WorldCompanionColors.deepOcean,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          if (duration != null &&
                              duration!.trim().isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule_rounded,
                                  size: 15,
                                  color: WorldCompanionColors.secondaryText,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  duration!,
                                  style: const TextStyle(
                                    color: WorldCompanionColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          if (price != null && price!.trim().isNotEmpty)
                            Text(
                              price!,
                              style: const TextStyle(
                                color: WorldCompanionColors.oceanBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
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

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFEAF2F9),
      alignment: Alignment.center,
      child: const Icon(
        Icons.explore_rounded,
        size: 48,
        color: WorldCompanionColors.oceanBlue,
      ),
    );
  }
}
