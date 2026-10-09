
import 'package:flutter/material.dart';

import '../../theme/world_companion_colors.dart';

class WorldCompanionBookingConfirmation extends StatelessWidget {
  const WorldCompanionBookingConfirmation({
    super.key,
    required this.propertyName,
    required this.location,
    required this.checkIn,
    required this.checkOut,
    required this.bookingReference,
    this.imageUrl,
    this.guestLabel,
    this.roomLabel,
    this.isConfirmed = false,
    this.onContinue,
    this.continueLabel = 'Continue',
  });

  final String propertyName;
  final String location;
  final String checkIn;
  final String checkOut;
  final String bookingReference;
  final String? imageUrl;
  final String? guestLabel;
  final String? roomLabel;
  final bool isConfirmed;
  final VoidCallback? onContinue;
  final String continueLabel;

  @override
  Widget build(BuildContext context) {
    final statusColor = isConfirmed
        ? const Color(0xFF287A57)
        : const Color(0xFF94631B);

    final statusBackground = isConfirmed
        ? const Color(0xFFE8F5ED)
        : const Color(0xFFFFF3D9);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD6E0E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: statusBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConfirmed
                  ? Icons.check_rounded
                  : Icons.hourglass_top_rounded,
              size: 40,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isConfirmed ? 'Booking confirmed' : 'Booking pending',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: WorldCompanionColors.deepOcean,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isConfirmed
                ? 'Your stay is marked as confirmed.'
                : 'Your stay has not been marked as confirmed yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF4B6075),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 165,
              width: double.infinity,
              child: _ConfirmationImage(imageUrl: imageUrl),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              propertyName,
              style: const TextStyle(
                color: WorldCompanionColors.deepOcean,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 17,
                color: WorldCompanionColors.oceanBlue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(
                    color: Color(0xFF4B6075),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4ED),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BOOKING REFERENCE',
                  style: TextStyle(
                    color: Color(0xFF718398),
                    fontSize: 10,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                SelectableText(
                  bookingReference.trim().isEmpty
                      ? 'Not available'
                      : bookingReference,
                  style: const TextStyle(
                    color: WorldCompanionColors.deepOcean,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StayDetail(
                  icon: Icons.login_rounded,
                  label: 'CHECK-IN',
                  value: checkIn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StayDetail(
                  icon: Icons.logout_rounded,
                  label: 'CHECK-OUT',
                  value: checkOut,
                ),
              ),
            ],
          ),
          if ((guestLabel != null && guestLabel!.trim().isNotEmpty) ||
              (roomLabel != null && roomLabel!.trim().isNotEmpty)) ...[
            const SizedBox(height: 18),
            if (guestLabel != null && guestLabel!.trim().isNotEmpty)
              _AdditionalDetail(
                icon: Icons.people_alt_outlined,
                value: guestLabel!,
              ),
            if (guestLabel != null &&
                guestLabel!.trim().isNotEmpty &&
                roomLabel != null &&
                roomLabel!.trim().isNotEmpty)
              const SizedBox(height: 10),
            if (roomLabel != null && roomLabel!.trim().isNotEmpty)
              _AdditionalDetail(
                icon: Icons.bed_outlined,
                value: roomLabel!,
              ),
          ],
          if (onContinue != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: WorldCompanionColors.deepOcean,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(
                  continueLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StayDetail extends StatelessWidget {
  const _StayDetail({
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

class _AdditionalDetail extends StatelessWidget {
  const _AdditionalDetail({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: WorldCompanionColors.oceanBlue,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF4B6075),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfirmationImage extends StatelessWidget {
  const _ConfirmationImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return _fallback();
    }

    return Image.network(
      imageUrl!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallback(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return Container(
          color: const Color(0xFFEEF4ED),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: WorldCompanionColors.oceanBlue,
          ),
        );
      },
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFEEF4ED),
      alignment: Alignment.center,
      child: const Icon(
        Icons.hotel_rounded,
        size: 46,
        color: WorldCompanionColors.softBlue,
      ),
    );
  }
}
