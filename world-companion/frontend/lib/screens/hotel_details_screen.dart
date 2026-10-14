import 'package:flutter/material.dart';

import '../theme/world_companion_colors.dart';
import '../theme/world_companion_elevation.dart';
import '../theme/world_companion_radius.dart';
import '../theme/world_companion_spacing.dart';
import '../theme/world_companion_typography.dart';
import 'booking_screen.dart';

class HotelDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> hotel;

  const HotelDetailsScreen({
    super.key,
    required this.hotel,
  });

  String _hotelName() {
    return hotel['name']?.toString() ?? 'Stay';
  }

  String _area() {
    return hotel['area']?.toString() ?? 'Location unavailable';
  }

  double _rating() {
    final value = hotel['rating'];

    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _pricePerNight() {
    final value = hotel['price_per_night'];

    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<String> _facilities() {
    final value = hotel['facilities'];

    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }

    return [];
  }

  List<Map<String, dynamic>> _roomTypes() {
    final value = hotel['room_types'];

    if (value is List) {
      return value
          .whereType<Map>()
          .map((room) => Map<String, dynamic>.from(room))
          .toList();
    }

    return [];
  }

  String _formatLabel(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _formatPrice(double price) {
    return '₹${price.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final facilities = _facilities();
    final rooms = _roomTypes();

    return Scaffold(
      backgroundColor: WorldCompanionColors.aiSurface,
      appBar: AppBar(
        title: const Text('Stay details'),
        backgroundColor: WorldCompanionColors.surface,
        foregroundColor: WorldCompanionColors.deepOcean,
        elevation: WorldCompanionElevation.none,
        scrolledUnderElevation: WorldCompanionElevation.none,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: WorldCompanionColors.border,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide
                    ? WorldCompanionSpacing.desktopPage
                    : WorldCompanionSpacing.mobilePage,
                vertical: WorldCompanionSpacing.lg,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: WorldCompanionSpacing.lg),
                      _buildQuickStats(context),
                      if (facilities.isNotEmpty) ...[
                        const SizedBox(height: WorldCompanionSpacing.xl),
                        _buildSectionTitle(context, 'Facilities'),
                        const SizedBox(height: WorldCompanionSpacing.md),
                        _buildFacilities(facilities),
                      ],
                      if (rooms.isNotEmpty) ...[
                        const SizedBox(height: WorldCompanionSpacing.xl),
                        _buildSectionTitle(context, 'Room types'),
                        const SizedBox(height: WorldCompanionSpacing.md),
                        _buildRoomTypes(rooms),
                      ],
                      const SizedBox(height: WorldCompanionSpacing.xl),
                      _buildBookingCard(context),
                      const SizedBox(height: WorldCompanionSpacing.lg),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final textTheme = WorldCompanionTypography.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.extraLarge),
        border: Border.all(color: WorldCompanionColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080B2545),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: WorldCompanionColors.infoSurface,
              borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
            ),
            child: const Icon(
              Icons.hotel_rounded,
              size: 34,
              color: WorldCompanionColors.oceanBlue,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.lg),
          Text(
            _hotelName(),
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 20,
                color: WorldCompanionColors.secondaryText,
              ),
              const SizedBox(width: WorldCompanionSpacing.xs),
              Expanded(
                child: Text(
                  _area(),
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: WorldCompanionSpacing.lg),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WorldCompanionSpacing.md,
              vertical: WorldCompanionSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: WorldCompanionColors.infoSurface,
              borderRadius: BorderRadius.circular(WorldCompanionRadius.medium),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 17,
                  color: WorldCompanionColors.oceanBlue,
                ),
                const SizedBox(width: WorldCompanionSpacing.xs),
                Flexible(
                  child: Text(
                    'Stay information',
                    style: textTheme.labelMedium?.copyWith(
                      color: WorldCompanionColors.oceanBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        return Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.star_rounded,
                label: 'Guest rating',
                value: hotel['rating'] == null ||
                        hotel['rating'].toString().trim().isEmpty
                    ? 'Not available'
                    : _rating().toStringAsFixed(1),
                iconColor: WorldCompanionColors.warning,
                compact: compact,
              ),
            ),
            const SizedBox(width: WorldCompanionSpacing.md),
            Expanded(
              child: _statCard(
                icon: Icons.nightlight_round,
                label: 'Price per night',
                value: hotel['price_per_night'] == null || _pricePerNight() <= 0
                    ? 'Not available'
                    : _formatPrice(_pricePerNight()),
                iconColor: WorldCompanionColors.oceanBlue,
                compact: compact,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    required bool compact,
  }) {
    final textTheme = WorldCompanionTypography.textTheme;

    return Container(
      padding: EdgeInsets.all(
        compact ? WorldCompanionSpacing.md : WorldCompanionSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
        border: Border.all(color: WorldCompanionColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 25),
          const SizedBox(height: WorldCompanionSpacing.md),
          Text(
            label,
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: WorldCompanionSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: WorldCompanionColors.deepOcean,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: WorldCompanionTypography.textTheme.headlineSmall,
    );
  }

  Widget _buildFacilities(List<String> facilities) {
    return Wrap(
      spacing: WorldCompanionSpacing.sm,
      runSpacing: WorldCompanionSpacing.sm,
      children: facilities.map((facility) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: WorldCompanionSpacing.md,
            vertical: WorldCompanionSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: WorldCompanionColors.successSurface,
            borderRadius: BorderRadius.circular(WorldCompanionRadius.pill),
            border: Border.all(
              color: WorldCompanionColors.success.withOpacity(0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 17,
                color: WorldCompanionColors.success,
              ),
              const SizedBox(width: WorldCompanionSpacing.xs),
              Text(
                _formatLabel(facility),
                style: WorldCompanionTypography.textTheme.labelMedium?.copyWith(
                  color: WorldCompanionColors.deepOcean,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoomTypes(List<Map<String, dynamic>> rooms) {
    final textTheme = WorldCompanionTypography.textTheme;

    return Column(
      children: rooms.map((room) {
        final type = room['type']?.toString() ?? 'Room';
        final priceValue = room['price'];

        final price = priceValue is num
            ? priceValue.toDouble()
            : double.tryParse(priceValue?.toString() ?? '') ?? 0;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: WorldCompanionSpacing.md),
          padding: const EdgeInsets.all(WorldCompanionSpacing.md),
          decoration: BoxDecoration(
            color: WorldCompanionColors.surface,
            borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
            border: Border.all(color: WorldCompanionColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: WorldCompanionColors.infoSurface,
                  borderRadius: BorderRadius.circular(
                    WorldCompanionRadius.medium,
                  ),
                ),
                child: const Icon(
                  Icons.bed_rounded,
                  color: WorldCompanionColors.oceanBlue,
                  size: 25,
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.md),
              Expanded(
                child: Text(
                  _formatLabel(type),
                  style: textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.sm),
              Text(
                _formatPrice(price),
                style: textTheme.titleMedium?.copyWith(
                  color: WorldCompanionColors.oceanBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBookingCard(BuildContext context) {
    final textTheme = WorldCompanionTypography.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
      decoration: BoxDecoration(
        color: WorldCompanionColors.deepOcean,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.extraLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.luggage_rounded,
            size: 30,
            color: WorldCompanionColors.softBlue,
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          Text(
            'Ready to stay here?',
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.sm),
          Text(
            hotel['is_external'] == true
                ? 'This nearby stay is listed by an external places provider. Confirm rates and availability directly with the property.'
                : 'Review your stay details and continue to booking.',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.78),
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: hotel['is_external'] == true
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => BookingScreen(hotel: hotel),
                        ),
                      );
                    },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(hotel['is_external'] == true
                  ? 'External listing'
                  : 'Book this stay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: WorldCompanionColors.softWhite,
                foregroundColor: WorldCompanionColors.deepOcean,
                elevation: WorldCompanionElevation.none,
                padding: const EdgeInsets.symmetric(
                  horizontal: WorldCompanionSpacing.lg,
                  vertical: WorldCompanionSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    WorldCompanionRadius.medium,
                  ),
                ),
                textStyle: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          if (hotel['is_external'] != true)
            Center(
              child: Text(
                'Booking is simulated in the current project backend.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.62),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
