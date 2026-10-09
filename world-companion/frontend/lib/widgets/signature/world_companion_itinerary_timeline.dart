
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';

enum WorldCompanionItineraryStatus {
  completed,
  current,
  upcoming,
}

class WorldCompanionItineraryStop {
  const WorldCompanionItineraryStop({
    required this.time,
    required this.title,
    required this.location,
    this.description,
    this.icon = Icons.place_outlined,
    this.status = WorldCompanionItineraryStatus.upcoming,
  });

  final String time;
  final String title;
  final String location;
  final String? description;
  final IconData icon;
  final WorldCompanionItineraryStatus status;
}

class WorldCompanionItineraryTimeline extends StatelessWidget {
  const WorldCompanionItineraryTimeline({
    super.key,
    required this.stops,
    this.onStopTap,
  });

  final List<WorldCompanionItineraryStop> stops;
  final ValueChanged<WorldCompanionItineraryStop>? onStopTap;

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD6E0E8)),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.route_rounded,
              size: 32,
              color: WorldCompanionColors.softBlue,
            ),
            SizedBox(height: 10),
            Text(
              'No itinerary stops yet',
              style: TextStyle(
                color: WorldCompanionColors.deepOcean,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Your planned stops will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF718398),
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(stops.length, (index) {
        final stop = stops[index];

        return _ItineraryTimelineRow(
          stop: stop,
          isLast: index == stops.length - 1,
          onTap: onStopTap == null ? null : () => onStopTap!(stop),
        );
      }),
    );
  }
}

class _ItineraryTimelineRow extends StatelessWidget {
  const _ItineraryTimelineRow({
    required this.stop,
    required this.isLast,
    this.onTap,
  });

  final WorldCompanionItineraryStop stop;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCompleted =
        stop.status == WorldCompanionItineraryStatus.completed;
    final isCurrent = stop.status == WorldCompanionItineraryStatus.current;

    final Color markerColor = isCompleted || isCurrent
        ? WorldCompanionColors.oceanBlue
        : const Color(0xFFB8C6D3);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 54,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? const Color(0xFFE2ECF5)
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: markerColor,
                      width: isCurrent ? 2 : 1.5,
                    ),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : stop.icon,
                    size: 17,
                    color: markerColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isCompleted
                          ? WorldCompanionColors.softBlue
                          : const Color(0xFFD6E0E8),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: 6,
                right: 2,
                bottom: isLast ? 0 : 22,
              ),
              child: Material(
                color: isCurrent
                    ? const Color(0xFFEEF4ED)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                stop.title,
                                style: TextStyle(
                                  color: WorldCompanionColors.deepOcean,
                                  fontSize: 15,
                                  fontWeight: isCurrent
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              stop.time,
                              style: const TextStyle(
                                color: Color(0xFF718398),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: WorldCompanionColors.oceanBlue,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                stop.location,
                                style: const TextStyle(
                                  color: Color(0xFF4B6075),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (stop.description != null &&
                            stop.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            stop.description!,
                            style: const TextStyle(
                              color: Color(0xFF718398),
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ],
                        if (isCurrent) ...[
                          const SizedBox(height: 9),
                          const Text(
                            'CURRENT STOP',
                            style: TextStyle(
                              color: WorldCompanionColors.oceanBlue,
                              fontSize: 10,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
