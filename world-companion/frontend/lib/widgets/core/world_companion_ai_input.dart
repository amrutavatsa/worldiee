import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_radius.dart';
import '../../theme/world_companion_typography.dart';

class WorldCompanionAiInput extends StatelessWidget {
  const WorldCompanionAiInput({
    super.key,
    required this.controller,
    this.hintText = 'Ask WorldCompanion anything...',
    this.onSubmitted,
    this.onVoicePressed,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onVoicePressed;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 56,
      ),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
        border: Border.all(
          color: WorldCompanionColors.border,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),

          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: WorldCompanionColors.softWhite,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 17,
              color: WorldCompanionColors.deepOcean,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.send,
              style:
                  WorldCompanionTypography.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle:
                    WorldCompanionTypography
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                  color: WorldCompanionColors.mutedText,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding:
                    const EdgeInsets.symmetric(
                  vertical: 16,
                ),
              ),
            ),
          ),

          if (onVoicePressed != null)
            IconButton(
              tooltip: 'Use voice',
              onPressed: enabled
                  ? onVoicePressed
                  : null,
              icon: const Icon(
                Icons.mic_none_rounded,
                color: WorldCompanionColors.deepOcean,
              ),
            ),

          const SizedBox(width: 4),
        ],
      ),
    );
  }
}