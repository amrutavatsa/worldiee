
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';

class WorldCompanionTripCard extends StatelessWidget {
  const WorldCompanionTripCard({
    super.key,
    required this.title,
    required this.destination,
    required this.dateLabel,
    this.imageUrl,
    this.status = 'Planned',
    this.progress,
    this.onTap,
  });

  final String title;
  final String destination;
  final String dateLabel;
  final String? imageUrl;
  final String status;
  final double? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress?.clamp(0.0, 1.0);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD6E0E8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: _TripImage(imageUrl: imageUrl),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: WorldCompanionColors.deepOcean,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WorldCompanionColors.deepOcean,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF4B6075),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 15,
                          color: Color(0xFF718398),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            dateLabel,
                            style: const TextStyle(
                              color: Color(0xFF718398),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (onTap != null)
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: WorldCompanionColors.oceanBlue,
                          ),
                      ],
                    ),
                    if (normalizedProgress != null) ...[
                      const SizedBox(height: 14),
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

class _TripImage extends StatelessWidget {
  const _TripImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _fallback();
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      width: double.infinity,
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
        Icons.landscape_rounded,
        size: 48,
        color: WorldCompanionColors.softBlue,
      ),
    );
  }
}
