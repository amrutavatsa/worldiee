
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';

class WorldCompanionPersonalizedRecommendation
    extends StatelessWidget {
  const WorldCompanionPersonalizedRecommendation({
    super.key,
    required this.title,
    required this.location,
    required this.reason,
    this.imageUrl,
    this.category,
    this.matchLabel,
    this.reasons = const [],
    this.onTap,
    this.onSave,
    this.isSaved = false,
  });

  final String title;
  final String location;
  final String reason;
  final String? imageUrl;
  final String? category;
  final String? matchLabel;
  final List<String> reasons;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WorldCompanionColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: WorldCompanionColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl!.trim().isNotEmpty)
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(19),
                        ),
                        child: Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _imageFallback();
                          },
                        ),
                      ),
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
                          right: 12,
                          top: 12,
                          child: Material(
                            color: Colors.white.withOpacity(0.94),
                            shape: const CircleBorder(),
                            child: IconButton(
                              onPressed: onSave,
                              tooltip: isSaved ? 'Remove saved place' : 'Save place',
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
                )
              else
                _imageFallback(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (matchLabel != null &&
                        matchLabel!.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 14,
                              color: WorldCompanionColors.oceanBlue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              matchLabel!,
                              style: const TextStyle(
                                color: WorldCompanionColors.oceanBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        color: WorldCompanionColors.deepOcean,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 17,
                          color: WorldCompanionColors.secondaryText,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              color: WorldCompanionColors.secondaryText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reason,
                      style: const TextStyle(
                        color: WorldCompanionColors.deepOcean,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    if (reasons.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'WHY IT FITS YOU',
                        style: TextStyle(
                          color: WorldCompanionColors.secondaryText,
                          fontSize: 11,
                          letterSpacing: 0.7,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 9),
                      ...reasons.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: WorldCompanionColors.oceanBlue,
                                size: 17,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item,
                                  style: const TextStyle(
                                    color: WorldCompanionColors.secondaryText,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (onTap != null) ...[
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Explore place',
                            style: TextStyle(
                              color: WorldCompanionColors.oceanBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 17,
                            color: WorldCompanionColors.oceanBlue,
                          ),
                        ],
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
      height: 150,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFEAF2F9),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(19),
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.travel_explore_rounded,
        size: 48,
        color: WorldCompanionColors.oceanBlue,
      ),
    );
  }
}
