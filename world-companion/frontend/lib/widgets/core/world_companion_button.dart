import 'package:flutter/material.dart';
import '../../theme/world_companion_typography.dart';

enum WorldCompanionButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
}

class WorldCompanionButton extends StatelessWidget {
  const WorldCompanionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = WorldCompanionButtonVariant.primary,
    this.icon,
    this.iconAfter = false,
    this.loading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final WorldCompanionButtonVariant variant;
  final IconData? icon;
  final bool iconAfter;
  final bool loading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : _buildContent();

    final button = switch (variant) {
      WorldCompanionButtonVariant.primary =>
        ElevatedButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      WorldCompanionButtonVariant.secondary =>
        FilledButton.tonal(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      WorldCompanionButtonVariant.outline =>
        OutlinedButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      WorldCompanionButtonVariant.ghost =>
        TextButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
    };

    if (!fullWidth) {
      return button;
    }

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }

  Widget _buildContent() {
    final text = Text(
      label,
      style: WorldCompanionTypography.textTheme.labelLarge,
    );

    if (icon == null) {
      return text;
    }

    final iconWidget = Icon(
      icon,
      size: 18,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: iconAfter
          ? [
              text,
              const SizedBox(width: 8),
              iconWidget,
            ]
          : [
              iconWidget,
              const SizedBox(width: 8),
              text,
            ],
    );
  }
}