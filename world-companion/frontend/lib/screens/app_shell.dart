import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../services/api_service.dart';
import 'home_screen.dart';
import 'explore_screens.dart';
import 'trip_screen.dart';
import 'stays_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  bool _isAiOpen = false;

  static const Color primary = Color(0xFF0E7774);
  static const Color deep = Color(0xFF123B43);
  static const Color aqua = Color(0xFFDFF4F1);
  static const Color surface = Color(0xFFFFFFFF);

  final List<Widget> _screens = const [
    HomeScreen(),
    ExploreScreen(),
    TripsScreen(),
    StaysScreen(),
    ProfileScreen(),
  ];

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) {
      return;
    }

    setState(() {
      _selectedIndex = index;
      _isAiOpen = false;
    });
  }

  void _toggleAiAssistant() {
    setState(() {
      _isAiOpen = !_isAiOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),

          if (_isAiOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isAiOpen = false;
                  });
                },
                child: Container(
                  color: Colors.black.withOpacity(0.12),
                ),
              ),
            ),

          if (_isAiOpen)
            const Positioned(
              left: 16,
              right: 16,
              bottom: 76,
              child: _AiAssistantPanel(),
            ),

          Positioned(
            right: 18,
            bottom: 12,
            child: _AiFloatingButton(
              isOpen: _isAiOpen,
              onTap: _toggleAiAssistant,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        backgroundColor: surface,
        elevation: 0,
        height: 72,
        indicatorColor: aqua,
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
              color: deep,
            ),
            selectedIcon: Icon(
              Icons.home_rounded,
              color: primary,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.explore_outlined,
              color: deep,
            ),
            selectedIcon: Icon(
              Icons.explore_rounded,
              color: primary,
            ),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.map_outlined,
              color: deep,
            ),
            selectedIcon: Icon(
              Icons.map_rounded,
              color: primary,
            ),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.hotel_outlined,
              color: deep,
            ),
            selectedIcon: Icon(
              Icons.hotel_rounded,
              color: primary,
            ),
            label: 'Stay',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.person_outline_rounded,
              color: deep,
            ),
            selectedIcon: Icon(
              Icons.person_rounded,
              color: primary,
            ),
            label: 'Profile',
          ),
        ],
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

  static const Color primary = Color(0xFF0E7774);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
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
    );
  }
}

class _AiAssistantPanel extends StatefulWidget {
  const _AiAssistantPanel();

  @override
  State<_AiAssistantPanel> createState() =>
      _AiAssistantPanelState();
}

class _AiAssistantPanelState extends State<_AiAssistantPanel> {
  static const Color primary = Color(0xFF0E7774);
  static const Color deep = Color(0xFF123B43);
  static const Color aqua = Color(0xFFDFF4F1);
  static const Color background = Color(0xFFF7F9F8);
  static const Color muted = Color(0xFF68777B);
  static const Color line = Color(0xFFDCE5E4);

  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _chatScrollController =
      ScrollController();

  final List<_ChatMessage> _messages = [];

  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isLoading) {
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isUser: true,
        ),
      );

      _isLoading = true;
    });

    _messageController.clear();

    _scrollToBottom();

    try {
      final response =
          await ApiService.sendAssistantMessage(text);

      final assistantMessage =
          _formatAssistantMessage(response["message"]);

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          _ChatMessage(
            text: assistantMessage,
            isUser: false,
          ),
        );

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          const _ChatMessage(
            text:
                "I couldn't connect to WorldCompanion right now.",
            isUser: false,
          ),
        );

        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  String _formatAssistantMessage(dynamic message) {
    if (message == null) {
      return "I couldn't generate a response.";
    }

    if (message is String) {
      return message;
    }

    if (message is Map) {
      final place = message["place"]?.toString();
      final category = message["category"]?.toString();
      final info = message["info"];

      if (place != null && info is List) {
        final buffer = StringBuffer();

        buffer.writeln(place);

        if (category != null && category.isNotEmpty) {
          buffer.writeln(category);
        }

        buffer.writeln();

        for (final item in info) {
          if (item is Map) {
            final topic = item["topic"]?.toString();
            final content = item["content"]?.toString();

            if (topic != null && topic.isNotEmpty) {
              buffer.writeln(topic);
            }

            if (content != null && content.isNotEmpty) {
              buffer.writeln(content);
            }

            buffer.writeln();
          }
        }

        return buffer.toString().trim();
      }

      return message.toString();
    }

    return message.toString();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScrollController.hasClients) {
        return;
      }

      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _useSuggestion(String text) {
    _messageController.text = text;

    _messageController.selection =
        TextSelection.fromPosition(
      TextPosition(
        offset: _messageController.text.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 470,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: line,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                16,
                18,
                14,
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: aqua,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WorldCompanion',
                          style: TextStyle(
                            color: deep,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Your AI travel companion',
                          style: TextStyle(
                            color: muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              height: 1,
              color: line,
            ),

            Expanded(
              child: ListView(
                controller: _chatScrollController,
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  12,
                ),
                children: [
                  if (_messages.isEmpty) ...[
                    const Text(
                      'How can I help with your trip?',
                      style: TextStyle(
                        color: deep,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Ask me about places, routes, hotels, '
                      'recommendations, or your trips.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Try asking',
                      style: TextStyle(
                        color: deep,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 9),

                    _SuggestionChip(
                      icon: Icons.spa_outlined,
                      text: 'Find somewhere relaxing',
                      onTap: () {
                        _useSuggestion(
                          'Find somewhere relaxing',
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    _SuggestionChip(
                      icon: Icons.nightlife_outlined,
                      text: 'Plan my evening',
                      onTap: () {
                        _useSuggestion(
                          'Plan my evening',
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    _SuggestionChip(
                      icon: Icons.hotel_outlined,
                      text: 'Find hotels',
                      onTap: () {
                        _useSuggestion(
                          'Find hotels',
                        );
                      },
                    ),

                    const SizedBox(height: 8),

                    _SuggestionChip(
                      icon: Icons.route_outlined,
                      text: 'Plan a route',
                      onTap: () {
                        _useSuggestion(
                          'Plan a route',
                        );
                      },
                    ),
                  ] else ...[
                    for (final message in _messages)
                      _ChatBubble(
                        message: message,
                      ),

                    if (_isLoading)
                      const _ChatBubble(
                        message: _ChatMessage(
                          text: 'Thinking...',
                          isUser: false,
                        ),
                      ),
                  ],
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                12,
              ),
              decoration: const BoxDecoration(
                color: background,
                border: Border(
                  top: BorderSide(
                    color: line,
                    width: 1,
                  ),
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(26),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction:
                            TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText:
                              'Ask WorldCompanion...',
                          hintStyle: const TextStyle(
                            color: muted,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          prefixIcon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: muted,
                            size: 19,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(17),
                            borderSide:
                                const BorderSide(
                              color: line,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(17),
                            borderSide:
                                const BorderSide(
                              color: line,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(17),
                            borderSide:
                                const BorderSide(
                              color: primary,
                              width: 1.3,
                            ),
                          ),
                        ),
                        onSubmitted: (_) {
                          _sendMessage();
                        },
                      ),
                    ),
                    const SizedBox(width: 7),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : _sendMessage,
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 180),
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _isLoading
                              ? primary.withOpacity(0.55)
                              : primary,
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 21,
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

  static const Color primary = Color(0xFF0E7774);
  static const Color deep = Color(0xFF123B43);
  static const Color line = Color(0xFFDCE5E4);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 270,
        ),
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? primary
              : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: message.isUser
              ? null
              : Border.all(
                  color: line,
                ),
        ),
        child: message.isUser
            ? Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                ),
              )
            : MarkdownBody(
                data: message.text,
                shrinkWrap: true,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(
                    color: deep,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  strong: const TextStyle(
                    color: deep,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                  em: const TextStyle(
                    color: deep,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                  h1: const TextStyle(
                    color: deep,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                  h2: const TextStyle(
                    color: deep,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  h3: const TextStyle(
                    color: deep,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                  listBullet: const TextStyle(
                    color: deep,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  listBulletPadding: const EdgeInsets.only(
                    right: 6,
                  ),
                  tableHead: const TextStyle(
                    color: deep,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  tableBody: const TextStyle(
                    color: deep,
                    fontSize: 11,
                    height: 1.35,
                  ),
                  tableBorder: TableBorder.all(
                    color: line,
                    width: 0.7,
                  ),
                  tableHeadAlign: TextAlign.left,
                  blockSpacing: 8,
                  listIndent: 16,
                  horizontalRuleDecoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: line,
                      ),
                    ),
                  ),
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

  static const Color primary = Color(0xFF0E7774);
  static const Color deep = Color(0xFF123B43);
  static const Color line = Color(0xFFDCE5E4);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: line,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: primary,
                size: 19,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: deep,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: deep,
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }
}