
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';

class WorldCompanionRouteSummary extends StatelessWidget {
  const WorldCompanionRouteSummary({
    super.key,
    required this.origin,
    required this.destination,
    required this.distanceLabel,
    required this.durationLabel,
    this.arrivalLabel,
    this.routeLabel,
    this.alternativeRouteLabels = const [],
    this.selectedAlternative = 0,
    this.onAlternativeSelected,
    this.onStartNavigation,
    this.onClose,
  });

  final String origin;
  final String destination;
  final String distanceLabel;
  final String durationLabel;
  final String? arrivalLabel;
  final String? routeLabel;
  final List<String> alternativeRouteLabels;
  final int selectedAlternative;
  final ValueChanged<int>? onAlternativeSelected;
  final VoidCallback? onStartNavigation;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final hasAlternatives = alternativeRouteLabels.isNotEmpty;
    final safeSelected = hasAlternatives
        ? selectedAlternative.clamp(0, alternativeRouteLabels.length - 1)
        : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD6E0E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Your route',
                  style: TextStyle(
                    color: WorldCompanionColors.deepOcean,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  tooltip: 'Close route summary',
                  icon: const Icon(Icons.close_rounded),
                  color: WorldCompanionColors.deepOcean,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(
                    Icons.circle,
                    size: 13,
                    color: WorldCompanionColors.oceanBlue,
                  ),
                  Container(
                    height: 35,
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFB8C6D3),
                  ),
                  const Icon(
                    Icons.location_on_rounded,
                    size: 20,
                    color: WorldCompanionColors.deepOcean,
                  ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FROM',
                      style: TextStyle(
                        color: Color(0xFF718398),
                        fontSize: 10,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      origin,
                      style: const TextStyle(
                        color: WorldCompanionColors.deepOcean,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 17),
                    const Text(
                      'TO',
                      style: TextStyle(
                        color: Color(0xFF718398),
                        fontSize: 10,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination,
                      style: const TextStyle(
                        color: WorldCompanionColors.deepOcean,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4ED),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _RouteMetric(
                    icon: Icons.schedule_rounded,
                    label: 'DURATION',
                    value: durationLabel,
                  ),
                ),
                Container(
                  width: 1,
                  height: 38,
                  color: const Color(0xFFD6E0E8),
                ),
                Expanded(
                  child: _RouteMetric(
                    icon: Icons.route_rounded,
                    label: 'DISTANCE',
                    value: distanceLabel,
                  ),
                ),
              ],
            ),
          ),
          if (arrivalLabel != null && arrivalLabel!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.flag_outlined,
                  size: 17,
                  color: WorldCompanionColors.oceanBlue,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Estimated arrival: $arrivalLabel',
                    style: const TextStyle(
                      color: Color(0xFF4B6075),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (routeLabel != null && routeLabel!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              routeLabel!,
              style: const TextStyle(
                color: Color(0xFF4B6075),
                fontSize: 13,
              ),
            ),
          ],
          if (hasAlternatives) ...[
            const SizedBox(height: 20),
            const Text(
              'Route options',
              style: TextStyle(
                color: WorldCompanionColors.deepOcean,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(alternativeRouteLabels.length, (index) {
                final isSelected = index == safeSelected;

                return ChoiceChip(
                  label: Text(alternativeRouteLabels[index]),
                  selected: isSelected,
                  onSelected: onAlternativeSelected == null
                      ? null
                      : (selected) {
                          if (selected) onAlternativeSelected!(index);
                        },
                  selectedColor: const Color(0xFFE2ECF5),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? WorldCompanionColors.oceanBlue
                        : const Color(0xFFD6E0E8),
                  ),
                  labelStyle: const TextStyle(
                    color: WorldCompanionColors.deepOcean,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
          ],
          if (onStartNavigation != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStartNavigation,
                icon: const Icon(Icons.navigation_rounded, size: 19),
                label: const Text('Start navigation'),
                style: FilledButton.styleFrom(
                  backgroundColor: WorldCompanionColors.deepOcean,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: WorldCompanionColors.oceanBlue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF718398),
                    fontSize: 9,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: WorldCompanionColors.deepOcean,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
