
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/world_companion_colors.dart';
import '../theme/world_companion_elevation.dart';
import '../theme/world_companion_motion.dart';
import '../theme/world_companion_radius.dart';
import '../theme/world_companion_spacing.dart';
import '../theme/world_companion_typography.dart';
import '../widgets/world_map.dart';
import 'app_shell.dart';
import 'place_details_screen.dart';

class ExploreScreen extends StatefulWidget {
  final bool routeMode;

  const ExploreScreen({
    super.key,
    this.routeMode = false,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  Map<String, dynamic> _pois = {};
  bool _loading = true;
  String? _error;

  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Parks',
    'Food',
    'Shopping',
    'Landmarks',
    'Areas',
  ];

  TextTheme get _textTheme => WorldCompanionTypography.textTheme;

  @override
  void initState() {
    super.initState();
    _loadPois();
  }

  Future<void> _loadPois() async {
    try {
      final data = await ApiService.getPois();

      if (!mounted) return;

      setState(() {
        _pois = data;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<MapEntry<String, dynamic>> get _filteredPois {
    final query = _searchQuery.trim().toLowerCase();

    return _pois.entries.where((entry) {
      if (entry.value is! Map) return false;

      final place = Map<String, dynamic>.from(entry.value);
      final name = place['name']?.toString().toLowerCase() ?? '';
      final category = place['category']?.toString().toLowerCase() ?? '';

      final matchesSearch =
          query.isEmpty ||
          name.contains(query) ||
          category.contains(query);

      if (_selectedCategory == 'All') {
        return matchesSearch;
      }

      final selected = _selectedCategory.toLowerCase();

      final matchesCategory = switch (selected) {
        'parks' => category == 'park' || category == 'parks',
        'food' =>
          category == 'food' ||
          category == 'restaurant' ||
          category == 'restaurants',
        'shopping' =>
          category == 'shopping' ||
          category == 'shop' ||
          category == 'shops',
        'landmarks' =>
          category == 'landmark' || category == 'landmarks',
        'areas' => category == 'area' || category == 'areas',
        _ => true,
      };

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorldCompanionColors.softWhite,
      appBar: AppBar(
        backgroundColor: WorldCompanionColors.softWhite,
        surfaceTintColor: Colors.transparent,
        elevation: WorldCompanionElevation.none,
        leading: IconButton(
          tooltip: 'Go home',
          onPressed: () => AppShellNavigation.of(context).goHome(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: WorldCompanionColors.deepOcean,
          ),
        ),
        title: Text(
          widget.routeMode ? 'Plan a Route' : 'Explore',
          style: _textTheme.titleLarge?.copyWith(
            color: WorldCompanionColors.deepOcean,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: WorldCompanionColors.oceanBlue,
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    final places = _filteredPois;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final horizontalPadding = isWide
            ? WorldCompanionSpacing.desktopPage
            : WorldCompanionSpacing.mobilePage;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            WorldCompanionSpacing.md,
            horizontalPadding,
            WorldCompanionSpacing.xxxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntro(),
                  const SizedBox(height: WorldCompanionSpacing.lg),
                  _buildSearchField(),
                  const SizedBox(height: WorldCompanionSpacing.lg),
                  _buildMap(isWide: isWide),
                  if (widget.routeMode) ...[
                    const SizedBox(height: WorldCompanionSpacing.lg),
                    _buildRouteModeCard(),
                  ],
                  const SizedBox(height: WorldCompanionSpacing.xxl),
                  _buildSectionHeading(
                    'Explore by category',
                    'Find places by interest',
                  ),
                  const SizedBox(height: WorldCompanionSpacing.md),
                  _buildCategories(),
                  const SizedBox(height: WorldCompanionSpacing.xxl),
                  _buildPlacesHeader(places.length),
                  const SizedBox(height: WorldCompanionSpacing.md),
                  if (places.isEmpty)
                    _buildEmptyState()
                  else
                    _buildPlacesGrid(places, isWide: isWide),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: WorldCompanionSpacing.sm,
            vertical: WorldCompanionSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: WorldCompanionColors.infoSurface,
            borderRadius: BorderRadius.circular(WorldCompanionRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.explore_outlined,
                size: 15,
                color: WorldCompanionColors.oceanBlue,
              ),
              const SizedBox(width: WorldCompanionSpacing.xs),
              Text(
                widget.routeMode ? 'YOUR NEXT JOURNEY' : 'YOUR WORLD, DISCOVERED',
                style: _textTheme.labelSmall?.copyWith(
                  color: WorldCompanionColors.oceanBlue,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: WorldCompanionSpacing.md),
        Text(
          widget.routeMode ? 'Plan your journey' : 'Discover the world',
          style: _textTheme.displayMedium?.copyWith(
            color: WorldCompanionColors.deepOcean,
            height: 1.12,
          ),
        ),
        const SizedBox(height: WorldCompanionSpacing.xs),
        Text(
          widget.routeMode
              ? 'Choose destinations and prepare your route.'
              : 'Find places worth experiencing, right on your map.',
          style: _textTheme.bodyMedium?.copyWith(
            color: WorldCompanionColors.secondaryText,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) {
        setState(() => _searchQuery = value);
      },
      style: _textTheme.bodyMedium?.copyWith(
        color: WorldCompanionColors.primaryText,
      ),
      decoration: InputDecoration(
        hintText: 'Search places and categories',
        hintStyle: _textTheme.bodyMedium?.copyWith(
          color: WorldCompanionColors.mutedText,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: WorldCompanionColors.oceanBlue,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: () => setState(() => _searchQuery = ''),
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: WorldCompanionColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: WorldCompanionSpacing.md,
          vertical: WorldCompanionSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
          borderSide: const BorderSide(color: WorldCompanionColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
          borderSide: const BorderSide(color: WorldCompanionColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
          borderSide: const BorderSide(
            color: WorldCompanionColors.oceanBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMap({required bool isWide}) {
    return Container(
      width: double.infinity,
      height: isWide ? 460 : 340,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: WorldCompanionColors.mapSurface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.extraLarge),
        border: Border.all(color: WorldCompanionColors.border),
        boxShadow: [
          BoxShadow(
            color: WorldCompanionColors.deepOcean.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const WorldMap(),
    );
  }

  Widget _buildRouteModeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
      decoration: BoxDecoration(
        color: WorldCompanionColors.infoSurface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
        border: Border.all(color: WorldCompanionColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: WorldCompanionColors.surface,
              borderRadius: BorderRadius.circular(WorldCompanionRadius.medium),
            ),
            child: const Icon(
              Icons.alt_route_rounded,
              color: WorldCompanionColors.oceanBlue,
            ),
          ),
          const SizedBox(width: WorldCompanionSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build your route',
                  style: _textTheme.titleMedium?.copyWith(
                    color: WorldCompanionColors.deepOcean,
                  ),
                ),
                const SizedBox(height: WorldCompanionSpacing.xxs),
                Text(
                  'Browse the destinations below to explore places for your journey.',
                  style: _textTheme.bodySmall?.copyWith(
                    color: WorldCompanionColors.secondaryText,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: _textTheme.headlineSmall?.copyWith(
            color: WorldCompanionColors.deepOcean,
          ),
        ),
        const SizedBox(height: WorldCompanionSpacing.xxs),
        Text(
          subtitle,
          style: _textTheme.bodySmall?.copyWith(
            color: WorldCompanionColors.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < _categories.length; i++) ...[
            if (i > 0) const SizedBox(width: WorldCompanionSpacing.xs),
            _categoryChip(_categories[i]),
          ],
        ],
      ),
    );
  }

  Widget _categoryChip(String label) {
    final selected = _selectedCategory == label;

    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: WorldCompanionMotion.fast,
        curve: WorldCompanionMotion.standardCurve,
        decoration: BoxDecoration(
          color: selected
              ? WorldCompanionColors.deepOcean
              : WorldCompanionColors.surface,
          borderRadius: BorderRadius.circular(WorldCompanionRadius.pill),
          border: Border.all(
            color: selected
                ? WorldCompanionColors.deepOcean
                : WorldCompanionColors.border,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(WorldCompanionRadius.pill),
            onTap: () => setState(() => _selectedCategory = label),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: WorldCompanionSpacing.md,
                vertical: WorldCompanionSpacing.sm,
              ),
              child: Text(
                label,
                style: _textTheme.labelMedium?.copyWith(
                  color: selected
                      ? WorldCompanionColors.surface
                      : WorldCompanionColors.secondaryText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlacesHeader(int count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            widget.routeMode ? 'Choose places' : 'Explore places',
            style: _textTheme.headlineSmall?.copyWith(
              color: WorldCompanionColors.deepOcean,
            ),
          ),
        ),
        const SizedBox(width: WorldCompanionSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: WorldCompanionSpacing.sm,
            vertical: WorldCompanionSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: WorldCompanionColors.surface,
            borderRadius: BorderRadius.circular(WorldCompanionRadius.pill),
            border: Border.all(color: WorldCompanionColors.border),
          ),
          child: Text(
            '$count places',
            style: _textTheme.labelSmall?.copyWith(
              color: WorldCompanionColors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlacesGrid(
    List<MapEntry<String, dynamic>> places, {
    required bool isWide,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: isWide ? 340 : 420,
        mainAxisExtent: 204,
        crossAxisSpacing: WorldCompanionSpacing.md,
        mainAxisSpacing: WorldCompanionSpacing.md,
      ),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final entry = places[index];
        final place = Map<String, dynamic>.from(entry.value);

        return _placeCard(
          name: place['name']?.toString() ?? entry.key,
          category: place['category']?.toString() ?? 'destination',
          place: {...place, 'id': entry.key},
        );
      },
    );
  }

  Widget _placeCard({
    required String name,
    required String category,
    required Map<String, dynamic> place,
  }) {
    final icon = _categoryIcon(category);

    return Material(
      color: WorldCompanionColors.surface,
      borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
      child: InkWell(
        borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlaceDetailsScreen(place: place),
            ),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
            border: Border.all(color: WorldCompanionColors.border),
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
                      color: WorldCompanionColors.infoSurface,
                      borderRadius:
                          BorderRadius.circular(WorldCompanionRadius.medium),
                    ),
                    child: Icon(
                      icon,
                      color: WorldCompanionColors.oceanBlue,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 18,
                    color: WorldCompanionColors.mutedText,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _textTheme.titleMedium?.copyWith(
                  color: WorldCompanionColors.deepOcean,
                ),
              ),
              const SizedBox(height: WorldCompanionSpacing.xxs),
              Text(
                _formatCategory(category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _textTheme.bodySmall?.copyWith(
                  color: WorldCompanionColors.mutedText,
                ),
              ),
              const SizedBox(height: WorldCompanionSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                    color: WorldCompanionColors.oceanBlue,
                  ),
                  const SizedBox(width: WorldCompanionSpacing.xs),
                  Text(
                    'View details',
                    style: _textTheme.labelMedium?.copyWith(
                      color: WorldCompanionColors.oceanBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: WorldCompanionSpacing.lg,
        vertical: WorldCompanionSpacing.xxxl,
      ),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
        border: Border.all(color: WorldCompanionColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.travel_explore_rounded,
            size: 42,
            color: WorldCompanionColors.softBlue,
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          Text(
            'No places found',
            style: _textTheme.titleMedium?.copyWith(
              color: WorldCompanionColors.deepOcean,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.xs),
          Text(
            'Try another search or select a different category.',
            textAlign: TextAlign.center,
            style: _textTheme.bodySmall?.copyWith(
              color: WorldCompanionColors.secondaryText,
            ),
          ),
          if (_searchQuery.isNotEmpty || _selectedCategory != 'All') ...[
            const SizedBox(height: WorldCompanionSpacing.md),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'All';
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(WorldCompanionSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: WorldCompanionColors.errorSurface,
                borderRadius:
                    BorderRadius.circular(WorldCompanionRadius.extraLarge),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 34,
                color: WorldCompanionColors.error,
              ),
            ),
            const SizedBox(height: WorldCompanionSpacing.lg),
            Text(
              'Couldn’t load places',
              style: _textTheme.headlineSmall?.copyWith(
                color: WorldCompanionColors.deepOcean,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WorldCompanionSpacing.xs),
            Text(
              'Check your connection and try again.',
              style: _textTheme.bodyMedium?.copyWith(
                color: WorldCompanionColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WorldCompanionSpacing.lg),
            FilledButton.icon(
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

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'park':
      case 'parks':
        return Icons.park_rounded;
      case 'food':
      case 'restaurant':
      case 'restaurants':
        return Icons.restaurant_rounded;
      case 'shopping':
      case 'shop':
      case 'shops':
        return Icons.shopping_bag_rounded;
      case 'landmark':
      case 'landmarks':
        return Icons.account_balance_rounded;
      case 'area':
      case 'areas':
        return Icons.location_city_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  String _formatCategory(String category) {
    if (category.isEmpty) return 'Destination';

    return category
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
