
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';
import '../../theme/world_companion_spacing.dart';

class WorldCompanionPrice extends StatelessWidget {
  const WorldCompanionPrice({
    super.key,
    required this.amount,
    this.currencySymbol = '₹',
    this.period,
    this.prefix,
    this.style,
    this.crossedOut = false,
  });

  final num amount;
  final String currencySymbol;
  final String? period;
  final String? prefix;
  final TextStyle? style;
  final bool crossedOut;

  String get _formattedAmount {
    final value = amount.toDouble();

    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ??
        Theme.of(context).textTheme.titleMedium?.copyWith(
              color: WorldCompanionColors.deepOcean,
              fontWeight: FontWeight.w700,
            );

    final periodStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: WorldCompanionColors.secondaryText,
          decoration:
              crossedOut ? TextDecoration.lineThrough : TextDecoration.none,
        );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: WorldCompanionSpacing.xxs,
      children: [
        if (prefix != null)
          Text(
            prefix!,
            style: effectiveStyle?.copyWith(fontWeight: FontWeight.w500),
          ),
        Text(
          '$currencySymbol$_formattedAmount',
          style: effectiveStyle?.copyWith(
            decoration:
                crossedOut ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        if (period != null) Text(period!, style: periodStyle),
      ],
    );
  }
}
