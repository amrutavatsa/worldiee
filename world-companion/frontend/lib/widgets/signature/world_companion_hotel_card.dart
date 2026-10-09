
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';

class WorldCompanionHotelCard extends StatelessWidget {
  const WorldCompanionHotelCard({
    super.key,
    required this.name,
    required this.location,
    required this.pricePerNight,
    this.imageUrl,
    this.rating,
    this.reviewCount,
    this.category,
    this.amenities = const [],
    this.onTap,
    this.onSave,
    this.isSaved = false,
    this.width = 280,
  });

  final String name;
  final String location;
  final double pricePerNight;
  final String? imageUrl;
  final double? rating;
  final int? reviewCount;
  final String? category;
  final List<String> amenities;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final bool isSaved;
  final double width;

  String _formatPrice(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
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
                      height: 175,
                      width: double.infinity,
                      child: _HotelImage(imageUrl: imageUrl),
                    ),
                    if (category != null && category!.trim().isNotEmpty)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(30),
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
                        top: 10,
                        right: 10,
                        child: Material(
                          color: Colors.white.withOpacity(0.95),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: isSaved
                                ? 'Remove from saved'
                                : 'Save accommodation',
                            onPressed: onSave,
                            icon: Icon(
                              isSaved
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isSaved
                                  ? const Color(0xFFD85B69)
                                  : WorldCompanionColors.deepOcean,
                              size: 20,
                            ),
                            constraints: const BoxConstraints.tightFor(
                              width: 42,
                              height: 42,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: WorldCompanionColors.deepOcean,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: WorldCompanionColors.oceanBlue,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF4B6075),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (rating != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 17,
                              color: WorldCompanionColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: WorldCompanionColors.deepOcean,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (reviewCount != null) ...[
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '($reviewCount reviews)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF718398),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      if (amenities.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: amenities.take(3).map((amenity) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF4ED),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                amenity,
                                style: const TextStyle(
                                  color: Color(0xFF4B6075),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            '₹',
                            style: TextStyle(
                              color: WorldCompanionColors.deepOcean,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _formatPrice(pricePerNight),
                            style: const TextStyle(
                              color: WorldCompanionColors.deepOcean,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 3),
                              child: Text(
                                '/ night',
                                style: TextStyle(
                                  color: Color(0xFF718398),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          if (onTap != null)
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: WorldCompanionColors.oceanBlue,
                              size: 20,
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
}

class _HotelImage extends StatelessWidget {
  const _HotelImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _fallback();
    }

    return Image.network(
      imageUrl!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallback(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return Container(
          color: const Color(0xFFEEF4ED),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: WorldCompanionColors.oceanBlue,
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
        Icons.hotel_rounded,
        size: 46,
        color: WorldCompanionColors.softBlue,
      ),
    );
  }
}
