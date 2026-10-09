import 'package:flutter/material.dart';

import 'world_companion_colors.dart';
import 'world_companion_elevation.dart';
import 'world_companion_radius.dart';
import 'world_companion_typography.dart';

abstract final class WorldCompanionTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.light(
      primary: WorldCompanionColors.deepOcean,
      onPrimary: Colors.white,

      secondary: WorldCompanionColors.oceanBlue,
      onSecondary: Colors.white,

      tertiary: WorldCompanionColors.softBlue,
      onTertiary: WorldCompanionColors.deepOcean,

      surface: WorldCompanionColors.surface,
      onSurface: WorldCompanionColors.primaryText,

      surfaceContainerHighest: WorldCompanionColors.softWhite,

      outline: WorldCompanionColors.border,
      outlineVariant: WorldCompanionColors.border,

      error: WorldCompanionColors.error,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,

      colorScheme: colorScheme,

      scaffoldBackgroundColor:
          WorldCompanionColors.softWhite,

      textTheme:
          WorldCompanionTypography.textTheme,

      fontFamily: 'Plus Jakarta Sans',

      visualDensity: VisualDensity.standard,

      appBarTheme: const AppBarTheme(
        backgroundColor:
            WorldCompanionColors.softWhite,
        foregroundColor:
            WorldCompanionColors.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),

      cardTheme: CardTheme(
        color: WorldCompanionColors.surface,
        elevation: WorldCompanionElevation.none,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            WorldCompanionRadius.large,
          ),
          side: const BorderSide(
            color: WorldCompanionColors.border,
            width: 1,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WorldCompanionColors.surface,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        hintStyle:
            WorldCompanionTypography.textTheme.bodyMedium?.copyWith(
          color: WorldCompanionColors.mutedText,
        ),

        labelStyle:
            WorldCompanionTypography.textTheme.bodyMedium?.copyWith(
          color: WorldCompanionColors.secondaryText,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            WorldCompanionRadius.medium,
          ),
          borderSide: const BorderSide(
            color: WorldCompanionColors.border,
          ),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            WorldCompanionRadius.medium,
          ),
          borderSide: const BorderSide(
            color: WorldCompanionColors.border,
          ),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            WorldCompanionRadius.medium,
          ),
          borderSide: const BorderSide(
            color: WorldCompanionColors.deepOcean,
            width: 1.5,
          ),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            WorldCompanionRadius.medium,
          ),
          borderSide: const BorderSide(
            color: WorldCompanionColors.error,
          ),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            WorldCompanionRadius.medium,
          ),
          borderSide: const BorderSide(
            color: WorldCompanionColors.error,
            width: 1.5,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              WorldCompanionColors.deepOcean,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              WorldCompanionRadius.medium,
            ),
          ),
          textStyle:
              WorldCompanionTypography.textTheme.labelLarge?.copyWith(
            color: Colors.white,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor:
              WorldCompanionColors.deepOcean,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          side: const BorderSide(
            color: WorldCompanionColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              WorldCompanionRadius.medium,
            ),
          ),
          textStyle:
              WorldCompanionTypography.textTheme.labelLarge?.copyWith(
            color: WorldCompanionColors.deepOcean,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor:
              WorldCompanionColors.deepOcean,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          textStyle:
              WorldCompanionTypography.textTheme.labelLarge,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor:
              WorldCompanionColors.deepOcean,
          minimumSize: const Size(44, 44),
          tapTargetSize:
              MaterialTapTargetSize.padded,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor:
            WorldCompanionColors.surface,
        selectedColor:
            WorldCompanionColors.deepOcean,
        disabledColor:
            WorldCompanionColors.softWhite,

        side: const BorderSide(
          color: WorldCompanionColors.border,
        ),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            WorldCompanionRadius.pill,
          ),
        ),

        labelStyle:
            WorldCompanionTypography.textTheme.labelMedium?.copyWith(
          color: WorldCompanionColors.secondaryText,
        ),

        secondaryLabelStyle:
            WorldCompanionTypography.textTheme.labelMedium?.copyWith(
          color: Colors.white,
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),

        elevation: 0,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            WorldCompanionColors.surface,
        elevation: 0,
        height: 76,

        indicatorColor:
            WorldCompanionColors.softWhite,

        surfaceTintColor: Colors.transparent,

        labelTextStyle:
            WidgetStateProperty.resolveWith(
          (states) {
            final selected = states.contains(
              WidgetState.selected,
            );

            return WorldCompanionTypography
                .textTheme
                .labelSmall!
                .copyWith(
              color: selected
                  ? WorldCompanionColors.deepOcean
                  : WorldCompanionColors.mutedText,
              fontWeight: selected
                  ? FontWeight.w700
                  : FontWeight.w500,
            );
          },
        ),

        iconTheme:
            WidgetStateProperty.resolveWith(
          (states) {
            final selected = states.contains(
              WidgetState.selected,
            );

            return IconThemeData(
              color: selected
                  ? WorldCompanionColors.deepOcean
                  : WorldCompanionColors.mutedText,
              size: selected ? 24 : 23,
            );
          },
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor:
            WorldCompanionColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
      ),

      dialogTheme: DialogTheme(
        backgroundColor:
            WorldCompanionColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation:
            WorldCompanionElevation.medium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            WorldCompanionRadius.extraLarge,
          ),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: WorldCompanionColors.border,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme:
          const ProgressIndicatorThemeData(
        color: WorldCompanionColors.deepOcean,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            WorldCompanionColors.deepOcean,
        contentTextStyle:
            WorldCompanionTypography
                .textTheme
                .bodyMedium
                ?.copyWith(
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            WorldCompanionRadius.medium,
          ),
        ),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: WorldCompanionColors.deepOcean,
          borderRadius: BorderRadius.circular(
            WorldCompanionRadius.small,
          ),
        ),
        textStyle:
            WorldCompanionTypography
                .textTheme
                .bodySmall
                ?.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
}