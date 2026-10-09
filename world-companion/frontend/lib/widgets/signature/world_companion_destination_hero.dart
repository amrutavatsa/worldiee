
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../core/world_companion_button.dart';

class WorldCompanionDestinationHero extends StatelessWidget {
  const WorldCompanionDestinationHero({
    super.key,
    required this.destination,
    this.eyebrow = 'YOUR NEXT ADVENTURE',
    this.description,
    this.imageUrl,
    this.location,
    this.buttonLabel = 'Explore destination',
    this.onExplore,
    this.onSave,
    this.isSaved = false,
    this.height = 300,
  });

  final String destination;
  final String eyebrow;
  final String? description;
  final String? imageUrl;
  final String? location;
  final String buttonLabel;
  final VoidCallback? onExplore;
  final VoidCallback? onSave;
  final bool isSaved;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: WorldCompanionColors.deepOcean,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null && imageUrl!.trim().isNotEmpty)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _fallback();
              },
            )
          else
            _fallback(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x220B2545),
                  Color(0x440B2545),
                  Color(0xF20B2545),
                ],
                stops: [0.0, 0.38, 1.0],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          eyebrow,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    if (onSave != null) ...[
                      const SizedBox(width: 10),
                      Material(
                        color: Colors.white.withOpacity(0.18),
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: onSave,
                          tooltip: isSaved
                              ? 'Remove saved destination'
                              : 'Save destination',
                          icon: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                if (location != null && location!.trim().isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFB9CDE0),
                        size: 17,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          location!,
                          style: const TextStyle(
                            color: Color(0xFFEAF2F9),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                ],
                Text(
                  destination,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (description != null &&
                    description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFEAF2F9),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
                if (onExplore != null) ...[
                  const SizedBox(height: 16),
                  WorldCompanionButton(
                    label: buttonLabel,
                    onPressed: onExplore,
                    variant: WorldCompanionButtonVariant.secondary,
                    icon: Icons.arrow_forward_rounded,
                    fullWidth: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallback() {
    return Container(
      color: WorldCompanionColors.oceanBlue,
      alignment: Alignment.center,
      child: const Icon(
        Icons.landscape_rounded,
        size: 70,
        color: Color(0xFFB9CDE0),
      ),
    );
  }
}
