import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/api_service.dart';
import '../theme/world_companion_colors.dart';
import '../theme/world_companion_elevation.dart';
import '../theme/world_companion_motion.dart';
import '../theme/world_companion_radius.dart';
import '../theme/world_companion_spacing.dart';
import '../theme/world_companion_typography.dart';
import '../widgets/world_map.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  Map<String, dynamic>? _pois;
  String? _startId;
  double? _currentLatitude;
  double? _currentLongitude;

  final Set<String> _selectedStops = {};

  Map<String, dynamic>? _routeResult;

  bool _loading = true;
  bool _computingRoute = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPois();
  }

  Future<void> _loadPois() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Enable device location services and try again.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required for route planning.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final nearby = await ApiService.getNearbyPlaces(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 10.0,
      );

      final places = <String, dynamic>{
        '__current_location__': <String, dynamic>{
          'name': 'My current location',
          'category': 'Current location',
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      };

      for (final raw in nearby) {
        if (raw is! Map) continue;
        final place = Map<String, dynamic>.from(raw);
        final lat = double.tryParse(
          (place['latitude'] ?? '').toString(),
        );
        final lon = double.tryParse(
          (place['longitude'] ?? '').toString(),
        );
        if (lat == null || lon == null) continue;

        final providerId = place['id']?.toString();
        final id = providerId != null && providerId.isNotEmpty
            ? providerId
            : '${place['name'] ?? 'place'}_${lat}_$lon';

        if (id == '__current_location__') continue;
        places[id] = place;
      }

      if (!mounted) return;
      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
        _pois = places;
        _startId = '__current_location__';
        _selectedStops.removeWhere((id) => !places.containsKey(id) ||
            id == '__current_location__');
        _routeResult = null;
        _loading = false;
        _error = places.length == 1
            ? 'No nearby destinations were found within 10 km.'
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pois = null;
        _startId = null;
        _selectedStops.clear();
        _routeResult = null;
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _computeRoute() async {
    if (_currentLatitude == null || _currentLongitude == null) {
      _showMessage('Your current location is not available. Try again.');
      return;
    }
    if (_selectedStops.isEmpty) {
      _showMessage('Select at least one destination.');
      return;
    }

    setState(() {
      _computingRoute = true;
      _error = null;
      _routeResult = null;
    });

    try {
      var fromLatitude = _currentLatitude!;
      var fromLongitude = _currentLongitude!;
      var fromName = 'My current location';
      var totalDistance = 0.0;
      final hops = <Map<String, dynamic>>[];

      for (final id in _selectedStops.toList()) {
        final place = _asStringMap(_pois?[id]);
        final toLatitude = double.tryParse(
          (place['latitude'] ?? '').toString(),
        );
        final toLongitude = double.tryParse(
          (place['longitude'] ?? '').toString(),
        );
        if (toLatitude == null || toLongitude == null) continue;

        final toName = place['name']?.toString() ?? id;
        final segment = await ApiService.getRealWorldRoute(
          startLatitude: fromLatitude,
          startLongitude: fromLongitude,
          destinationLatitude: toLatitude,
          destinationLongitude: toLongitude,
        );

        final distance = double.tryParse(
          (segment['distance_km'] ?? '').toString(),
        ) ?? 0.0;
        totalDistance += distance;
        hops.add({
          'from_name': fromName,
          'to_name': toName,
          'distance_km': distance,
        });

        fromLatitude = toLatitude;
        fromLongitude = toLongitude;
        fromName = toName;
      }

      if (hops.isEmpty) {
        throw Exception('The selected destinations have no valid coordinates.');
      }

      if (!mounted) return;
      setState(() {
        _routeResult = {
          'total_distance_km': totalDistance,
          'hops': hops,
        };
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to calculate the route. ${error.toString().replaceFirst('Exception: ', '')}';
      });
    } finally {
      if (mounted) {
        setState(() => _computingRoute = false);
      }
    }
  }

  void _toggleStop(String placeId, bool selected) {
    setState(() {
      if (selected) {
        _selectedStops.add(placeId);
      } else {
        _selectedStops.remove(placeId);
      }

      _routeResult = null;
      _error = null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: WorldCompanionColors.deepOcean,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            WorldCompanionRadius.medium,
          ),
        ),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Route planner',
          style: WorldCompanionTypography.textTheme.titleLarge,
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: WorldCompanionColors.primaryText,
        elevation: WorldCompanionElevation.none,
        scrolledUnderElevation: WorldCompanionElevation.none,
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_pois == null || _pois!.isEmpty) {
      return _buildErrorState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final pagePadding = constraints.maxWidth >= 1200
            ? WorldCompanionSpacing.desktopPage
            : constraints.maxWidth >= 700
                ? WorldCompanionSpacing.tabletPage
                : WorldCompanionSpacing.mobilePage;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            pagePadding,
            WorldCompanionSpacing.md,
            pagePadding,
            WorldCompanionSpacing.xxxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: WorldCompanionSpacing.lg),
                  if (isWide) ...[
                    _buildMapSection(),
                    const SizedBox(height: WorldCompanionSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              _buildStartPointCard(theme),
                              const SizedBox(
                                height: WorldCompanionSpacing.md,
                              ),
                              _buildStopsCard(theme),
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: WorldCompanionSpacing.lg,
                        ),
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _buildRouteSummaryCard(theme),
                              const SizedBox(
                                height: WorldCompanionSpacing.md,
                              ),
                              _buildComputeButton(),
                              if (_error != null) ...[
                                const SizedBox(
                                  height: WorldCompanionSpacing.md,
                                ),
                                _buildErrorBanner(),
                              ],
                              if (_routeResult != null) ...[
                                const SizedBox(
                                  height: WorldCompanionSpacing.md,
                                ),
                                _buildRouteResult(theme),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    _buildMapSection(),
                    const SizedBox(height: WorldCompanionSpacing.lg),
                    _buildStartPointCard(theme),
                    const SizedBox(height: WorldCompanionSpacing.md),
                    _buildStopsCard(theme),
                    const SizedBox(height: WorldCompanionSpacing.md),
                    _buildRouteSummaryCard(theme),
                    const SizedBox(height: WorldCompanionSpacing.md),
                    _buildComputeButton(),
                    if (_error != null) ...[
                      const SizedBox(height: WorldCompanionSpacing.md),
                      _buildErrorBanner(),
                    ],
                    if (_routeResult != null) ...[
                      const SizedBox(height: WorldCompanionSpacing.lg),
                      _buildRouteResult(theme),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan your next journey',
          style: WorldCompanionTypography.editorial.copyWith(
            fontSize: 32,
          ),
        ),
        const SizedBox(height: WorldCompanionSpacing.xs),
        Text(
          'Choose a starting point, select the places you want to visit, '
          'and calculate your optimized route.',
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Container(
      width: double.infinity,
      height: 360,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: WorldCompanionColors.mapSurface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
        border: Border.all(
          color: WorldCompanionColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: WorldCompanionColors.deepOcean.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const WorldMap(showPoiMarkers: false),
    );
  }

  Widget _buildStartPointCard(ThemeData theme) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.trip_origin_rounded,
            title: 'Starting point',
            subtitle: 'Your current GPS location',
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          Container(
            padding: const EdgeInsets.all(WorldCompanionSpacing.md),
            decoration: BoxDecoration(
              color: WorldCompanionColors.aiSurface,
              borderRadius: BorderRadius.circular(WorldCompanionRadius.medium),
              border: Border.all(color: WorldCompanionColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.my_location_rounded,
                  color: WorldCompanionColors.oceanBlue,
                ),
                const SizedBox(width: WorldCompanionSpacing.sm),
                Expanded(
                  child: Text(
                    'My current location',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.gps_fixed_rounded,
                  color: WorldCompanionColors.success,
                ),
              ],
            ),
          ),
          if (_currentLatitude != null && _currentLongitude != null) ...[
            const SizedBox(height: WorldCompanionSpacing.xs),
            Text(
              '${_currentLatitude!.toStringAsFixed(5)}, ${_currentLongitude!.toStringAsFixed(5)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStopsCard(ThemeData theme) {
    final availableStops = _pois!.entries
        .where((entry) => entry.key != _startId)
        .toList();

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSectionTitle(
                  icon: Icons.place_outlined,
                  title: 'Places to visit',
                  subtitle: 'Add one or more stops',
                ),
              ),
              if (_selectedStops.isNotEmpty) _buildSelectionBadge(),
            ],
          ),
          const SizedBox(height: WorldCompanionSpacing.sm),
          Text(
            'Select the destinations you want included in your route.',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          if (availableStops.isEmpty)
            Text(
              'No additional places are available.',
              style: theme.textTheme.bodyMedium,
            )
          else
            ...availableStops.map(_buildStopTile),
        ],
      ),
    );
  }

  Widget _buildStopTile(MapEntry<String, dynamic> entry) {
    final place = _asStringMap(entry.value);
    final name = place['name']?.toString() ?? entry.key;
    final category = place['category']?.toString() ?? 'Place';
    final isSelected = _selectedStops.contains(entry.key);

    return AnimatedContainer(
      duration: WorldCompanionMotion.fast,
      curve: WorldCompanionMotion.standardCurve,
      margin: const EdgeInsets.only(
        bottom: WorldCompanionSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isSelected
            ? WorldCompanionColors.infoSurface
            : WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.medium,
        ),
        border: Border.all(
          color: isSelected
              ? WorldCompanionColors.oceanBlue
              : WorldCompanionColors.border,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: _computingRoute
            ? null
            : (checked) => _toggleStop(
                  entry.key,
                  checked ?? false,
                ),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: WorldCompanionColors.oceanBlue,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: WorldCompanionSpacing.sm,
          vertical: WorldCompanionSpacing.xxs,
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: WorldCompanionTypography.textTheme.titleSmall,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(
            top: WorldCompanionSpacing.xxs,
          ),
          child: Text(
            _formatCategory(category),
            style: WorldCompanionTypography.textTheme.bodySmall,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WorldCompanionSpacing.sm,
        vertical: WorldCompanionSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: WorldCompanionColors.infoSurface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.pill,
        ),
      ),
      child: Text(
        '${_selectedStops.length} selected',
        style: WorldCompanionTypography.textTheme.labelMedium?.copyWith(
          color: WorldCompanionColors.oceanBlue,
        ),
      ),
    );
  }

  Widget _buildRouteSummaryCard(ThemeData theme) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.route_rounded,
            title: 'Route summary',
            subtitle: 'Your current selections',
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.trip_origin_rounded,
                  label: 'Starting point',
                  value: _getPlaceName(_startId),
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.sm),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.flag_outlined,
                  label: 'Selected stops',
                  value: '${_selectedStops.length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComputeButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _computingRoute ? null : _computeRoute,
        icon: _computingRoute
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.alt_route_rounded),
        label: Text(
          _computingRoute
              ? 'Calculating route...'
              : 'Compute optimized route',
        ),
        style: FilledButton.styleFrom(
          backgroundColor: WorldCompanionColors.oceanBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: WorldCompanionColors.softBlue,
          padding: const EdgeInsets.symmetric(
            vertical: WorldCompanionSpacing.md,
            horizontal: WorldCompanionSpacing.lg,
          ),
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

  Widget _buildRouteResult(ThemeData theme) {
    final result = _routeResult!;
    final distance = result['total_distance_km'];
    final rawHops = result['hops'];
    final hops = rawHops is List ? rawHops : <dynamic>[];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSectionTitle(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Optimized route',
                  subtitle: 'Your calculated journey',
                ),
              ),
              if (distance != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: WorldCompanionSpacing.sm,
                    vertical: WorldCompanionSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: WorldCompanionColors.successSurface,
                    borderRadius: BorderRadius.circular(
                      WorldCompanionRadius.pill,
                    ),
                  ),
                  child: Text(
                    '${_formatDistance(distance)} km',
                    style: WorldCompanionTypography
                        .textTheme.labelMedium
                        ?.copyWith(
                      color: WorldCompanionColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: WorldCompanionSpacing.lg),
          if (hops.isEmpty)
            Text(
              'No route steps were returned.',
              style: theme.textTheme.bodyMedium,
            )
          else
            ...List.generate(
              hops.length,
              (index) => _buildHop(
                hops[index],
                index,
                hops.length,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHop(dynamic rawHop, int index, int totalHops) {
    if (rawHop is! Map) {
      return const SizedBox.shrink();
    }

    final hop = Map<String, dynamic>.from(rawHop);
    final fromName = hop['from_name']?.toString() ?? 'Starting point';
    final toName = hop['to_name']?.toString() ?? 'Destination';
    final distance = hop['distance_km'];
    final isLast = index == totalHops - 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: index == 0
                      ? WorldCompanionColors.oceanBlue
                      : WorldCompanionColors.infoSurface,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: WorldCompanionTypography.textTheme.labelMedium
                      ?.copyWith(
                    color: index == 0
                        ? Colors.white
                        : WorldCompanionColors.oceanBlue,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 42,
                  margin: const EdgeInsets.symmetric(
                    vertical: WorldCompanionSpacing.xxs,
                  ),
                  color: WorldCompanionColors.border,
                ),
            ],
          ),
        ),
        const SizedBox(width: WorldCompanionSpacing.sm),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(
              bottom: WorldCompanionSpacing.md,
            ),
            padding: const EdgeInsets.all(
              WorldCompanionSpacing.md,
            ),
            decoration: BoxDecoration(
              color: WorldCompanionColors.aiSurface,
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.large,
              ),
              border: Border.all(
                color: WorldCompanionColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fromName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: WorldCompanionTypography.textTheme.bodySmall,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: WorldCompanionSpacing.xs,
                  ),
                  child: Icon(
                    Icons.south_rounded,
                    size: 17,
                    color: WorldCompanionColors.oceanBlue,
                  ),
                ),
                Text(
                  toName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: WorldCompanionTypography.textTheme.titleSmall,
                ),
                if (distance != null) ...[
                  const SizedBox(height: WorldCompanionSpacing.sm),
                  Row(
                    children: [
                      const Icon(
                        Icons.straighten_rounded,
                        size: 15,
                        color: WorldCompanionColors.mutedText,
                      ),
                      const SizedBox(width: WorldCompanionSpacing.xs),
                      Text(
                        '${_formatDistance(distance)} km',
                        style: WorldCompanionTypography
                            .textTheme.labelMedium
                            ?.copyWith(
                          color: WorldCompanionColors.oceanBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(
          WorldCompanionSpacing.xl,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: WorldCompanionColors.errorSurface,
                borderRadius: BorderRadius.circular(
                  WorldCompanionRadius.extraLarge,
                ),
              ),
              child: const Icon(
                Icons.route_outlined,
                size: 32,
                color: WorldCompanionColors.error,
              ),
            ),
            const SizedBox(height: WorldCompanionSpacing.lg),
            Text(
              'Route planning unavailable',
              textAlign: TextAlign.center,
              style: WorldCompanionTypography.textTheme.headlineSmall,
            ),
            const SizedBox(height: WorldCompanionSpacing.xs),
            Text(
              _error ?? 'Unable to load places for route planning.',
              textAlign: TextAlign.center,
              style: WorldCompanionTypography.textTheme.bodyMedium
                  ?.copyWith(height: 1.6),
            ),
            const SizedBox(height: WorldCompanionSpacing.lg),
            OutlinedButton.icon(
              onPressed: _loading ? null : _loadPois,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        WorldCompanionSpacing.md,
      ),
      decoration: BoxDecoration(
        color: WorldCompanionColors.errorSurface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.medium,
        ),
        border: Border.all(
          color: WorldCompanionColors.error.withOpacity(0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: WorldCompanionColors.error,
            size: 20,
          ),
          const SizedBox(width: WorldCompanionSpacing.sm),
          Expanded(
            child: Text(
              _error!,
              style: WorldCompanionTypography.textTheme.bodySmall
                  ?.copyWith(
                color: WorldCompanionColors.error,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          child: Icon(
            icon,
            size: 21,
            color: WorldCompanionColors.oceanBlue,
          ),
        ),
        const SizedBox(width: WorldCompanionSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: WorldCompanionTypography.textTheme.titleMedium,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: WorldCompanionSpacing.xxs),
                Text(
                  subtitle,
                  style: WorldCompanionTypography.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _getPlaceName(String? id) {
    if (id == null || _pois == null) {
      return 'Not selected';
    }

    final place = _pois![id];

    if (place is Map) {
      return place['name']?.toString() ?? id;
    }

    return id;
  }

  String _formatCategory(String value) {
    if (value.isEmpty) return 'Place';

    return value[0].toUpperCase() + value.substring(1);
  }

  String _formatDistance(dynamic value) {
    if (value == null) return '0';

    final number = double.tryParse(value.toString());

    if (number == null) return value.toString();

    return number.toStringAsFixed(
      number == number.roundToDouble() ? 0 : 2,
    );
  }

  Map<String, dynamic> _asStringMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        WorldCompanionSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
        border: Border.all(
          color: WorldCompanionColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: WorldCompanionColors.deepOcean.withOpacity(0.035),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(
        WorldCompanionSpacing.md,
      ),
      decoration: BoxDecoration(
        color: WorldCompanionColors.aiSurface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.large,
        ),
        border: Border.all(
          color: WorldCompanionColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: WorldCompanionColors.oceanBlue,
          ),
          const SizedBox(height: WorldCompanionSpacing.sm),
          Text(
            label,
            style: WorldCompanionTypography.textTheme.labelMedium,
          ),
          const SizedBox(height: WorldCompanionSpacing.xs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: WorldCompanionTypography.textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

