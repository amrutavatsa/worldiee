import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../services/api_service.dart';
import '../theme/world_companion_colors.dart';
import '../theme/world_companion_elevation.dart';
import '../theme/world_companion_motion.dart';
import '../theme/world_companion_radius.dart';
import '../theme/world_companion_spacing.dart';
import '../theme/world_companion_typography.dart';
import 'home_screen.dart';
import 'explore_screens.dart';
import 'trip_screen.dart';
import 'stays_screen.dart';
import 'profile_screen.dart';

class AppShellNavigation extends InheritedWidget {
  const AppShellNavigation({
    super.key,
    required this.goHome,
    required super.child,
  });

  final VoidCallback goHome;

  static AppShellNavigation? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppShellNavigation>();
  }

  static AppShellNavigation of(BuildContext context) {
    final navigation = maybeOf(context);

    assert(
      navigation != null,
      'AppShellNavigation was not found in the widget tree.',
    );

    return navigation!;
  }

  @override
  bool updateShouldNotify(AppShellNavigation oldWidget) {
    return goHome != oldWidget.goHome;
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const int _homeIndex = 0;
  static const int _exploreIndex = 1;
  static const int _tripsIndex = 2;
  static const int _staysIndex = 3;
  static const int _profileIndex = 4;
  static const int _destinationCount = 5;

  int _selectedIndex = _homeIndex;
  bool _isAiOpen = false;

  // Screens are created only when the user first opens them.
  // This prevents off-screen pages from initializing at app startup.
  late final List<Widget?> _screens = List<Widget?>.filled(
    _destinationCount,
    null,
  )..[_homeIndex] = const HomeScreen();

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore_rounded),
      label: 'Explore',
    ),
    NavigationDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map_rounded),
      label: 'Trips',
    ),
    NavigationDestination(
      icon: Icon(Icons.hotel_outlined),
      selectedIcon: Icon(Icons.hotel_rounded),
      label: 'Stay',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  static const List<NavigationRailDestination> _railDestinations = [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore_rounded),
      label: Text('Explore'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map_rounded),
      label: Text('Trips'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.hotel_outlined),
      selectedIcon: Icon(Icons.hotel_rounded),
      label: Text('Stay'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.person_outline_rounded),
      selectedIcon: Icon(Icons.person_rounded),
      label: Text('Profile'),
    ),
  ];

  Widget _screenForIndex(int index) {
    switch (index) {
      case _homeIndex:
        return const HomeScreen();
      case _exploreIndex:
        return const ExploreScreen();
      case _tripsIndex:
        return const TripsScreen();
      case _staysIndex:
        return const StaysScreen();
      case _profileIndex:
        return const ProfileScreen();
      default:
        throw RangeError.index(index, _destinations);
    }
  }

  void _onDestinationSelected(int index) {
    if (index < 0 || index >= _destinationCount) return;
    if (index == _selectedIndex && !_isAiOpen) return;

    setState(() {
      // Construct the page before switching to its index.
      // It will be retained in the IndexedStack afterwards.
      _screens[index] ??= _screenForIndex(index);

      _selectedIndex = index;
      _isAiOpen = false;
    });
  }

  void _goHome() {
    if (!mounted) return;

    if (_selectedIndex == _homeIndex && !_isAiOpen) return;

    setState(() {
      _screens[_homeIndex] ??= const HomeScreen();
      _selectedIndex = _homeIndex;
      _isAiOpen = false;
    });
  }

  void _toggleAiAssistant() {
    if (!mounted) return;

    setState(() {
      _isAiOpen = !_isAiOpen;
    });
  }

  void _closeAiAssistant() {
    if (!mounted || !_isAiOpen) return;

    setState(() {
      _isAiOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    // IndexedStack requires a child for each index. Unvisited destinations
    // get lightweight placeholders until the user selects them.
    final screenChildren = _screens
        .map<Widget>((screen) => screen ?? const SizedBox.shrink())
        .toList(growable: false);

    return AppShellNavigation(
      goHome: _goHome,
      child: Scaffold(
        backgroundColor: WorldCompanionColors.softWhite,
        body: Row(
          children: [
            if (isWide)
              Container(
                width: 92,
                decoration: const BoxDecoration(
                  color: WorldCompanionColors.surface,
                  border: Border(
                    right: BorderSide(
                      color: WorldCompanionColors.border,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(
                        height: WorldCompanionSpacing.lg,
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: WorldCompanionColors.deepOcean,
                          borderRadius: BorderRadius.circular(
                            WorldCompanionRadius.large,
                          ),
                        ),
                        child: const Icon(
                          Icons.explore_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                      const SizedBox(
                        height: WorldCompanionSpacing.xl,
                      ),
                      Expanded(
                        child: NavigationRail(
                          selectedIndex: _selectedIndex,
                          onDestinationSelected: _onDestinationSelected,
                          labelType: NavigationRailLabelType.all,
                          backgroundColor: Colors.transparent,
                          useIndicator: true,
                          indicatorColor:
                              WorldCompanionColors.infoSurface,
                          selectedIconTheme: const IconThemeData(
                            color: WorldCompanionColors.deepOcean,
                            size: 23,
                          ),
                          unselectedIconTheme: const IconThemeData(
                            color: WorldCompanionColors.mutedText,
                            size: 22,
                          ),
                          selectedLabelTextStyle:
                              Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color:
                                        WorldCompanionColors.deepOcean,
                                    fontWeight: FontWeight.w700,
                                  ),
                          unselectedLabelTextStyle:
                              Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color:
                                        WorldCompanionColors.mutedText,
                                  ),
                          destinations: _railDestinations,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: WorldCompanionSpacing.lg,
                        ),
                        child: IconButton(
                          tooltip: _isAiOpen
                              ? 'Close AI travel assistant'
                              : 'Open AI travel assistant',
                          onPressed: _toggleAiAssistant,
                          style: IconButton.styleFrom(
                            backgroundColor:
                                WorldCompanionColors.deepOcean,
                            foregroundColor: Colors.white,
                            fixedSize: const Size(48, 48),
                          ),
                          icon: Icon(
                            _isAiOpen
                                ? Icons.close_rounded
                                : Icons.auto_awesome_rounded,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: screenChildren,
                    ),
                  ),

                  // Tap outside the assistant to dismiss it.
                  if (_isAiOpen)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _closeAiAssistant,
                        child: ColoredBox(
                          color: WorldCompanionColors.deepOcean
                              .withOpacity(0.22),
                        ),
                      ),
                    ),

                  if (_isAiOpen)
                    Positioned(
                      left: isWide
                          ? null
                          : WorldCompanionSpacing.sm,
                      right: isWide
                          ? WorldCompanionSpacing.lg
                          : WorldCompanionSpacing.sm,
                      bottom: isWide ? 28 : 82,
                      width: isWide ? 420 : null,
                      child: SafeArea(
                        top: false,
                        child: _AiAssistantPanel(
                          onClose: _closeAiAssistant,
                        ),
                      ),
                    ),

                  if (!isWide)
                    Positioned(
                      right: WorldCompanionSpacing.md,
                      bottom: WorldCompanionSpacing.sm,
                      child: SafeArea(
                        top: false,
                        child: _AiFloatingButton(
                          isOpen: _isAiOpen,
                          onTap: _toggleAiAssistant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: isWide
            ? null
            : NavigationBar(
                height: 72,
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onDestinationSelected,
                backgroundColor: WorldCompanionColors.surface,
                indicatorColor: WorldCompanionColors.infoSurface,
                surfaceTintColor: Colors.transparent,
                elevation: WorldCompanionElevation.low,
                labelBehavior:
                    NavigationDestinationLabelBehavior.alwaysShow,
                destinations: _destinations,
              ),
      ),
    );
  }
}

class _AiFloatingButton extends StatelessWidget {
  const _AiFloatingButton({
    required this.isOpen,
    required this.onTap,
  });

  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isOpen
          ? 'Close AI travel assistant'
          : 'Open AI travel assistant',
      child: Material(
        color: WorldCompanionColors.deepOcean,
        shape: const CircleBorder(),
        elevation: WorldCompanionElevation.medium,
        shadowColor:
            WorldCompanionColors.deepOcean.withOpacity(0.2),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 54,
            height: 54,
            child: AnimatedSwitcher(
              duration: WorldCompanionMotion.fast,
              switchInCurve: WorldCompanionMotion.standardCurve,
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: Icon(
                isOpen
                    ? Icons.close_rounded
                    : Icons.auto_awesome_rounded,
                key: ValueKey<bool>(isOpen),
                color: Colors.white,
                size: isOpen ? 26 : 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AiAssistantPanel extends StatefulWidget {
  const _AiAssistantPanel({
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  State<_AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends State<_AiAssistantPanel> {
  static const int maxConversationMessages = 20;
  static const int maxToolContextEntries = 20;

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _chatScrollController =
      ScrollController();

  final List<_ChatMessage> _messages = [];
  final List<Map<String, dynamic>> _toolContext = [];

  bool _isLoading = false;
  bool _requiresConfirmation = false;
  String? _pendingActionMessage;

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _buildConversationHistory() {
    final startIndex = _messages.length > maxConversationMessages
        ? _messages.length - maxConversationMessages
        : 0;

    final conversation = _messages
        .sublist(startIndex)
        .map(
          (message) => <String, dynamic>{
            'role': message.isUser ? 'user' : 'assistant',
            'content': message.text,
          },
        )
        .toList();

    if (_toolContext.isNotEmpty) {
      conversation.add({
        'role': 'tool_context',
        'content': jsonEncode(_toolContext),
      });
    }

    return conversation;
  }

  void _updateToolContext(dynamic rawContext) {
    if (rawContext is! List) return;

    for (final item in rawContext) {
      if (item is Map) {
        _toolContext.add(Map<String, dynamic>.from(item));
      }
    }

    if (_toolContext.length > maxToolContextEntries) {
      _toolContext.removeRange(
        0,
        _toolContext.length - maxToolContextEntries,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isLoading) return;

    await _sendAssistantRequest(
      text: text,
      confirmed: false,
      addUserMessage: true,
    );
  }

  Future<void> _sendAssistantRequest({
    required String text,
    required bool confirmed,
    required bool addUserMessage,
  }) async {
    if (_isLoading) return;

    final conversation = _buildConversationHistory();

    if (!mounted) return;

    setState(() {
      if (addUserMessage) {
        _messages.add(
          _ChatMessage(text: text, isUser: true),
        );
      }

      _isLoading = true;

      if (confirmed) {
        _requiresConfirmation = false;
        _pendingActionMessage = null;
      }
    });

    if (addUserMessage) {
      _messageController.clear();
    }

    _scrollToBottom();

    try {
      final response = await ApiService.sendAssistantMessage(
        text,
        conversation: conversation,
        confirmed: confirmed,
      );

      _updateToolContext(response['tool_context']);

      final assistantMessage =
          _formatAssistantMessage(response['message']);

      final requiresConfirmation =
          response['requires_confirmation'] == true;

      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatMessage(
            text: assistantMessage,
            isUser: false,
          ),
        );

        _isLoading = false;
        _requiresConfirmation = requiresConfirmation;
        _pendingActionMessage =
            requiresConfirmation ? text : null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          const _ChatMessage(
            text:
                "I couldn't connect to WorldCompanion right now. Please try again.",
            isUser: false,
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _confirmAction() async {
    final pendingMessage = _pendingActionMessage;

    if (pendingMessage == null ||
        pendingMessage.trim().isEmpty ||
        _isLoading) {
      return;
    }

    await _sendAssistantRequest(
      text: pendingMessage,
      confirmed: true,
      addUserMessage: false,
    );
  }

  void _cancelAction() {
    if (!mounted) return;

    setState(() {
      _requiresConfirmation = false;
      _pendingActionMessage = null;
    });
  }

  String _formatAssistantMessage(dynamic message) {
    if (message == null) {
      return "I couldn't generate a response.";
    }

    if (message is String) {
      final text = message.trim();
      return text.isEmpty
          ? "I couldn't generate a response."
          : text;
    }

    if (message is Map) {
      final place = message['place']?.toString();
      final category = message['category']?.toString();
      final info = message['info'];

      if (place != null && info is List) {
        final buffer = StringBuffer()..writeln(place);

        if (category != null && category.isNotEmpty) {
          buffer.writeln(category);
        }

        buffer.writeln();

        for (final item in info) {
          if (item is! Map) continue;

          final topic = item['topic']?.toString();
          final content = item['content']?.toString();

          if (topic != null && topic.isNotEmpty) {
            buffer.writeln('**$topic**');
          }

          if (content != null && content.isNotEmpty) {
            buffer.writeln(content);
          }

          buffer.writeln();
        }

        return buffer.toString().trim();
      }

      return jsonEncode(message);
    }

    return message.toString();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chatScrollController.hasClients) return;

      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: WorldCompanionMotion.standard,
        curve: WorldCompanionMotion.standardCurve,
      );
    });
  }

  void _useSuggestion(String text) {
    _messageController
      ..text = text
      ..selection = TextSelection.collapsed(
        offset: text.length,
      );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final panelHeight =
        (size.height * 0.68).clamp(320.0, 560.0).toDouble();

    return Material(
      color: WorldCompanionColors.surface,
      elevation: WorldCompanionElevation.high,
      shadowColor:
          WorldCompanionColors.deepOcean.withOpacity(0.16),
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(
        WorldCompanionRadius.extraLarge,
      ),
      child: SizedBox(
        height: panelHeight,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WorldCompanionSpacing.md,
                WorldCompanionSpacing.sm,
                WorldCompanionSpacing.sm,
                WorldCompanionSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: WorldCompanionColors.infoSurface,
                      borderRadius: BorderRadius.circular(
                        WorldCompanionRadius.medium,
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: WorldCompanionColors.deepOcean,
                      size: 22,
                    ),
                  ),
                  const SizedBox(
                    width: WorldCompanionSpacing.sm,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WorldCompanion',
                          style: WorldCompanionTypography
                              .textTheme.titleMedium
                              ?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Your AI travel companion',
                          style: WorldCompanionTypography
                              .textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close assistant',
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              color: WorldCompanionColors.border,
            ),
            Expanded(
              child: ListView(
                controller: _chatScrollController,
                padding: const EdgeInsets.all(
                  WorldCompanionSpacing.md,
                ),
                children: [
                  if (_messages.isEmpty) ...[
                    Text(
                      'Where would you like to go?',
                      style: WorldCompanionTypography
                          .textTheme.headlineSmall,
                    ),
                    const SizedBox(
                      height: WorldCompanionSpacing.xs,
                    ),
                    Text(
                      'Ask about places, routes, hotels, or your travel plans.',
                      style: WorldCompanionTypography
                          .textTheme.bodyMedium,
                    ),
                    const SizedBox(
                      height: WorldCompanionSpacing.lg,
                    ),
                    Text(
                      'TRY ASKING',
                      style: WorldCompanionTypography
                          .textTheme.labelMedium
                          ?.copyWith(
                        color: WorldCompanionColors.oceanBlue,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(
                      height: WorldCompanionSpacing.sm,
                    ),
                    _SuggestionChip(
                      icon: Icons.spa_outlined,
                      text: 'Find somewhere relaxing',
                      onTap: () => _useSuggestion(
                        'Find somewhere relaxing',
                      ),
                    ),
                    _SuggestionChip(
                      icon: Icons.nightlife_outlined,
                      text: 'Plan my evening',
                      onTap: () => _useSuggestion(
                        'Plan my evening',
                      ),
                    ),
                    _SuggestionChip(
                      icon: Icons.hotel_outlined,
                      text: 'Find hotels',
                      onTap: () => _useSuggestion('Find hotels'),
                    ),
                    _SuggestionChip(
                      icon: Icons.route_outlined,
                      text: 'Plan a route',
                      onTap: () => _useSuggestion('Plan a route'),
                    ),
                  ] else ...[
                    for (final message in _messages)
                      _ChatBubble(message: message),
                    if (_isLoading)
                      const _ChatBubble(
                        message: _ChatMessage(
                          text: 'Thinking...',
                          isUser: false,
                        ),
                      ),
                    if (_requiresConfirmation && !_isLoading)
                      _ConfirmationCard(
                        onConfirm: _confirmAction,
                        onCancel: _cancelAction,
                      ),
                  ],
                ],
              ),
            ),
            const Divider(
              height: 1,
              color: WorldCompanionColors.border,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WorldCompanionSpacing.sm,
                WorldCompanionSpacing.sm,
                WorldCompanionSpacing.sm,
                WorldCompanionSpacing.md,
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Ask WorldCompanion...',
                          prefixIcon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                          ),
                          filled: true,
                          fillColor: WorldCompanionColors.aiSurface,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: WorldCompanionSpacing.md,
                            vertical: WorldCompanionSpacing.sm,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              WorldCompanionRadius.large,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              WorldCompanionRadius.large,
                            ),
                            borderSide: const BorderSide(
                              color: WorldCompanionColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              WorldCompanionRadius.large,
                            ),
                            borderSide: const BorderSide(
                              color: WorldCompanionColors.oceanBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: WorldCompanionSpacing.xs,
                    ),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: FilledButton(
                        onPressed:
                            _isLoading ? null : _sendMessage,
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              WorldCompanionColors.deepOcean,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              WorldCompanionRadius.medium,
                            ),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_upward_rounded,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: WorldCompanionSpacing.sm,
      ),
      padding: const EdgeInsets.all(
        WorldCompanionSpacing.md,
      ),
      decoration: BoxDecoration(
        color: WorldCompanionColors.warningSurface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.large,
        ),
        border: Border.all(
          color: WorldCompanionColors.warning.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                color: WorldCompanionColors.warning,
              ),
              const SizedBox(
                width: WorldCompanionSpacing.xs,
              ),
              Expanded(
                child: Text(
                  'Confirmation required',
                  style:
                      WorldCompanionTypography.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: WorldCompanionSpacing.xs,
          ),
          Text(
            'Please confirm before WorldCompanion completes this action.',
            style: WorldCompanionTypography.textTheme.bodySmall,
          ),
          const SizedBox(
            height: WorldCompanionSpacing.md,
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(
                width: WorldCompanionSpacing.xs,
              ),
              Expanded(
                child: FilledButton(
                  onPressed: onConfirm,
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
  });

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width < 500
              ? double.infinity
              : 320,
        ),
        margin: const EdgeInsets.only(
          bottom: WorldCompanionSpacing.sm,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: WorldCompanionSpacing.md,
          vertical: WorldCompanionSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? WorldCompanionColors.deepOcean
              : WorldCompanionColors.aiSurface,
          borderRadius: BorderRadius.circular(
            WorldCompanionRadius.large,
          ).copyWith(
            bottomRight: isUser
                ? const Radius.circular(
                    WorldCompanionRadius.small,
                  )
                : null,
            bottomLeft: !isUser
                ? const Radius.circular(
                    WorldCompanionRadius.small,
                  )
                : null,
          ),
          border: isUser
              ? null
              : Border.all(
                  color: WorldCompanionColors.border,
                ),
        ),
        child: isUser
            ? Text(
                message.text,
                style: WorldCompanionTypography
                    .textTheme.bodyMedium
                    ?.copyWith(
                  color: Colors.white,
                  height: 1.5,
                ),
              )
            : MarkdownBody(
                data: message.text,
                shrinkWrap: true,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: WorldCompanionTypography
                      .textTheme.bodyMedium
                      ?.copyWith(height: 1.5),
                  strong: WorldCompanionTypography
                      .textTheme.bodyMedium
                      ?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: WorldCompanionColors.deepOcean,
                  ),
                  h1: WorldCompanionTypography
                      .textTheme.headlineSmall,
                  h2: WorldCompanionTypography
                      .textTheme.titleLarge,
                  h3: WorldCompanionTypography
                      .textTheme.titleMedium,
                  listBullet:
                      WorldCompanionTypography.textTheme.bodyMedium,
                  blockSpacing: WorldCompanionSpacing.sm,
                ),
              ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: WorldCompanionSpacing.xs,
      ),
      child: Material(
        color: WorldCompanionColors.surface,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.medium,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            WorldCompanionRadius.medium,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WorldCompanionSpacing.md,
              vertical: WorldCompanionSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.medium,
              ),
              border: Border.all(
                color: WorldCompanionColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: WorldCompanionColors.oceanBlue,
                  size: 19,
                ),
                const SizedBox(
                  width: WorldCompanionSpacing.sm,
                ),
                Expanded(
                  child: Text(
                    text,
                    style: WorldCompanionTypography
                        .textTheme.bodyMedium
                        ?.copyWith(
                      color: WorldCompanionColors.deepOcean,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: WorldCompanionColors.mutedText,
                  size: 13,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
