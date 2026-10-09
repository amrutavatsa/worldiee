
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';

class WorldCompanionBookingSummary extends StatelessWidget {
  const WorldCompanionBookingSummary({
    super.key,
    required this.propertyName,
    required this.location,
    required this.checkIn,
    required this.checkOut,
    required this.guestLabel,
    required this.roomLabel,
    required this.nightlyRate,
    required this.nightCount,
    required this.subtotal,
    this.taxesAndFees,
    this.discount,
    this.total,
    this.currencySymbol = '₹',
    this.onEdit,
  });

  final String propertyName;
  final String location;
  final String checkIn;
  final String checkOut;
  final String guestLabel;
  final String roomLabel;
  final double nightlyRate;
  final int nightCount;
  final double subtotal;
  final double? taxesAndFees;
  final double? discount;
  final double? total;
  final String currencySymbol;
  final VoidCallback? onEdit;

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final calculatedTotal =
        total ?? subtotal + (taxesAndFees ?? 0) - (discount ?? 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD6E0E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Booking summary',
                  style: TextStyle(
                    color: WorldCompanionColors.deepOcean,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onEdit != null)
                TextButton(
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF4ED),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.hotel_rounded,
                  color: WorldCompanionColors.oceanBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      propertyName,
                      style: const TextStyle(
                        color: WorldCompanionColors.deepOcean,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        color: Color(0xFF718398),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFD6E0E8), height: 1),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _BookingDetail(
                  icon: Icons.login_rounded,
                  label: 'CHECK-IN',
                  value: checkIn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BookingDetail(
                  icon: Icons.logout_rounded,
                  label: 'CHECK-OUT',
                  value: checkOut,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _BookingDetail(
            icon: Icons.people_alt_outlined,
            label: 'GUESTS',
            value: guestLabel,
          ),
          const SizedBox(height: 14),
          _BookingDetail(
            icon: Icons.bed_outlined,
            label: 'ROOM',
            value: roomLabel,
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFD6E0E8), height: 1),
          const SizedBox(height: 16),
          const Text(
            'Price breakdown',
            style: TextStyle(
              color: WorldCompanionColors.deepOcean,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          _PriceRow(
            label:
                '$currencySymbol${_formatAmount(nightlyRate)} × $nightCount ${nightCount == 1 ? 'night' : 'nights'}',
            amount: subtotal,
            currencySymbol: currencySymbol,
          ),
          if (taxesAndFees != null) ...[
            const SizedBox(height: 10),
            _PriceRow(
              label: 'Taxes and fees',
              amount: taxesAndFees!,
              currencySymbol: currencySymbol,
            ),
          ],
          if (discount != null && discount! > 0) ...[
            const SizedBox(height: 10),
            _PriceRow(
              label: 'Discount',
              amount: -discount!,
              currencySymbol: currencySymbol,
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFD6E0E8), height: 1),
          const SizedBox(height: 15),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    color: WorldCompanionColors.deepOcean,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$currencySymbol${_formatAmount(calculatedTotal)}',
                style: const TextStyle(
                  color: WorldCompanionColors.deepOcean,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Final amount is based on the supplied booking details.',
            style: TextStyle(
              color: Color(0xFF718398),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingDetail extends StatelessWidget {
  const _BookingDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: WorldCompanionColors.oceanBlue,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF718398),
                  fontSize: 10,
                  letterSpacing: 0.7,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  color: WorldCompanionColors.deepOcean,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    required this.currencySymbol,
    this.isDiscount = false,
  });

  final String label;
  final double amount;
  final String currencySymbol;
  final bool isDiscount;

  String _formatAmount(double value) {
    final absoluteValue = value.abs();
    if (absoluteValue == absoluteValue.roundToDouble()) {
      return absoluteValue.toStringAsFixed(0);
    }
    return absoluteValue.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final amountLabel = isDiscount
        ? '-$currencySymbol${_formatAmount(amount)}'
        : '$currencySymbol${_formatAmount(amount)}';

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4B6075),
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          amountLabel,
          style: TextStyle(
            color: isDiscount
                ? const Color(0xFF287A57)
                : WorldCompanionColors.deepOcean,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
