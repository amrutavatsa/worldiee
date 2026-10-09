
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';

enum WorldCompanionSosStatusType {
  preparing,
  sent,
  acknowledged,
  resolved,
  failed,
}

class WorldCompanionSosStatus extends StatelessWidget {
  const WorldCompanionSosStatus({
    super.key,
    required this.status,
    this.title,
    this.message,
    this.reference,
    this.onRetry,
    this.onDismiss,
  });

  final WorldCompanionSosStatusType status;
  final String? title;
  final String? message;
  final String? reference;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    Color accent = WorldCompanionColors.oceanBlue;
    Color background = const Color(0xFFEAF2F9);
    IconData icon = Icons.hourglass_top_rounded;
    String defaultTitle = 'Preparing SOS';
    String defaultMessage = 'Your emergency request is being prepared.';

    if (status == WorldCompanionSosStatusType.sent) {
      accent = const Color(0xFF247A45);
      background = const Color(0xFFE4F4E8);
      icon = Icons.check_circle_outline_rounded;
      defaultTitle = 'SOS request sent';
      defaultMessage =
          'Your request has been submitted. Follow the instructions shown in your app.';
    } else if (status == WorldCompanionSosStatusType.acknowledged) {
      accent = const Color(0xFF247A45);
      background = const Color(0xFFE4F4E8);
      icon = Icons.support_agent_rounded;
      defaultTitle = 'SOS acknowledged';
      defaultMessage =
          'Your request has been acknowledged. Keep your phone available.';
    } else if (status == WorldCompanionSosStatusType.resolved) {
      accent = const Color(0xFF247A45);
      background = const Color(0xFFE4F4E8);
      icon = Icons.verified_rounded;
      defaultTitle = 'SOS marked resolved';
      defaultMessage =
          'This request is marked as resolved. Contact local emergency services if you still need help.';
    } else if (status == WorldCompanionSosStatusType.failed) {
      accent = WorldCompanionColors.error;
      background = WorldCompanionColors.errorSurface;
      icon = Icons.error_outline_rounded;
      defaultTitle = 'SOS request needs attention';
      defaultMessage =
          'The request could not be confirmed. If you are in immediate danger, contact local emergency services directly.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: accent,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? defaultTitle,
                  style: TextStyle(
                    color: WorldCompanionColors.deepOcean,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message ?? defaultMessage,
                  style: TextStyle(
                    color: WorldCompanionColors.secondaryText,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                if (reference != null && reference!.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Reference: ${reference!}',
                    style: TextStyle(
                      color: WorldCompanionColors.deepOcean,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (status == WorldCompanionSosStatusType.failed &&
                    onRetry != null) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try again'),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Dismiss status',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded),
              color: WorldCompanionColors.secondaryText,
            ),
        ],
      ),
    );
  }
}
