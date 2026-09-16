import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'place_details_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  Map<String, dynamic> _pois = {};
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedCategory = 'All';

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

    final selectedCategory =
        _selectedCategory.toLowerCase().replaceAll('s', '');

    final matchesCategory = category == selectedCategory;

    return matchesSearch && matchesCategory;
  }).toList();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9F8),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF172326),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Explore',
          style: TextStyle(
            color: Color(0xFF172326),
            fontSize: 24,
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
        color: Color(0xFF0E7774),
      ),
    );
  }

  if (_error != null) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFF68777B),
            ),
            const SizedBox(height: 16),
            const Text(
              'Couldn’t load places',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF172326),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF68777B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadPois();
              },
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  final places = _filteredPois;

  return LayoutBuilder(
    builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 900;

      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isWide ? 48 : 20,
          12,
          isWide ? 48 : 20,
          40,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1200,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Discover Bengaluru',
                  style: TextStyle(
                    color: Color(0xFF172326),
                    fontSize: 30,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find places worth experiencing.',
                  style: TextStyle(
                    color: Color(0xFF68777B),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Search
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search places',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF68777B),
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 32),

                // Category heading
                const Text(
                  'Explore by category',
                  style: TextStyle(
                    color: Color(0xFF172326),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 14),

                // Category placeholders for the frame.
                // Functional filtering will be added next.
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _categoryChip('All'),
                    _categoryChip('Parks'),
                    _categoryChip('Food'),
                    _categoryChip('Shopping'),
                    _categoryChip('Landmarks'),
                    _categoryChip('Areas'),
                    ],
                  ),

                const SizedBox(height: 32),

                // Places heading
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Popular places',
                        style: TextStyle(
                          color: Color(0xFF172326),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${places.length} places',
                      style: const TextStyle(
                        color: Color(0xFF68777B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                places.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Text(
                            'No places found',
                            style: TextStyle(
                              color: Color(0xFF68777B),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 360,
                          mainAxisExtent: 190,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: places.length,
                        itemBuilder: (context, index) {
                          final entry = places[index];
                          final place =
                              Map<String, dynamic>.from(entry.value);

                          return _placeCard(
                            name: place['name']?.toString() ?? entry.key,
                            category: place['category']?.toString() ?? 'destination',
                            place: {
                              ...place,
                              'id': entry.key,
                              },
                            );
                        },
                      ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
  
  Widget _categoryChip(String label) {
  final selected = _selectedCategory == label;

  return GestureDetector(
    onTap: () {
      setState(() {
        _selectedCategory = label;
      });
    },
    child: Container(
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF0E7774)
            : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? const Color(0xFF0E7774)
              : const Color(0xFFDCE5E4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : const Color(0xFF172326),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

  Widget _placeCard({
  required String name,
  required String category,
  required Map<String, dynamic> place,
}) {
  return Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceDetailsScreen(
              place: place,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFDFF4F1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _categoryIcon(category),
                color: const Color(0xFF0E7774),
                size: 23,
              ),
            ),
            const Spacer(),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: Color(0xFF172326),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _formatCategory(category),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF68777B),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'park':
        return Icons.park_rounded;
      case 'food':
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'landmark':
        return Icons.account_balance_rounded;
      case 'area':
        return Icons.location_city_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  String _formatCategory(String category) {
    if (category.isEmpty) return 'Destination';

    return category[0].toUpperCase() + category.substring(1);
  }
}