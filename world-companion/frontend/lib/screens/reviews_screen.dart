import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/world_companion_colors.dart';
import '../theme/world_companion_elevation.dart';
import '../theme/world_companion_radius.dart';
import '../theme/world_companion_spacing.dart';
import '../theme/world_companion_typography.dart';

class ReviewsScreen extends StatefulWidget {
  final String targetType;
  final String targetId;
  final String placeName;

  const ReviewsScreen({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.placeName,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  bool _loading = true;
  String? _error;

  double? _averageRating;
  int _reviewCount = 0;
  List<Map<String, dynamic>> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getReviews(
        targetType: widget.targetType,
        targetId: widget.targetId,
      );

      if (!mounted) return;

      final rawReviews = data['reviews'];

      setState(() {
        _averageRating = data['average_rating'] is num
            ? (data['average_rating'] as num).toDouble()
            : null;

        _reviewCount = data['count'] is num
            ? (data['count'] as num).toInt()
            : 0;

        _reviews = rawReviews is List
            ? rawReviews
                .whereType<Map>()
                .map(
                  (review) => Map<String, dynamic>.from(review),
                )
                .toList()
            : [];

        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Unable to load reviews right now.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorldCompanionColors.softWhite,
      appBar: AppBar(
        title: Text(
          'Reviews',
          style: WorldCompanionTypography.textTheme.titleLarge,
        ),
        backgroundColor: WorldCompanionColors.softWhite,
        foregroundColor: WorldCompanionColors.primaryText,
        elevation: WorldCompanionElevation.none,
        scrolledUnderElevation: WorldCompanionElevation.none,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReviews,
          color: WorldCompanionColors.oceanBlue,
          backgroundColor: WorldCompanionColors.surface,
          child: _buildBody(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReviewSheet,
        backgroundColor: WorldCompanionColors.deepOcean,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.rate_review_outlined),
        label: const Text('Write a review'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.55,
            child: const Center(
              child: CircularProgressIndicator(
                color: WorldCompanionColors.oceanBlue,
              ),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        WorldCompanionSpacing.mobilePage,
        WorldCompanionSpacing.md,
        WorldCompanionSpacing.mobilePage,
        112,
      ),
      children: [
        _buildHero(),
        const SizedBox(height: WorldCompanionSpacing.xl),
        _buildRatingSummary(),
        const SizedBox(height: WorldCompanionSpacing.xl),
        _buildReviewsHeading(),
        const SizedBox(height: WorldCompanionSpacing.md),
        if (_reviews.isEmpty)
          _buildEmptyState()
        else
          ..._reviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(
                bottom: WorldCompanionSpacing.md,
              ),
              child: _buildReviewCard(review),
            ),
          ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.medium,
              ),
            ),
            child: const Icon(
              Icons.reviews_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.lg),
          Text(
            widget.placeName,
            style: WorldCompanionTypography.textTheme.headlineMedium
                ?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.xs),
          Text(
            'Real experiences from fellow travelers.',
            style: WorldCompanionTypography.textTheme.bodyMedium
                ?.copyWith(
              color: Colors.white.withOpacity(0.84),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSummary() {
    final rating = _averageRating;

    return Container(
      padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
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
            color: Color(0x060B2545),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COMMUNITY RATING',
            style: WorldCompanionTypography.textTheme.labelMedium
                ?.copyWith(
              letterSpacing: 1.1,
              color: WorldCompanionColors.oceanBlue,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 82,
                height: 88,
                decoration: BoxDecoration(
                  color: WorldCompanionColors.warningSurface,
                  borderRadius: BorderRadius.circular(
                    WorldCompanionRadius.large,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      rating != null ? rating.toStringAsFixed(1) : '—',
                      style: WorldCompanionTypography
                          .textTheme.headlineMedium
                          ?.copyWith(
                        color: WorldCompanionColors.deepOcean,
                      ),
                    ),
                    if (rating != null)
                      const Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: WorldCompanionColors.warning,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating != null
                          ? _ratingLabel(rating)
                          : 'No ratings yet',
                      style: WorldCompanionTypography.textTheme.titleLarge,
                    ),
                    const SizedBox(height: WorldCompanionSpacing.xs),
                    Text(
                      _reviewCount == 1
                          ? 'Based on 1 review'
                          : 'Based on $_reviewCount reviews',
                      style: WorldCompanionTypography.textTheme.bodyMedium,
                    ),
                    if (rating != null) ...[
                      const SizedBox(height: WorldCompanionSpacing.sm),
                      _buildStars(
                        rating.round().clamp(0, 5),
                        size: 19,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsHeading() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TRAVELER VOICES',
                style: WorldCompanionTypography.textTheme.labelMedium
                    ?.copyWith(
                  color: WorldCompanionColors.oceanBlue,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: WorldCompanionSpacing.xxs),
              Text(
                'Traveler reviews',
                style: WorldCompanionTypography.textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        Container(
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
            '$_reviewCount ${_reviewCount == 1 ? 'review' : 'reviews'}',
            style: WorldCompanionTypography.textTheme.labelMedium
                ?.copyWith(
              color: WorldCompanionColors.oceanBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final authorValue = review['author']?.toString().trim();
    final author = authorValue == null || authorValue.isEmpty
        ? 'Anonymous'
        : authorValue;

    final comment = review['comment']?.toString().trim() ?? '';

    final rating = review['rating'] is num
        ? (review['rating'] as num).toInt().clamp(0, 5)
        : 0;

    final createdAt = review['created_at']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(WorldCompanionSpacing.md),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: WorldCompanionColors.infoSurface,
                child: Text(
                  author[0].toUpperCase(),
                  style: WorldCompanionTypography.textTheme.titleMedium
                      ?.copyWith(
                    color: WorldCompanionColors.oceanBlue,
                  ),
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WorldCompanionTypography.textTheme.titleSmall,
                    ),
                    if (createdAt != null &&
                        createdAt.trim().isNotEmpty) ...[
                      const SizedBox(height: WorldCompanionSpacing.xxs),
                      Text(
                        _formatDate(createdAt),
                        style: WorldCompanionTypography.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.xs),
              _buildStars(rating, size: 17),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: WorldCompanionSpacing.md),
            Text(
              comment,
              style: WorldCompanionTypography.textTheme.bodyMedium
                  ?.copyWith(height: 1.6),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStars(
    int rating, {
    double size = 18,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating
              ? Icons.star_rounded
              : Icons.star_outline_rounded,
          size: size,
          color: WorldCompanionColors.warning,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              Icons.rate_review_outlined,
              size: 30,
              color: WorldCompanionColors.oceanBlue,
            ),
          ),
          const SizedBox(height: WorldCompanionSpacing.lg),
          Text(
            'No reviews yet',
            style: WorldCompanionTypography.textTheme.titleLarge,
          ),
          const SizedBox(height: WorldCompanionSpacing.xs),
          Text(
            'Be the first traveler to share an experience.',
            textAlign: TextAlign.center,
            style: WorldCompanionTypography.textTheme.bodyMedium
                ?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(WorldCompanionSpacing.lg),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
        Container(
          padding: const EdgeInsets.all(WorldCompanionSpacing.xl),
          decoration: BoxDecoration(
            color: WorldCompanionColors.surface,
            borderRadius: BorderRadius.circular(
              WorldCompanionRadius.extraLarge,
            ),
            border: Border.all(
              color: WorldCompanionColors.error.withOpacity(0.25),
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 46,
                color: WorldCompanionColors.error,
              ),
              const SizedBox(height: WorldCompanionSpacing.md),
              Text(
                'Reviews are unavailable',
                textAlign: TextAlign.center,
                style: WorldCompanionTypography.textTheme.titleLarge,
              ),
              const SizedBox(height: WorldCompanionSpacing.xs),
              Text(
                _error ?? 'Unable to load reviews right now.',
                textAlign: TextAlign.center,
                style: WorldCompanionTypography.textTheme.bodyMedium,
              ),
              const SizedBox(height: WorldCompanionSpacing.lg),
              OutlinedButton.icon(
                onPressed: _loadReviews,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddReviewSheet() {
    int selectedRating = 0;
    final commentController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  WorldCompanionSpacing.lg,
                  WorldCompanionSpacing.sm,
                  WorldCompanionSpacing.lg,
                  WorldCompanionSpacing.xl,
                ),
                decoration: BoxDecoration(
                  color: WorldCompanionColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(
                      WorldCompanionRadius.extraLarge,
                    ),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x180B2545),
                      blurRadius: 24,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: WorldCompanionColors.border,
                            borderRadius: BorderRadius.circular(
                              WorldCompanionRadius.pill,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: WorldCompanionSpacing.lg),
                      Text(
                        'Write a review',
                        style:
                            WorldCompanionTypography.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: WorldCompanionSpacing.xs),
                      Text(
                        widget.placeName,
                        style: WorldCompanionTypography.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: WorldCompanionSpacing.xl),
                      Text(
                        'Your rating',
                        style: WorldCompanionTypography.textTheme.titleSmall,
                      ),
                      const SizedBox(height: WorldCompanionSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(5, (index) {
                          final value = index + 1;

                          return IconButton(
                            tooltip: '$value star${value == 1 ? '' : 's'}',
                            padding: const EdgeInsets.all(
                              WorldCompanionSpacing.xxs,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            onPressed: () {
                              setSheetState(() {
                                selectedRating = value;
                              });
                            },
                            icon: Icon(
                              value <= selectedRating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: WorldCompanionColors.warning,
                              size: 31,
                            ),
                          );
                        }),
                      ),
                      if (selectedRating > 0) ...[
                        const SizedBox(height: WorldCompanionSpacing.xxs),
                        Text(
                          _ratingLabel(selectedRating.toDouble()),
                          style: WorldCompanionTypography
                              .textTheme.labelMedium
                              ?.copyWith(
                            color: WorldCompanionColors.oceanBlue,
                          ),
                        ),
                      ],
                      const SizedBox(height: WorldCompanionSpacing.lg),
                      TextField(
                        controller: commentController,
                        maxLines: 4,
                        maxLength: 1000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Share your experience...',
                          hintStyle:
                              WorldCompanionTypography.textTheme.bodyMedium
                                  ?.copyWith(
                            color: WorldCompanionColors.mutedText,
                          ),
                          filled: true,
                          fillColor: WorldCompanionColors.aiSurface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              WorldCompanionRadius.medium,
                            ),
                            borderSide: const BorderSide(
                              color: WorldCompanionColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              WorldCompanionRadius.medium,
                            ),
                            borderSide: const BorderSide(
                              color: WorldCompanionColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              WorldCompanionRadius.medium,
                            ),
                            borderSide: const BorderSide(
                              color: WorldCompanionColors.oceanBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: WorldCompanionSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: selectedRating == 0
                              ? null
                              : () async {
                                  final rating = selectedRating;
                                  final comment =
                                      commentController.text.trim();

                                  Navigator.pop(sheetContext);

                                  await _submitReview(rating, comment);
                                },
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Submit review'),
                          style: FilledButton.styleFrom(
                            backgroundColor: WorldCompanionColors.deepOcean,
                            foregroundColor: Colors.white,
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
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(commentController.dispose);
  }

  Future<void> _submitReview(
    int rating,
    String comment,
  ) async {
    try {
      await ApiService.createReview(
        targetType: widget.targetType,
        targetId: widget.targetId,
        rating: rating,
        comment: comment,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review submitted successfully.'),
        ),
      );

      await _loadReviews();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to submit the review.'),
        ),
      );
    }
  }

  String _ratingLabel(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very good';
    if (rating >= 3.0) return 'Good';
    if (rating >= 2.0) return 'Fair';
    return 'Needs improvement';
  }

  String _formatDate(String value) {
    try {
      final date = DateTime.parse(value);

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return value;
    }
  }
}
