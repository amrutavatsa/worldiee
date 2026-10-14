
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingScreen({
    super.key,
    required this.onFinished,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  static const String completedKey = 'onboarding_completed';

  static const Color navy = Color(0xFF0B2545);
  static const Color ivory = Color(0xFFEEF4ED);
  static const Color gold = Color(0xFFE5C28A);
  static const Color mutedWhite = Color(0xFFD8E1E9);

  final PageController _pageController = PageController();

  late final AnimationController _textController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  int _currentPage = 0;
  bool _saving = false;

  final List<_TravelPage> _pages = const [
    _TravelPage(
      eyebrow: 'GO BEYOND THE ORDINARY',
      title: 'The world is\nwaiting for you.',
      description:
          'Discover extraordinary destinations, hidden gems, and experiences worth remembering.',
      image:
          'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=1400&q=85',
      location: 'THE DOLOMITES, ITALY',
    ),
    _TravelPage(
      eyebrow: 'EVERY DETAIL, IN HARMONY',
      title: 'Your journey.\nYour way.',
      description:
          'Bring your places, stays, and plans together. Spend less time organising and more time exploring.',
      image:
          'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=1400&q=85',
      location: 'LAKE BLED, SLOVENIA',
    ),
    _TravelPage(
      eyebrow: 'A COMPANION FOR EVERY MILE',
      title: 'Travel with\nconfidence.',
      description:
          'Meet your AI Companion for travel inspiration, thoughtful guidance, and your next great adventure.',
      image:
          'https://images.unsplash.com/photo-1530789253388-582c481c54b0?auto=format&fit=crop&w=1400&q=85',
      location: 'SOMEWHERE BEAUTIFUL',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutCubic,
      ),
    );

    _textController.forward();
  }

  void _handlePageChanged(int index) {
    if (index == _currentPage) return;

    setState(() {
      _currentPage = index;
    });

    _textController
      ..stop()
      ..reset()
      ..forward();
  }

  Future<void> _finish() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(completedKey, true);

      if (!mounted) return;

      widget.onFinished();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save your progress. Please try again.',
          ),
        ),
      );
    }
  }

  void _next() {
    if (_saving) return;

    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = MediaQuery.sizeOf(context);
          final isWide = constraints.maxWidth >= 700;
          final isShort = constraints.maxHeight < 700;

          final horizontalPadding = isWide ? 64.0 : 26.0;
          final titleSize = isWide ? 52.0 : (isShort ? 35.0 : 43.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Cinematic images with subtle horizontal parallax.
              AnimatedBuilder(
                animation: _pageController,
                builder: (context, _) {
                  final page = _pageController.hasClients &&
                          _pageController.position.hasViewportDimension
                      ? (_pageController.page ??
                          _currentPage.toDouble())
                      : _currentPage.toDouble();

                  return Stack(
                    fit: StackFit.expand,
                    children: List.generate(_pages.length, (index) {
                      final distance = index - page;
                      final opacity = (1.0 - distance.abs())
                          .clamp(0.0, 1.0)
                          .toDouble();

                      return Positioned.fill(
                        child: ClipRect(
                          child: Opacity(
                            opacity: opacity,
                            child: Transform.translate(
                              offset: Offset(-distance * 42.0, 0),
                              child: SizedBox(
                                width: size.width + 100,
                                height: size.height,
                                child: _CinematicImage(
                                  imageUrl: _pages[index].image,
                                  active: index == _currentPage,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),

              // Cinematic overlay for readable text.
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.16, 0.40, 0.67, 1.0],
                      colors: [
                        Color(0xB3030D19),
                        Color(0x26030D19),
                        Color(0x18030D19),
                        Color(0xCC0B2545),
                        Color(0xFF0B2545),
                      ],
                    ),
                  ),
                ),
              ),

              // Transparent PageView handles both swipes and button navigation.
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        12,
                        horizontalPadding,
                        8,
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/world_companion_mark.png',
                            width: 36,
                            height: 36,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.explore_rounded,
                              size: 34,
                              color: ivory,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'WorldCompanion',
                            style: TextStyle(
                              color: ivory,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.35,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _saving ? null : _finish,
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: Color(0xFFE3EAF0),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        onPageChanged: _handlePageChanged,
                        itemBuilder: (context, index) {
                          return const SizedBox.expand();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Foreground copy and controls.
              SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: isShort ? 72 : 88),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _textController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: child,
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 720,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 26,
                                    height: 1,
                                    color: gold,
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: Text(
                                        _pages[_currentPage].location,
                                        key: ValueKey(
                                          _pages[_currentPage].location,
                                        ),
                                        style: const TextStyle(
                                          color: Color(0xFFE6D2AB),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 22),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 380),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, animation) {
                                  final slide = Tween<Offset>(
                                    begin: const Offset(0, 0.08),
                                    end: Offset.zero,
                                  ).animate(animation);

                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: slide,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  _pages[_currentPage].title,
                                  key: ValueKey(
                                    _pages[_currentPage].title,
                                  ),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: titleSize,
                                    height: 1.08,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  _pages[_currentPage].description,
                                  key: ValueKey(
                                    _pages[_currentPage].description,
                                  ),
                                  style: TextStyle(
                                    color: mutedWhite,
                                    fontSize: isWide ? 16 : 14,
                                    height: 1.65,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isShort ? 22 : 34),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        isShort ? 12 : 22,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 720,
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Row(
                                  children: List.generate(
                                    _pages.length,
                                    (index) => AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 350),
                                      curve: Curves.easeOutCubic,
                                      margin:
                                          const EdgeInsets.only(right: 7),
                                      width: index == _currentPage ? 32 : 7,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: index == _currentPage
                                            ? gold
                                            : Colors.white.withOpacity(0.38),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_currentPage + 1}'.padLeft(2, '0'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  ' / ${_pages.length.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.60),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isShort ? 16 : 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: FilledButton(
                                onPressed: _saving ? null : _next,
                                style: FilledButton.styleFrom(
                                  backgroundColor: ivory,
                                  foregroundColor: navy,
                                  disabledBackgroundColor:
                                      ivory.withOpacity(0.75),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(17),
                                  ),
                                ),
                                child: AnimatedSwitcher(
                                  duration:
                                      const Duration(milliseconds: 220),
                                  child: _saving
                                      ? const SizedBox(
                                          key: ValueKey('loading'),
                                          width: 21,
                                          height: 21,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: navy,
                                          ),
                                        )
                                      : Row(
                                          key: ValueKey(_currentPage),
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _currentPage ==
                                                      _pages.length - 1
                                                  ? 'Begin your journey'
                                                  : 'Continue',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(height: isShort ? 8 : 15),
                            const Text(
                              'MADE FOR THE WAY YOU TRAVEL',
                              style: TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 9,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CinematicImage extends StatelessWidget {
  final String imageUrl;
  final bool active;

  const _CinematicImage({
    required this.imageUrl,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: active ? 1.05 : 1.0,
      duration: const Duration(seconds: 7),
      curve: Curves.easeOutCubic,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) {
          return const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF42677C),
                  Color(0xFF13315C),
                  Color(0xFF0B2545),
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.landscape_rounded,
                size: 90,
                color: Color(0x668DA9C4),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TravelPage {
  final String eyebrow;
  final String title;
  final String description;
  final String image;
  final String location;

  const _TravelPage({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.image,
    required this.location,
  });
}
