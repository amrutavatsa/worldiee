
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../core/world_companion_button.dart';

class WorldCompanionArrivalCard extends StatelessWidget {
  const WorldCompanionArrivalCard({
    super.key,
    required this.destination,
    this.location,
    this.imageUrl,
    this.arrivalMessage = 'You have arrived at your destination.',
    this.onContinue,
    this.continueLabel = 'Continue exploring',
  });

  final String destination;
  final String? location;
  final String? imageUrl;
  final String arrivalMessage;
  final VoidCallback? onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: WorldCompanionColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl!.trim().isNotEmpty)
            SizedBox(
              height: 190,
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
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F4E8),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF247A45),
                        size: 16,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'ARRIVED',
                        style: TextStyle(
                          color: Color(0xFF247A45),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome to',
                  style: textTheme.bodyMedium?.copyWith(
                    color: WorldCompanionColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  destination,
                  style: textTheme.headlineSmall?.copyWith(
                    color: WorldCompanionColors.deepOcean,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (location != null && location!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: WorldCompanionColors.secondaryText,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location!,
                          style: textTheme.bodySmall?.copyWith(
                            color: WorldCompanionColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  arrivalMessage,
                  style: textTheme.bodyMedium?.copyWith(
                    color: WorldCompanionColors.secondaryText,
                    height: 1.5,
                  ),
                ),
                if (onContinue != null) ...[
                  const SizedBox(height: 24),
                  WorldCompanionButton(
                    label: continueLabel,
                    onPressed: onContinue,
                    variant: WorldCompanionButtonVariant.primary,
                    icon: Icons.explore_rounded,
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

  Widget _imageFallback() {
    return Container(
      height: 150,
      width: double.infinity,
      color: WorldCompanionColors.softBlue.withOpacity(0.18),
      alignment: Alignment.center,
      child: const Icon(
        Icons.location_on_rounded,
        size: 54,
        color: WorldCompanionColors.oceanBlue,
      ),
    );
  }
}
