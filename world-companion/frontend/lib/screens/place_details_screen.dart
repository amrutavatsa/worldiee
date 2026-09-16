import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'reviews_screen.dart';
import 'route_screen.dart';

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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingInfo = false;
        _infoError = 'Unable to load additional place information.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = widget.place['name']?.toString() ?? 'Unknown place';

    final category =
        widget.place['category']?.toString() ?? 'Place';

    final description =
        widget.place['description']?.toString() ??
        'Discover more about this place and what makes it worth experiencing.';

    final tags = _extractTags();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.72),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.place_rounded,
                    size: 72,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ----------------------------------------------------------
                // CATEGORY
                // ----------------------------------------------------------

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _formatCategory(category),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ----------------------------------------------------------
                // TITLE
                // ----------------------------------------------------------

                Text(
                  name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // ----------------------------------------------------------
                // DESCRIPTION
                // ----------------------------------------------------------

                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 28),

                // ----------------------------------------------------------
                // BACKEND PLACE INFORMATION
                // ----------------------------------------------------------

                _buildPlaceInfoSection(theme),

                // ----------------------------------------------------------
                // TAGS
                // ----------------------------------------------------------

                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 28),

                  Text(
                    'Good to know',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.grey.shade200,
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 28),

                // ----------------------------------------------------------
                // QUICK ACTIONS
                // ----------------------------------------------------------

                Text(
                  'Explore this place',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    // ------------------------------------------------------
                    // REVIEWS
                    // ------------------------------------------------------

                    Expanded(
                      child: _ActionCard(
                        icon: Icons.rate_review_outlined,
                        label: 'Reviews',
                        onTap: _openReviews,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ------------------------------------------------------
                    // PLAN ROUTE
                    // ------------------------------------------------------

                    Expanded(
                      child: _ActionCard(
                        icon: Icons.alt_route_rounded,
                        label: 'Plan route',
                        onTap: _openRoutePlanner,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ----------------------------------------------------------
                // NEARBY
                // ----------------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showNearbyMessage,
                    icon: const Icon(Icons.near_me_outlined),
                    label: const Text('Find nearby places'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // REVIEWS
  // =========================================================================

  void _openReviews() {
    final placeId = widget.place['id']?.toString();

    if (placeId == null || placeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reviews are unavailable for this place.',
          ),
        ),
      );

      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewsScreen(
          targetType: 'place',
          targetId: placeId,
          placeName:
              widget.place['name']?.toString() ?? 'Place',
        ),
      ),
    );
  }

  // =========================================================================
  // ROUTE PLANNER
  // =========================================================================

  void _openRoutePlanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RouteScreen(),
      ),
    );
  }

  // =========================================================================
  // NEARBY
  // =========================================================================

  void _showNearbyMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Nearby places are available through the existing project scope.',
        ),
      ),
    );
  }

  // =========================================================================
  // TAG EXTRACTION
  // =========================================================================

  List<String> _extractTags() {
    final rawTags = widget.place['tags'];

    if (rawTags is! List) {
      return <String>[];
    }

    return rawTags
        .map((tag) => tag.toString())
        .where((tag) => tag.trim().isNotEmpty)
        .toList();
  }

  // =========================================================================
  // PLACE INFORMATION
  // =========================================================================

  Widget _buildPlaceInfoSection(ThemeData theme) {
    if (_loadingInfo) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading more information...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (_infoError != null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _infoError!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.4,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_placeInfo == null || _placeInfo!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About this place',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoContent(theme),
      ],
    );
  }

  Widget _buildInfoContent(ThemeData theme) {
    final info = _placeInfo!;

    final rawInfo = info['info'];

    if (rawInfo is List && rawInfo.isNotEmpty) {
      final validItems = rawInfo.whereType<Map>().where((item) {
        final topic = item['topic']?.toString() ?? '';
        final content = item['content']?.toString() ?? '';

        return topic.isNotEmpty || content.isNotEmpty;
      }).toList();

      if (validItems.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        children: validItems.map<Widget>((item) {
          final topic = item['topic']?.toString() ?? '';
          final content = item['content']?.toString() ?? '';

          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (topic.isNotEmpty) ...[
                  Text(
                    _formatLabel(topic),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                if (content.isNotEmpty)
                  Text(
                    content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                      color: Colors.grey.shade700,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return const SizedBox.shrink();
  }

  // =========================================================================
  // FORMATTERS
  // =========================================================================

  String _formatCategory(String value) {
    if (value.isEmpty) {
      return 'Place';
    }

    return value[0].toUpperCase() + value.substring(1);
  }

  String _formatLabel(String value) {
    if (value.isEmpty) {
      return value;
    }

    final formatted = value.replaceAll('_', ' ');

    return formatted[0].toUpperCase() + formatted.substring(1);
  }
}

// =============================================================================
// ACTION CARD
// =============================================================================

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}