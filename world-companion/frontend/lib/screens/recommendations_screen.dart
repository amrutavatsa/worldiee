import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/world_companion_colors.dart';
import '../theme/world_companion_elevation.dart';
import '../theme/world_companion_motion.dart';
import '../theme/world_companion_radius.dart';
import '../theme/world_companion_spacing.dart';
import '../theme/world_companion_typography.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState
    extends State<RecommendationsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getRecommendations();

      if (!mounted) return;

      setState(() {
        _recommendations = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _stringValue(
    Map<String, dynamic> item,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = item[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return '';
  }

  IconData _categoryIcon(String category) {
    final value = category.toLowerCase();

    if (value.contains('food') ||
        value.contains('restaurant') ||
        value.contains('cafe') ||
        value.contains('dining')) {
      return Icons.restaurant_rounded;
    }

    if (value.contains('park') ||
        value.contains('nature') ||
        value.contains('garden') ||
        value.contains('wildlife')) {
      return Icons.park_rounded;
    }

    if (value.contains('shopping') || value.contains('market')) {
      return Icons.shopping_bag_rounded;
    }

    if (value.contains('museum') ||
        value.contains('history') ||
        value.contains('culture') ||
        value.contains('heritage')) {
      return Icons.account_balance_rounded;
    }

    if (value.contains('hotel') ||
        value.contains('stay') ||
        value.contains('resort')) {
      return Icons.hotel_rounded;
    }

    if (value.contains('beach') ||
        value.contains('lake') ||
        value.contains('water')) {
      return Icons.water_rounded;
    }

    return Icons.place_rounded;
  }

  Widget _sectionHeading() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: WorldCompanionSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR DISCOVERIES',
                  style: WorldCompanionTypography.textTheme.labelMedium
                      ?.copyWith(
                    color: WorldCompanionColors.oceanBlue,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: WorldCompanionSpacing.xxs),
                Text(
                  'Picked for you',
                  style: WorldCompanionTypography.textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          if (!_loading && _error == null)
            Text(
              '${_recommendations.length} ${_recommendations.length == 1 ? 'place' : 'places'}',
              style: WorldCompanionTypography.textTheme.labelMedium
                  ?.copyWith(
                color: WorldCompanionColors.mutedText,
              ),
            ),
        ],
      ),
    );
  }

  Widget _recommendationCard(
    Map<String, dynamic> item,
    int index,
  ) {
    final name = _stringValue(
      item,
      ['name', 'title', 'place_name'],
    );

    final category = _stringValue(
      item,
      ['category', 'type'],
    );

    final description = _stringValue(
      item,
      ['description', 'summary'],
    );

    final tagsValue = item['tags'];
    final tags = tagsValue is List
        ? tagsValue
            .map((tag) => tag.toString().trim())
            .where((tag) => tag.isNotEmpty)
            .join(' • ')
        : '';

    final displayName =
        name.isEmpty ? 'Recommended place' : name;

    final icon = _categoryIcon(category);

    final iconBackground = index.isEven
        ? WorldCompanionColors.infoSurface
        : WorldCompanionColors.aiSurface;

    return Container(
      margin: const EdgeInsets.only(
        bottom: WorldCompanionSpacing.md,
      ),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
        border: Border.all(
          color: WorldCompanionColors.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080B2545),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(WorldCompanionSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(
                  WorldCompanionRadius.large,
                ),
              ),
              child: Icon(
                icon,
                color: WorldCompanionColors.oceanBlue,
                size: 25,
              ),
            ),
            const SizedBox(width: WorldCompanionSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: WorldCompanionTypography.textTheme.titleMedium,
                  ),
                  if (category.isNotEmpty) ...[
                    const SizedBox(height: WorldCompanionSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: WorldCompanionSpacing.sm,
                        vertical: WorldCompanionSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: WorldCompanionColors.infoSurface,
                        borderRadius: BorderRadius.circular(
                          WorldCompanionRadius.pill,
                        ),
                      ),
                      child: Text(
                        category,
                        style: WorldCompanionTypography
                            .textTheme.labelSmall
                            ?.copyWith(
                          color: WorldCompanionColors.oceanBlue,
                        ),
                      ),
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: WorldCompanionSpacing.sm),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: WorldCompanionTypography.textTheme.bodyMedium
                          ?.copyWith(height: 1.5),
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: WorldCompanionSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.local_offer_outlined,
                          size: 15,
                          color: WorldCompanionColors.mutedText,
                        ),
                        const SizedBox(width: WorldCompanionSpacing.xs),
                        Expanded(
                          child: Text(
                            tags,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: WorldCompanionTypography
                                .textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            WorldCompanionColors.deepOcean,
            WorldCompanionColors.oceanBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0B2545),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.large,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: WorldCompanionSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Made for your journey',
                  style: WorldCompanionTypography.textTheme.headlineSmall
                      ?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: WorldCompanionSpacing.xs),
                Text(
                  'Discover places that fit your interests and travel preferences.',
                  style: WorldCompanionTypography.textTheme.bodyMedium
                      ?.copyWith(
                    color: Colors.white.withOpacity(0.84),
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

  Widget _loadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: WorldCompanionSpacing.xxxl,
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: WorldCompanionColors.oceanBlue,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          Text(
            'Finding places for you...',
            style: WorldCompanionTypography.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
        border: Border.all(
          color: WorldCompanionColors.error.withOpacity(0.28),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: WorldCompanionColors.errorSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: WorldCompanionColors.error,
              size: 26,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          Text(
            'Could not load recommendations',
            textAlign: TextAlign.center,
            style: WorldCompanionTypography.textTheme.titleMedium,
          ),
          const SizedBox(height: WorldCompanionSpacing.xs),
          Text(
            _error ?? 'Something went wrong. Please try again.',
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: WorldCompanionTypography.textTheme.bodySmall,
          ),
          const SizedBox(height: WorldCompanionSpacing.lg),
          FilledButton.icon(
            onPressed: _loadRecommendations,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
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
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorldCompanionSpacing.xl),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.extraLarge,
        ),
        border: Border.all(
          color: WorldCompanionColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: WorldCompanionColors.infoSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.explore_outlined,
              color: WorldCompanionColors.oceanBlue,
              size: 32,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.lg),
          Text(
            'No recommendations yet',
            textAlign: TextAlign.center,
            style: WorldCompanionTypography.textTheme.titleLarge,
          ),
          const SizedBox(height: WorldCompanionSpacing.xs),
          Text(
            'Your next discovery starts with your travel preferences. '
            'Set your interests and come back to explore places selected for you.',
            textAlign: TextAlign.center,
            style: WorldCompanionTypography.textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorldCompanionColors.softWhite,
      appBar: AppBar(
        title: Text(
          'Recommendations',
          style: WorldCompanionTypography.textTheme.titleLarge,
        ),
        backgroundColor: WorldCompanionColors.softWhite,
        foregroundColor: WorldCompanionColors.primaryText,
        elevation: WorldCompanionElevation.none,
        scrolledUnderElevation: WorldCompanionElevation.none,
        actions: [
          IconButton(
            tooltip: 'Refresh recommendations',
            onPressed: _loading ? null : _loadRecommendations,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: WorldCompanionSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecommendations,
          color: WorldCompanionColors.oceanBlue,
          backgroundColor: WorldCompanionColors.surface,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              WorldCompanionSpacing.mobilePage,
              WorldCompanionSpacing.xs,
              WorldCompanionSpacing.mobilePage,
              WorldCompanionSpacing.xxxl,
            ),
            children: [
              _heroCard(),
              const SizedBox(height: WorldCompanionSpacing.xl),
              _sectionHeading(),
              AnimatedSwitcher(
                duration: WorldCompanionMotion.standard,
                switchInCurve: WorldCompanionMotion.standardCurve,
                child: _loading
                    ? _loadingState()
                    : _error != null
                        ? _errorState()
                        : _recommendations.isEmpty
                            ? _emptyState()
                            : Column(
                                key: const ValueKey('recommendations'),
                                children: _recommendations
                                    .asMap()
                                    .entries
                                    .where((entry) => entry.value is Map)
                                    .map((entry) {
                                  return _recommendationCard(
                                    Map<String, dynamic>.from(
                                      entry.value as Map,
                                    ),
                                    entry.key,
                                  );
                                }).toList(),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
