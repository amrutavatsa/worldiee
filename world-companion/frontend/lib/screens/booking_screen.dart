import 'package:flutter/material.dart';

import '../services/api_service.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> hotel;

  const BookingScreen({
    super.key,
    required this.hotel,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _guestNameController = TextEditingController();

  String? _selectedRoomType;

  DateTime? _checkInDate;
  DateTime? _checkOutDate;

  bool _isBooking = false;

  @override
  void dispose() {
    _guestNameController.dispose();
    super.dispose();
  }

  String _hotelName() {
    return widget.hotel['name']?.toString() ?? 'Stay';
  }

  String _area() {
    return widget.hotel['area']?.toString() ?? 'Location unavailable';
  }

  List<Map<String, dynamic>> _roomTypes() {
    final value = widget.hotel['room_types'];

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

  double _roomPrice(
    Map<String, dynamic> room,
  ) {
    final value = room['price'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _formatDate(
    DateTime date,
  ) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String _apiDate(
    DateTime date,
  ) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  Future<void> _pickCheckInDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _checkInDate ?? now,
      firstDate: now,
      lastDate: DateTime(
        now.year + 2,
        now.month,
        now.day,
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _checkInDate = selected;

      if (_checkOutDate != null &&
          !_checkOutDate!.isAfter(selected)) {
        _checkOutDate = null;
      }
    });
  }

  Future<void> _pickCheckOutDate() async {
    final now = DateTime.now();

    final minimumDate = _checkInDate == null
        ? now.add(const Duration(days: 1))
        : _checkInDate!.add(
            const Duration(days: 1),
          );

    final selected = await showDatePicker(
      context: context,
      initialDate: _checkOutDate ?? minimumDate,
      firstDate: minimumDate,
      lastDate: DateTime(
        now.year + 2,
        now.month,
        now.day,
      ),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _checkOutDate = selected;
    });
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRoomType == null) {
      _showMessage(
        'Please select a room type.',
      );
      return;
    }

    if (_checkInDate == null) {
      _showMessage(
        'Please select a check-in date.',
      );
      return;
    }

    if (_checkOutDate == null) {
      _showMessage(
        'Please select a check-out date.',
      );
      return;
    }

    if (!_checkOutDate!.isAfter(_checkInDate!)) {
      _showMessage(
        'Check-out must be after check-in.',
      );
      return;
    }

    final guestName = _guestNameController.text.trim();
    final roomType = _selectedRoomType!;
    final checkIn = _apiDate(_checkInDate!);
    final checkOut = _apiDate(_checkOutDate!);

    setState(() {
      _isBooking = true;
    });

    try {
      final response = await ApiService.createBooking(
        hotelId: widget.hotel['id'].toString(),
        guestName: guestName,
        roomType: roomType,
        checkIn: checkIn,
        checkOut: checkOut,
      );

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BookingResultScreen(
            hotel: widget.hotel,
            booking: response,
            guestName: guestName,
            roomType: roomType,
            checkIn: checkIn,
            checkOut: checkOut,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Unable to complete the booking right now.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final rooms = _roomTypes();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Book your stay',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: const Color(0xFF172326),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            final isWide = constraints.maxWidth >= 800;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isWide ? 48 : 20,
                20,
                isWide ? 48 : 20,
                40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 900,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildHotelSummary(context),
                        const SizedBox(height: 24),
                        _buildGuestSection(context),
                        const SizedBox(height: 20),
                        if (rooms.isNotEmpty) ...[
                          _buildRoomSection(
                            context,
                            rooms,
                          ),
                          const SizedBox(height: 20),
                        ],
                        _buildDateSection(context),
                        const SizedBox(height: 24),
                        _buildConfirmSection(context),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHotelSummary(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFDCE5E4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFDFF4F1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.hotel_rounded,
              color: Color(0xFF0E7774),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _hotelName(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172326),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: Color(0xFF68777B),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _area(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF68777B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestSection(
    BuildContext context,
  ) {
    return _sectionCard(
      context,
      title: 'Guest details',
      child: TextFormField(
        controller: _guestNameController,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'Guest name',
          hintText: 'Enter the guest name',
          prefixIcon: Icon(
            Icons.person_outline_rounded,
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Enter the guest name';
          }

          return null;
        },
      ),
    );
  }

  Widget _buildRoomSection(
    BuildContext context,
    List<Map<String, dynamic>> rooms,
  ) {
    return _sectionCard(
      context,
      title: 'Choose room type',
      child: Column(
        children: rooms.map(
          (room) {
            final type =
                room['type']?.toString() ?? 'Room';

            final price = _roomPrice(room);

            final isSelected =
                _selectedRoomType == type;

            return Padding(
              padding: const EdgeInsets.only(
                bottom: 10,
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedRoomType = type;
                  });
                },
                borderRadius:
                    BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 160,
                  ),
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFDFF4F1)
                        : const Color(0xFFF7F9F8),
                    borderRadius:
                        BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF0E7774)
                          : const Color(0xFFDCE5E4),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons
                                .radio_button_checked_rounded
                            : Icons
                                .radio_button_off_rounded,
                        color:
                            const Color(0xFF0E7774),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _formatRoomType(type),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF172326),
                          ),
                        ),
                      ),
                      Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0E7774),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _buildDateSection(
    BuildContext context,
  ) {
    return _sectionCard(
      context,
      title: 'Stay dates',
      child: Row(
        children: [
          Expanded(
            child: _dateField(
              context,
              label: 'Check-in',
              icon: Icons.login_rounded,
              date: _checkInDate,
              onTap: _pickCheckInDate,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _dateField(
              context,
              label: 'Check-out',
              icon: Icons.logout_rounded,
              date: _checkOutDate,
              onTap: _pickCheckOutDate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateField(
    BuildContext context, {
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFDCE5E4),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: const Color(0xFF0E7774),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF68777B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              date == null
                  ? 'Select date'
                  : _formatDate(date),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: date == null
                    ? const Color(0xFF68777B)
                    : const Color(0xFF172326),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmSection(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF123B43),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirm your stay',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Review your details before submitting the booking.',
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
              onPressed:
                  _isBooking ? null : _submitBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFF27C4A),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    const Color(0xFF8B9799),
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
              child: _isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Confirm booking',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w700,
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

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFDCE5E4),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF172326),
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class BookingResultScreen extends StatelessWidget {
  final Map<String, dynamic> hotel;
  final Map<String, dynamic> booking;

  // These come directly from the booking form.
  final String guestName;
  final String roomType;
  final String checkIn;
  final String checkOut;

  const BookingResultScreen({
    super.key,
    required this.hotel,
    required this.booking,
    required this.guestName,
    required this.roomType,
    required this.checkIn,
    required this.checkOut,
  });

  String _hotelName() {
    return hotel['name']?.toString() ?? 'Stay';
  }

  String _bookingId() {
    return booking['id']?.toString() ??
        booking['booking_id']?.toString() ??
        'Booking created';
  }

  String _status() {
    return booking['status']?.toString() ?? 'confirmed';
  }

  String _displayRoomType() {
    return roomType
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _displayDate(String value) {
    final parsed = DateTime.tryParse(value);

    if (parsed == null) {
      return value;
    }

    final day =
        parsed.day.toString().padLeft(2, '0');
    final month =
        parsed.month.toString().padLeft(2, '0');

    return '$day/$month/${parsed.year}';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F9F8),
      appBar: AppBar(
        title: const Text(
          'Booking result',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor:
            const Color(0xFFF7F9F8),
        foregroundColor:
            const Color(0xFF172326),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 700,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  Container(
                    width: 78,
                    height: 78,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFDFF4F1,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color:
                          Color(0xFF248A67),
                      size: 48,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Booking submitted',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          Color(0xFF172326),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Your booking request for ${_hotelName()} has been created.',
                    textAlign:
                        TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color:
                          Color(0xFF68777B),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  _detailsCard(),

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.all(
                      18,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFFFF3E8,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),
                    child: const Text(
                      'This project currently uses simulated booking. No real payment or external reservation has been made.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Color(0xFF7A4A2A),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child:
                        ElevatedButton(
                      onPressed: () {
                        Navigator.popUntil(
                          context,
                          (route) =>
                              route.isFirst,
                        );
                      },
                      child: const Text(
                        'Back to stays',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailsCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              const Color(0xFFDCE5E4),
        ),
      ),
      child: Column(
        children: [
          _detailRow(
            'Booking ID',
            _bookingId(),
          ),
          _divider(),

          _detailRow(
            'Hotel',
            _hotelName(),
          ),
          _divider(),

          _detailRow(
            'Guest',
            guestName,
          ),
          _divider(),

          _detailRow(
            'Room',
            _displayRoomType(),
          ),
          _divider(),

          _detailRow(
            'Check-in',
            _displayDate(checkIn),
          ),
          _divider(),

          _detailRow(
            'Check-out',
            _displayDate(checkOut),
          ),
          _divider(),

          _detailRow(
            'Status',
            _status(),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color:
                  Color(0xFF68777B),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            value,
            textAlign:
                TextAlign.right,
            style:
                const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
              color:
                  Color(0xFF172326),
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return const Padding(
      padding:
          EdgeInsets.symmetric(
        vertical: 13,
      ),
      child: Divider(
        height: 1,
        color:
            Color(0xFFDCE5E4),
      ),
    );
  }
}