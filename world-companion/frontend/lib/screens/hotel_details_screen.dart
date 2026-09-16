import 'package:flutter/material.dart';
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

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _pricePerNight() {
    final value = hotel['price_per_night'];

    if (value is num) {
      return value.toDouble();
    }

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
          .map(
            (room) => Map<String, dynamic>.from(room),
          )
          .toList();
    }

    return [];
  }

  String _formatFacility(String facility) {
    return facility
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _formatRoomType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facilities = _facilities();
    final rooms = _roomTypes();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Stay details'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: const Color(0xFF172326),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildQuickStats(context),
                const SizedBox(height: 28),
                if (facilities.isNotEmpty) ...[
                  _buildSectionTitle(
                    context,
                    'Facilities',
                  ),
                  const SizedBox(height: 12),
                  _buildFacilities(context, facilities),
                  const SizedBox(height: 28),
                ],
                if (rooms.isNotEmpty) ...[
                  _buildSectionTitle(
                    context,
                    'Room types',
                  ),
                  const SizedBox(height: 12),
                  _buildRoomTypes(context, rooms),
                  const SizedBox(height: 28),
                ],
                _buildBookingCard(context, hotel),
                const SizedBox(height: 24),
              ],
            );

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 48 : 20,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1100,
                  ),
                  child: content,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFDCE5E4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF4F1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.hotel_rounded,
              size: 32,
              color: Color(0xFF0E7774),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _hotelName(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF172326),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Color(0xFF68777B),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _area(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF68777B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {

    return Row(
      children: [
        Expanded(
          child: _statCard(
            context,
            icon: Icons.star_rounded,
            label: 'Rating',
            value: _rating().toStringAsFixed(1),
            iconColor: const Color(0xFFF27C4A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            context,
            icon: Icons.currency_rupee_rounded,
            label: 'Per night',
            value: _pricePerNight().toStringAsFixed(0),
            iconColor: const Color(0xFF0E7774),
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFDCE5E4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF68777B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF172326),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
  ) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF172326),
      ),
    );
  }

  Widget _buildFacilities(
    BuildContext context,
    List<String> facilities,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: facilities.map((facility) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFDFF4F1),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 17,
                color: Color(0xFF0E7774),
              ),
              const SizedBox(width: 7),
              Text(
                _formatFacility(facility),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF123B43),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoomTypes(
    BuildContext context,
    List<Map<String, dynamic>> rooms,
  ) {
    return Column(
      children: rooms.map((room) {
        final type = room['type']?.toString() ?? 'Room';
        final priceValue = room['price'];

        final price = priceValue is num
            ? priceValue.toDouble()
            : double.tryParse(
                  priceValue?.toString() ?? '',
                ) ??
                0;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFDCE5E4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9F8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bed_rounded,
                  color: Color(0xFF0E7774),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _formatRoomType(type),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF172326),
                  ),
                ),
              ),
              Text(
                '₹${price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0E7774),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBookingCard(BuildContext context, Map<String, dynamic> hotel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF123B43),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ready to stay here?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Choose your room and continue with the booking.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.78),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(hotel: hotel),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF27C4A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Book this stay',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Booking is simulated in the current project backend.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.60),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}