
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../services/api_service.dart';
import '../widgets/world_map.dart';
import 'place_details_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const Color _primary = Color(0xFF0B2545);
  static const Color _secondary = Color(0xFF134074);
  static const Color _surface = Color(0xFFEEF4ED);
  static const Color _chipBackground = Color(0xFFEAF0F7);

  static const List<String> _categories = [
    'All',
    'Parks',
    'Food',
    'Stays',
    'Shopping',
    'Landmarks',
    'Areas',
  ];

  // These values are sent to the existing Django nearby endpoint.
  // They must match the category keys accepted by the backend view.
  static const Map<String, String> _apiCategoryMap = {
    'Parks': 'park',
    'Food': 'food',
    'Stays': 'hotel',
    'Shopping': 'shopping',
    'Landmarks': 'landmark',
  };

  final TextEditingController _searchController =
      TextEditingController();

  final ScrollController _cardsController = ScrollController();

  List<Map<String, dynamic>> _nearbyPlaces = [];
  Position? _currentPosition;

  String _selectedCategory = 'All';
  String _loadedForCategory = 'All';
  String _searchQuery = '';
  String? _errorMessage;

  bool _isLoading = true;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadNearbyPlaces(category: 'All');
  }

  @override
  void dispose() {
    // Invalidate pending requests before disposing the screen.
    _requestId++;
    _searchController.dispose();
    _cardsController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Nearby places
  // ---------------------------------------------------------------------------

  Future<void> _loadNearbyPlaces({String? category}) async {
    if (!mounted) return;

    final requestedCategory = category ?? _selectedCategory;
    final requestId = ++_requestId;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _nearbyPlaces = [];
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Enable GPS or location services to discover nearby places.',
        );
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission is unavailable. Enable location access '
          'in your device or browser settings.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted || requestId != _requestId) return;

      setState(() {
        _currentPosition = position;
      });

      final apiCategory = _apiCategoryMap[requestedCategory];

      debugPrint(
        '[Explore] Requesting category: $requestedCategory',
      );
      debugPrint(
        '[Explore] API category parameter: '
        '${apiCategory ?? "none (all places)"}',
      );
      debugPrint(
        '[Explore] Coordinates: '
        '${position.latitude}, ${position.longitude}',
      );

      // Real-world nearby places only.
      // Do not merge in ApiService.getPois(), which contains predefined POIs.
      //
      // Areas uses the unfiltered nearby result and filters it locally because
      // it does not have a dedicated category entry in _apiCategoryMap.
      final response = await ApiService.getNearbyPlaces(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 10.0,
        category: apiCategory,
      );

      if (!mounted || requestId != _requestId) return;

      final normalizedPlaces = response
          .whereType<Map>()
          .map(
            (item) => _normalizePlace(
              Map<String, dynamic>.from(item),
            ),
          )
          .where(_isUsablePlace)
          .toList();

      final uniquePlaces = _deduplicatePlaces(normalizedPlaces);

      debugPrint(
        '[Explore] Raw API result count: ${response.length}',
      );
      debugPrint(
        '[Explore] Usable unique places: ${uniquePlaces.length}',
      );
      debugPrint(
        '[Explore] Results: '
        '${uniquePlaces.map(_placeName).toList()}',
      );

      setState(() {
        _nearbyPlaces = uniquePlaces;
        _loadedForCategory = requestedCategory;
        _isLoading = false;

        _errorMessage = uniquePlaces.isEmpty
            ? requestedCategory == 'All'
                ? 'The nearby API returned no usable places. '
                    'Try refreshing or check your location.'
                : 'The API returned no places for $requestedCategory. '
                    'Try All or refresh.'
            : null;
      });
    } catch (error, stackTrace) {
      debugPrint('[Explore] Nearby request error: $error');
      debugPrint('$stackTrace');

      if (!mounted || requestId != _requestId) return;

      setState(() {
        _nearbyPlaces = [];
        _loadedForCategory = requestedCategory;
        _isLoading = false;
        _errorMessage = _friendlyError(error);
      });
    }
  }

  String _friendlyError(Object error) {
    final message =
        error.toString().replaceFirst('Exception: ', '').trim();

    if (message.contains('SocketException') ||
        message.contains('Failed host lookup')) {
      return 'Cannot reach the nearby places service. '
          'Check your internet connection and API address.';
    }

    if (message.contains('TimeoutException') ||
        message.contains('timed out')) {
      return 'The nearby places service timed out. Please try again.';
    }

    if (message.contains('API error 401') ||
        message.contains('API error 403')) {
      return 'The nearby places service rejected the request. '
          'Check authentication and backend permissions.';
    }

    return message.isEmpty
        ? 'Could not load nearby places.'
        : message;
  }

  // The existing ApiService returns List<dynamic>, with each item expected
  // to be a place object. This normalizer also supports GeoJSON Features.
  Map<String, dynamic> _normalizePlace(
    Map<String, dynamic> source,
  ) {
    final properties = source['properties'];

    if (properties is Map) {
      final place = Map<String, dynamic>.from(properties);

      // Preserve useful fields that may exist on the outer Feature.
      place.putIfAbsent('id', () => source['id']);
      place['_geometry'] = source['geometry'];
      place['_source'] = 'nearby';

      return place;
    }

    source['_source'] = 'nearby';
    return source;
  }

  bool _isUsablePlace(Map<String, dynamic> place) {
    if (_placeName(place).trim().isEmpty) return false;

    final coordinates = _coordinates(place);

    return _firstString(place, [
          'place_id',
          'placeId',
          'provider_id',
          'geoapify_id',
          'fsq_id',
          'id',
        ]).isNotEmpty ||
        coordinates != null ||
        _placeAddress(place).isNotEmpty;
  }

  List<Map<String, dynamic>> _deduplicatePlaces(
    List<Map<String, dynamic>> places,
  ) {
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];

    for (final place in places) {
      final id = _firstString(place, [
        'place_id',
        'placeId',
        'provider_id',
        'geoapify_id',
        'fsq_id',
        'id',
      ]);

      final coordinates = _coordinates(place);

      final key = id.isNotEmpty
          ? 'id:${id.toLowerCase()}'
          : coordinates != null
              ? 'geo:${coordinates.$1.toStringAsFixed(5)},'
                  '${coordinates.$2.toStringAsFixed(5)}'
              : 'name:${_normalize(_placeName(place))}|'
                  '${_normalize(_placeAddress(place))}';

      if (seen.add(key)) {
        result.add(place);
      }
    }

    result.sort((a, b) {
      final distanceA = _distanceKm(a);
      final distanceB = _distanceKm(b);

      if (distanceA == null && distanceB == null) return 0;
      if (distanceA == null) return 1;
      if (distanceB == null) return -1;

      return distanceA.compareTo(distanceB);
    });

    return result;
  }

  // ---------------------------------------------------------------------------
  // Category and text helpers
  // ---------------------------------------------------------------------------

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _firstString(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = map[key];

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }

      if (value is num) {
        return value.toString();
      }
    }

    return '';
  }

  // Read category metadata only. Never infer a category from the place name
  // or address: for example, a road named "Park Road" is not a park.
  void _collectCategoryValues(
    dynamic value,
    List<String> output,
  ) {
    if (value == null) return;

    if (value is String || value is num) {
      final normalized = _normalize(value.toString());
      if (normalized.isNotEmpty) output.add(normalized);
      return;
    }

    if (value is List) {
      for (final item in value) {
        _collectCategoryValues(item, output);
      }
      return;
    }

    if (value is Map) {
      const categoryKeys = {
        'geoapify_categories',
        'categories',
        'category',
        'subcategory',
        'type',
        'class',
        'kind',
      };

      for (final entry in value.entries) {
        if (categoryKeys.contains(
          entry.key.toString().toLowerCase(),
        )) {
          _collectCategoryValues(entry.value, output);
        }
      }
    }
  }

  List<String> _categoryMetadata(
    Map<String, dynamic> place,
  ) {
    final values = <String>[];

    for (final key in [
      'category',
      'subcategory',
      'type',
      'categories',
      'geoapify_categories',
    ]) {
      if (place.containsKey(key)) {
        _collectCategoryValues(place[key], values);
      }
    }

    final tags = place['tags'];
    if (tags is Map) {
      _collectCategoryValues(tags, values);
    }

    final properties = place['properties'];
    if (properties is Map) {
      for (final key in [
        'category',
        'subcategory',
        'type',
        'categories',
        'geoapify_categories',
      ]) {
        if (properties.containsKey(key)) {
          _collectCategoryValues(properties[key], values);
        }
      }

      final nestedTags = properties['tags'];
      if (nestedTags is Map) {
        _collectCategoryValues(nestedTags, values);
      }
    }

    return values.toSet().toList();
  }

  bool _hasCategory(
    List<String> metadata,
    List<String> accepted,
  ) {
    for (final value in metadata) {
      for (final category in accepted) {
        final expected = _normalize(category);

        if (value == expected ||
            value.startsWith('$expected ') ||
            value.contains(' $expected ')) {
          return true;
        }
      }
    }

    return false;
  }

  bool _isArea(Map<String, dynamic> place) {
    final metadata = _categoryMetadata(place);

    return _hasCategory(metadata, [
      'place locality',
      'place neighbourhood',
      'place neighborhood',
      'place district',
      'place suburb',
      'administrative',
      'locality',
      'neighbourhood',
      'neighborhood',
      'district',
      'suburb',
      'quarter',
      'city',
      'town',
      'village',
    ]);
  }

  bool _matchesCategory(
    Map<String, dynamic> place,
    String category,
  ) {
    if (category == 'All') return true;

    final metadata = _categoryMetadata(place);

    switch (category) {
      case 'Parks':
        return _hasCategory(metadata, [
          'leisure park',
          'leisure garden',
          'leisure nature reserve',
          'leisure playground',
          'leisure recreation ground',
          'park',
          'garden',
          'nature reserve',
          'national park',
          'protected area',
          'playground',
        ]);

      case 'Food':
        return _hasCategory(metadata, [
          'catering restaurant',
          'catering cafe',
          'catering fast food',
          'catering food court',
          'catering bakery',
          'catering bar',
          'catering pub',
          'catering',
          'restaurant',
          'fast food',
          'food court',
          'cafe',
          'coffee shop',
          'bakery',
          'ice cream',
        ]);

      case 'Stays':
        return _hasCategory(metadata, [
          'accommodation hotel',
          'accommodation motel',
          'accommodation hostel',
          'accommodation guest house',
          'accommodation',
          'hotel',
          'motel',
          'hostel',
          'guest house',
          'lodging',
          'resort',
          'camping',
        ]);

      case 'Shopping':
        return _hasCategory(metadata, [
          'commercial shopping mall',
          'commercial supermarket',
          'commercial department store',
          'commercial market',
          'commercial',
          'shop',
          'shopping',
          'retail',
          'supermarket',
          'mall',
          'market',
          'clothing',
          'electronics',
        ]);

      case 'Landmarks':
        return _hasCategory(metadata, [
          'tourism attraction',
          'tourism museum',
          'tourism viewpoint',
          'tourism monument',
          'tourism',
          'historic',
          'heritage',
          'monument',
          'museum',
          'memorial',
          'viewpoint',
          'place of worship',
        ]);

      case 'Areas':
        return _isArea(place);

      default:
        return true;
    }
  }

  List<Map<String, dynamic>> get _filteredPlaces {
    final query = _normalize(_searchQuery);

    return _nearbyPlaces.where((place) {
      // The API already filtered named categories. Do not reject its results
      // a second time if the provider omits category metadata.
      //
      // Areas is the exception: it is filtered locally from the All response.
      if (_loadedForCategory == 'Areas' &&
          !_matchesCategory(place, 'Areas')) {
        return false;
      }

      if (query.isEmpty) return true;

      final searchable = _normalize(
        '${_placeName(place)} '
        '${_placeAddress(place)} '
        '${_displayCategory(place)}',
      );

      return searchable.contains(query);
    }).toList();
  }

  String _placeName(Map<String, dynamic> place) {
    return _firstString(place, [
      'name',
      'display_name',
      'title',
      'address_line1',
      'formatted',
    ]);
  }

  String _placeAddress(Map<String, dynamic> place) {
    final direct = _firstString(place, [
      'formatted',
      'address',
      'full_address',
      'display_name',
      'vicinity',
    ]);

    if (direct.isNotEmpty) return direct;

    return [
      _firstString(place, ['address_line1', 'street']),
      _firstString(place, ['address_line2', 'suburb', 'district']),
      _firstString(place, ['city', 'town', 'village']),
    ].where((part) => part.isNotEmpty).join(', ');
  }

  String _displayCategory(Map<String, dynamic> place) {
    final metadata = _categoryMetadata(place);

    if (_hasCategory(metadata, ['catering'])) {
      return 'Food & Drink';
    }

    if (_hasCategory(metadata, ['accommodation'])) {
      return 'Stay';
    }

    if (_hasCategory(metadata, [
      'leisure park',
      'park',
      'garden',
    ])) {
      return 'Park';
    }

    if (_hasCategory(metadata, ['commercial', 'shop'])) {
      return 'Shopping';
    }

    if (_hasCategory(metadata, ['tourism', 'historic'])) {
      return 'Landmark';
    }

    if (_isArea(place)) return 'Area';

    final direct = _firstString(place, [
      'subcategory',
      'category',
      'type',
    ]);

    if (direct.isEmpty) return 'Nearby place';

    return direct
        .split(RegExp(r'[._\s]+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  IconData _categoryIcon(Map<String, dynamic> place) {
    final metadata = _categoryMetadata(place);

    if (_hasCategory(metadata, [
      'accommodation',
      'hotel',
      'hostel',
    ])) {
      return Icons.hotel_rounded;
    }

    if (_hasCategory(metadata, [
      'catering',
      'restaurant',
      'cafe',
    ])) {
      return Icons.restaurant_rounded;
    }

    if (_hasCategory(metadata, [
      'leisure',
      'park',
      'garden',
    ])) {
      return Icons.park_rounded;
    }

    if (_hasCategory(metadata, [
      'commercial',
      'shop',
      'shopping',
    ])) {
      return Icons.shopping_bag_rounded;
    }

    if (_hasCategory(metadata, [
      'tourism',
      'historic',
      'museum',
    ])) {
      return Icons.account_balance_rounded;
    }

    if (_isArea(place)) {
      return Icons.location_city_rounded;
    }

    return Icons.place_rounded;
  }

  String _placeImage(Map<String, dynamic> place) {
    return _firstString(place, [
      'image_url',
      'image',
      'photo_url',
      'thumbnail',
      'photo',
    ]);
  }

  (double, double)? _coordinates(
    Map<String, dynamic> place,
  ) {
    final lat = place['latitude'] ?? place['lat'];
    final lon = place['longitude'] ?? place['lon'] ?? place['lng'];

    if (lat is num && lon is num) {
      if (lat >= -90 &&
          lat <= 90 &&
          lon >= -180 &&
          lon <= 180) {
        return (lat.toDouble(), lon.toDouble());
      }
    }

    final geometry = place['_geometry'] ?? place['geometry'];

    if (geometry is Map) {
      final coordinates = geometry['coordinates'];

      // GeoJSON Point coordinates are [longitude, latitude].
      if (coordinates is List && coordinates.length >= 2) {
        final longitude = coordinates[0];
        final latitude = coordinates[1];

        if (longitude is num && latitude is num) {
          return (
            latitude.toDouble(),
            longitude.toDouble(),
          );
        }
      }
    }

    return null;
  }

  double? _distanceKm(Map<String, dynamic> place) {
    final value =
        place['distance_km'] ??
        place['distanceKm'] ??
        place['distance'];

    if (value is num) {
      // Some providers return distance in metres.
      return value > 100 ? value / 1000 : value.toDouble();
    }

    if (value is String) {
      final parsed = double.tryParse(value);

      if (parsed != null) {
        return parsed > 100 ? parsed / 1000 : parsed;
      }
    }

    final coordinates = _coordinates(place);
    final current = _currentPosition;

    if (coordinates == null || current == null) return null;

    return Geolocator.distanceBetween(
          current.latitude,
          current.longitude,
          coordinates.$1,
          coordinates.$2,
        ) /
        1000;
  }

  // ---------------------------------------------------------------------------
  // Interactions
  // ---------------------------------------------------------------------------

  Future<void> _selectCategory(String category) async {
    if (category == _selectedCategory && !_isLoading) return;

    setState(() {
      _selectedCategory = category;
      _searchQuery = '';
      _searchController.clear();
    });

    if (_cardsController.hasClients) {
      _cardsController.jumpTo(0);
    }

    await _loadNearbyPlaces(category: category);
  }

  Future<void> _openPlace(
    Map<String, dynamic> place,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaceDetailsScreen(place: place),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main screen
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          // Keep the map full-screen and disable its predefined POI markers.
          const Positioned.fill(
            child: WorldMap(
              showBottomPlaceOverlay: false,
              showPoiMarkers: false,
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 265,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _buildTopControls(),
                ),
                const Spacer(),
                _buildBottomPlaces(_filteredPlaces),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top controls
  // ---------------------------------------------------------------------------

  Widget _buildTopControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.13),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.explore_rounded,
                color: _primary,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Discover real places around you',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _floatingButton(
              Icons.my_location_rounded,
              'Refresh nearby places',
              () => _loadNearbyPlaces(
                category: _selectedCategory,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.13),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
            decoration: InputDecoration(
              hintText: 'Search nearby places...',
              hintStyle: TextStyle(
                color: Colors.blueGrey.shade400,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: _primary,
              ),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final selected = category == _selectedCategory;

              return Material(
                color: selected ? _primary : Colors.white,
                borderRadius: BorderRadius.circular(24),
                elevation: 3,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _selectCategory(category),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : _primary,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _floatingButton(
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      elevation: 5,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          width: 44,
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              color: _primary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom place cards
  // ---------------------------------------------------------------------------

  Widget _buildBottomPlaces(
    List<Map<String, dynamic>> places,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCategory == 'All'
                            ? 'Nearby places'
                            : _selectedCategory,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _isLoading
                            ? 'Finding real places near you...'
                            : '${places.length} '
                                '${places.length == 1 ? 'place' : 'places'} found',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                else
                  _floatingButton(
                    Icons.refresh_rounded,
                    'Reload places',
                    () => _loadNearbyPlaces(
                      category: _selectedCategory,
                    ),
                  ),
              ],
            ),
          ),
          if (_isLoading)
            _buildStatusCard(
              message: 'Discovering real nearby places...',
              loading: true,
            )
          else if (_errorMessage != null || places.isEmpty)
            _buildStatusCard(
              message: _errorMessage ??
                  'No places match your search. Try another filter.',
              loading: false,
            )
          else
            SizedBox(
              height: 174,
              child: ListView.separated(
                controller: _cardsController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: places.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _buildPlaceCard(places[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String message,
    required bool loading,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (loading)
            const SizedBox(
              height: 26,
              width: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: _secondary,
              ),
            )
          else
            const Icon(
              Icons.location_searching_rounded,
              color: _primary,
              size: 28,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _primary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          if (!loading)
            TextButton(
              onPressed: () => _loadNearbyPlaces(
                category: _selectedCategory,
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(
    Map<String, dynamic> place,
  ) {
    final imageUrl = _placeImage(place);
    final distance = _distanceKm(place);
    final icon = _categoryIcon(place);
    final address = _placeAddress(place);

    return SizedBox(
      width: 282,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        elevation: 7,
        child: InkWell(
          onTap: () => _openPlace(place),
          child: Row(
            children: [
              SizedBox(
                width: 104,
                height: double.infinity,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _imagePlaceholder(icon),
                      )
                    : _imagePlaceholder(icon),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    12,
                    10,
                    10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _chipBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _displayCategory(place),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        _placeName(place),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Expanded(
                        child: Text(
                          address.isEmpty
                              ? 'Address unavailable'
                              : address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.blueGrey.shade600,
                            fontSize: 11,
                            height: 1.25,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            color: _secondary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              distance == null
                                  ? 'Nearby'
                                  : '${distance.toStringAsFixed(1)} km away',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _secondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: _primary,
                            size: 17,
                          ),
                        ],
                      ),
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

  Widget _imagePlaceholder(IconData icon) {
    return Container(
      color: _chipBackground,
      child: Center(
        child: Icon(
          icon,
          size: 32,
          color: _primary.withOpacity(0.72),
        ),
      ),
    );
  }
}
