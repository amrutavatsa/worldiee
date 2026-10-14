import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/api_service.dart';
import '../theme/world_companion_colors.dart';
import '../theme/world_companion_elevation.dart';
import '../theme/world_companion_motion.dart';
import '../theme/world_companion_radius.dart';
import '../theme/world_companion_spacing.dart';
import '../theme/world_companion_typography.dart';
import 'app_shell.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final TextEditingController _titleController =
      TextEditingController();

  List<Map<String, dynamic>> _places = [];
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

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // LOAD SAVED ITINERARY
  // ---------------------------------------------------------------------------

  Future<void> _loadSavedItinerary() async {
    try {
      final itineraries = await ApiService.getItineraries();

      if (!mounted || itineraries.isEmpty) return;

      final latest = itineraries.first;
      final details = await ApiService.getItinerary(
        latest['id'].toString(),
      );

      if (!mounted) return;

      setState(() {
        _createdTrip = Map<String, dynamic>.from(details);
        _titleController.text = details['title']?.toString() ?? '';
      });
    } catch (_) {
      // The screen remains usable if saved itineraries cannot load.
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD PLACES
  // ---------------------------------------------------------------------------

  Future<void> _loadPlaces() async {
    if (mounted) {
      setState(() => _isLoadingPlaces = true);
    }

    List<Map<String, dynamic>> places = [];
    String? notice;

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is unavailable.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 15));

      final nearby = await ApiService.getNearbyPlaces(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 10.0,
      );

      places = nearby.map((item) {
        final place = Map<String, dynamic>.from(item as Map);
        final providerId =
            (place['provider_id'] ?? place['id'] ?? '')
                .toString()
                .trim();
        final name = (place['name'] ?? '').toString().trim();
        final latitude = place['latitude'];
        final longitude = place['longitude'];
        final stableKey = providerId.isNotEmpty
            ? providerId
            : '${name}_${latitude}_$longitude';

        place['provider_id'] = providerId;
        place['id'] = 'external:$stableKey';
        place['is_external'] = true;
        return place;
      }).where((place) {
        return (place['name'] ?? '').toString().trim().isNotEmpty &&
            place['latitude'] != null &&
            place['longitude'] != null;
      }).toList();

      if (places.isEmpty) {
        places = _extractPlaces(await ApiService.getPois());
        notice = 'No nearby results; showing curated places.';
      }
    } catch (_) {
      try {
        places = _extractPlaces(await ApiService.getPois());
        notice = 'Nearby discovery unavailable; showing curated places.';
      } catch (_) {
        places = [];
        notice = 'Could not load places.';
      }
    }

    if (!mounted) return;

    setState(() {
      _places = places;
      _isLoadingPlaces = false;
    });

    if (notice != null) {
      _showMessage(notice);
    }
  }

  List<Map<String, dynamic>> _extractPlaces(
    Map<String, dynamic> response,
  ) {
    final result = <Map<String, dynamic>>[];

    for (final entry in response.entries) {
      if (entry.value is! Map) continue;

      final place = Map<String, dynamic>.from(
        entry.value as Map,
      );

      // Preserve the backend map key as the actual place ID.
      place['id'] = entry.key;
      result.add(place);
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // PLACE HELPERS
  // ---------------------------------------------------------------------------

  String _getPlaceId(Map<String, dynamic> place) =>
      place['id']?.toString() ?? '';

  String _getPlaceName(Map<String, dynamic> place) =>
      place['name']?.toString() ?? 'Unknown place';

  String _getPlaceCategory(Map<String, dynamic> place) =>
      place['category']?.toString() ?? 'Place';

  IconData _getCategoryIcon(String category) {
    final value = category.toLowerCase();

    if (value.contains('restaurant') || value.contains('food')) {
      return Icons.restaurant_outlined;
    }
    if (value.contains('park')) return Icons.park_outlined;
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

  // ---------------------------------------------------------------------------
  // PLACE SELECTION
  // ---------------------------------------------------------------------------

  void _togglePlace(String placeId) {
    if (placeId.isEmpty) return;

    setState(() {
      if (_selectedPlaceIds.contains(placeId)) {
        _selectedPlaceIds.remove(placeId);
      } else {
        _selectedPlaceIds.add(placeId);
      }

      _createdTrip = null;
    });
  }

  // ---------------------------------------------------------------------------
  // CREATE TRIP
  // ---------------------------------------------------------------------------

  Future<void> _createTrip() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      _showMessage('Please enter a trip name.');
      return;
    }

    if (_selectedPlaceIds.isEmpty) {
      _showMessage('Please select at least one place.');
      return;
    }

    setState(() => _isCreatingTrip = true);

    try {
      final stops = <Map<String, dynamic>>[];
      final selectedIds = _selectedPlaceIds.toList();

      for (int index = 0; index < selectedIds.length; index++) {
        final selectedId = selectedIds[index];
        final place = _places.firstWhere(
          (candidate) => _getPlaceId(candidate) == selectedId,
          orElse: () => <String, dynamic>{},
        );

        if (place.isEmpty) {
          throw Exception('A selected place is no longer available.');
        }

        final stop = <String, dynamic>{
          'day_number': 1,
          'order': index + 1,
        };

        if (place['is_external'] == true) {
          stop.addAll({
            'external_place_id':
                (place['provider_id'] ?? '').toString(),
            'external_place_name': _getPlaceName(place),
            'external_place_category': _getPlaceCategory(place),
            'external_place_latitude': place['latitude'],
            'external_place_longitude': place['longitude'],
            'external_place_address':
                (place['address'] ?? '').toString(),
          });
        } else {
          // Local Place IDs are strings, not integers.
          stop['place_id'] = selectedId;
        }

        stops.add(stop);
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

      _showMessage('Trip created successfully.');
    } catch (_) {
      if (!mounted) return;

      setState(() => _isCreatingTrip = false);
      _showMessage('Could not create the trip.');
    }
  }

  // VIEW ITINERARY
  // ---------------------------------------------------------------------------

  Future<void> _viewItinerary() async {
    if (_createdTrip == null) return;

    final itineraryId = _createdTrip!['id'];

    if (itineraryId == null) {
      _showMessage('Trip ID was not returned by the server.');
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
        builder: (_) => _ItineraryDetailsSheet(
          itinerary: Map<String, dynamic>.from(details),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not load itinerary details.');
    }
  }

  // ---------------------------------------------------------------------------
  // RESET
  // ---------------------------------------------------------------------------

  void _resetTrip() {
    setState(() {
      _titleController.clear();
      _selectedPlaceIds.clear();
      _createdTrip = null;
    });
  }

  // ---------------------------------------------------------------------------
  // FEEDBACK
  // ---------------------------------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: WorldCompanionColors.deepOcean,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              WorldCompanionRadius.medium,
            ),
          ),
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // SCREEN
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorldCompanionColors.softWhite,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Home',
          onPressed: () => AppShellNavigation.of(context).goHome(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          'My trips',
          style: WorldCompanionTypography.textTheme.titleLarge,
        ),
        backgroundColor: WorldCompanionColors.softWhite,
        surfaceTintColor: Colors.transparent,
        elevation: WorldCompanionElevation.none,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPlaces,
          color: WorldCompanionColors.oceanBlue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              WorldCompanionSpacing.mobilePage,
              WorldCompanionSpacing.xs,
              WorldCompanionSpacing.mobilePage,
              WorldCompanionSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: WorldCompanionSpacing.xl),
                _buildTripName(context),
                const SizedBox(height: WorldCompanionSpacing.xl),
                _buildPlacesHeader(context),
                const SizedBox(height: WorldCompanionSpacing.md),
                _buildPlaces(context),
                const SizedBox(height: WorldCompanionSpacing.lg),
                _buildCreateButton(),
                if (_createdTrip != null) ...[
                  const SizedBox(height: WorldCompanionSpacing.lg),
                  _buildCreatedTripCard(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HERO
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WorldCompanionColors.deepOcean,
            WorldCompanionColors.oceanBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            top: -12,
            child: Icon(
              Icons.explore_outlined,
              size: 112,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(
                    WorldCompanionRadius.medium,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.16),
                  ),
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(height: WorldCompanionSpacing.lg),
              Text(
                'Your next adventure starts here.',
                style: WorldCompanionTypography.textTheme.headlineMedium
                    ?.copyWith(
                  color: Colors.white,
                  height: 1.22,
                ),
              ),
              const SizedBox(height: WorldCompanionSpacing.sm),
              Text(
                'Build a trip from places available in WorldCompanion and keep your itinerary together.',
                style: WorldCompanionTypography.textTheme.bodyMedium
                    ?.copyWith(
                  color: Colors.white.withOpacity(0.82),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: WorldCompanionSpacing.lg),
              Row(
                children: [
                  _HeroStat(
                    icon: Icons.place_outlined,
                    label: '${_places.length} places',
                  ),
                  const SizedBox(width: WorldCompanionSpacing.md),
                  _HeroStat(
                    icon: Icons.check_circle_outline,
                    label: '${_selectedPlaceIds.length} selected',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TRIP NAME
  // ---------------------------------------------------------------------------

  Widget _buildTripName(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Name your trip',
          style: WorldCompanionTypography.textTheme.titleLarge,
        ),
        const SizedBox(height: WorldCompanionSpacing.xs),
        Text(
          'Give this adventure a name you will remember.',
          style: WorldCompanionTypography.textTheme.bodyMedium,
        ),
        const SizedBox(height: WorldCompanionSpacing.md),
        TextField(
          controller: _titleController,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_createdTrip != null) {
              setState(() => _createdTrip = null);
            }
          },
          decoration: InputDecoration(
            hintText: 'e.g. Bangalore weekend',
            prefixIcon: const Icon(Icons.edit_location_alt_outlined),
            filled: true,
            fillColor: WorldCompanionColors.surface,
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
                color: WorldCompanionColors.oceanBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PLACES HEADER
  // ---------------------------------------------------------------------------

  Widget _buildPlacesHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose your stops',
                style: WorldCompanionTypography.textTheme.titleLarge,
              ),
              const SizedBox(height: WorldCompanionSpacing.xxs),
              Text(
                'Select the places you want to visit.',
                style: WorldCompanionTypography.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        if (_selectedPlaceIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WorldCompanionSpacing.sm,
              vertical: WorldCompanionSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: WorldCompanionColors.infoSurface,
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.pill,
              ),
              border: Border.all(
                color: WorldCompanionColors.softBlue.withOpacity(0.45),
              ),
            ),
            child: Text(
              '${_selectedPlaceIds.length} selected',
              style: WorldCompanionTypography.textTheme.labelMedium
                  ?.copyWith(
                color: WorldCompanionColors.oceanBlue,
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PLACES LIST
  // ---------------------------------------------------------------------------

  Widget _buildPlaces(BuildContext context) {
    if (_isLoadingPlaces) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: WorldCompanionSpacing.xxxl,
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: WorldCompanionColors.oceanBlue,
          ),
        ),
      );
    }

    if (_places.isEmpty) {
      return _buildEmptyPlaces(context);
    }

    return Column(
      children: _places.map((place) {
        return _buildPlaceCard(context, place);
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // PLACE CARD
  // ---------------------------------------------------------------------------

  Widget _buildPlaceCard(
    BuildContext context,
    Map<String, dynamic> place,
  ) {
    final placeId = _getPlaceId(place);
    final name = _getPlaceName(place);
    final category = _getPlaceCategory(place);

    final selected = placeId.isNotEmpty &&
        _selectedPlaceIds.contains(placeId);

    return Padding(
      padding: const EdgeInsets.only(
        bottom: WorldCompanionSpacing.sm,
      ),
      child: Material(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.large,
        ),
        child: InkWell(
          onTap: placeId.isEmpty ? null : () => _togglePlace(placeId),
          borderRadius: BorderRadius.circular(
            WorldCompanionRadius.large,
          ),
          child: AnimatedContainer(
            duration: WorldCompanionMotion.standard,
            curve: WorldCompanionMotion.standardCurve,
            width: double.infinity,
            padding: const EdgeInsets.all(
              WorldCompanionSpacing.md,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? WorldCompanionColors.infoSurface
                  : WorldCompanionColors.surface,
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.large,
              ),
              border: Border.all(
                color: selected
                    ? WorldCompanionColors.oceanBlue
                    : WorldCompanionColors.border,
                width: selected ? 1.5 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: WorldCompanionColors.oceanBlue
                            .withOpacity(0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: WorldCompanionMotion.standard,
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected
                        ? WorldCompanionColors.oceanBlue
                            .withOpacity(0.10)
                        : WorldCompanionColors.aiSurface,
                    borderRadius: BorderRadius.circular(
                      WorldCompanionRadius.medium,
                    ),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: selected
                        ? WorldCompanionColors.oceanBlue
                        : WorldCompanionColors.secondaryText,
                    size: 23,
                  ),
                ),
                const SizedBox(width: WorldCompanionSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: WorldCompanionTypography.textTheme.titleMedium
                            ?.copyWith(
                          color: WorldCompanionColors.deepOcean,
                        ),
                      ),
                      const SizedBox(height: WorldCompanionSpacing.xxs),
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WorldCompanionTypography.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: WorldCompanionSpacing.sm),
                AnimatedContainer(
                  duration: WorldCompanionMotion.standard,
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? WorldCompanionColors.oceanBlue
                        : Colors.transparent,
                    border: Border.all(
                      color: selected
                          ? WorldCompanionColors.oceanBlue
                          : WorldCompanionColors.border,
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

  // ---------------------------------------------------------------------------
  // EMPTY PLACES
  // ---------------------------------------------------------------------------

  Widget _buildEmptyPlaces(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorldCompanionSpacing.xl),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.large,
        ),
        border: Border.all(color: WorldCompanionColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: WorldCompanionColors.aiSurface,
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.large,
              ),
            ),
            child: const Icon(
              Icons.location_off_outlined,
              size: 28,
              color: WorldCompanionColors.secondaryText,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          Text(
            'No places available',
            style: WorldCompanionTypography.textTheme.titleMedium,
          ),
          const SizedBox(height: WorldCompanionSpacing.xs),
          Text(
            'The existing backend did not return any places. Try refreshing to load them again.',
            textAlign: TextAlign.center,
            style: WorldCompanionTypography.textTheme.bodyMedium,
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          OutlinedButton.icon(
            onPressed: _loadPlaces,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Refresh places'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CREATE BUTTON
  // ---------------------------------------------------------------------------

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isCreatingTrip ? null : _createTrip,
        icon: _isCreatingTrip
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_road_rounded),
        label: Text(
          _isCreatingTrip ? 'Creating trip...' : 'Create my trip',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: WorldCompanionColors.deepOcean,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              WorldCompanionColors.deepOcean.withOpacity(0.55),
          elevation: WorldCompanionElevation.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              WorldCompanionRadius.medium,
            ),
          ),
          textStyle: WorldCompanionTypography.textTheme.labelLarge,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CREATED TRIP
  // ---------------------------------------------------------------------------

  Widget _buildCreatedTripCard(BuildContext context) {
    final title = _createdTrip?['title']?.toString() ??
        _titleController.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
        border: Border.all(color: WorldCompanionColors.border),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 6),
            color: WorldCompanionColors.deepOcean.withOpacity(0.05),
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
                  color: WorldCompanionColors.successSurface,
                  borderRadius: BorderRadius.circular(
                    WorldCompanionRadius.medium,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: WorldCompanionColors.success,
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip created',
                      style: WorldCompanionTypography.textTheme.titleMedium,
                    ),
                    const SizedBox(height: WorldCompanionSpacing.xxs),
                    Text(
                      'Your itinerary is ready to view.',
                      style: WorldCompanionTypography.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: WorldCompanionSpacing.lg),
          Text(
            title,
            style: WorldCompanionTypography.textTheme.headlineSmall,
          ),
          const SizedBox(height: WorldCompanionSpacing.xs),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 17,
                color: WorldCompanionColors.secondaryText,
              ),
              const SizedBox(width: WorldCompanionSpacing.xs),
              Text(
                '${_selectedPlaceIds.length} places selected',
                style: WorldCompanionTypography.textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: WorldCompanionSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _viewItinerary,
                  icon: const Icon(
                    Icons.visibility_outlined,
                    size: 18,
                  ),
                  label: const Text('View itinerary'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: WorldCompanionColors.oceanBlue,
                    side: const BorderSide(
                      color: WorldCompanionColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        WorldCompanionRadius.medium,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.sm),
              IconButton(
                tooltip: 'Create another trip',
                onPressed: _resetTrip,
                style: IconButton.styleFrom(
                  backgroundColor: WorldCompanionColors.aiSurface,
                  foregroundColor: WorldCompanionColors.deepOcean,
                ),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HERO STAT
// =============================================================================

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroStat({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WorldCompanionSpacing.sm,
        vertical: WorldCompanionSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.pill,
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: WorldCompanionSpacing.xs),
          Text(
            label,
            style: WorldCompanionTypography.textTheme.labelMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final title = itinerary['title']?.toString() ?? 'My Trip';
    final days = itinerary['days'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: WorldCompanionColors.softWhite,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(WorldCompanionRadius.extraLarge),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            WorldCompanionSpacing.mobilePage,
            WorldCompanionSpacing.md,
            WorldCompanionSpacing.mobilePage,
            WorldCompanionSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: WorldCompanionColors.border,
                    borderRadius: BorderRadius.circular(
                      WorldCompanionRadius.pill,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: WorldCompanionSpacing.lg),
              Text(
                title,
                style: WorldCompanionTypography.textTheme.headlineMedium,
              ),
              const SizedBox(height: WorldCompanionSpacing.xs),
              Text(
                'Your saved itinerary',
                style: WorldCompanionTypography.textTheme.bodyMedium,
              ),
              const SizedBox(height: WorldCompanionSpacing.lg),
              Expanded(
                child: _buildDays(context, days),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DAYS
  // ---------------------------------------------------------------------------

  Widget _buildDays(BuildContext context, dynamic days) {
    final normalizedDays = _normalizeDays(days);

    if (normalizedDays.isEmpty) {
      return Center(
        child: Text(
          'No itinerary stops available.',
          style: WorldCompanionTypography.textTheme.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      itemCount: normalizedDays.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: WorldCompanionSpacing.md),
      itemBuilder: (context, index) {
        return _buildDayCard(context, normalizedDays[index]);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // NORMALIZE BACKEND DAYS
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _normalizeDays(dynamic days) {
    final result = <Map<String, dynamic>>[];

    if (days is Map) {
      final entries = days.entries.toList();

      entries.sort((a, b) {
        final aDay = int.tryParse(a.key.toString()) ?? 0;
        final bDay = int.tryParse(b.key.toString()) ?? 0;
        return aDay.compareTo(bDay);
      });

      for (final entry in entries) {
        final rawStops = entry.value;
        final stops = <dynamic>[];

        if (rawStops is List) {
          stops.addAll(rawStops);
        } else if (rawStops is Map) {
          stops.add(rawStops);
        }

        result.add({
          'day_number': entry.key.toString(),
          'stops': stops,
        });
      }

      return result;
    }

    if (days is List) {
      for (int index = 0; index < days.length; index++) {
        final rawDay = days[index];

        if (rawDay is Map) {
          final day = Map<String, dynamic>.from(rawDay);
          day['day_number'] ??= index + 1;
          result.add(day);
        }
      }
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // DAY CARD
  // ---------------------------------------------------------------------------

  Widget _buildDayCard(
    BuildContext context,
    Map<String, dynamic> day,
  ) {
    final dayNumber = day['day_number']?.toString() ?? '1';
    final stops = day['stops'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.large,
        ),
        border: Border.all(color: WorldCompanionColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WorldCompanionColors.infoSurface,
                  borderRadius: BorderRadius.circular(
                    WorldCompanionRadius.medium,
                  ),
                ),
                child: Text(
                  dayNumber,
                  style: WorldCompanionTypography.textTheme.titleMedium
                      ?.copyWith(
                    color: WorldCompanionColors.oceanBlue,
                  ),
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.md),
              Text(
                'Day $dayNumber',
                style: WorldCompanionTypography.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: WorldCompanionSpacing.lg),
          if (stops is List && stops.isNotEmpty)
            ...List.generate(
              stops.length,
              (index) => _buildStop(
                context,
                stops[index],
                index,
                isLast: index == stops.length - 1,
              ),
            )
          else
            Text(
              'No stops planned.',
              style: WorldCompanionTypography.textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STOP
  // ---------------------------------------------------------------------------

  Widget _buildStop(
    BuildContext context,
    dynamic rawStop,
    int index, {
    required bool isLast,
  }) {
    if (rawStop is! Map) return const SizedBox.shrink();

    final stop = Map<String, dynamic>.from(rawStop);

    final placeName = stop['place']?.toString() ??
        stop['place_name']?.toString() ??
        stop['name']?.toString() ??
        'Place ${index + 1}';

    final scheduledTime = stop['scheduled_time']?.toString() ?? '';
    final notes = stop['notes']?.toString() ?? '';

    return Padding(
      padding: EdgeInsets.only(
        bottom: isLast ? 0 : WorldCompanionSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: WorldCompanionColors.infoSurface,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: WorldCompanionTypography.textTheme.labelLarge
                      ?.copyWith(
                    color: WorldCompanionColors.oceanBlue,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 1.5,
                  height: 28,
                  color: WorldCompanionColors.border,
                ),
            ],
          ),
          const SizedBox(width: WorldCompanionSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: WorldCompanionSpacing.xxs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    placeName,
                    style: WorldCompanionTypography.textTheme.titleMedium,
                  ),
                  if (scheduledTime.isNotEmpty) ...[
                    const SizedBox(height: WorldCompanionSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 15,
                          color: WorldCompanionColors.mutedText,
                        ),
                        const SizedBox(width: WorldCompanionSpacing.xs),
                        Expanded(
                          child: Text(
                            scheduledTime,
                            style: WorldCompanionTypography
                                .textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: WorldCompanionSpacing.xs),
                    Text(
                      notes,
                      style: WorldCompanionTypography.textTheme.bodySmall,
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
