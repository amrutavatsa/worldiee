
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';

enum WorldCompanionSafetySeverity {
  info,
  warning,
  critical,
}

class WorldCompanionSafetyAlert extends StatelessWidget {
  const WorldCompanionSafetyAlert({
    super.key,
    required this.title,
    required this.message,
    this.severity = WorldCompanionSafetySeverity.info,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  final String title;
  final String message;
  final WorldCompanionSafetySeverity severity;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final Color accent;
    final Color surface;
    final IconData icon;

    switch (severity) {
      case WorldCompanionSafetySeverity.info:
        accent = WorldCompanionColors.oceanBlue;
        surface = const Color(0xFFEAF2F9);
        icon = Icons.info_outline_rounded;
      case WorldCompanionSafetySeverity.warning:
        accent = const Color(0xFF9A6700);
        surface = const Color(0xFFFFF4D6);
        icon = Icons.warning_amber_rounded;
      case WorldCompanionSafetySeverity.critical:
        accent = WorldCompanionColors.error;
        surface = WorldCompanionColors.errorSurface;
        icon = Icons.emergency_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withOpacity(0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: WorldCompanionColors.deepOcean,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: TextStyle(
                    color: WorldCompanionColors.secondaryText,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Dismiss alert',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded),
              color: WorldCompanionColors.secondaryText,
            ),
        ],
      ),
    );
  }
}
