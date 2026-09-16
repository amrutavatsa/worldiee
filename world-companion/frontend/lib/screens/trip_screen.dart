import 'package:flutter/material.dart';

import '../services/api_service.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final TextEditingController _titleController = TextEditingController();

  /// Backend POIs are returned as:
  ///
  /// {
  ///   "1": {...},
  ///   "2": {...},
  ///   "3": {...}
  /// }
  ///
  /// We preserve the backend map key as the place ID.
  List<Map<String, dynamic>> _places = [];

  /// Selected place IDs.
  final Set<String> _selectedPlaceIds = <String>{};

  bool _isLoadingPlaces = true;
  bool _isCreatingTrip = false;

  Map<String, dynamic>? _createdTrip;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
    _loadSavedItinerary();
  }
  Future<void> _loadSavedItinerary() async {
  try {
    final itineraries = await ApiService.getItineraries();

    if (!mounted || itineraries.isEmpty) {
      return;
    }

    final latest = itineraries.first;

    final details = await ApiService.getItinerary(
      latest['id'].toString(),
    );

    if (!mounted) return;

    setState(() {
      _createdTrip = Map<String, dynamic>.from(details);
      _titleController.text = details['title']?.toString() ?? '';
    });
  } catch (e) {
    // Loading saved trips should not prevent the Trips screen
    // from displaying the places/create-trip interface.
  }
}

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // LOAD PLACES
  // ===========================================================================

  Future<void> _loadPlaces() async {
    if (mounted) {
      setState(() {
        _isLoadingPlaces = true;
      });
    }

    try {
      final response = await ApiService.getPois();

      final places = _extractPlaces(response);

      if (!mounted) return;

      setState(() {
        _places = places;
        _isLoadingPlaces = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _places = [];
        _isLoadingPlaces = false;
      });

      _showMessage('Could not load places.');
    }
  }

  /// Converts the backend POI map into a list for rendering.
  ///
  /// The important part is that the map key is preserved as `id`.
  List<Map<String, dynamic>> _extractPlaces(
    Map<String, dynamic> response,
  ) {
    final result = <Map<String, dynamic>>[];

    for (final entry in response.entries) {
      if (entry.value is! Map) {
        continue;
      }

      final place = Map<String, dynamic>.from(
        entry.value as Map,
      );

      // The backend uses the map key as the actual place ID.
      place['id'] = entry.key;

      result.add(place);
    }

    return result;
  }

  // ===========================================================================
  // PLACE HELPERS
  // ===========================================================================

  String _getPlaceId(
    Map<String, dynamic> place,
  ) {
    return place['id']?.toString() ?? '';
  }

  String _getPlaceName(
    Map<String, dynamic> place,
  ) {
    return place['name']?.toString() ?? 'Unknown place';
  }

  String _getPlaceCategory(
    Map<String, dynamic> place,
  ) {
    return place['category']?.toString() ?? 'Place';
  }

  IconData _getCategoryIcon(
    String category,
  ) {
    final value = category.toLowerCase();

    if (value.contains('restaurant') ||
        value.contains('food')) {
      return Icons.restaurant_outlined;
    }

    if (value.contains('park')) {
      return Icons.park_outlined;
    }

    if (value.contains('shopping')) {
      return Icons.shopping_bag_outlined;
    }

    if (value.contains('landmark')) {
      return Icons.account_balance_outlined;
    }

    if (value.contains('area')) {
      return Icons.location_city_outlined;
    }

    return Icons.place_outlined;
  }

  // ===========================================================================
  // PLACE SELECTION
  // ===========================================================================

  void _togglePlace(
    String placeId,
  ) {
    if (placeId.isEmpty) {
      return;
    }

    setState(() {
      if (_selectedPlaceIds.contains(placeId)) {
        _selectedPlaceIds.remove(placeId);
      } else {
        _selectedPlaceIds.add(placeId);
      }

      // Existing itinerary no longer represents the current selection.
      _createdTrip = null;
    });
  }

  // ===========================================================================
  // CREATE ITINERARY
  // ===========================================================================

  Future<void> _createTrip() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      _showMessage(
        'Please enter a trip name.',
      );
      return;
    }

    if (_selectedPlaceIds.isEmpty) {
      _showMessage(
        'Please select at least one place.',
      );
      return;
    }

    setState(() {
      _isCreatingTrip = true;
    });

    try {
      final stops = <Map<String, dynamic>>[];

      for (
        int index = 0;
        index < _selectedPlaceIds.length;
        index++
      ) {
        final placeId = _selectedPlaceIds.elementAt(index);

        final parsedPlaceId = int.tryParse(placeId);

        stops.add({
          'place_id': parsedPlaceId ?? placeId,
          'day_number': 1,
          'order': index + 1,
        });
      }

      final result = await ApiService.createItinerary(
        title: title,
        stops: stops,
      );

      if (!mounted) return;

      setState(() {
        _createdTrip = Map<String, dynamic>.from(result);
        _isCreatingTrip = false;
      });

      _showMessage(
        'Trip created successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCreatingTrip = false;
      });

      _showMessage(
        'Could not create the trip.',
      );
    }
  }

  // ===========================================================================
  // VIEW ITINERARY
  // ===========================================================================

  Future<void> _viewItinerary() async {
    if (_createdTrip == null) {
      return;
    }

    final itineraryId = _createdTrip!['id'];

    if (itineraryId == null) {
      _showMessage(
        'Trip ID was not returned by the server.',
      );
      return;
    }

    try {
      final details = await ApiService.getItinerary(
        itineraryId.toString(),
      );

      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return _ItineraryDetailsSheet(
            itinerary: Map<String, dynamic>.from(
              details,
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Could not load itinerary details.',
      );
    }
  }

  // ===========================================================================
  // RESET
  // ===========================================================================

  void _resetTrip() {
    setState(() {
      _titleController.clear();
      _selectedPlaceIds.clear();
      _createdTrip = null;
    });
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF123B43),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Trips'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPlaces,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              8,
              20,
              32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),

                const SizedBox(height: 24),

                _buildTripName(context),

                const SizedBox(height: 28),

                _buildPlacesHeader(context),

                const SizedBox(height: 12),

                _buildPlaces(context),

                const SizedBox(height: 24),

                _buildCreateButton(context),

                if (_createdTrip != null) ...[
                  const SizedBox(height: 24),
                  _buildCreatedTripCard(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            const Color(0xFF123B43),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.map_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Plan your next adventure',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Create an itinerary using places already available in World Companion.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TRIP NAME
  // ===========================================================================

  Widget _buildTripName(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trip name',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: _titleController,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_createdTrip != null) {
              setState(() {
                _createdTrip = null;
              });
            }
          },
          decoration: const InputDecoration(
            hintText: 'e.g. Bangalore Weekend',
            prefixIcon: Icon(
              Icons.edit_outlined,
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // PLACES HEADER
  // ===========================================================================

  Widget _buildPlacesHeader(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            'Choose places',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        if (_selectedPlaceIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_selectedPlaceIds.length} selected',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // PLACES LIST
  // ===========================================================================

  Widget _buildPlaces(
    BuildContext context,
  ) {
    if (_isLoadingPlaces) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 40,
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_places.isEmpty) {
      return _buildEmptyPlaces(context);
    }

    return Column(
      children: _places.map(
        (place) {
          return _buildPlaceCard(
            context,
            place,
          );
        },
      ).toList(),
    );
  }

  // ===========================================================================
  // PLACE CARD
  // ===========================================================================

  Widget _buildPlaceCard(
    BuildContext context,
    Map<String, dynamic> place,
  ) {
    final theme = Theme.of(context);

    final placeId = _getPlaceId(place);
    final name = _getPlaceName(place);
    final category = _getPlaceCategory(place);

    final selected =
        placeId.isNotEmpty &&
        _selectedPlaceIds.contains(placeId);

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          // IMPORTANT:
          // The entire card is clickable.
          onTap: placeId.isEmpty
              ? null
              : () => _togglePlace(placeId),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 180,
            ),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primary.withOpacity(0.06)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : const Color(0xFFDCE5E4),
                width: selected ? 1.5 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(
                          0,
                          4,
                        ),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary.withOpacity(0.12)
                        : const Color(0xFFF7F9F8),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: selected
                        ? theme.colorScheme.primary
                        : const Color(0xFF68777B),
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF68777B),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 180,
                  ),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? theme.colorScheme.primary
                          : const Color(0xFFB8C5C4),
                      width: 1.5,
                    ),
                  ),
                  child: selected
                      ? const Icon(
                          Icons.check_rounded,
                          size: 17,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================

  Widget _buildEmptyPlaces(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDCE5E4),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 42,
            color: Color(0xFF68777B),
          ),

          SizedBox(height: 12),

          Text(
            'No places available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'No POIs were returned by the existing backend.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF68777B),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // CREATE BUTTON
  // ===========================================================================

  Widget _buildCreateButton(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isCreatingTrip
            ? null
            : _createTrip,
        icon: _isCreatingTrip
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.add_road,
              ),
        label: Text(
          _isCreatingTrip
              ? 'Creating trip...'
              : 'Create trip',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              theme.colorScheme.primary.withOpacity(0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // CREATED TRIP CARD
  // ===========================================================================

  Widget _buildCreatedTripCard(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    final title =
        _createdTrip?['title']?.toString() ??
        _titleController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFDCE5E4),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(
              0,
              8,
            ),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF4F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  'Trip created',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '${_selectedPlaceIds.length} places added',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF68777B),
            ),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _viewItinerary,
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 18,
                  ),
                  label: const Text(
                    'View itinerary',
                  ),
                ),
              ),

              const SizedBox(width: 10),

              IconButton(
                tooltip: 'Create another trip',
                onPressed: _resetTrip,
                icon: const Icon(
                  Icons.refresh,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ITINERARY DETAILS SHEET
// =============================================================================

// =============================================================================
// ITINERARY DETAILS SHEET
// =============================================================================

class _ItineraryDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> itinerary;

  const _ItineraryDetailsSheet({
    required this.itinerary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final title =
        itinerary['title']?.toString() ?? 'My Trip';

    final days = itinerary['days'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD0D9D8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Your saved itinerary',
                style: TextStyle(
                  color: Color(0xFF68777B),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: _buildDays(
                  context,
                  days,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // DAYS
  // ===========================================================================

  Widget _buildDays(
    BuildContext context,
    dynamic days,
  ) {
    final normalizedDays = _normalizeDays(days);

    if (normalizedDays.isEmpty) {
      return const Center(
        child: Text(
          'No itinerary stops available.',
          style: TextStyle(
            color: Color(0xFF68777B),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: normalizedDays.length,
      separatorBuilder: (_, __) {
        return const SizedBox(height: 16);
      },
      itemBuilder: (context, index) {
        final day = normalizedDays[index];

        return _buildDayCard(
          context,
          day,
        );
      },
    );
  }

  // ===========================================================================
  // NORMALIZE BACKEND DAYS
  // ===========================================================================

  List<Map<String, dynamic>> _normalizeDays(
    dynamic days,
  ) {
    final result = <Map<String, dynamic>>[];

    // -------------------------------------------------------------------------
    // Backend's actual format:
    //
    // {
    //   "1": [
    //     {
    //       "place": "Indiranagar",
    //       "scheduled_time": "",
    //       "notes": ""
    //     },
    //     ...
    //   ]
    // }
    // -------------------------------------------------------------------------

    if (days is Map) {
      final entries = days.entries.toList();

      entries.sort((a, b) {
        final aDay =
            int.tryParse(a.key.toString()) ?? 0;

        final bDay =
            int.tryParse(b.key.toString()) ?? 0;

        return aDay.compareTo(bDay);
      });

      for (final entry in entries) {
        final dayNumber = entry.key.toString();

        final rawStops = entry.value;

        final stops = <dynamic>[];

        if (rawStops is List) {
          stops.addAll(rawStops);
        } else if (rawStops is Map) {
          stops.add(rawStops);
        }

        result.add({
          'day_number': dayNumber,
          'stops': stops,
        });
      }

      return result;
    }

    // -------------------------------------------------------------------------
    // Also support a List format if the backend ever returns one.
    // -------------------------------------------------------------------------

    if (days is List) {
      for (int index = 0; index < days.length; index++) {
        final rawDay = days[index];

        if (rawDay is Map) {
          final day =
              Map<String, dynamic>.from(rawDay);

          day['day_number'] ??= index + 1;

          result.add(day);
        }
      }
    }

    return result;
  }

  // ===========================================================================
  // DAY CARD
  // ===========================================================================

  Widget _buildDayCard(
    BuildContext context,
    Map<String, dynamic> day,
  ) {
    final theme = Theme.of(context);

    final dayNumber =
        day['day_number']?.toString() ?? '1';

    final stops = day['stops'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDCE5E4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day heading
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  dayNumber,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Text(
                'Day $dayNumber',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (stops is List && stops.isNotEmpty)
            ...List.generate(
              stops.length,
              (index) {
                return _buildStop(
                  context,
                  stops[index],
                  index,
                  isLast: index == stops.length - 1,
                );
              },
            )
          else
            const Text(
              'No stops planned.',
              style: TextStyle(
                color: Color(0xFF68777B),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STOP
  // ===========================================================================

  Widget _buildStop(
    BuildContext context,
    dynamic rawStop,
    int index, {
    required bool isLast,
  }) {
    if (rawStop is! Map) {
      return const SizedBox.shrink();
    }

    final stop =
        Map<String, dynamic>.from(rawStop);

    // IMPORTANT:
    // Backend returns:
    //
    // "place": "Indiranagar"
    //
    // NOT:
    //
    // "place": {"name": "Indiranagar"}
    //
    String placeName =
        stop['place']?.toString() ??
        stop['place_name']?.toString() ??
        stop['name']?.toString() ??
        'Place ${index + 1}';

    final scheduledTime =
        stop['scheduled_time']?.toString() ?? '';

    final notes =
        stop['notes']?.toString() ?? '';

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),

              if (!isLast)
                Container(
                  width: 1,
                  height: 28,
                  color: const Color(0xFFDCE5E4),
                ),
            ],
          ),

          const SizedBox(width: 14),

          // Stop information
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 5,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    placeName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  if (scheduledTime.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 14,
                          color: Color(0xFF68777B),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          scheduledTime,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF68777B),
                          ),
                        ),
                      ],
                    ),
                  ],

                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notes,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF68777B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}