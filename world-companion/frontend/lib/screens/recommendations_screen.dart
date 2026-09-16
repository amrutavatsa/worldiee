import 'package:flutter/material.dart';

import '../services/api_service.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  State<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState
    extends State<RecommendationsScreen> {
  static const Color primary = Color(0xFF0E7774);
  static const Color deep = Color(0xFF123B43);
  static const Color aqua = Color(0xFFDFF4F1);
  static const Color background = Color(0xFFF7F9F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF172326);
  static const Color muted = Color(0xFF68777B);
  static const Color line = Color(0xFFDCE5E4);
  static const Color error = Color(0xFFC94B4B);

  bool _loading = true;
  String? _error;
  List<dynamic> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
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
        return value.toString();
      }
    }

    return '';
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

    String tags = '';

    if (tagsValue is List) {
      tags = tagsValue
          .map((tag) => tag.toString())
          .join(' • ');
    }

    final displayName =
        name.isEmpty ? 'Recommended place' : name;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08123B43),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: index.isEven ? aqua : const Color(0xFFFFEEE8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                category.toLowerCase().contains('food') ||
                        category.toLowerCase().contains('restaurant')
                    ? Icons.restaurant_rounded
                    : category.toLowerCase().contains('park') ||
                            category.toLowerCase().contains('nature')
                        ? Icons.park_rounded
                        : category.toLowerCase().contains('shopping')
                            ? Icons.shopping_bag_rounded
                            : Icons.place_rounded,
                color: primary,
                size: 25,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  if (category.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: aqua,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 9),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],

                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      tags,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: line),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            color: primary,
            size: 42,
          ),
          SizedBox(height: 16),
          Text(
            'No recommendations yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Set your travel preferences and come back to discover places that match your interests.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: muted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Recommendations'),
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadRecommendations,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecommendations,
          color: primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      deep,
                      primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Made for your journey',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Places selected from your travel preferences.',
                            style: TextStyle(
                              color: Color(0xD9FFFFFF),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: primary,
                    ),
                  ),
                )
              else if (_error != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: error.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: error,
                        size: 38,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Could not load recommendations',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _loadRecommendations,
                        icon: const Icon(
                          Icons.refresh_rounded,
                        ),
                        label: const Text('Try again'),
                      ),
                    ],
                  ),
                )
              else if (_recommendations.isEmpty)
                _emptyState()
              else
                ..._recommendations.asMap().entries.map(
                  (entry) {
                    final value = entry.value;

                    if (value is Map) {
                      return _recommendationCard(
                        Map<String, dynamic>.from(value),
                        entry.key,
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}