
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';

class WorldCompanionTravelProgressCard extends StatelessWidget {
  const WorldCompanionTravelProgressCard({
    super.key,
    required this.title,
    required this.destination,
    required this.completedStops,
    required this.totalStops,
    this.nextStop,
    this.progress,
    this.onTap,
  });

  final String title;
  final String destination;
  final int completedStops;
  final int totalStops;
  final String? nextStop;
  final double? progress;
  final VoidCallback? onTap;

  double get _progress {
    if (progress != null) {
      return progress!.clamp(0.0, 1.0).toDouble();
    }

    if (totalStops <= 0) return 0.0;

    return (completedStops / totalStops).clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: WorldCompanionColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: WorldCompanionColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: WorldCompanionColors.softBlue.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      color: WorldCompanionColors.oceanBlue,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: WorldCompanionColors.deepOcean,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destination,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: WorldCompanionColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: WorldCompanionColors.secondaryText,
                    ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      '${(_progress * 100).round()}% completed',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: WorldCompanionColors.deepOcean,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '$completedStops of $totalStops stops',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: WorldCompanionColors.secondaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: _progress,
                  minHeight: 8,
                  backgroundColor: WorldCompanionColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    WorldCompanionColors.oceanBlue,
                  ),
                ),
              ),
              if (nextStop != null && nextStop!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        color: WorldCompanionColors.oceanBlue,
                        size: 19,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UP NEXT',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: WorldCompanionColors.secondaryText,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              nextStop!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: WorldCompanionColors.deepOcean,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
