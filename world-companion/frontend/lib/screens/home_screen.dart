import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/api_service.dart';
import 'companion_screen.dart';
import 'explore_screens.dart';
import 'nearby_screen.dart';
import 'place_details_screen.dart';
import 'profile_screen.dart';
import 'route_screen.dart';
import 'stays_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  static const Duration _silenceDuration = Duration(seconds: 3);

  bool _speechAvailable = false;
  bool _isListening = false;
  bool _voiceSubmitting = false;

  bool _nearbyLoading = true;
  String? _nearbyError;
  List<Map<String, dynamic>> _nearbyPlaces = [];

  bool _recommendationsLoading = true;
  List<Map<String, dynamic>> _recommendations = [];

  Timer? _speechSilenceTimer;

  static const List<Map<String, String>> _destinations = [
    {
      'name': 'Coorg',
      'subtitle': 'Coffee trails & green hills',
      'image':
          'https://images.unsplash.com/photo-1511497584788-876760111969?w=900&auto=format&fit=crop&q=85',
    },
    {
      'name': 'Hampi',
      'subtitle': 'Ancient ruins & heritage',
      'image':
          'https://images.unsplash.com/photo-1600100397608-f0109a6c0d4a?w=900&auto=format&fit=crop&q=85',
    },
    {
      'name': 'Goa',
      'subtitle': 'Coastal escapes',
      'image':
          'https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?w=900&auto=format&fit=crop&q=85',
    },
    {
      'name': 'Mysuru',
      'subtitle': 'Palaces & local culture',
      'image':
          'https://images.unsplash.com/photo-1566552881560-0be862a7c445?w=900&auto=format&fit=crop&q=85',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _loadNearbyPlaces();
    _loadRecommendations();
  }

  @override
  void dispose() {
    _speechSilenceTimer?.cancel();
    _speech.stop();
    _controller.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Speech input
  // ---------------------------------------------------------------------------

  Future<void> _initializeSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;

          final listening = status == 'listening';

          setState(() {
            _isListening = listening;
          });

          if (!listening) {
            _cancelSilenceTimer();
          }
        },
        onError: (_) {
          if (!mounted) return;

          setState(() {
            _isListening = false;
            _voiceSubmitting = false;
          });

          _cancelSilenceTimer();
        },
      );

      if (!mounted) return;

      setState(() {
        _speechAvailable = available;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _speechAvailable = false;
      });
    }
  }

  void _resetSilenceTimer() {
    _speechSilenceTimer?.cancel();
    _speechSilenceTimer = Timer(
      _silenceDuration,
      _handleSpeechSilence,
    );
  }

  void _cancelSilenceTimer() {
    _speechSilenceTimer?.cancel();
    _speechSilenceTimer = null;
  }

  Future<void> _handleSpeechSilence() async {
    if (!mounted || !_isListening || _voiceSubmitting) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _voiceSubmitting = true;
    });

    _cancelSilenceTimer();

    try {
      await _speech.stop();

      if (!mounted) return;

      setState(() {
        _isListening = false;
      });

      await Future<void>.delayed(
        const Duration(milliseconds: 250),
      );

      if (!mounted) return;

      final recognizedText = _controller.text.trim();

      setState(() {
        _voiceSubmitting = false;
      });

      if (recognizedText.isNotEmpty) {
        _openCompanion(initialMessage: recognizedText);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isListening = false;
        _voiceSubmitting = false;
      });

      _showMessage('Could not finish voice input. Please try again.');
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _cancelSilenceTimer();

      final text = _controller.text.trim();

      try {
        await _speech.stop();
      } catch (_) {
        // Continue with recognized text if stopping fails.
      }

      if (!mounted) return;

      setState(() {
        _isListening = false;
      });

      if (text.isNotEmpty) {
        _openCompanion(initialMessage: text);
      }

      return;
    }

    if (_voiceSubmitting) return;

    if (!_speechAvailable) {
      await _initializeSpeech();
    }

    if (!_speechAvailable || !mounted) {
      _showMessage(
        'Voice input is unavailable. Please type your question.',
      );
      return;
    }

    _controller.clear();

    try {
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: 'en_IN',
          listenMode: stt.ListenMode.confirmation,
          partialResults: true,
        ),
        onResult: (result) {
          if (!mounted) return;

          setState(() {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.collapsed(
              offset: _controller.text.length,
            );
          });

          if (result.recognizedWords.trim().isNotEmpty) {
            _resetSilenceTimer();
          }

          if (result.finalResult) {
            _resetSilenceTimer();
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _isListening = true;
      });

      _resetSilenceTimer();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isListening = false;
        _voiceSubmitting = false;
      });

      _cancelSilenceTimer();
      _showMessage('Could not start voice input. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Dedicated Companion navigation
  // ---------------------------------------------------------------------------

  void _openCompanion({String? initialMessage}) {
    final message = initialMessage?.trim();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CompanionScreen(
          initialMessage:
              message != null && message.isNotEmpty ? message : null,
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // Nearby places
  // ---------------------------------------------------------------------------

  Future<void> _loadNearbyPlaces() async {
    if (!mounted) return;

    setState(() {
      _nearbyLoading = true;
      _nearbyError = null;
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
        radiusKm: 10,
      );

      if (!mounted) return;

      final parsedPlaces = result
          .whereType<Map>()
          .map((place) => Map<String, dynamic>.from(place))
          .toList();

      setState(() {
        _nearbyPlaces = parsedPlaces;
        _nearbyLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().toLowerCase();

      setState(() {
        _nearbyLoading = false;
        _nearbyError = message.contains('permission')
            ? 'Allow location access to discover places around you.'
            : message.contains('disabled')
                ? 'Enable location services and try again.'
                : message.contains('timed out')
                    ? 'Location took too long to respond.'
                    : 'Nearby places could not be loaded right now.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Recommendations
  // ---------------------------------------------------------------------------

  Future<void> _loadRecommendations() async {
    if (!mounted) return;

    setState(() {
      _recommendationsLoading = true;
    });

    try {
      final result = await ApiService.getRecommendations();

      if (!mounted) return;

      setState(() {
        _recommendations = result
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _recommendationsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _recommendationsLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _openPlace(Map<String, dynamic> place) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PlaceDetailsScreen(place: place),
      ),
    );
  }

  void _openNearby() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const NearbyScreen(),
      ),
    );
  }

  void _openExplore() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ExploreScreen(),
      ),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const ProfileScreen(),
      ),
    );
  }

  void _openRoutePlanner() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const RouteScreen(),
      ),
    );
  }

  void _openStays() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const StaysScreen(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _prettyCategory(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'Place';
    }

    final raw = value.toString().replaceAll('_', ' ').trim();

    return raw
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  String _distanceLabel(dynamic value) {
    if (value == null) return '';

    final distance = double.tryParse(value.toString());
    if (distance == null || !distance.isFinite || distance < 0) {
      return '';
    }

    if (distance < 1) {
      return '${(distance * 1000).round()} m away';
    }

    return '${distance.toStringAsFixed(1)} km away';
  }

  String? _imageUrl(Map<String, dynamic> data) {
    for (final key in [
      'image_url',
      'photo_url',
      'image',
      'photo',
      'thumbnail',
    ]) {
      final value = data[key];

      if (value is String &&
          (value.startsWith('https://') ||
              value.startsWith('http://'))) {
        return value;
      }
    }

    return null;
  }

  IconData _iconForCategory(dynamic value) {
    final category = value?.toString().toLowerCase() ?? '';

    if (category.contains('food') ||
        category.contains('restaurant') ||
        category.contains('cafe')) {
      return Icons.restaurant_rounded;
    }

    if (category.contains('stay') ||
        category.contains('hotel') ||
        category.contains('lodging')) {
      return Icons.hotel_rounded;
    }

    if (category.contains('shopping')) {
      return Icons.shopping_bag_rounded;
    }

    if (category.contains('park') || category.contains('leisure')) {
      return Icons.park_rounded;
    }

    if (category.contains('museum') ||
        category.contains('historic') ||
        category.contains('explore')) {
      return Icons.account_balance_rounded;
    }

    return Icons.place_rounded;
  }

  Widget _categoryPlaceholder({
    required Color backgroundColor,
    required Color iconColor,
    required IconData icon,
    double iconSize = 40,
  }) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor,
      ),
    );
  }

  Widget _networkImage({
    required String imageUrl,
    required BoxFit fit,
    required Widget fallback,
  }) {
    return Image.network(
      imageUrl,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;

        return Stack(
          fit: StackFit.expand,
          children: [
            fallback,
            Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress.expectedTotalBytes == null
                      ? null
                      : progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Main UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              _loadNearbyPlaces(),
              _loadRecommendations(),
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildGreeting()),
              SliverToBoxAdapter(child: _buildSearchSection()),
              SliverToBoxAdapter(child: _buildQuickActions()),
              SliverToBoxAdapter(
                child: _buildSectionHeading(
                  title: 'Featured destinations',
                  subtitle: 'Ideas for your next escape',
                  actionLabel: 'Explore all',
                  onAction: _openExplore,
                ),
              ),
              SliverToBoxAdapter(child: _buildFeaturedDestinations()),
              SliverToBoxAdapter(
                child: _buildSectionHeading(
                  title: 'Discover places near you',
                  subtitle: 'Real places around your current location',
                  actionLabel: 'See all',
                  onAction: _openNearby,
                ),
              ),
              SliverToBoxAdapter(child: _buildNearbySection()),
              SliverToBoxAdapter(
                child: _buildSectionHeading(
                  title: 'Recommended for you',
                  subtitle: 'Suggestions from WorldCompanion',
                  actionLabel: 'Explore',
                  onAction: _openExplore,
                ),
              ),
              SliverToBoxAdapter(child: _buildRecommendationsSection()),
              SliverToBoxAdapter(child: _buildCompanionSection()),
              const SliverToBoxAdapter(
                child: SizedBox(height: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.explore_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORLD COMPANION',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.15,
                      ),
                ),
                Text(
                  'Your journey, thoughtfully planned.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: _openProfile,
            icon: Icon(
              Icons.account_circle_outlined,
              color: colors.primary,
              size: 29,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHERE TO NEXT?',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
          ),
          const SizedBox(height: 9),
          Text(
            'Your next adventure\nstarts here.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            'Discover places, plan routes, and make every trip count.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _openCompanion(initialMessage: value);
                }
              },
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Search destinations, places or hotels...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colors.primary,
                ),
                suffixIcon: IconButton(
                  tooltip: _isListening
                      ? 'Stop voice input'
                      : 'Use voice input',
                  onPressed: _voiceSubmitting ? null : _toggleListening,
                  icon: Icon(
                    _isListening
                        ? Icons.mic_rounded
                        : Icons.mic_none_rounded,
                    color: _isListening ? colors.error : colors.primary,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: colors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: colors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: colors.primary,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: colors.surface,
              ),
            ),
            if (_isListening || _voiceSubmitting) ...[
              const SizedBox(height: 8),
              Text(
                _voiceSubmitting
                    ? 'Opening your companion…'
                    : 'Listening… pause for 3 seconds to continue',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.primary,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                final query = _controller.text.trim();

                _openCompanion(
                  initialMessage: query.isEmpty ? null : query,
                );
              },
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Ask your companion'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final colors = Theme.of(context).colorScheme;

    final actions = [
      (
        title: 'Explore',
        icon: Icons.travel_explore_rounded,
        onTap: _openExplore,
      ),
      (
        title: 'Plan a trip',
        icon: Icons.route_rounded,
        onTap: _openRoutePlanner,
      ),
      (
        title: 'Nearby',
        icon: Icons.my_location_rounded,
        onTap: _openNearby,
      ),
      (
        title: 'Find stays',
        icon: Icons.hotel_rounded,
        onTap: _openStays,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      child: Row(
        children: actions.map((action) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: action.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Icon(
                            action.icon,
                            color: colors.primary,
                            size: 25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 16, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedDestinations() {
    return SizedBox(
      height: 224,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _destinations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final destination = _destinations[index];

          return SizedBox(
            width: 255,
            child: _buildPhotoCard(
              title: destination['name']!,
              subtitle: destination['subtitle']!,
              imageUrl: destination['image']!,
              onTap: () => _openCompanion(
                initialMessage:
                    'Help me plan a trip to ${destination['name']}',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoCard({
    required String title,
    required String subtitle,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(21),
      child: Material(
        color: colors.surfaceContainerHighest,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _networkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                fallback: _categoryPlaceholder(
                  backgroundColor: colors.primaryContainer,
                  iconColor: colors.primary,
                  icon: Icons.landscape_rounded,
                  iconSize: 56,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.78),
                    ],
                    stops: const [0.25, 1],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNearbySection() {
    final colors = Theme.of(context).colorScheme;

    if (_nearbyLoading) {
      return const SizedBox(
        height: 135,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_nearbyError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_off_rounded,
                color: colors.primary,
                size: 28,
              ),
              const SizedBox(height: 9),
              Text(
                _nearbyError!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: _loadNearbyPlaces,
                    child: const Text('Try again'),
                  ),
                  TextButton(
                    onPressed: _openNearby,
                    child: const Text('Open Nearby'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_nearbyPlaces.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                Icons.explore_rounded,
                color: colors.primary,
                size: 30,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No nearby places were returned. Try refreshing or explore the full map.',
                ),
              ),
              IconButton(
                onPressed: _loadNearbyPlaces,
                tooltip: 'Refresh nearby places',
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
      );
    }

    final visiblePlaces = _nearbyPlaces.take(8).toList();

    return SizedBox(
      height: 236,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: visiblePlaces.length,
        separatorBuilder: (_, __) => const SizedBox(width: 13),
        itemBuilder: (context, index) {
          final place = visiblePlaces[index];
          final name = place['name']?.toString() ?? 'Nearby place';
          final category = _prettyCategory(
            place['subcategory'] ?? place['category'],
          );
          final distance = _distanceLabel(place['distance_km']);
          final imageUrl = _imageUrl(place);

          final fallback = _categoryPlaceholder(
            backgroundColor: colors.primaryContainer,
            iconColor: colors.primary,
            icon: _iconForCategory(place['category']),
          );

          return SizedBox(
            width: 210,
            child: Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openPlace(place),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 126,
                      width: double.infinity,
                      child: imageUrl == null
                          ? fallback
                          : _networkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              fallback: fallback,
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            distance.isEmpty
                                ? category
                                : '$category · $distance',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    final colors = Theme.of(context).colorScheme;

    if (_recommendationsLoading) {
      return const SizedBox(
        height: 90,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recommendations.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: colors.primary,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Explore places and save your travel preferences to get more relevant suggestions.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recommendations.take(4).map((place) {
        final item = Map<String, dynamic>.from(place);
        final imageUrl = _imageUrl(item);
        final name = item['name']?.toString() ??
            item['title']?.toString() ??
            'Recommended place';
        final category = _prettyCategory(
          item['subcategory'] ?? item['category'],
        );

        final fallback = _categoryPlaceholder(
          backgroundColor: colors.primaryContainer,
          iconColor: colors.primary,
          icon: _iconForCategory(item['category']),
          iconSize: 28,
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: () => _openPlace(item),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: SizedBox(
                        width: 68,
                        height: 68,
                        child: imageUrl == null
                            ? fallback
                            : _networkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                fallback: fallback,
                              ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            category,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompanionSection() {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 0),
      child: Material(
        color: colors.primary,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () => _openCompanion(),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(19),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your travel companion',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Ask questions, discover places and plan your next journey.',
                        style: TextStyle(
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}