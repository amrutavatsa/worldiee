import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../services/api_service.dart';

class WorldMap extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onPlaceSelected;
  final String? selectedPlaceId;
  final bool showBottomPlaceOverlay;
  final bool showPoiMarkers;

  const WorldMap({
    super.key,
    this.onPlaceSelected,
    this.selectedPlaceId,
    this.showBottomPlaceOverlay = true,
    this.showPoiMarkers = true,
  });

  @override
  State<WorldMap> createState() => _WorldMapState();
}

class _WorldMapState extends State<WorldMap> {
  static const String _poiSourceId = 'worldcompanion-pois';
  static const String _poiLayerId = 'worldcompanion-poi-layer';
  static const String _poiSelectedLayerId = 'worldcompanion-poi-selected-layer';

  // ===========================================================================
  // NEARBY DISCOVERY LAYER
  // ===========================================================================

  static const String _nearbySourceId = 'worldcompanion-nearby';
  static const String _nearbyLayerId = 'worldcompanion-nearby-layer';
  static const String _nearbySelectedLayerId =
      'worldcompanion-nearby-selected-layer';

  static const double _nearbyRadiusKm = 5.0;

  // ===========================================================================
  // A* ROUTE LAYER
  // ===========================================================================

  static const String _routeSourceId = 'worldcompanion-route';
  static const String _routeLayerId = 'worldcompanion-route-layer';

  MapLibreMapController? _mapController;

  bool _styleLoaded = false;
  bool _initialCameraPositionSet = false;

  bool _poiLayerAdded = false;
  bool _nearbyLayerAdded = false;
  bool _routeLayerAdded = false;

  bool _loadingPois = true;
  bool _loadingLocation = true;
  bool _loadingNearby = true;
  bool _loadingRoute = false;

  String? _poiError;
  String? _locationError;
  String? _nearbyError;
  String? _routeError;

  Map<String, dynamic> _pois = {};

  List<Map<String, dynamic>> _nearbyPlaces = [];

  Position? _currentPosition;

  String? _selectedPoiId;
  Map<String, dynamic>? _selectedPlace;

  List<List<double>> _routeCoordinates = [];

  final List<Circle> _currentLocationCircles = [];

  @override
  void initState() {
    super.initState();

    debugPrint('WorldMap: INIT');

    _loadPois();
    _loadCurrentLocation();
  }

  @override
  void didUpdateWidget(covariant WorldMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedPlaceId != oldWidget.selectedPlaceId &&
        widget.selectedPlaceId != null) {
      _syncExternalSelection(widget.selectedPlaceId!);
    }
  }

  Future<void> _syncExternalSelection(String id) async {
    if (_pois.containsKey(id)) {
      await _selectPoi(id);
      return;
    }
    if (_nearbyPlaces.any((place) => place['id']?.toString() == id)) {
      await _selectNearbyPlace(id);
    }
  }

  @override
  void dispose() {
    _mapController = null;
    super.dispose();
  }

  // ===========================================================================
  // POI LOADING
  // ===========================================================================

  Future<void> _loadPois() async {
    debugPrint('WorldMap: Loading POIs...');

    try {
      final result = await ApiService.getPois();

      debugPrint('WorldMap: POIs received = ${result.length}');
      debugPrint(
        'WorldMap: POI keys = ${result.keys.toList()}',
      );

      if (!mounted) return;

      setState(() {
        _pois = Map<String, dynamic>.from(result);
        _loadingPois = false;
        _poiError = null;
      });

      if (_styleLoaded && widget.showPoiMarkers) {
        await _renderPoiLayer();
      }
    } catch (e, stackTrace) {
      debugPrint('WorldMap: POI ERROR = $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _loadingPois = false;
        _poiError = e.toString();
      });
    }
  }

  // ===========================================================================
  // MAP CREATED
  // ===========================================================================

  void _onMapCreated(
    MapLibreMapController controller,
  ) {
    _mapController = controller;

    debugPrint('WorldMap: MAP CREATED');
    debugPrint(
      'WorldMap: Using layer-based POI interaction.',
    );
  }

  // ===========================================================================
  // STYLE LOADED
  // ===========================================================================

  Future<void> _onStyleLoaded() async {
    debugPrint('WorldMap: STYLE LOADED');

    _styleLoaded = true;

    if (widget.showPoiMarkers && _pois.isNotEmpty) {
      await _renderPoiLayer();
    }

    if (_nearbyPlaces.isNotEmpty) {
      await _renderNearbyLayer();
    }

    if (_currentPosition != null) {
      await _renderCurrentLocation();
    }

    if (_routeCoordinates.length >= 2) {
      await _renderRoute();
    }

    await _centerOnCurrentLocationIfNeeded();
  }

  // ===========================================================================
  // MAP CLICK
  // ===========================================================================

  Future<void> _onMapClick(
    Point<double> point,
    LatLng coordinates,
  ) async {
    debugPrint(
      'WorldMap: MAP CLICK = '
      '${coordinates.latitude}, ${coordinates.longitude}',
    );

    await _handleMapClick(point);
  }

  Future<void> _handleMapClick(
    Point<double> point,
  ) async {
    final controller = _mapController;

    if (controller == null) {
      debugPrint(
        'WorldMap: MAP CONTROLLER IS NULL',
      );
      return;
    }

    try {
      final layers = <String>[
        _nearbySelectedLayerId,
        _nearbyLayerId,
        if (widget.showPoiMarkers) ...[
          _poiSelectedLayerId,
          _poiLayerId,
        ],
      ];
      final features = await controller.queryRenderedFeatures(
        point,
        layers,
        null,
      );

      debugPrint(
        'WorldMap: Rendered features found = ${features.length}',
      );

      if (features.isEmpty) {
        debugPrint(
          'WorldMap: No place found at clicked location.',
        );
        return;
      }

      // -----------------------------------------------------------------------
      // Prefer nearby discovery features first.
      // -----------------------------------------------------------------------

      for (final feature in features) {
        debugPrint(
          'WorldMap: FEATURE = $feature',
        );

        final rawProperties = feature['properties'];

        if (rawProperties == null) {
          debugPrint(
            'WorldMap: FEATURE HAS NO PROPERTIES',
          );
          continue;
        }

        final properties = Map<String, dynamic>.from(
          rawProperties as Map,
        );

        debugPrint(
          'WorldMap: FEATURE PROPERTIES = $properties',
        );

        final nearbyId = properties['nearby_id']?.toString();

        if (nearbyId != null && nearbyId.isNotEmpty) {
          debugPrint(
            'WorldMap: CLICKED NEARBY PLACE ID = $nearbyId',
          );

          await _selectNearbyPlace(nearbyId);
          return;
        }

        final poiId = properties['poi_id']?.toString();

        if (poiId != null && poiId.isNotEmpty) {
          debugPrint(
            'WorldMap: CLICKED POI ID = $poiId',
          );

          await _selectPoi(poiId);
          return;
        }
      }
    } catch (e, stackTrace) {
      debugPrint(
        'WorldMap: MAP CLICK ERROR = $e',
      );
      debugPrint('$stackTrace');
    }
  }

  // ===========================================================================
  // SELECT POI
  // ===========================================================================

  Future<void> _selectPoi(
    String poiId,
  ) async {
    debugPrint(
      'WorldMap: Selecting POI = $poiId',
    );

    final rawPlace = _pois[poiId];

    if (rawPlace == null) {
      debugPrint(
        'WorldMap: POI ID not found in local POI map = $poiId',
      );
      return;
    }

    final place = Map<String, dynamic>.from(
      rawPlace as Map,
    );

    debugPrint(
      'WorldMap: SELECTED PLACE = $place',
    );

    if (!mounted) return;

    setState(() {
      _selectedPoiId = poiId;
      _selectedPlace = place;
      _routeError = null;
    });

    debugPrint(
      'WorldMap: SELECTED PLACE STATE UPDATED',
    );

    widget.onPlaceSelected?.call(place);

    await _updatePoiSource();
    await _updateNearbySource();
    await _moveCameraToSelectedPoi(place);
  }

  // ===========================================================================
  // SELECT NEARBY PLACE
  // ===========================================================================

  Future<void> _selectNearbyPlace(
    String nearbyId,
  ) async {
    debugPrint(
      'WorldMap: Selecting nearby place = $nearbyId',
    );

    Map<String, dynamic>? selected;

    for (final place in _nearbyPlaces) {
      final id = place['id']?.toString();

      if (id == nearbyId) {
        selected = Map<String, dynamic>.from(place);
        break;
      }
    }

    if (selected == null) {
      debugPrint(
        'WorldMap: Nearby place not found locally = $nearbyId',
      );
      return;
    }

    debugPrint(
      'WorldMap: SELECTED NEARBY PLACE = $selected',
    );

    if (!mounted) return;

    setState(() {
      _selectedPoiId = nearbyId;
      _selectedPlace = selected;
      _routeError = null;
    });

    widget.onPlaceSelected?.call(selected);

    await _updatePoiSource();
    await _updateNearbySource();
    await _moveCameraToSelectedPoi(selected);
  }

  // ===========================================================================
  // BUILD POI GEOJSON
  // ===========================================================================

  Map<String, dynamic> _buildPoiFeatureCollection() {
    final features = <Map<String, dynamic>>[];

    for (final entry in _pois.entries) {
      final poiId = entry.key;

      final place = Map<String, dynamic>.from(
        entry.value as Map,
      );

      final latitude = _readCoordinate(
        place,
        const [
          'latitude',
          'lat',
        ],
      );

      final longitude = _readCoordinate(
        place,
        const [
          'longitude',
          'lng',
          'lon',
        ],
      );

      if (latitude == null || longitude == null) {
        debugPrint(
          'WorldMap: Skipping POI $poiId because coordinates are missing.',
        );
        continue;
      }

      final isSelected = poiId == _selectedPoiId;

      features.add({
        'type': 'Feature',
        'id': poiId,
        'properties': {
          'poi_id': poiId,
          'selected': isSelected,
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [
            longitude,
            latitude,
          ],
        },
      });
    }

    debugPrint(
      'WorldMap: Built ${features.length} POI GeoJSON features.',
    );

    return {
      'type': 'FeatureCollection',
      'features': features,
    };
  }

  // ===========================================================================
  // BUILD NEARBY GEOJSON
  // ===========================================================================

  Map<String, dynamic> _buildNearbyFeatureCollection() {
    final features = <Map<String, dynamic>>[];

    for (final place in _nearbyPlaces) {
      final nearbyId = place['id']?.toString();

      if (nearbyId == null || nearbyId.isEmpty) {
        continue;
      }

      final latitude = _readCoordinate(
        place,
        const [
          'latitude',
          'lat',
        ],
      );

      final longitude = _readCoordinate(
        place,
        const [
          'longitude',
          'lng',
          'lon',
        ],
      );

      if (latitude == null || longitude == null) {
        debugPrint(
          'WorldMap: Skipping nearby place $nearbyId because coordinates are missing.',
        );
        continue;
      }

      final isSelected = nearbyId == _selectedPoiId;

      features.add({
        'type': 'Feature',
        'id': 'nearby-$nearbyId',
        'properties': {
          'nearby_id': nearbyId,
          'selected': isSelected,
        },
        'geometry': {
          'type': 'Point',
          'coordinates': [
            longitude,
            latitude,
          ],
        },
      });
    }

    debugPrint(
      'WorldMap: Built ${features.length} nearby GeoJSON features.',
    );

    return {
      'type': 'FeatureCollection',
      'features': features,
    };
  }

  // ===========================================================================
  // COORDINATE HELPER
  // ===========================================================================

  double? _readCoordinate(
    Map<String, dynamic> place,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = place[key];

      if (value is num) {
        return value.toDouble();
      }

      if (value is String) {
        final parsed = double.tryParse(value);

        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  // ===========================================================================
  // RENDER POI LAYERS
  // ===========================================================================

  Future<void> _renderPoiLayer() async {
    final controller = _mapController;

    if (controller == null || !_styleLoaded || _pois.isEmpty) {
      return;
    }

    if (_poiLayerAdded) {
      await _updatePoiSource();
      return;
    }

    final featureCollection = _buildPoiFeatureCollection();

    try {
      debugPrint(
        'WorldMap: Adding POI GeoJSON source...',
      );

      await controller.addGeoJsonSource(
        _poiSourceId,
        featureCollection,
      );

      debugPrint(
        'WorldMap: POI GeoJSON source added.',
      );

      // -----------------------------------------------------------------------
      // NORMAL POI LAYER
      // -----------------------------------------------------------------------

      await controller.addCircleLayer(
        _poiSourceId,
        _poiLayerId,
        const CircleLayerProperties(
          circleRadius: 8.0,
          circleColor: '#0E7774',
          circleOpacity: 1.0,
          circleStrokeWidth: 3.0,
          circleStrokeColor: '#FFFFFF',
          circleStrokeOpacity: 1.0,
        ),
        filter: [
          '==',
          ['get', 'selected'],
          false,
        ],
        enableInteraction: false,
      );

      debugPrint(
        'WorldMap: Normal POI layer added.',
      );

      // -----------------------------------------------------------------------
      // SELECTED POI LAYER
      // -----------------------------------------------------------------------

      await controller.addCircleLayer(
        _poiSourceId,
        _poiSelectedLayerId,
        const CircleLayerProperties(
          circleRadius: 12.0,
          circleColor: '#F59E0B',
          circleOpacity: 1.0,
          circleStrokeWidth: 4.0,
          circleStrokeColor: '#FFFFFF',
          circleStrokeOpacity: 1.0,
        ),
        filter: [
          '==',
          ['get', 'selected'],
          true,
        ],
        enableInteraction: false,
      );

      debugPrint(
        'WorldMap: Selected POI layer added.',
      );

      _poiLayerAdded = true;

      debugPrint(
        'WorldMap: POI layer setup complete.',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'WorldMap: POI LAYER ERROR = $e',
      );
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _poiError = e.toString();
      });
    }
  }

  // ===========================================================================
  // UPDATE POI SOURCE
  // ===========================================================================

  Future<void> _updatePoiSource() async {
    final controller = _mapController;

    if (controller == null || !_styleLoaded || !_poiLayerAdded) {
      return;
    }

    try {
      final featureCollection = _buildPoiFeatureCollection();

      await controller.setGeoJsonSource(
        _poiSourceId,
        featureCollection,
      );

      debugPrint(
        'WorldMap: POI GeoJSON source updated.',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'WorldMap: POI SOURCE UPDATE ERROR = $e',
      );
      debugPrint('$stackTrace');
    }
  }

  // ===========================================================================
  // NEARBY DISCOVERY
  // ===========================================================================

  Future<void> _loadNearbyPlaces() async {
    final position = _currentPosition;

    if (position == null) {
      debugPrint(
        'WorldMap: NEARBY ERROR = Current location unavailable.',
      );
      return;
    }

    debugPrint(
      'WorldMap: Loading nearby places...',
    );

    debugPrint(
      'WorldMap: Nearby search center = '
      '${position.latitude}, ${position.longitude}',
    );

    debugPrint(
      'WorldMap: Nearby radius = $_nearbyRadiusKm km',
    );

    if (mounted) {
      setState(() {
        _loadingNearby = true;
        _nearbyError = null;
      });
    }

    try {
      final result = await ApiService.getNearbyPlaces(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: _nearbyRadiusKm,
      );

      final nearby = result
          .whereType<Map>()
          .map(
            (place) => Map<String, dynamic>.from(place),
          )
          .toList();

      debugPrint(
        'WorldMap: Nearby places received = ${nearby.length}',
      );

      for (final place in nearby) {
        debugPrint(
          'WorldMap: NEARBY = '
          '${place['name']} '
          '(${place['distance_km']} km)',
        );
      }

      if (!mounted) return;

      setState(() {
        _nearbyPlaces = nearby;
        _loadingNearby = false;
        _nearbyError = null;
      });

      if (_styleLoaded) {
        await _renderNearbyLayer();
      }
    } catch (e, stackTrace) {
      debugPrint(
        'WorldMap: NEARBY ERROR = $e',
      );
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _loadingNearby = false;
        _nearbyError = e.toString();
        _nearbyPlaces = [];
      });

      if (_styleLoaded) {
        await _renderNearbyLayer();
      }
    }
  }

  // ===========================================================================
  // RENDER NEARBY LAYERS
  // ===========================================================================

  Future<void> _renderNearbyLayer() async {
    final controller = _mapController;

    if (controller == null || !_styleLoaded) {
      return;
    }

    final featureCollection = _buildNearbyFeatureCollection();

    try {
      if (_nearbyLayerAdded) {
        await _updateNearbySource();
        return;
      }

      debugPrint(
        'WorldMap: Adding nearby GeoJSON source...',
      );

      await controller.addGeoJsonSource(
        _nearbySourceId,
        featureCollection,
      );

      debugPrint(
        'WorldMap: Nearby GeoJSON source added.',
      );

      // -----------------------------------------------------------------------
      // NORMAL NEARBY LAYER
      // -----------------------------------------------------------------------

      await controller.addCircleLayer(
        _nearbySourceId,
        _nearbyLayerId,
        const CircleLayerProperties(
          circleRadius: 7.0,
          circleColor: '#7C3AED',
          circleOpacity: 0.95,
          circleStrokeWidth: 3.0,
          circleStrokeColor: '#FFFFFF',
          circleStrokeOpacity: 1.0,
        ),
        filter: [
          '==',
          ['get', 'selected'],
          false,
        ],
        enableInteraction: false,
      );

      debugPrint(
        'WorldMap: Nearby normal layer added.',
      );

      // -----------------------------------------------------------------------
      // SELECTED NEARBY LAYER
      // -----------------------------------------------------------------------

      await controller.addCircleLayer(
        _nearbySourceId,
        _nearbySelectedLayerId,
        const CircleLayerProperties(
          circleRadius: 11.0,
          circleColor: '#F59E0B',
          circleOpacity: 1.0,
          circleStrokeWidth: 4.0,
          circleStrokeColor: '#FFFFFF',
          circleStrokeOpacity: 1.0,
        ),
        filter: [
          '==',
          ['get', 'selected'],
          true,
        ],
        enableInteraction: false,
      );

      debugPrint(
        'WorldMap: Nearby selected layer added.',
      );

      _nearbyLayerAdded = true;

      debugPrint(
        'WorldMap: NEARBY DISCOVERY LAYER READY',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'WorldMap: NEARBY LAYER ERROR = $e',
      );
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _nearbyError = e.toString();
      });
    }
  }

  // ===========================================================================
  // UPDATE NEARBY SOURCE
  // ===========================================================================

  Future<void> _updateNearbySource() async {
    final controller = _mapController;

    if (controller == null || !_styleLoaded || !_nearbyLayerAdded) {
      return;
    }

    try {
      final featureCollection = _buildNearbyFeatureCollection();

      await controller.setGeoJsonSource(
        _nearbySourceId,
        featureCollection,
      );

      debugPrint(
        'WorldMap: Nearby GeoJSON source updated.',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'WorldMap: NEARBY SOURCE UPDATE ERROR = $e',
      );
      debugPrint('$stackTrace');
    }
  }

  Future<void> _centerOnCurrentLocationIfNeeded() async {
    if (_initialCameraPositionSet || !_styleLoaded) return;

    final controller = _mapController;
    final position = _currentPosition;
    if (controller == null || position == null) return;

    // Set the guard before animating so GPS/style callbacks cannot recenter twice.
    _initialCameraPositionSet = true;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        14.5,
      ),
    );
  }

  // ===========================================================================
  // CURRENT LOCATION
  // ===========================================================================

  Future<void> _loadCurrentLocation() async {
    debugPrint(
      'WorldMap: Loading current location...',
    );

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission denied.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission permanently denied.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      debugPrint(
        'WorldMap: Current location = '
        '${position.latitude}, ${position.longitude}',
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _loadingLocation = false;
        _locationError = null;
      });

      if (_styleLoaded) {
        await _renderCurrentLocation();
      }

      await _centerOnCurrentLocationIfNeeded();

      // -----------------------------------------------------------------------
      // Nearby Discovery starts after GPS becomes available.
      // -----------------------------------------------------------------------

      await _loadNearbyPlaces();
    } catch (e, stackTrace) {
      debugPrint(
        'WorldMap: LOCATION ERROR = $e',
      );
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _loadingLocation = false;
        _locationError = e.toString();
        _loadingNearby = false;
      });
    }
  }

  // ===========================================================================
  // CURRENT LOCATION MARKER
  // ===========================================================================

  Future<void> _renderCurrentLocation() async {
    final controller = _mapController;
    final position = _currentPosition;

    if (controller == null || position == null || !_styleLoaded) {
      return;
    }

    try {
      if (_currentLocationCircles.isNotEmpty) {
        await controller.removeCircles(
          _currentLocationCircles,
        );

        _currentLocationCircles.clear();
      }

      final locationCircle = await controller.addCircle(
        CircleOptions(
          geometry: LatLng(
            position.latitude,
            position.longitude,
          ),
          circleRadius: 11.0,
          circleColor: '#2563EB',
          circleOpacity: 0.22,
          circleStrokeWidth: 2.0,
          circleStrokeColor: '#FFFFFF',
          circleStrokeOpacity: 1.0,
        ),
      );

      _currentLocationCircles.add(
        locationCircle,
      );

      debugPrint(
        'WorldMap: Current location marker rendered.',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'WorldMap: CURRENT LOCATION MARKER ERROR = $e',
      );
      debugPrint('$stackTrace');
    }
  }

  // ===========================================================================
  // A* ROUTING
  // ===========================================================================

  Future<void> _buildRouteToSelectedPoi() async {
    if (_selectedPoiId == null) {
      debugPrint(
        'WorldMap: ROUTE ERROR = No destination selected.',
      );
      return;
    }

    if (!_pois.containsKey(_selectedPoiId)) {
      if (mounted) {
        setState(() {
          _routeError =
              'Routing is currently available only for known WorldCompanion POIs.';
        });
      }

      debugPrint(
        'WorldMap: ROUTE ERROR = Selected nearby place is not in A* graph.',
      );

      return;
    }

    if (_currentPosition == null) {
      debugPrint(
        'WorldMap: ROUTE ERROR = Current location unavailable.',
      );

      if (mounted) {
        setState(() {
          _routeError = 'Your current location is not available yet.';
        });
      }

      return;
    }

    if (_pois.isEmpty) {
      debugPrint(
        'WorldMap: ROUTE ERROR = POIs not loaded.',
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _loadingRoute = true;
      _routeError = null;
    });

    try {
      // -----------------------------------------------------------------------
      // STEP 1
      // Find the POI closest to the user's current GPS position.
      // -----------------------------------------------------------------------

      String? nearestPoiId;
      double nearestDistance = double.infinity;

      for (final entry in _pois.entries) {
        final poiId = entry.key;

        final rawPoi = entry.value;

        if (rawPoi is! Map) {
          continue;
        }

        final poi = Map<String, dynamic>.from(rawPoi);

        final latitude = _readCoordinate(
          poi,
          const [
            'latitude',
            'lat',
          ],
        );

        final longitude = _readCoordinate(
          poi,
          const [
            'longitude',
            'lng',
            'lon',
          ],
        );

        if (latitude == null || longitude == null) {
          continue;
        }

        final distance = _haversineKm(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          latitude,
          longitude,
        );

        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestPoiId = poiId;
        }
      }

      if (nearestPoiId == null) {
        throw Exception(
          'Could not find a nearby starting POI.',
        );
      }

      debugPrint(
        'WorldMap: ROUTE START POI = $nearestPoiId',
      );

      debugPrint(
        'WorldMap: DISTANCE TO START POI = '
        '${nearestDistance.toStringAsFixed(3)} km',
      );

      debugPrint(
        'WorldMap: ROUTE DESTINATION = $_selectedPoiId',
      );

      // -----------------------------------------------------------------------
      // STEP 2
      // Call the existing Django A* endpoint.
      // -----------------------------------------------------------------------

      final result = await ApiService.optimizeRoute(
        nearestPoiId,
        [_selectedPoiId!],
      );

      debugPrint(
        'WorldMap: A* RESULT = $result',
      );

      // -----------------------------------------------------------------------
      // STEP 3
      // Extract hops from the backend response.
      // -----------------------------------------------------------------------

      final rawHops = result['hops'];

      if (rawHops is! List || rawHops.isEmpty) {
        throw Exception(
          'A* returned no route hops.',
        );
      }

      final coordinates = <List<double>>[];

      // -----------------------------------------------------------------------
      // STEP 4
      // Convert every POI in the A* path into [longitude, latitude].
      // -----------------------------------------------------------------------

      for (final rawHop in rawHops) {
        if (rawHop is! Map) {
          continue;
        }

        final hop = Map<String, dynamic>.from(rawHop);

        final rawPath = hop['path'];

        if (rawPath is! List) {
          continue;
        }

        for (final rawId in rawPath) {
          final poiId = rawId.toString();

          final rawPoi = _pois[poiId];

          if (rawPoi is! Map) {
            debugPrint(
              'WorldMap: Route POI not found locally = $poiId',
            );
            continue;
          }

          final poi = Map<String, dynamic>.from(rawPoi);

          final latitude = _readCoordinate(
            poi,
            const [
              'latitude',
              'lat',
            ],
          );

          final longitude = _readCoordinate(
            poi,
            const [
              'longitude',
              'lng',
              'lon',
            ],
          );

          if (latitude == null || longitude == null) {
            continue;
          }

          final coordinate = [
            longitude,
            latitude,
          ];

          if (coordinates.isEmpty ||
              coordinates.last[0] != coordinate[0] ||
              coordinates.last[1] != coordinate[1]) {
            coordinates.add(coordinate);
          }
        }
      }

      if (coordinates.length < 2) {
        throw Exception(
          'A* returned insufficient coordinates to draw a route.',
        );
      }

      // -----------------------------------------------------------------------
      // STEP 5
      // Store route and draw it.
      // -----------------------------------------------------------------------

      final position = _currentPosition!;

      final displayCoordinates = <List<double>>[
        [position.longitude, position.latitude],
        ...coordinates,
      ];

      final destinationRaw = _pois[_selectedPoiId];

      if (destinationRaw is Map) {
        final destination = Map<String, dynamic>.from(destinationRaw);

        final latitude =
            _readCoordinate(destination, const ['latitude', 'lat']);

        final longitude =
            _readCoordinate(destination, const ['longitude', 'lng', 'lon']);

        if (latitude != null && longitude != null) {
          final endpoint = [longitude, latitude];

          if (displayCoordinates.last[0] != endpoint[0] ||
              displayCoordinates.last[1] != endpoint[1]) {
            displayCoordinates.add(endpoint);
          }
        }
      }

      _routeCoordinates = displayCoordinates;
      await _renderRoute();

      debugPrint(
        'WorldMap: ROUTE DRAWN = '
        '${coordinates.length} coordinates',
      );

      if (!mounted) return;

      setState(() {});
    } catch (e, stackTrace) {
      debugPrint(
        'WorldMap: ROUTE ERROR = $e',
      );
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _routeError = e.toString();
      });
    } finally {
      // Do not return from finally.
      // This avoids control-flow issues while still preventing
      // setState after the widget has been disposed.
      if (mounted) {
        setState(() {
          _loadingRoute = false;
        });
      }
    }
  }

  // ===========================================================================
  // HAVERSINE DISTANCE
  // ===========================================================================

  double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371.0;

    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;

    final dPhi = (lat2 - lat1) * pi / 180;

    final dLambda = (lon2 - lon1) * pi / 180;

    final a = sin(dPhi / 2) * sin(dPhi / 2) +
        cos(phi1) * cos(phi2) * sin(dLambda / 2) * sin(dLambda / 2);

    final c = 2 *
        atan2(
          sqrt(a),
          sqrt(1 - a),
        );

    return earthRadius * c;
  }

  // ===========================================================================
  // BUILD ROUTE GEOJSON
  // ===========================================================================

  Map<String, dynamic> _buildRouteFeatureCollection() {
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {
            'route': true,
          },
          'geometry': {
            'type': 'LineString',
            'coordinates': _routeCoordinates,
          },
        },
      ],
    };
  }

  // ===========================================================================
  // RENDER ROUTE
  // ===========================================================================

  Future<void> _renderRoute() async {
    final controller = _mapController;

    if (controller == null || !_styleLoaded || _routeCoordinates.length < 2) {
      return;
    }

    try {
      final featureCollection = _buildRouteFeatureCollection();

      if (_routeLayerAdded) {
        await controller.setGeoJsonSource(
          _routeSourceId,
          featureCollection,
        );

        debugPrint(
          'WorldMap: ROUTE SOURCE UPDATED',
        );

        return;
      }

      debugPrint(
        'WorldMap: Adding route GeoJSON source...',
      );

      await controller.addGeoJsonSource(
        _routeSourceId,
        featureCollection,
      );

      debugPrint(
        'WorldMap: Route GeoJSON source added.',
      );

      await controller.addLineLayer(
        _routeSourceId,
        _routeLayerId,
        const LineLayerProperties(
          lineColor: '#2563EB',
          lineWidth: 5.0,
          lineOpacity: 0.9,
          lineCap: 'round',
          lineJoin: 'round',
        ),
        enableInteraction: false,
      );

      _routeLayerAdded = true;

      debugPrint(
        'WorldMap: ROUTE LAYER ADDED',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'WorldMap: ROUTE RENDER ERROR = $e',
      );
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _routeError = e.toString();
      });
    }
  }

  // ===========================================================================
  // CLEAR ROUTE
  // ===========================================================================

  Future<void> _clearRoute() async {
    if (!mounted) return;

    setState(() {
      _routeCoordinates = [];
      _routeError = null;
    });

    final controller = _mapController;

    if (controller == null || !_styleLoaded || !_routeLayerAdded) {
      return;
    }

    try {
      await controller.setGeoJsonSource(
        _routeSourceId,
        {
          'type': 'FeatureCollection',
          'features': [],
        },
      );

      debugPrint(
        'WorldMap: ROUTE CLEARED',
      );
    } catch (e) {
      debugPrint(
        'WorldMap: ROUTE CLEAR ERROR = $e',
      );
    }
  }

  // ===========================================================================
  // MOVE CAMERA TO SELECTED PLACE
  // ===========================================================================

  Future<void> _moveCameraToSelectedPoi(
    Map<String, dynamic> place,
  ) async {
    final controller = _mapController;

    if (controller == null) {
      return;
    }

    final latitude = _readCoordinate(
      place,
      const [
        'latitude',
        'lat',
      ],
    );

    final longitude = _readCoordinate(
      place,
      const [
        'longitude',
        'lng',
        'lon',
      ],
    );

    if (latitude == null || longitude == null) {
      debugPrint(
        'WorldMap: Selected place has no valid coordinates.',
      );
      return;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            latitude,
            longitude,
          ),
          14.5,
        ),
      );

      debugPrint(
        'WorldMap: CAMERA MOVED TO SELECTED PLACE',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'WorldMap: CAMERA MOVE ERROR = $e',
      );
      debugPrint('$stackTrace');
    }
  }

  // ===========================================================================
  // RECENTER
  // ===========================================================================

  Future<void> _recenterToCurrentLocation() async {
    final controller = _mapController;
    final position = _currentPosition;

    if (controller == null || position == null) {
      await _loadCurrentLocation();
      return;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(
            position.latitude,
            position.longitude,
          ),
          14.5,
        ),
      );
    } catch (e) {
      debugPrint(
        'WorldMap: RECENTER ERROR = $e',
      );
    }
  }

  // ===========================================================================
  // CLEAR SELECTED POI
  // ===========================================================================

  Future<void> _clearSelectedPoi() async {
    if (!mounted) return;

    await _clearRoute();

    setState(() {
      _selectedPoiId = null;
      _selectedPlace = null;
    });

    await _updatePoiSource();
    await _updateNearbySource();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: MapLibreMap(
            styleString: 'https://demotiles.maplibre.org/style.json',
            initialCameraPosition: const CameraPosition(
              target: LatLng(
                13.9716,
                77.5946,
              ),
              zoom: 11.0,
            ),
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapClick: _onMapClick,
            myLocationEnabled: true,
          ),
        ),

        // =====================================================================
        // TOP STATUS CHIPS
        // =====================================================================

        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: SafeArea(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (_loadingPois)
                    _buildStatusChip(
                      icon: Icons.location_searching,
                      label: 'Loading places...',
                    )
                  else if (_poiError != null)
                    _buildStatusChip(
                      icon: Icons.error_outline,
                      label: 'Places unavailable',
                    )
                  else
                    _buildStatusChip(
                      icon: Icons.place,
                      label: '${_pois.length} places',
                    ),
                  const SizedBox(width: 8),
                  if (_loadingLocation)
                    _buildStatusChip(
                      icon: Icons.my_location,
                      label: 'Finding you...',
                    )
                  else if (_locationError != null)
                    _buildStatusChip(
                      icon: Icons.location_disabled,
                      label: 'Location unavailable',
                    )
                  else
                    _buildStatusChip(
                      icon: Icons.gps_fixed,
                      label: 'Location active',
                    ),
                  const SizedBox(width: 8),
                  if (_loadingNearby)
                    _buildStatusChip(
                      icon: Icons.radar,
                      label: 'Finding nearby...',
                    )
                  else if (_nearbyError != null)
                    _buildStatusChip(
                      icon: Icons.error_outline,
                      label: 'Nearby unavailable',
                    )
                  else
                    _buildStatusChip(
                      icon: Icons.near_me,
                      label: '${_nearbyPlaces.length} nearby',
                    ),
                ],
              ),
            ),
          ),
        ),

        // =====================================================================
        // SELECTED PLACE CARD
        // =====================================================================

        if (widget.showBottomPlaceOverlay && _selectedPlace != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SafeArea(
              child: _buildSelectedPlaceCard(
                _selectedPlace!,
              ),
            ),
          ),

        // =====================================================================
        // YOU ARE HERE
        // =====================================================================

        if (widget.showBottomPlaceOverlay &&
            _selectedPlace == null &&
            _currentPosition != null)
          Positioned(
            left: 16,
            bottom: 24,
            child: SafeArea(
              child: _buildLocationChip(),
            ),
          ),

        // =====================================================================
        // RECENTER BUTTON
        // =====================================================================

        Positioned(
          right: 16,
          bottom: widget.showBottomPlaceOverlay && _selectedPlace != null
              ? 190
              : 82,
          child: SafeArea(
            child: Material(
              color: Colors.white,
              elevation: 5,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _recenterToCurrentLocation,
                child: const SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(
                    Icons.my_location,
                    color: Color(0xFF0E7774),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STATUS CHIP
  // ===========================================================================

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 3),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF0E7774),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOCATION CHIP
  // ===========================================================================

  Widget _buildLocationChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 4),
            color: Color(0x22000000),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_pin_circle,
            size: 18,
            color: Color(0xFF2563EB),
          ),
          SizedBox(width: 7),
          Text(
            'You are here',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SELECTED PLACE CARD
  // ===========================================================================

  Widget _buildSelectedPlaceCard(
    Map<String, dynamic> place,
  ) {
    final name = _getPlaceText(
      place,
      const [
        'name',
        'title',
      ],
    );

    final category = _getPlaceText(
      place,
      const [
        'category',
        'type',
      ],
    );

    final description = _getPlaceText(
      place,
      const [
        'description',
        'summary',
      ],
    );

    final tags = _getPlaceTags(place);

    final selectedId = _selectedPoiId;

    final canRoute = selectedId != null && _pois.containsKey(selectedId);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              blurRadius: 24,
              spreadRadius: 0,
              offset: Offset(0, 8),
              color: Color(0x33000000),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name ?? 'Unknown place',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (category != null) ...[
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0E7774),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                  onTap: _clearSelectedPoi,
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.close,
                      size: 21,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),

            if (description != null && description.isNotEmpty) ...[
              const SizedBox(
                height: 10,
              ),
              Text(
                description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],

            if (tags.isNotEmpty) ...[
              const SizedBox(
                height: 12,
              ),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: tags.map(
                  (tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFF3F4F6,
                        ),
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(
                            0xFF374151,
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
            ],

            const SizedBox(height: 16),

            // -----------------------------------------------------------------
            // ROUTE BUTTON
            // -----------------------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _loadingRoute || !canRoute
                    ? null
                    : _buildRouteToSelectedPoi,
                icon: _loadingRoute
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        canRoute ? Icons.alt_route : Icons.info_outline,
                      ),
                label: Text(
                  _loadingRoute
                      ? 'Building route...'
                      : canRoute
                          ? 'Route here'
                          : 'Routing unavailable',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E7774),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  disabledForegroundColor: const Color(0xFF6B7280),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // ROUTE INFORMATION
            // -----------------------------------------------------------------

            if (_routeCoordinates.length >= 2) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.route,
                    size: 17,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'A* route ready',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearRoute,
                    child: const Text(
                      'Clear',
                    ),
                  ),
                ],
              ),
            ],

            if (_routeError != null) ...[
              const SizedBox(height: 8),
              Text(
                _routeError!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // PLACE TEXT HELPER
  // ===========================================================================

  String? _getPlaceText(
    Map<String, dynamic> place,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = place[key];

      if (value == null) {
        continue;
      }

      final text = value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return null;
  }

  // ===========================================================================
  // PLACE TAGS HELPER
  // ===========================================================================

  List<String> _getPlaceTags(
    Map<String, dynamic> place,
  ) {
    final possibleTags = [
      place['tags'],
      place['features'],
      place['highlights'],
    ];

    for (final value in possibleTags) {
      if (value is List) {
        return value
            .map(
              (item) => item.toString().trim(),
            )
            .where(
              (item) => item.isNotEmpty,
            )
            .take(6)
            .toList();
      }
    }

    return [];
  }
}
