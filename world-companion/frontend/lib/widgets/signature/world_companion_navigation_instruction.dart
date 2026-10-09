import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';

class WorldCompanionNavigationInstruction extends StatelessWidget {
  const WorldCompanionNavigationInstruction({
    super.key,
    required this.instruction,
    required this.distanceToManeuver,
    this.nextInstruction,
    this.remainingDistance,
    this.remainingDuration,
    this.maneuverIcon = Icons.turn_right_rounded,
    this.onExit,
    this.onOverview,
  });

  final String instruction;
  final String distanceToManeuver;
  final String? nextInstruction;
  final String? remainingDistance;
  final String? remainingDuration;
  final IconData maneuverIcon;
  final VoidCallback? onExit;
  final VoidCallback? onOverview;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WorldCompanionColors.deepOcean,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.navigation_rounded,
                color: Color(0xFF8DA9C4),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'NAVIGATION',
                  style: TextStyle(
                    color: Color(0xFFB9CDE0),
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onOverview != null)
                IconButton(
                  onPressed: onOverview,
                  tooltip: 'Route overview',
                  icon: const Icon(Icons.map_outlined),
                  color: Colors.white,
                ),
              if (onExit != null)
                IconButton(
                  onPressed: onExit,
                  tooltip: 'Exit navigation',
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.white,
                ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  maneuverIcon,
                  color: Colors.white,
                  size: 39,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      distanceToManeuver,
                      style: const TextStyle(
                        color: Color(0xFFB9CDE0),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      instruction,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (nextInstruction != null &&
              nextInstruction!.trim().isNotEmpty) ...[
            const SizedBox(height: 17),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.subdirectory_arrow_right_rounded,
                    color: Color(0xFF8DA9C4),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'THEN',
                          style: TextStyle(
                            color: Color(0xFFB9CDE0),
                            fontSize: 10,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          nextInstruction!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if ((remainingDistance != null &&
                  remainingDistance!.trim().isNotEmpty) ||
              (remainingDuration != null &&
                  remainingDuration!.trim().isNotEmpty)) ...[
            const SizedBox(height: 18),
            const Divider(
              color: Color(0xFF38516D),
              height: 1,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (remainingDistance != null &&
                    remainingDistance!.trim().isNotEmpty)
                  Expanded(
                    child: _RemainingMetric(
                      icon: Icons.route_rounded,
                      label: 'DISTANCE LEFT',
                      value: remainingDistance!,
                    ),
                  ),
                if (remainingDistance != null &&
                    remainingDistance!.trim().isNotEmpty &&
                    remainingDuration != null &&
                    remainingDuration!.trim().isNotEmpty)
                  const SizedBox(width: 12),
                if (remainingDuration != null &&
                    remainingDuration!.trim().isNotEmpty)
                  Expanded(
                    child: _RemainingMetric(
                      icon: Icons.schedule_rounded,
                      label: 'TIME LEFT',
                      value: remainingDuration!,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RemainingMetric extends StatelessWidget {
  const _RemainingMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF8DA9C4),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFB9CDE0),
                  fontSize: 9,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}