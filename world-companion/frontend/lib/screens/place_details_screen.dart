
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/world_companion_colors.dart';
import '../theme/world_companion_elevation.dart';
import '../theme/world_companion_motion.dart';
import '../theme/world_companion_radius.dart';
import '../theme/world_companion_spacing.dart';
import '../theme/world_companion_typography.dart';
import 'real_world_route_screen.dart';
import 'reviews_screen.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> place;

  const PlaceDetailsScreen({
    super.key,
    required this.place,
  });

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  Map<String, dynamic>? _placeInfo;
  bool _loadingInfo = true;
  String? _infoError;

  Map<String, dynamic>? _aiIntelligence;
  bool _loadingAi = false;
  String? _aiError;

  TextTheme get _textTheme => WorldCompanionTypography.textTheme;

  @override
  void initState() {
    super.initState();
    _loadPlaceInfo();
  }

  Future<void> _loadPlaceInfo() async {
    final placeId = widget.place['id']?.toString();

    if (placeId == null || placeId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loadingInfo = false;
        _infoError = 'Place information is unavailable.';
      });
      return;
    }

    try {
      final data = await ApiService.getPlaceInfo(placeId);
      if (!mounted) return;

      setState(() {
        _placeInfo = data;
        _loadingInfo = false;
        _infoError = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingInfo = false;
        _infoError = 'Unable to load additional place information.';
      });
    }
  }

  Future<void> _generateAiIntelligence() async {
    final placeId = widget.place['id']?.toString();

    if (placeId == null || placeId.isEmpty) {
      setState(() {
        _aiError = 'AI intelligence is unavailable for this place.';
      });
      return;
    }

    setState(() {
      _loadingAi = true;
      _aiError = null;
    });

    try {
      final data = await ApiService.generatePlaceIntelligence(
        placeId: placeId,
      );

      if (!mounted) return;

      setState(() {
        _aiIntelligence = data;
        _loadingAi = false;
        _aiError = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingAi = false;
        _aiError = 'Unable to generate AI intelligence for this place.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.place['name']?.toString() ?? 'Unknown place';
    final category = widget.place['category']?.toString() ?? 'Place';
    final description = widget.place['description']?.toString() ??
        'Discover more about this place and what makes it worth experiencing.';
    final tags = _extractTags();

    return Scaffold(
      backgroundColor: WorldCompanionColors.softWhite,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 270,
            pinned: true,
            backgroundColor: WorldCompanionColors.deepOcean,
            foregroundColor: WorldCompanionColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: WorldCompanionElevation.none,
            iconTheme: const IconThemeData(
              color: WorldCompanionColors.surface,
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.fromSTEB(
                56,
                0,
                WorldCompanionSpacing.md,
                WorldCompanionSpacing.md,
              ),
              title: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _textTheme.titleLarge?.copyWith(
                  color: WorldCompanionColors.surface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: _buildHero(category),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              WorldCompanionSpacing.mobilePage,
              WorldCompanionSpacing.lg,
              WorldCompanionSpacing.mobilePage,
              WorldCompanionSpacing.xxxl,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCategoryBadge(category),
                const SizedBox(height: WorldCompanionSpacing.md),
                Text(
                  name,
                  style: _textTheme.displayMedium?.copyWith(
                    color: WorldCompanionColors.deepOcean,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: WorldCompanionSpacing.sm),
                Text(
                  description,
                  style: _textTheme.bodyLarge?.copyWith(
                    color: WorldCompanionColors.secondaryText,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: WorldCompanionSpacing.xxl),
                _buildPlaceInfoSection(),
                const SizedBox(height: WorldCompanionSpacing.xxl),
                _buildAiIntelligenceSection(),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: WorldCompanionSpacing.xxl),
                  _buildTagsSection(tags),
                ],
                const SizedBox(height: WorldCompanionSpacing.xxl),
                _buildActionsSection(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(String category) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                WorldCompanionColors.deepOcean,
                WorldCompanionColors.navyBlue,
                WorldCompanionColors.oceanBlue,
              ],
            ),
          ),
        ),
        Positioned(
          top: 35,
          right: -30,
          child: Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: WorldCompanionColors.surface.withOpacity(0.08),
                width: 28,
              ),
            ),
          ),
        ),
        Positioned(
          right: 36,
          top: 55,
          child: Icon(
            _categoryIcon(category),
            size: 94,
            color: WorldCompanionColors.surface.withOpacity(0.85),
          ),
        ),
        Positioned(
          left: WorldCompanionSpacing.lg,
          bottom: 76,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WorldCompanionSpacing.sm,
              vertical: WorldCompanionSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: WorldCompanionColors.surface.withOpacity(0.12),
              borderRadius: BorderRadius.circular(WorldCompanionRadius.pill),
              border: Border.all(
                color: WorldCompanionColors.surface.withOpacity(0.20),
              ),
            ),
            child: Text(
              'WORLD COMPANION  /  DISCOVER',
              style: _textTheme.labelSmall?.copyWith(
                color: WorldCompanionColors.surface,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 110,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x660B2545),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBadge(String category) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: WorldCompanionSpacing.md,
          vertical: WorldCompanionSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: WorldCompanionColors.infoSurface,
          borderRadius: BorderRadius.circular(WorldCompanionRadius.pill),
          border: Border.all(
            color: WorldCompanionColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _categoryIcon(category),
              size: 15,
              color: WorldCompanionColors.oceanBlue,
            ),
            const SizedBox(width: WorldCompanionSpacing.xs),
            Text(
              _formatCategory(category),
              style: _textTheme.labelMedium?.copyWith(
                color: WorldCompanionColors.oceanBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceInfoSection() {
    if (_loadingInfo) {
      return _sectionCard(
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: WorldCompanionColors.oceanBlue,
              ),
            ),
            SizedBox(width: WorldCompanionSpacing.md),
            Expanded(
              child: Text('Loading more information...'),
            ),
          ],
        ),
      );
    }

    if (_infoError != null) {
      return _sectionCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: WorldCompanionColors.oceanBlue,
            ),
            const SizedBox(width: WorldCompanionSpacing.md),
            Expanded(
              child: Text(
                _infoError!,
                style: _textTheme.bodyMedium?.copyWith(
                  color: WorldCompanionColors.secondaryText,
                  height: 1.5,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Retry loading information',
              onPressed: () {
                setState(() {
                  _loadingInfo = true;
                  _infoError = null;
                });
                _loadPlaceInfo();
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      );
    }

    if (_placeInfo == null || _placeInfo!.isEmpty) {
      return const SizedBox.shrink();
    }

    final rawInfo = _placeInfo!['info'];

    if (rawInfo is! List) {
      return const SizedBox.shrink();
    }

    final items = rawInfo.whereType<Map>().where((item) {
      final topic = item['topic']?.toString() ?? '';
      final content = item['content']?.toString() ?? '';
      return topic.isNotEmpty || content.isNotEmpty;
    }).toList();

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'About this place',
          'Useful details for your visit',
          Icons.info_outline_rounded,
        ),
        const SizedBox(height: WorldCompanionSpacing.md),
        for (final item in items) ...[
          _buildInfoItem(
            topic: item['topic']?.toString() ?? '',
            content: item['content']?.toString() ?? '',
          ),
          const SizedBox(height: WorldCompanionSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildInfoItem({
    required String topic,
    required String content,
  }) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (topic.isNotEmpty) ...[
            Text(
              _formatLabel(topic),
              style: _textTheme.titleSmall?.copyWith(
                color: WorldCompanionColors.deepOcean,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: WorldCompanionSpacing.xs),
          ],
          if (content.isNotEmpty)
            Text(
              content,
              style: _textTheme.bodyMedium?.copyWith(
                color: WorldCompanionColors.secondaryText,
                height: 1.65,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAiIntelligenceSection() {
    if (_aiIntelligence == null && !_loadingAi && _aiError == null) {
      return _sectionCard(
        backgroundColor: WorldCompanionColors.infoSurface,
        borderColor: WorldCompanionColors.softBlue.withOpacity(0.45),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _aiHeader(),
            const SizedBox(height: WorldCompanionSpacing.md),
            Text(
              'Get a quick AI-powered travel insight about this place, '
              'grounded in available WorldCompanion place data.',
              style: _textTheme.bodyMedium?.copyWith(
                color: WorldCompanionColors.secondaryText,
                height: 1.6,
              ),
            ),
            const SizedBox(height: WorldCompanionSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _generateAiIntelligence,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Generate intelligence'),
                style: FilledButton.styleFrom(
                  backgroundColor: WorldCompanionColors.deepOcean,
                  foregroundColor: WorldCompanionColors.surface,
                  padding: const EdgeInsets.symmetric(
                    vertical: WorldCompanionSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(WorldCompanionRadius.medium),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_loadingAi) {
      return _sectionCard(
        backgroundColor: WorldCompanionColors.infoSurface,
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: WorldCompanionColors.oceanBlue,
              ),
            ),
            const SizedBox(width: WorldCompanionSpacing.md),
            Expanded(
              child: Text(
                'Generating travel intelligence...',
                style: _textTheme.bodyMedium?.copyWith(
                  color: WorldCompanionColors.deepOcean,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_aiError != null) {
      return _sectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _aiHeader(),
            const SizedBox(height: WorldCompanionSpacing.md),
            Text(
              _aiError!,
              style: _textTheme.bodyMedium?.copyWith(
                color: WorldCompanionColors.secondaryText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: WorldCompanionSpacing.md),
            OutlinedButton.icon(
              onPressed: _generateAiIntelligence,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final intelligence =
        _aiIntelligence?['intelligence']?.toString() ?? '';

    if (intelligence.isEmpty) {
      return const SizedBox.shrink();
    }

    return _sectionCard(
      borderColor: WorldCompanionColors.softBlue.withOpacity(0.55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _aiHeader(),
          const SizedBox(height: WorldCompanionSpacing.lg),
          ..._buildAiContent(intelligence),
          const SizedBox(height: WorldCompanionSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _generateAiIntelligence,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Regenerate'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: WorldCompanionColors.surface,
            borderRadius: BorderRadius.circular(WorldCompanionRadius.medium),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: WorldCompanionColors.oceanBlue,
          ),
        ),
        const SizedBox(width: WorldCompanionSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Place Intelligence',
                style: _textTheme.titleMedium?.copyWith(
                  color: WorldCompanionColors.deepOcean,
                ),
              ),
              const SizedBox(height: WorldCompanionSpacing.xxs),
              Text(
                'Travel insights, tailored to this place',
                style: _textTheme.bodySmall?.copyWith(
                  color: WorldCompanionColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildAiContent(String intelligence) {
    final sections = _parseAiSections(intelligence);

    if (sections.isEmpty) {
      return [
        Text(
          intelligence,
          style: _textTheme.bodyMedium?.copyWith(
            color: WorldCompanionColors.secondaryText,
            height: 1.7,
          ),
        ),
      ];
    }

    return sections.entries.map((entry) {
      return Padding(
        padding: const EdgeInsets.only(
          bottom: WorldCompanionSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.key,
              style: _textTheme.labelLarge?.copyWith(
                color: WorldCompanionColors.oceanBlue,
              ),
            ),
            const SizedBox(height: WorldCompanionSpacing.xs),
            Text(
              entry.value,
              style: _textTheme.bodyMedium?.copyWith(
                color: WorldCompanionColors.secondaryText,
                height: 1.65,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Map<String, String> _parseAiSections(String text) {
    const sectionNames = [
      'WHY VISIT',
      'WHAT TO DO',
      'BEST FOR',
      'BEST TIME',
      'TRAVEL INSIGHT',
    ];

    final found = <MapEntry<int, String>>[];

    for (final name in sectionNames) {
      final index = text.indexOf('$name:');
      if (index >= 0) {
        found.add(MapEntry(index, name));
      }
    }

    found.sort((a, b) => a.key.compareTo(b.key));

    final sections = <String, String>{};

    for (var i = 0; i < found.length; i++) {
      final heading = found[i];
      final start = heading.key + heading.value.length + 1;
      final end = i + 1 < found.length ? found[i + 1].key : text.length;
      final content = text.substring(start, end).trim();

      if (content.isNotEmpty) {
        sections[_formatAiSectionTitle(heading.value)] = content;
      }
    }

    return sections;
  }

  String _formatAiSectionTitle(String value) {
    switch (value) {
      case 'WHY VISIT':
        return 'Why visit';
      case 'WHAT TO DO':
        return 'What to do';
      case 'BEST FOR':
        return 'Best for';
      case 'BEST TIME':
        return 'Best time';
      case 'TRAVEL INSIGHT':
        return 'Travel insight';
      default:
        return _formatLabel(value);
    }
  }

  Widget _buildTagsSection(List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Good to know',
          'A few things that describe this destination',
          Icons.bookmark_border_rounded,
        ),
        const SizedBox(height: WorldCompanionSpacing.md),
        Wrap(
          spacing: WorldCompanionSpacing.xs,
          runSpacing: WorldCompanionSpacing.xs,
          children: tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: WorldCompanionSpacing.md,
                vertical: WorldCompanionSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: WorldCompanionColors.surface,
                borderRadius:
                    BorderRadius.circular(WorldCompanionRadius.pill),
                border: Border.all(color: WorldCompanionColors.border),
              ),
              child: Text(
                tag,
                style: _textTheme.labelMedium?.copyWith(
                  color: WorldCompanionColors.secondaryText,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(
          'Explore this place',
          'Choose what you want to do next',
          Icons.explore_outlined,
        ),
        const SizedBox(height: WorldCompanionSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;

            return Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.rate_review_outlined,
                    label: 'Reviews',
                    compact: compact,
                    onTap: _openReviews,
                  ),
                ),
                const SizedBox(width: WorldCompanionSpacing.sm),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.alt_route_rounded,
                    label: 'Plan route',
                    compact: compact,
                    onTap: _openRoutePlanner,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: WorldCompanionSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showNearbyMessage,
            icon: const Icon(Icons.near_me_outlined),
            label: const Text('Find nearby places'),
            style: OutlinedButton.styleFrom(
              foregroundColor: WorldCompanionColors.oceanBlue,
              side: const BorderSide(color: WorldCompanionColors.border),
              padding: const EdgeInsets.symmetric(
                vertical: WorldCompanionSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(WorldCompanionRadius.medium),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeading(String title, String subtitle, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: WorldCompanionColors.infoSurface,
            borderRadius: BorderRadius.circular(WorldCompanionRadius.medium),
          ),
          child: Icon(
            icon,
            color: WorldCompanionColors.oceanBlue,
            size: 21,
          ),
        ),
        const SizedBox(width: WorldCompanionSpacing.md),
        Expanded(
          child: Column(
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
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required Widget child,
    Color backgroundColor = WorldCompanionColors.surface,
    Color borderColor = WorldCompanionColors.border,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: WorldCompanionColors.deepOcean.withOpacity(0.025),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  void _openReviews() {
    final placeId = widget.place['id']?.toString();

    if (placeId == null || placeId.isEmpty) {
      _showMessage('Reviews are unavailable for this place.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewsScreen(
          targetType: 'place',
          targetId: placeId,
          placeName: widget.place['name']?.toString() ?? 'Place',
        ),
      ),
    );
  }

  void _openRoutePlanner() {
    final latitude = _readDouble(widget.place['latitude']);
    final longitude = _readDouble(widget.place['longitude']);
    final placeName = widget.place['name']?.toString() ?? 'Place';

    if (latitude == null || longitude == null) {
      _showMessage('Route information is unavailable for this place.');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RealWorldRouteScreen(
          placeName: placeName,
          destinationLatitude: latitude,
          destinationLongitude: longitude,
        ),
      ),
    );
  }

  double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _showNearbyMessage() {
    _showMessage(
      'Nearby discovery is not connected to this action yet.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<String> _extractTags() {
    final rawTags = widget.place['tags'];

    if (rawTags is! List) return <String>[];

    return rawTags
        .map((tag) => tag.toString().trim())
        .where((tag) => tag.isNotEmpty)
        .toList();
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

  String _formatCategory(String value) {
    return _formatLabel(value);
  }

  String _formatLabel(String value) {
    if (value.isEmpty) return value;

    return value
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = WorldCompanionTypography.textTheme;

    return AnimatedContainer(
      duration: WorldCompanionMotion.standard,
      curve: WorldCompanionMotion.standardCurve,
      child: Material(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
          child: Container(
            constraints: const BoxConstraints(minHeight: 74),
            padding: EdgeInsets.symmetric(
              horizontal: compact
                  ? WorldCompanionSpacing.sm
                  : WorldCompanionSpacing.md,
              vertical: WorldCompanionSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(WorldCompanionRadius.large),
              border: Border.all(color: WorldCompanionColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: WorldCompanionColors.infoSurface,
                    borderRadius:
                        BorderRadius.circular(WorldCompanionRadius.medium),
                  ),
                  child: Icon(
                    icon,
                    color: WorldCompanionColors.oceanBlue,
                    size: 21,
                  ),
                ),
                const SizedBox(width: WorldCompanionSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.labelLarge?.copyWith(
                      color: WorldCompanionColors.deepOcean,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
