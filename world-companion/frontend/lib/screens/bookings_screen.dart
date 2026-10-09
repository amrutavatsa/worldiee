import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/world_companion_colors.dart';
import '../theme/world_companion_elevation.dart';
import '../theme/world_companion_radius.dart';
import '../theme/world_companion_spacing.dart';
import '../theme/world_companion_typography.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getBookingHistory();

      if (!mounted) return;

      setState(() {
        _bookings = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _value(
    Map<String, dynamic> booking,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = booking[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return WorldCompanionColors.success;
      case 'pending':
        return WorldCompanionColors.warning;
      case 'cancelled':
      case 'canceled':
        return WorldCompanionColors.error;
      default:
        return WorldCompanionColors.mutedText;
    }
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WorldCompanionSpacing.sm,
        vertical: WorldCompanionSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(WorldCompanionRadius.pill),
      ),
      child: Text(
        status,
        style: WorldCompanionTypography.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _dateInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: WorldCompanionColors.mutedText,
            ),
            const SizedBox(width: WorldCompanionSpacing.xxs),
            Flexible(
              child: Text(
                label,
                style: WorldCompanionTypography.textTheme.labelSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: WorldCompanionSpacing.xs),
        Text(
          value.isEmpty ? 'Not available' : value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: WorldCompanionTypography.textTheme.bodyMedium?.copyWith(
            color: WorldCompanionColors.deepOcean,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _bookingCard(Map<String, dynamic> booking) {
    final hotelName = _value(
      booking,
      ['hotel_name', 'hotel', 'name'],
      fallback: 'Hotel booking',
    );

    final roomType = _value(
      booking,
      ['room_type', 'room'],
      fallback: 'Room',
    );

    final checkIn = _value(booking, ['check_in', 'checkIn']);
    final checkOut = _value(booking, ['check_out', 'checkOut']);

    final status = _value(
      booking,
      ['status'],
      fallback: 'Pending',
    );

    final bookingId = _value(
      booking,
      ['id', 'booking_id', 'uuid'],
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: WorldCompanionSpacing.md,
      ),
      padding: const EdgeInsets.all(WorldCompanionSpacing.md),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
        border: Border.all(color: WorldCompanionColors.border),
        boxShadow: [
          BoxShadow(
            color: WorldCompanionColors.deepOcean.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: WorldCompanionColors.infoSurface,
                  borderRadius: BorderRadius.circular(
                    WorldCompanionRadius.medium,
                  ),
                ),
                child: const Icon(
                  Icons.hotel_rounded,
                  color: WorldCompanionColors.deepOcean,
                  size: 25,
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotelName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: WorldCompanionTypography.textTheme.titleMedium
                          ?.copyWith(
                        color: WorldCompanionColors.deepOcean,
                      ),
                    ),
                    const SizedBox(height: WorldCompanionSpacing.xxs),
                    Text(
                      roomType,
                      style: WorldCompanionTypography.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.xs),
              Flexible(
                child: Align(
                  alignment: Alignment.topRight,
                  child: _statusBadge(status),
                ),
              ),
            ],
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          Container(
            padding: const EdgeInsets.all(WorldCompanionSpacing.md),
            decoration: BoxDecoration(
              color: WorldCompanionColors.aiSurface,
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.medium,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _dateInfo(
                    icon: Icons.login_rounded,
                    label: 'CHECK-IN',
                    value: checkIn,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  margin: const EdgeInsets.symmetric(
                    horizontal: WorldCompanionSpacing.sm,
                  ),
                  color: WorldCompanionColors.border,
                ),
                Expanded(
                  child: _dateInfo(
                    icon: Icons.logout_rounded,
                    label: 'CHECK-OUT',
                    value: checkOut,
                  ),
                ),
              ],
            ),
          ),
          if (bookingId.isNotEmpty) ...[
            const SizedBox(height: WorldCompanionSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  size: 15,
                  color: WorldCompanionColors.mutedText,
                ),
                const SizedBox(width: WorldCompanionSpacing.xxs),
                Expanded(
                  child: Text(
                    'Booking ID: $bookingId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WorldCompanionTypography.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
      decoration: BoxDecoration(
        color: WorldCompanionColors.deepOcean,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -15,
            child: Icon(
              Icons.travel_explore_rounded,
              size: 112,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(
                    WorldCompanionRadius.medium,
                  ),
                ),
                child: const Icon(
                  Icons.hotel_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your stays',
                      style: WorldCompanionTypography.textTheme.headlineSmall
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: WorldCompanionSpacing.xxs),
                    Text(
                      'Your hotel reservations, all in one place.',
                      style: WorldCompanionTypography.textTheme.bodyMedium
                          ?.copyWith(
                        color: Colors.white.withOpacity(0.78),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(
        top: WorldCompanionSpacing.xl,
        bottom: WorldCompanionSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: WorldCompanionTypography.textTheme.headlineSmall,
          ),
          const SizedBox(height: WorldCompanionSpacing.xxs),
          Text(
            subtitle,
            style: WorldCompanionTypography.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: WorldCompanionSpacing.lg,
        vertical: WorldCompanionSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
        border: Border.all(color: WorldCompanionColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: WorldCompanionColors.infoSurface,
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.extraLarge,
              ),
            ),
            child: const Icon(
              Icons.luggage_outlined,
              color: WorldCompanionColors.deepOcean,
              size: 36,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.lg),
          Text(
            'No bookings yet',
            textAlign: TextAlign.center,
            style: WorldCompanionTypography.textTheme.titleLarge,
          ),
          const SizedBox(height: WorldCompanionSpacing.xs),
          Text(
            'Your hotel bookings will appear here after you make a reservation.',
            textAlign: TextAlign.center,
            style: WorldCompanionTypography.textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Container(
      padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.large,
        ),
        border: Border.all(
          color: WorldCompanionColors.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: WorldCompanionColors.errorSurface,
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.medium,
              ),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: WorldCompanionColors.error,
              size: 28,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          Text(
            'Could not load bookings',
            textAlign: TextAlign.center,
            style: WorldCompanionTypography.textTheme.titleMedium,
          ),
          const SizedBox(height: WorldCompanionSpacing.xs),
          Text(
            _error ?? 'Something went wrong.',
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: WorldCompanionTypography.textTheme.bodySmall,
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          FilledButton.icon(
            onPressed: _loading ? null : _loadBookings,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _loadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        vertical: WorldCompanionSpacing.xxxl,
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: WorldCompanionColors.deepOcean,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorldCompanionColors.softWhite,
      appBar: AppBar(
        backgroundColor: WorldCompanionColors.softWhite,
        foregroundColor: WorldCompanionColors.deepOcean,
        surfaceTintColor: Colors.transparent,
        elevation: WorldCompanionElevation.none,
        title: Text(
          'Bookings',
          style: WorldCompanionTypography.textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh bookings',
            onPressed: _loading ? null : _loadBookings,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: WorldCompanionSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadBookings,
          color: WorldCompanionColors.deepOcean,
          backgroundColor: WorldCompanionColors.surface,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              WorldCompanionSpacing.mobilePage,
              WorldCompanionSpacing.sm,
              WorldCompanionSpacing.mobilePage,
              WorldCompanionSpacing.xxxl,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _summaryCard(),
                      if (!_loading && _error == null) ...[
                        _sectionHeading(
                          'Booking history',
                          _bookings.isEmpty
                              ? 'Your upcoming stays will show up here.'
                              : '${_bookings.length} ${_bookings.length == 1 ? 'reservation' : 'reservations'} in your history.',
                        ),
                      ],
                      if (_loading)
                        _loadingState()
                      else if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: WorldCompanionSpacing.xl,
                          ),
                          child: _errorState(),
                        )
                      else if (_bookings.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: WorldCompanionSpacing.sm,
                          ),
                          child: _emptyState(),
                        )
                      else
                        ..._bookings.map((booking) {
                          if (booking is Map) {
                            return _bookingCard(
                              Map<String, dynamic>.from(booking),
                            );
                          }

                          return const SizedBox.shrink();
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
