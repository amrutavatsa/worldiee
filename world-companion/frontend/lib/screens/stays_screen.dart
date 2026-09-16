import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'hotel_details_screen.dart';

class StaysScreen extends StatefulWidget {
  const StaysScreen({super.key});

  @override
  State<StaysScreen> createState() => _StaysScreenState();
}

class _StaysScreenState extends State<StaysScreen> {
  int _selectedCategory = 0;

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _hotels = [];

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getHotels();

      final hotels = _extractHotels(response);

      if (!mounted) return;

      setState(() {
        _hotels = hotels;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hotels = [];
        _isLoading = false;
        _errorMessage = 'Unable to load stays right now.';
      });
    }
  }

  List<Map<String, dynamic>> _extractHotels(
    dynamic response,
  ) {
    final result = <Map<String, dynamic>>[];

    if (response is List) {
      for (final item in response) {
        if (item is Map) {
          result.add(
            Map<String, dynamic>.from(item),
          );
        }
      }

      return result;
    }

    if (response is Map) {
      dynamic hotelData;

      if (response['hotels'] is List) {
        hotelData = response['hotels'];
      } else if (response['data'] is List) {
        hotelData = response['data'];
      } else if (response['data'] is Map) {
        final data = response['data'];

        if (data['hotels'] is List) {
          hotelData = data['hotels'];
        }
      }

      if (hotelData is List) {
        for (final item in hotelData) {
          if (item is Map) {
            result.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }
    }

    return result;
  }

  String _getName(
    Map<String, dynamic> hotel,
  ) {
    return hotel['name']?.toString() ?? 'Unnamed stay';
  }

  String _getArea(
    Map<String, dynamic> hotel,
  ) {
    return hotel['area']?.toString() ?? 'Bengaluru';
  }

  double? _getPrice(
    Map<String, dynamic> hotel,
  ) {
    final value = hotel['price_per_night'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  double? _getRating(
    Map<String, dynamic> hotel,
  ) {
    final value = hotel['rating'];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    );
  }

  List<String> _getFacilities(
    Map<String, dynamic> hotel,
  ) {
    final value = hotel['facilities'];

    if (value is List) {
      return value
          .map(
            (item) => item.toString(),
          )
          .toList();
    }

    if (value is Map) {
      return value.entries
          .where(
            (entry) =>
                entry.value == true ||
                entry.value != null,
          )
          .map(
            (entry) => entry.key.toString(),
          )
          .toList();
    }

    return [];
  }

  String _formatPrice(
    double? price,
  ) {
    if (price == null) {
      return 'Price unavailable';
    }

    return '₹${price.toStringAsFixed(0)} / night';
  }

  void _selectCategory(
    int index,
  ) {
    setState(() {
      _selectedCategory = index;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Stay',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor:
            theme.scaffoldBackgroundColor,
        foregroundColor:
            const Color(0xFF172326),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadHotels,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final isWide =
            constraints.maxWidth >= 800;

        return SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            20,
            8,
            20,
            40,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1100,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildHero(context),

                  const SizedBox(
                    height: 22,
                  ),

                  _buildCategorySelector(
                    context,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  _buildSelectedCategory(
                    context,
                    isWide,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHero(
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            const Color(0xFF123B43),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white
                  .withOpacity(0.14),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.hotel_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'Find your stay',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'Hotels, hostels and dorms for your journey.',
            style: TextStyle(
              color: Colors.white
                  .withOpacity(0.82),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(
    BuildContext context,
  ) {
    final categories = [
      (
        label: 'Hotels',
        icon: Icons.hotel_outlined,
        available: true,
      ),
      (
        label: 'Hostels',
        icon: Icons.groups_outlined,
        available: false,
      ),
      (
        label: 'Dorms',
        icon: Icons.bed_outlined,
        available: false,
      ),
    ];

    return SizedBox(
      height: 92,
      child: Row(
        children: List.generate(
          categories.length,
          (index) {
            final category =
                categories[index];

            final isSelected =
                _selectedCategory == index;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right:
                      index == categories.length - 1
                          ? 0
                          : 10,
                ),
                child: _buildCategoryCard(
                  context,
                  index,
                  category.label,
                  category.icon,
                  category.available,
                  isSelected,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    int index,
    String label,
    IconData icon,
    bool available,
    bool selected,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () {
          _selectCategory(index);
        },
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : const Color(0xFFDCE5E4),
            ),
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected
                    ? Colors.white
                    : const Color(0xFF68777B),
              ),

              const SizedBox(
                height: 6,
              ),

              Text(
                label,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(0xFF172326),
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),

              if (!available)
                Text(
                  'Soon',
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                            .withOpacity(0.75)
                        : const Color(
                            0xFF68777B,
                          ),
                    fontSize: 9,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCategory(
    BuildContext context,
    bool isWide,
  ) {
    if (_selectedCategory != 0) {
      return _buildUnavailableCategory(
        context,
      );
    }

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(
          top: 80,
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState(
        context,
      );
    }

    if (_hotels.isEmpty) {
      return _buildEmptyState(
        context,
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Hotels',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w700,
                    ),
              ),
            ),

            Text(
              '${_hotels.length} available',
              style: const TextStyle(
                color: Color(0xFF68777B),
                fontSize: 12,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 14,
        ),

        isWide
            ? _buildWideGrid(context)
            : _buildMobileList(context),
      ],
    );
  }

  Widget _buildMobileList(
    BuildContext context,
  ) {
    return Column(
      children: _hotels.map(
        (hotel) {
          return Padding(
            padding:
                const EdgeInsets.only(
              bottom: 14,
            ),
            child: _buildHotelCard(
              context,
              hotel,
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildWideGrid(
    BuildContext context,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(),
      itemCount: _hotels.length,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (
        context,
        index,
      ) {
        return _buildHotelCard(
          context,
          _hotels[index],
        );
      },
    );
  }

  Widget _buildHotelCard(
    BuildContext context,
    Map<String, dynamic> hotel,
  ) {
    final theme = Theme.of(context);

    final name = _getName(hotel);
    final area = _getArea(hotel);
    final price = _getPrice(hotel);
    final rating = _getRating(hotel);
    final facilities =
        _getFacilities(hotel);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(22),

        // CHANGED:
        // Hotel cards now open the real
        // HotelDetailsScreen using the
        // exact backend hotel object.
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  HotelDetailsScreen(
                hotel: hotel,
              ),
            ),
          );
        },

        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color:
                theme.colorScheme.surface,
            borderRadius:
                BorderRadius.circular(22),
            border: Border.all(
              color:
                  const Color(0xFFDCE5E4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(
                  0,
                  6,
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFDFF4F1,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                    ),
                    child: Icon(
                      Icons.hotel_outlined,
                      color: theme
                          .colorScheme
                          .primary,
                      size: 28,
                    ),
                  ),

                  const SizedBox(
                    width: 14,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          name,
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style: theme
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Row(
                          children: [
                            const Icon(
                              Icons
                                  .location_on_outlined,
                              size: 15,
                              color: Color(
                                0xFF68777B,
                              ),
                            ),

                            const SizedBox(
                              width: 4,
                            ),

                            Expanded(
                              child: Text(
                                area,
                                maxLines: 1,
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    const TextStyle(
                                  color: Color(
                                    0xFF68777B,
                                  ),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (rating != null)
                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFFFF3E8,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons
                                .star_rounded,
                            size: 15,
                            color: Color(
                              0xFFF27C4A,
                            ),
                          ),

                          const SizedBox(
                            width: 3,
                          ),

                          Text(
                            rating
                                .toStringAsFixed(
                              1,
                            ),
                            style:
                                const TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      _formatPrice(price),
                      style: TextStyle(
                        color: theme
                            .colorScheme
                            .primary,
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons
                        .arrow_forward_rounded,
                    color: Color(
                      0xFF68777B,
                    ),
                    size: 20,
                  ),
                ],
              ),

              if (facilities.isNotEmpty) ...[
                const SizedBox(
                  height: 14,
                ),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children:
                      facilities.take(3).map(
                    (facility) {
                      return Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFF7F9F8,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            10,
                          ),
                        ),
                        child: Text(
                          facility,
                          style:
                              const TextStyle(
                            fontSize: 11,
                            color: Color(
                              0xFF68777B,
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnavailableCategory(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color:
            Theme.of(context)
                .colorScheme
                .surface,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              const Color(0xFFDCE5E4),
        ),
      ),
      child: Column(
        children: [
          Icon(
            _selectedCategory == 1
                ? Icons.groups_outlined
                : Icons.bed_outlined,
            size: 48,
            color:
                const Color(0xFF68777B),
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            _selectedCategory == 1
                ? 'Hostels'
                : 'Dorms',
            style: const TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'This stay category will be connected when its existing backend support is available.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF68777B),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color:
            Theme.of(context)
                .colorScheme
                .surface,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              const Color(0xFFDCE5E4),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.hotel_outlined,
            size: 48,
            color: Color(0xFF68777B),
          ),

          SizedBox(
            height: 14,
          ),

          Text(
            'No hotels available',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          SizedBox(
            height: 6,
          ),

          Text(
            'The existing backend did not return any hotel listings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF68777B),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color:
            Theme.of(context)
                .colorScheme
                .surface,
        borderRadius:
            BorderRadius.circular(22),
        border: Border.all(
          color:
              const Color(0xFFDCE5E4),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons
                .cloud_off_outlined,
            size: 48,
            color: Color(
              0xFFC94B4B,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          const Text(
            'Unable to load hotels',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'Check the backend connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(
                0xFF68777B,
              ),
              fontSize: 13,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          OutlinedButton.icon(
            onPressed: _loadHotels,
            icon: const Icon(
              Icons.refresh,
            ),
            label: const Text(
              'Try again',
            ),
          ),
        ],
      ),
    );
  }
}