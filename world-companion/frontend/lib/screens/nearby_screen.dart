import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/api_service.dart';
import '../theme/world_companion_colors.dart';
import '../theme/world_companion_elevation.dart';
import '../theme/world_companion_radius.dart';
import '../theme/world_companion_spacing.dart';
import '../theme/world_companion_typography.dart';
import '../widgets/world_map.dart';
import 'place_details_screen.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  static const double radiusKm = 10.0;

  static const List<Map<String, String>> categories = [
    {'label': 'All places', 'value': 'all'},
    {'label': 'Food & dining', 'value': 'food'},
    {'label': 'Stays', 'value': 'stays'},
    {'label': 'Explore', 'value': 'explore'},
    {'label': 'Shopping', 'value': 'shopping'},
    {'label': 'Leisure', 'value': 'leisure'},
  ];

  List<Map<String, dynamic>> places = [];
  bool loading = true;
  String? error;
  String selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadNearbyPlaces();
  }

  Future<void> _loadNearbyPlaces() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

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

      if (permission == LocationPermission.denied) {
        throw Exception('Location permission was denied.');
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is permanently denied.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Location request timed out.');
        },
      );

      final result = await ApiService.getNearbyPlaces(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: radiusKm,
        category:
            selectedCategory == 'all' ? null : selectedCategory,
      );

      if (!mounted) return;

      setState(() {
        places = result
            .map((place) => Map<String, dynamic>.from(place))
            .toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object errorObject) {
    final message = errorObject.toString().toLowerCase();

    if (message.contains('permission')) {
      return 'Location permission is required to discover nearby places.';
    }

    if (message.contains('disabled')) {
      return 'Please enable location services and try again.';
    }

    if (message.contains('timed out')) {
      return 'Your location took too long to respond. Please try again.';
    }

    if (message.contains('location')) {
      return 'Unable to determine your current location.';
    }

    return 'Something went wrong while loading nearby places.';
  }

  Future<void> _changeCategory(String category) async {
    if (selectedCategory == category || loading) return;

    setState(() {
      selectedCategory = category;
    });

    await _loadNearbyPlaces();
  }

  Future<void> _openPlace(Map<String, dynamic> place) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PlaceDetailsScreen(place: place),
      ),
    );
  }

  Future<void> _openMap() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const WorldMap(),
      ),
    );
  }

  String _formatDistance(dynamic distance) {
    if (distance == null) return '';

    final value = double.tryParse(distance.toString());

    if (value == null) return '';
    if (value < 0) return '';

    if (value < 1) {
      return '${(value * 1000).round()} m away';
    }

    return '${value.toStringAsFixed(1)} km away';
  }

  IconData _categoryIcon(String? category, String? subcategory) {
    switch (category?.toLowerCase()) {
      case 'food':
        switch (subcategory?.toLowerCase()) {
          case 'cafe':
            return Icons.local_cafe_rounded;
          case 'bar':
          case 'pub':
          case 'biergarten':
            return Icons.local_bar_rounded;
          case 'fast_food':
          case 'food_court':
            return Icons.fastfood_rounded;
          default:
            return Icons.restaurant_rounded;
        }

      case 'stays':
        switch (subcategory?.toLowerCase()) {
          case 'guest_house':
            return Icons.house_rounded;
          case 'resort':
            return Icons.beach_access_rounded;
          default:
            return Icons.hotel_rounded;
        }

      case 'explore':
        switch (subcategory?.toLowerCase()) {
          case 'museum':
            return Icons.museum_rounded;
          case 'zoo':
            return Icons.pets_rounded;
          case 'aquarium':
            return Icons.water_rounded;
          case 'theme_park':
            return Icons.attractions_rounded;
          case 'viewpoint':
            return Icons.visibility_rounded;
          default:
            return Icons.account_balance_rounded;
        }

      case 'shopping':
        switch (subcategory?.toLowerCase()) {
          case 'market':
            return Icons.storefront_rounded;
          default:
            return Icons.shopping_bag_rounded;
        }

      case 'leisure':
        switch (subcategory?.toLowerCase()) {
          case 'park':
          case 'garden':
            return Icons.park_rounded;
          case 'cinema':
            return Icons.movie_rounded;
          case 'playground':
            return Icons.sports_esports_rounded;
          default:
            return Icons.spa_rounded;
        }

      default:
        return Icons.place_rounded;
    }
  }

  String _prettySubcategory(String? category, String? subcategory) {
    if (subcategory == null || subcategory.isEmpty) {
      return _prettyCategory(category);
    }

    const labels = {
      'fast_food': 'Fast Food',
      'food_court': 'Food Court',
      'guest_house': 'Guest House',
      'theme_park': 'Theme Park',
      'department_store': 'Department Store',
    };

    return labels[subcategory.toLowerCase()] ??
        _formatLabel(subcategory);
  }

  String _prettyCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'food':
        return 'Food & Dining';
      case 'stays':
        return 'Stays';
      case 'explore':
        return 'Explore';
      case 'shopping':
        return 'Shopping';
      case 'leisure':
        return 'Leisure';
      default:
        return category == null || category.isEmpty
            ? 'Place'
            : _formatLabel(category);
    }
  }

  String _formatLabel(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Widget _buildHeader() {
    final textTheme = WorldCompanionTypography.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: WorldCompanionSpacing.mobilePage,
        vertical: WorldCompanionSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: WorldCompanionColors.surface,
        border: Border(
          bottom: BorderSide(color: WorldCompanionColors.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: WorldCompanionColors.infoSurface,
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.medium,
              ),
            ),
            child: const Icon(
              Icons.explore_rounded,
              color: WorldCompanionColors.oceanBlue,
              size: 25,
            ),
          ),
          const SizedBox(width: WorldCompanionSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nearby', style: textTheme.headlineSmall),
                const SizedBox(height: WorldCompanionSpacing.xxs),
                Text(
                  'Discover places around you',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh nearby places',
            onPressed: loading ? null : _loadNearbyPlaces,
            icon: const Icon(Icons.refresh_rounded),
            color: WorldCompanionColors.oceanBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBanner() {
    final textTheme = WorldCompanionTypography.textTheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        WorldCompanionSpacing.mobilePage,
        WorldCompanionSpacing.lg,
        WorldCompanionSpacing.mobilePage,
        0,
      ),
      padding: const EdgeInsets.all(WorldCompanionSpacing.md),
      decoration: BoxDecoration(
        color: WorldCompanionColors.infoSurface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
        border: Border.all(color: WorldCompanionColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: WorldCompanionColors.surface,
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.medium,
              ),
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: WorldCompanionColors.oceanBlue,
            ),
          ),
          const SizedBox(width: WorldCompanionSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Around your location',
                  style: textTheme.titleSmall?.copyWith(
                    color: WorldCompanionColors.deepOcean,
                  ),
                ),
                const SizedBox(height: WorldCompanionSpacing.xxs),
                Text(
                  'Discover places within ${radiusKm.toStringAsFixed(0)} km',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: WorldCompanionSpacing.sm),
          Container(
            constraints: const BoxConstraints(minWidth: 38),
            padding: const EdgeInsets.symmetric(
              horizontal: WorldCompanionSpacing.sm,
              vertical: WorldCompanionSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: WorldCompanionColors.surface,
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.medium,
              ),
            ),
            child: Text(
              loading ? '—' : places.length.toString(),
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: WorldCompanionColors.oceanBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: WorldCompanionSpacing.mobilePage,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: WorldCompanionSpacing.sm),
        itemBuilder: (context, index) {
          final category = categories[index];
          final label = category['label']!;
          final value = category['value']!;
          final isSelected = selectedCategory == value;

          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: loading ? null : (_) => _changeCategory(value),
            selectedColor: WorldCompanionColors.deepOcean,
            backgroundColor: WorldCompanionColors.surface,
            labelStyle: WorldCompanionTypography.textTheme.labelLarge
                ?.copyWith(
              color: isSelected
                  ? Colors.white
                  : WorldCompanionColors.secondaryText,
            ),
            side: BorderSide(
              color: isSelected
                  ? WorldCompanionColors.deepOcean
                  : WorldCompanionColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.medium,
              ),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place) {
    final textTheme = WorldCompanionTypography.textTheme;
    final name = place['name']?.toString() ?? 'Unknown place';
    final category = place['category']?.toString();
    final subcategory = place['subcategory']?.toString();
    final distance = _formatDistance(place['distance_km']);
    final tags = place['tags'];

    return Material(
      color: WorldCompanionColors.surface,
      borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
      child: InkWell(
        onTap: () => _openPlace(place),
        borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
        child: Container(
          padding: const EdgeInsets.all(WorldCompanionSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
            border: Border.all(color: WorldCompanionColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x060B2545),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
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
                child: Icon(
                  _categoryIcon(category, subcategory),
                  color: WorldCompanionColors.oceanBlue,
                  size: 26,
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
                      style: textTheme.titleMedium?.copyWith(
                        color: WorldCompanionColors.deepOcean,
                      ),
                    ),
                    const SizedBox(height: WorldCompanionSpacing.xs),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: WorldCompanionSpacing.xs,
                      runSpacing: WorldCompanionSpacing.xxs,
                      children: [
                        Text(
                          _prettySubcategory(category, subcategory),
                          style: textTheme.labelMedium?.copyWith(
                            color: WorldCompanionColors.oceanBlue,
                          ),
                        ),
                        if (distance.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.near_me_outlined,
                                size: 14,
                                color: WorldCompanionColors.mutedText,
                              ),
                              const SizedBox(width: WorldCompanionSpacing.xxs),
                              Text(
                                distance,
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (tags is List && tags.isNotEmpty) ...[
                      const SizedBox(height: WorldCompanionSpacing.sm),
                      Wrap(
                        spacing: WorldCompanionSpacing.xs,
                        runSpacing: WorldCompanionSpacing.xs,
                        children: tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: WorldCompanionSpacing.sm,
                              vertical: WorldCompanionSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: WorldCompanionColors.aiSurface,
                              borderRadius: BorderRadius.circular(
                                WorldCompanionRadius.small,
                              ),
                            ),
                            child: Text(
                              _formatLabel(tag.toString()),
                              style: textTheme.labelSmall,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.xs),
              const Padding(
                padding: EdgeInsets.only(top: WorldCompanionSpacing.sm),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: WorldCompanionColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: WorldCompanionColors.oceanBlue,
          ),
          SizedBox(height: WorldCompanionSpacing.md),
          Text(
            'Finding places around you…',
            style: TextStyle(
              color: WorldCompanionColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return _buildMessageState(
      icon: Icons.location_off_outlined,
      title: 'Unable to load nearby places',
      message: error ?? 'Please try again.',
      actionLabel: 'Try again',
      onAction: _loadNearbyPlaces,
      isError: true,
    );
  }

  Widget _buildEmptyState() {
    final selectedLabel = categories.firstWhere(
      (item) => item['value'] == selectedCategory,
      orElse: () => {
        'label': 'places',
        'value': selectedCategory,
      },
    )['label']!;

    return _buildMessageState(
      icon: Icons.explore_outlined,
      title: 'No places found',
      message: selectedCategory == 'all'
          ? 'There are no places within ${radiusKm.toStringAsFixed(0)} km.'
          : 'No $selectedLabel places were found within ${radiusKm.toStringAsFixed(0)} km.',
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    bool isError = false,
  }) {
    final textTheme = WorldCompanionTypography.textTheme;
    final tint = isError
        ? WorldCompanionColors.error
        : WorldCompanionColors.oceanBlue;
    final tintSurface = isError
        ? WorldCompanionColors.errorSurface
        : WorldCompanionColors.infoSurface;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(WorldCompanionSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: tintSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tint, size: 34),
              ),
              const SizedBox(height: WorldCompanionSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: WorldCompanionSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: WorldCompanionSpacing.lg),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(actionLabel),
                  style: FilledButton.styleFrom(
                    backgroundColor: WorldCompanionColors.deepOcean,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: WorldCompanionSpacing.lg,
                      vertical: WorldCompanionSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        WorldCompanionRadius.medium,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlacesList() {
    if (places.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      color: WorldCompanionColors.oceanBlue,
      onRefresh: _loadNearbyPlaces,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          WorldCompanionSpacing.mobilePage,
          WorldCompanionSpacing.md,
          WorldCompanionSpacing.mobilePage,
          112,
        ),
        itemCount: places.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: WorldCompanionSpacing.md),
        itemBuilder: (context, index) => _buildPlaceCard(places[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorldCompanionColors.aiSurface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildLocationBanner(),
            const SizedBox(height: WorldCompanionSpacing.lg),
            _buildCategoryFilters(),
            const SizedBox(height: WorldCompanionSpacing.sm),
            Expanded(
              child: loading
                  ? _buildLoading()
                  : error != null
                      ? _buildError()
                      : _buildPlacesList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openMap,
        backgroundColor: WorldCompanionColors.deepOcean,
        foregroundColor: Colors.white,
        elevation: WorldCompanionElevation.low,
        icon: const Icon(Icons.map_outlined),
        label: const Text(
          'View on map',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
