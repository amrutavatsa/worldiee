import 'package:flutter/material.dart';

import '../services/api_service.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  static const Color primary = Color(0xFF0E7774);
  static const Color deep = Color(0xFF123B43);
  static const Color aqua = Color(0xFFDFF4F1);
  static const Color background = Color(0xFFF7F9F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF172326);
  static const Color muted = Color(0xFF68777B);
  static const Color line = Color(0xFFDCE5E4);
  static const Color success = Color(0xFF248A67);
  static const Color warning = Color(0xFFB7791F);
  static const Color error = Color(0xFFC94B4B);

  bool _loading = true;
  String? _error;
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
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
        return success;
      case 'pending':
        return warning;
      case 'cancelled':
      case 'canceled':
        return error;
      default:
        return muted;
    }
  }

  Widget _bookingCard(
    Map<String, dynamic> booking,
  ) {
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

    final checkIn = _value(
      booking,
      ['check_in', 'checkIn'],
    );

    final checkOut = _value(
      booking,
      ['check_out', 'checkOut'],
    );

    final status = _value(
      booking,
      ['status'],
      fallback: 'Pending',
    );

    final bookingId = _value(
      booking,
      ['id', 'booking_id', 'uuid'],
    );

    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08123B43),
            blurRadius: 14,
            offset: Offset(0, 6),
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
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: aqua,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.hotel_rounded,
                  color: primary,
                  size: 25,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotelName,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      roomType,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _dateInfo(
                    label: 'Check-in',
                    value: checkIn.isEmpty
                        ? 'Not available'
                        : checkIn,
                  ),
                ),
                Container(
                  width: 1,
                  height: 34,
                  color: line,
                ),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 14),
                    child: _dateInfo(
                      label: 'Check-out',
                      value: checkOut.isEmpty
                          ? 'Not available'
                          : checkOut,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (bookingId.isNotEmpty) ...[
            const SizedBox(height: 13),
            Text(
              'Booking ID: $bookingId',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: muted,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dateInfo({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ink,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.hotel_outlined,
            color: primary,
            size: 44,
          ),
          SizedBox(height: 16),
          Text(
            'No bookings yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Your hotel bookings will appear here after you make a reservation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Bookings'),
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadBookings,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadBookings,
          color: primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      deep,
                      primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.hotel_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your stays',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'View your WorldCompanion hotel booking history.',
                            style: TextStyle(
                              color: Color(0xD9FFFFFF),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: primary,
                    ),
                  ),
                )
              else if (_error != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: error.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: error,
                        size: 38,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Could not load bookings',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _loadBookings,
                        icon: const Icon(
                          Icons.refresh_rounded,
                        ),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                )
              else if (_bookings.isEmpty)
                _emptyState()
              else
                ..._bookings.map(
                  (booking) {
                    if (booking is Map) {
                      return _bookingCard(
                        Map<String, dynamic>.from(booking),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}