import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_radius.dart';
import '../../theme/world_companion_typography.dart';

class WorldCompanionSearchField extends StatelessWidget {
  const WorldCompanionSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search places, destinations, stays...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;

        return TextField(
          controller: controller,
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: WorldCompanionTypography.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: WorldCompanionColors.secondaryText,
            ),
            suffixIcon: hasText
                ? IconButton(
                    tooltip: 'Clear search',
                    onPressed: onClear ?? controller.clear,
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  )
                : null,
            filled: true,
            fillColor: WorldCompanionColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.pill,
              ),
              borderSide: const BorderSide(
                color: WorldCompanionColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.pill,
              ),
              borderSide: const BorderSide(
                color: WorldCompanionColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.pill,
              ),
              borderSide: const BorderSide(
                color: WorldCompanionColors.deepOcean,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        );
      },
    );
  }
}