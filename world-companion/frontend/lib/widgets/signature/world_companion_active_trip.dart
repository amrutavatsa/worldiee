
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';

class WorldCompanionActiveTrip extends StatelessWidget {
  const WorldCompanionActiveTrip({
    super.key,
    required this.title,
    required this.destination,
    required this.nextStop,
    this.imageUrl,
    this.etaLabel,
    this.progress,
    this.onViewTrip,
    this.onNavigate,
  });

  final String title;
  final String destination;
  final String nextStop;
  final String? imageUrl;
  final String? etaLabel;
  final double? progress;
  final VoidCallback? onViewTrip;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress?.clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD6E0E8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 150,
                width: double.infinity,
                child: _ActiveTripImage(imageUrl: imageUrl),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: WorldCompanionColors.deepOcean,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: Color(0xFF8ED6B1),
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Journey in progress',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: WorldCompanionColors.deepOcean,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 17,
                      color: WorldCompanionColors.oceanBlue,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        destination,
                        style: const TextStyle(
                          color: Color(0xFF4B6075),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF4ED),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        color: WorldCompanionColors.oceanBlue,
                        size: 22,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'UP NEXT',
                              style: TextStyle(
                                color: Color(0xFF718398),
                                fontSize: 10,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              nextStop,
                              style: const TextStyle(
                                color: WorldCompanionColors.deepOcean,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (etaLabel != null &&
                                etaLabel!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                etaLabel!,
                                style: const TextStyle(
                                  color: Color(0xFF4B6075),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (normalizedProgress != null) ...[
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Journey progress',
                        style: TextStyle(
                          color: Color(0xFF4B6075),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(normalizedProgress * 100).round()}%',
                        style: const TextStyle(
                          color: WorldCompanionColors.deepOcean,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: normalizedProgress,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFE5EBF0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        WorldCompanionColors.oceanBlue,
                      ),
                    ),
                  ),
                ],
                if (onViewTrip != null || onNavigate != null) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      if (onViewTrip != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onViewTrip,
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  WorldCompanionColors.deepOcean,
                              side: const BorderSide(
                                color: Color(0xFFD6E0E8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('View trip'),
                          ),
                        ),
                      if (onViewTrip != null && onNavigate != null)
                        const SizedBox(width: 10),
                      if (onNavigate != null)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onNavigate,
                            icon: const Icon(
                              Icons.navigation_rounded,
                              size: 17,
                            ),
                            label: const Text('Navigate'),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  WorldCompanionColors.deepOcean,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveTripImage extends StatelessWidget {
  const _ActiveTripImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _fallback();
    }

    return Image.network(
      imageUrl!,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallback(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return Container(
          color: const Color(0xFFEEF4ED),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            color: WorldCompanionColors.oceanBlue,
            strokeWidth: 2,
          ),
        );
      },
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFEEF4ED),
      alignment: Alignment.center,
      child: const Icon(
        Icons.explore_rounded,
        size: 48,
        color: WorldCompanionColors.softBlue,
      ),
    );
  }
}
