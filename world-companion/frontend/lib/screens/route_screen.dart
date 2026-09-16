import 'package:flutter/material.dart';

import '../services/api_service.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  Map<String, dynamic>? _pois;

  String? _startId;

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

  // ===========================================================================
  // LOAD POIS
  // ===========================================================================

  Future<void> _loadPois() async {
    try {
      final pois = await ApiService.getPois();

      if (!mounted) return;

      if (pois.isEmpty) {
        setState(() {
          _pois = pois;
          _loading = false;
          _error = 'No places are available for route planning.';
        });

        return;
      }

      setState(() {
        _pois = pois;
        _startId = pois.keys.first;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load places for route planning.';
        _loading = false;
      });
    }
  }

  // ===========================================================================
  // COMPUTE ROUTE
  // ===========================================================================

  Future<void> _computeRoute() async {
    if (_startId == null || _selectedStops.isEmpty) {
      _showMessage(
        'Select at least one place to create a route.',
      );
      return;
    }

    setState(() {
      _computingRoute = true;
      _error = null;
      _routeResult = null;
    });

    try {
      final result = await ApiService.optimizeRoute(
        _startId!,
        _selectedStops.toList(),
      );

      if (!mounted) return;

      setState(() {
        _routeResult = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to calculate the optimized route.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _computingRoute = false;
        });
      }
    }
  }

  // ===========================================================================
  // STARTING POINT CHANGE
  // ===========================================================================

  void _changeStartPoint(String? value) {
    if (value == null) return;

    setState(() {
      _startId = value;

      // A place cannot be both the starting point and a selected stop.
      _selectedStops.remove(value);

      // Clear previous route because the input has changed.
      _routeResult = null;
    });
  }

  // ===========================================================================
  // STOP SELECTION
  // ===========================================================================

  void _toggleStop(String placeId, bool selected) {
    setState(() {
      if (selected) {
        _selectedStops.add(placeId);
      } else {
        _selectedStops.remove(placeId);
      }

      // Previous result no longer represents the current selection.
      _routeResult = null;
    });
  }

  // ===========================================================================
  // MESSAGE
  // ===========================================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF123B43),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Text(message),
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Route Planner',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: const Color(0xFF172326),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _buildBody(theme),
    );
  }

  // ===========================================================================
  // BODY
  // ===========================================================================

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
        final isWide = constraints.maxWidth >= 800;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1100,
              ),
              child: isWide
                  ? _buildWideLayout(theme)
                  : _buildMobileLayout(theme),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // MOBILE LAYOUT
  // ===========================================================================

  Widget _buildMobileLayout(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const SizedBox(height: 24),
        _buildStartPointCard(theme),
        const SizedBox(height: 20),
        _buildStopsCard(theme),
        const SizedBox(height: 20),
        _buildComputeButton(theme),
        if (_error != null) ...[
          const SizedBox(height: 16),
          _buildErrorBanner(),
        ],
        if (_routeResult != null) ...[
          const SizedBox(height: 24),
          _buildRouteResult(theme),
        ],
      ],
    );
  }

  // ===========================================================================
  // WIDE LAYOUT
  // ===========================================================================

  Widget _buildWideLayout(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _buildStartPointCard(theme),
                  const SizedBox(height: 20),
                  _buildStopsCard(theme),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _buildRouteSummaryCard(theme),
                  const SizedBox(height: 20),
                  _buildComputeButton(theme),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorBanner(),
                  ],
                  if (_routeResult != null) ...[
                    const SizedBox(height: 20),
                    _buildRouteResult(theme),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan your route',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF172326),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose where you want to start and the places you want to visit.',
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: const Color(0xFF68777B),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // STARTING POINT CARD
  // ===========================================================================

  Widget _buildStartPointCard(ThemeData theme) {
    final currentStart = _pois![_startId];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.trip_origin_rounded,
            title: 'Starting point',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFDCE5E4),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _startId,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF0E7774),
                ),
                items: _pois!.entries.map((entry) {
                  final place = Map<String, dynamic>.from(
                    entry.value,
                  );

                  final name =
                      place['name']?.toString() ?? entry.key;

                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF172326),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _changeStartPoint,
              ),
            ),
          ),
          if (currentStart is Map) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 17,
                  color: Color(0xFF68777B),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    currentStart['category']?.toString() ??
                        'Destination',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF68777B),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // STOPS CARD
  // ===========================================================================

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
                ),
              ),
              if (_selectedStops.isNotEmpty)
                _buildSelectionBadge(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select one or more places for your optimized route.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF68777B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          if (availableStops.isEmpty)
            const Text(
              'No additional places are available.',
              style: TextStyle(
                color: Color(0xFF68777B),
              ),
            )
          else
            ...availableStops.map(
              (entry) => _buildStopTile(entry),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // STOP TILE
  // ===========================================================================

  Widget _buildStopTile(
    MapEntry<String, dynamic> entry,
  ) {
    final place = Map<String, dynamic>.from(entry.value);

    final name =
        place['name']?.toString() ?? entry.key;

    final category =
        place['category']?.toString() ?? 'Place';

    final isSelected =
        _selectedStops.contains(entry.key);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFDFF4F1)
            : const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF0E7774).withOpacity(0.28)
              : const Color(0xFFDCE5E4),
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (checked) {
          _toggleStop(
            entry.key,
            checked ?? false,
          );
        },
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: const Color(0xFF0E7774),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 2,
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF172326),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            _formatCategory(category),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF68777B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SELECTION BADGE
  // ===========================================================================

  Widget _buildSelectionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFDFF4F1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '${_selectedStops.length} selected',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0E7774),
        ),
      ),
    );
  }

  // ===========================================================================
  // ROUTE SUMMARY
  // ===========================================================================

  Widget _buildRouteSummaryCard(ThemeData theme) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: Icons.route_rounded,
            title: 'Route summary',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.trip_origin_rounded,
                  label: 'Start',
                  value: _getPlaceName(_startId),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.flag_outlined,
                  label: 'Stops',
                  value: '${_selectedStops.length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // COMPUTE BUTTON
  // ===========================================================================

  Widget _buildComputeButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _computingRoute
            ? null
            : _computeRoute,
        icon: _computingRoute
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.alt_route_rounded,
              ),
        label: Text(
          _computingRoute
              ? 'Calculating route...'
              : 'Compute optimized route',
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0E7774),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              const Color(0xFF9BB9B7),
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ROUTE RESULT
  // ===========================================================================

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
            children: [
              Expanded(
                child: _buildSectionTitle(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Optimized route',
                ),
              ),
              if (distance != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1EC),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '${_formatDistance(distance)} km',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF27C4A),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (hops.isEmpty)
            const Text(
              'No route steps were returned.',
              style: TextStyle(
                color: Color(0xFF68777B),
              ),
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

  // ===========================================================================
  // ROUTE HOP
  // ===========================================================================

  Widget _buildHop(
    dynamic rawHop,
    int index,
    int totalHops,
  ) {
    if (rawHop is! Map) {
      return const SizedBox.shrink();
    }

    final hop = Map<String, dynamic>.from(rawHop);

    final fromName =
        hop['from_name']?.toString() ?? 'Starting point';

    final toName =
        hop['to_name']?.toString() ?? 'Destination';

    final distance = hop['distance_km'];

    final isLast = index == totalHops - 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: index == 0
                      ? const Color(0xFF0E7774)
                      : const Color(0xFFDFF4F1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: index == 0
                        ? Colors.white
                        : const Color(0xFF0E7774),
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 42,
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                  ),
                  color: const Color(0xFFDCE5E4),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fromName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF68777B),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Icon(
                    Icons.south_rounded,
                    size: 16,
                    color: Color(0xFF0E7774),
                  ),
                ),
                Text(
                  toName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172326),
                  ),
                ),
                if (distance != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${_formatDistance(distance)} km',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0E7774),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // ERROR STATE
  // ===========================================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1EC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.route_outlined,
                size: 30,
                color: Color(0xFFF27C4A),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Route planning unavailable',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF172326),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ??
                  'Unable to load places for route planning.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF68777B),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });

                _loadPois();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ERROR BANNER
  // ===========================================================================

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF27C4A).withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFF27C4A),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF6B3D2C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SECTION TITLE
  // ===========================================================================

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFDFF4F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: const Color(0xFF0E7774),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF172326),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

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
    if (value.isEmpty) {
      return 'Place';
    }

    return value[0].toUpperCase() + value.substring(1);
  }

  String _formatDistance(dynamic value) {
    if (value == null) {
      return '0';
    }

    final number = double.tryParse(value.toString());

    if (number == null) {
      return value.toString();
    }

    return number.toStringAsFixed(
      number == number.roundToDouble() ? 0 : 2,
    );
  }
}

// =============================================================================
// SECTION CARD
// =============================================================================

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFDCE5E4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// =============================================================================
// SUMMARY ITEM
// =============================================================================

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: const Color(0xFF0E7774),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF68777B),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF172326),
            ),
          ),
        ],
      ),
    );
  }
}