
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../services/api_service.dart';
import '../theme/world_companion_colors.dart';
import '../theme/world_companion_elevation.dart';
import '../theme/world_companion_motion.dart';
import '../theme/world_companion_radius.dart';
import '../theme/world_companion_spacing.dart';
import '../theme/world_companion_typography.dart';

class RealWorldRouteScreen extends StatefulWidget {
  final String placeName;
  final double destinationLatitude;
  final double destinationLongitude;

  const RealWorldRouteScreen({
    super.key,
    required this.placeName,
    required this.destinationLatitude,
    required this.destinationLongitude,
  });

  @override
  State<RealWorldRouteScreen> createState() =>
      _RealWorldRouteScreenState();
}

class _RealWorldRouteScreenState extends State<RealWorldRouteScreen> {
  static const String _routeSourceId = 'worldcompanion-real-world-route';
  static const String _routeLayerId = 'worldcompanion-real-world-route-layer';

  MapLibreMapController? _mapController;

  bool _styleLoaded = false;
  bool _loading = true;
  bool _routeLayerAdded = false;

  String? _error;

  double? _distanceKm;
  double? _durationMinutes;

  String _selectedMode = 'drive';

  Map<String, dynamic>? _routeGeometry;

  TextTheme get _textTheme => WorldCompanionTypography.textTheme;

  @override
  void initState() {
    super.initState();
    debugPrint('RealWorldRouteScreen: INIT');
    _loadRoute();
  }

  @override
  void dispose() {
    _mapController = null;
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    debugPrint('RealWorldRouteScreen: MAP CREATED');
  }

  Future<void> _onStyleLoaded() async {
    debugPrint('RealWorldRouteScreen: STYLE LOADED');
    _styleLoaded = true;

    if (_routeGeometry != null) {
      await _renderRoute();
      await _fitRouteCamera();
    }
  }

  Future<void> _loadRoute() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final position = await _getCurrentPosition();

      if (!mounted) return;

      debugPrint(
        'RealWorldRouteScreen: START = '
        '${position.latitude}, ${position.longitude}',
      );

      debugPrint(
        'RealWorldRouteScreen: DESTINATION = '
        '${widget.destinationLatitude}, '
        '${widget.destinationLongitude}',
      );

      final result = await ApiService.getRealWorldRoute(
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        destinationLatitude: widget.destinationLatitude,
        destinationLongitude: widget.destinationLongitude,
        mode: _selectedMode,
      );

      debugPrint('RealWorldRouteScreen: ROUTE RESULT = $result');

      final distance = _readDouble(result['distance_km']);
      final duration = _readDouble(result['duration_minutes']);
      final geometry = result['geometry'];

      if (geometry is! Map) {
        throw Exception(
          'The routing service returned no route geometry.',
        );
      }

      if (!mounted) return;

      setState(() {
        _distanceKm = distance;
        _durationMinutes = duration;
        _routeGeometry = Map<String, dynamic>.from(geometry);
        _loading = false;
      });

      if (_styleLoaded) {
        await _renderRoute();
        await _fitRouteCamera();
      }
    } catch (e, stackTrace) {
      debugPrint('RealWorldRouteScreen: ROUTE ERROR = $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> _buildRouteFeatureCollection() {
    return {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {'route': true},
          'geometry': _routeGeometry,
        },
      ],
    };
  }

  Future<void> _renderRoute() async {
    final controller = _mapController;

    if (controller == null ||
        !_styleLoaded ||
        _routeGeometry == null) {
      return;
    }

    try {
      final featureCollection = _buildRouteFeatureCollection();

      if (_routeLayerAdded) {
        await controller.setGeoJsonSource(
          _routeSourceId,
          featureCollection,
        );
        debugPrint('RealWorldRouteScreen: ROUTE SOURCE UPDATED');
        return;
      }

      await controller.addGeoJsonSource(
        _routeSourceId,
        featureCollection,
      );

      debugPrint('RealWorldRouteScreen: ROUTE SOURCE ADDED');

      await controller.addLineLayer(
        _routeSourceId,
        _routeLayerId,
        const LineLayerProperties(
          lineColor: '#134074',
          lineWidth: 5.0,
          lineOpacity: 0.92,
          lineCap: 'round',
          lineJoin: 'round',
        ),
        enableInteraction: false,
      );

      _routeLayerAdded = true;
      debugPrint('RealWorldRouteScreen: ROUTE LAYER ADDED');
    } catch (e, stackTrace) {
      debugPrint('RealWorldRouteScreen: ROUTE RENDER ERROR = $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _fitRouteCamera() async {
    final controller = _mapController;
    final geometry = _routeGeometry;

    if (controller == null || geometry == null) return;

    try {
      final bounds = _extractBoundsFromGeometry(geometry);

      if (bounds == null) return;

      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          left: 50,
          top: 310,
          right: 50,
          bottom: 100,
        ),
      );

      debugPrint('RealWorldRouteScreen: CAMERA FIT TO ROUTE');
    } catch (e, stackTrace) {
      debugPrint('RealWorldRouteScreen: CAMERA ERROR = $e');
      debugPrint('$stackTrace');
    }
  }

  LatLngBounds? _extractBoundsFromGeometry(
    Map<String, dynamic> geometry,
  ) {
    final type = geometry['type']?.toString();
    final coordinates = geometry['coordinates'];

    if (coordinates is! List) return null;

    final points = <LatLng>[];

    if (type == 'LineString') {
      _collectLineStringCoordinates(coordinates, points);
    } else if (type == 'MultiLineString') {
      for (final line in coordinates) {
        if (line is List) {
          _collectLineStringCoordinates(line, points);
        }
      }
    }

    if (points.length < 2) return null;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLon = points.first.longitude;
    double maxLon = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
  }

  void _collectLineStringCoordinates(
    List<dynamic> coordinates,
    List<LatLng> output,
  ) {
    for (final coordinate in coordinates) {
      if (coordinate is! List || coordinate.length < 2) continue;

      final longitude = _readDouble(coordinate[0]);
      final latitude = _readDouble(coordinate[1]);

      if (longitude == null || latitude == null) continue;

      output.add(LatLng(latitude, longitude));
    }
  }

  Future<void> _changeMode(String mode) async {
    if (_selectedMode == mode || _loading) return;

    setState(() {
      _selectedMode = mode;
      _loading = true;
      _error = null;
    });

    await _loadRoute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorldCompanionColors.softWhite,
      body: Stack(
        children: [
          Positioned.fill(
            child: MapLibreMap(
              styleString:
                  'https://demotiles.maplibre.org/style.json',
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.destinationLatitude,
                  widget.destinationLongitude,
                ),
                zoom: 14,
              ),
              onMapCreated: _onMapCreated,
              onStyleLoadedCallback: _onStyleLoaded,
              myLocationEnabled: true,
            ),
          ),

          // Top route controls.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  WorldCompanionSpacing.md,
                  WorldCompanionSpacing.sm,
                  WorldCompanionSpacing.md,
                  0,
                ),
                child: _buildRouteInfoCard(),
              ),
            ),
          ),

          // Back button remains accessible above the map.
          Positioned(
            top: MediaQuery.paddingOf(context).top +
                WorldCompanionSpacing.sm,
            left: WorldCompanionSpacing.md,
            child: _MapBackButton(
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),

          if (_error != null)
            Positioned(
              left: WorldCompanionSpacing.md,
              right: WorldCompanionSpacing.md,
              bottom: WorldCompanionSpacing.lg,
              child: SafeArea(
                top: false,
                child: _buildErrorCard(),
              ),
            ),

          if (_loading)
            Positioned.fill(
              child: ColoredBox(
                color: WorldCompanionColors.deepOcean.withOpacity(0.20),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(
                      WorldCompanionSpacing.xl,
                    ),
                    padding: const EdgeInsets.all(
                      WorldCompanionSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: WorldCompanionColors.surface,
                      borderRadius: BorderRadius.circular(
                        WorldCompanionRadius.large,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: WorldCompanionColors.deepOcean
                              .withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 25,
                          height: 25,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: WorldCompanionColors.oceanBlue,
                          ),
                        ),
                        const SizedBox(width: WorldCompanionSpacing.md),
                        Flexible(
                          child: Text(
                            'Building your route...',
                            style: _textTheme.titleSmall?.copyWith(
                              color: WorldCompanionColors.deepOcean,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    return Container(
      margin: const EdgeInsets.only(
        top: 54,
      ),
      padding: const EdgeInsets.all(WorldCompanionSpacing.md),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
        border: Border.all(color: WorldCompanionColors.border),
        boxShadow: [
          BoxShadow(
            color: WorldCompanionColors.deepOcean.withOpacity(0.13),
            blurRadius: 22,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: WorldCompanionColors.infoSurface,
                  borderRadius: BorderRadius.circular(
                    WorldCompanionRadius.medium,
                  ),
                ),
                child: const Icon(
                  Icons.alt_route_rounded,
                  color: WorldCompanionColors.oceanBlue,
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR ROUTE TO',
                      style: _textTheme.labelSmall?.copyWith(
                        color: WorldCompanionColors.mutedText,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: WorldCompanionSpacing.xxs),
                    Text(
                      widget.placeName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _textTheme.titleLarge?.copyWith(
                        color: WorldCompanionColors.deepOcean,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildMetric(
                  icon: Icons.route_rounded,
                  label: 'Distance',
                  value: _distanceKm == null
                      ? '--'
                      : '${_distanceKm!.toStringAsFixed(2)} km',
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.sm),
              Expanded(
                child: _buildMetric(
                  icon: Icons.schedule_rounded,
                  label: 'Estimated time',
                  value: _durationMinutes == null
                      ? '--'
                      : _formatDuration(_durationMinutes!),
                ),
              ),
            ],
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          Text(
            'TRAVEL MODE',
            style: _textTheme.labelSmall?.copyWith(
              color: WorldCompanionColors.mutedText,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildModeButton(
                  mode: 'drive',
                  icon: Icons.directions_car_rounded,
                  label: 'Drive',
                ),
                const SizedBox(width: WorldCompanionSpacing.xs),
                _buildModeButton(
                  mode: 'motorcycle',
                  icon: Icons.two_wheeler_rounded,
                  label: 'Bike',
                ),
                const SizedBox(width: WorldCompanionSpacing.xs),
                _buildModeButton(
                  mode: 'scooter',
                  icon: Icons.electric_scooter_rounded,
                  label: 'Scooter',
                ),
                const SizedBox(width: WorldCompanionSpacing.xs),
                _buildModeButton(
                  mode: 'bicycle',
                  icon: Icons.pedal_bike_rounded,
                  label: 'Cycle',
                ),
                const SizedBox(width: WorldCompanionSpacing.xs),
                _buildModeButton(
                  mode: 'walk',
                  icon: Icons.directions_walk_rounded,
                  label: 'Walk',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(WorldCompanionSpacing.sm),
      decoration: BoxDecoration(
        color: WorldCompanionColors.aiSurface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.medium),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: WorldCompanionColors.oceanBlue,
          ),
          const SizedBox(width: WorldCompanionSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: _textTheme.labelSmall?.copyWith(
                    color: WorldCompanionColors.mutedText,
                  ),
                ),
                const SizedBox(height: WorldCompanionSpacing.xxs),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _textTheme.titleSmall?.copyWith(
                    color: WorldCompanionColors.deepOcean,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String mode,
    required IconData icon,
    required String label,
  }) {
    final selected = _selectedMode == mode;

    return AnimatedContainer(
      duration: WorldCompanionMotion.fast,
      curve: WorldCompanionMotion.standardCurve,
      child: Material(
        color: selected
            ? WorldCompanionColors.deepOcean
            : WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.medium),
        child: InkWell(
          borderRadius: BorderRadius.circular(WorldCompanionRadius.medium),
          onTap: _loading ? null : () => _changeMode(mode),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WorldCompanionSpacing.sm,
              vertical: WorldCompanionSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.medium,
              ),
              border: Border.all(
                color: selected
                    ? WorldCompanionColors.deepOcean
                    : WorldCompanionColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color: selected
                      ? WorldCompanionColors.surface
                      : WorldCompanionColors.secondaryText,
                ),
                const SizedBox(width: WorldCompanionSpacing.xs),
                Text(
                  label,
                  style: _textTheme.labelMedium?.copyWith(
                    color: selected
                        ? WorldCompanionColors.surface
                        : WorldCompanionColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
        border: Border.all(
          color: WorldCompanionColors.error.withOpacity(0.30),
        ),
        boxShadow: [
          BoxShadow(
            color: WorldCompanionColors.deepOcean.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: WorldCompanionColors.error,
              ),
              const SizedBox(width: WorldCompanionSpacing.sm),
              Expanded(
                child: Text(
                  'Could not build route',
                  style: _textTheme.titleMedium?.copyWith(
                    color: WorldCompanionColors.deepOcean,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: WorldCompanionSpacing.sm),
          Text(
            _error!,
            style: _textTheme.bodySmall?.copyWith(
              color: WorldCompanionColors.secondaryText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loadRoute,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
              style: FilledButton.styleFrom(
                backgroundColor: WorldCompanionColors.deepOcean,
                foregroundColor: WorldCompanionColors.surface,
                padding: const EdgeInsets.symmetric(
                  vertical: WorldCompanionSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    WorldCompanionRadius.medium,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(double minutes) {
    if (minutes < 1) return '< 1 min';

    final rounded = minutes.round();

    if (rounded < 60) return '$rounded min';

    final hours = rounded ~/ 60;
    final remainingMinutes = rounded % 60;

    if (remainingMinutes == 0) return '$hours hr';

    return '$hours hr $remainingMinutes min';
  }
}

class _MapBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MapBackButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: WorldCompanionColors.surface,
      elevation: WorldCompanionElevation.low,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.arrow_back_rounded,
            color: WorldCompanionColors.deepOcean,
          ),
        ),
      ),
    );
  }
}
