
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';

class WorldCompanionTravelPreferenceCard extends StatelessWidget {
  const WorldCompanionTravelPreferenceCard({
    super.key,
    required this.title,
    required this.preferences,
    this.subtitle,
    this.icon = Icons.tune_rounded,
    this.onEdit,
  });

  final String title;
  final List<String> preferences;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
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
                child: Icon(
                  icon,
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
                      style: const TextStyle(
                        color: WorldCompanionColors.deepOcean,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null &&
                        subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: WorldCompanionColors.secondaryText,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  tooltip: 'Edit preferences',
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: WorldCompanionColors.oceanBlue,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (preferences.isEmpty)
            const Text(
              'No preferences added yet.',
              style: TextStyle(
                color: WorldCompanionColors.secondaryText,
                fontSize: 13,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: preferences.map((preference) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: WorldCompanionColors.border,
                    ),
                  ),
                  child: Text(
                    preference,
                    style: const TextStyle(
                      color: WorldCompanionColors.deepOcean,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
