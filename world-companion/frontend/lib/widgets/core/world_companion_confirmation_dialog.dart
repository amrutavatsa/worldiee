
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_radius.dart';
import '../../theme/world_companion_spacing.dart';
import 'world_companion_button.dart';

class WorldCompanionConfirmationDialog extends StatelessWidget {
  const WorldCompanionConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final IconData? icon;

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return WorldCompanionConfirmationDialog(
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          isDestructive: isDestructive,
          icon: icon,
        );
      },
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
      ),
      backgroundColor: WorldCompanionColors.surface,
      icon: icon == null
          ? null
          : Icon(
              icon,
              color: isDestructive
                  ? WorldCompanionColors.error
                  : WorldCompanionColors.deepOcean,
            ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: WorldCompanionColors.primaryText,
              fontWeight: FontWeight.w700,
            ),
      ),
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: WorldCompanionColors.secondaryText,
            ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        WorldCompanionSpacing.md,
        0,
        WorldCompanionSpacing.md,
        WorldCompanionSpacing.md,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        WorldCompanionButton(
          label: confirmLabel,
          onPressed: () => Navigator.of(context).pop(true),
          variant: isDestructive
              ? WorldCompanionButtonVariant.outline
              : WorldCompanionButtonVariant.primary,
        ),
      ],
    );
  }
}
