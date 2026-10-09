import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../services/api_service.dart';
import '../theme/world_companion_colors.dart';
import '../theme/world_companion_typography.dart';
import '../theme/world_companion_spacing.dart';
import '../theme/world_companion_radius.dart';
import '../theme/world_companion_motion.dart';

class CompanionScreen extends StatefulWidget {
  final String? initialMessage;

  const CompanionScreen({
    super.key,
    this.initialMessage,
  });

  @override
  State<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends State<CompanionScreen> {
  final TextEditingController _messageController =
      TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];

  bool _isLoading = false;
  bool _initialMessageSent = false;

  TextTheme get _textTheme => WorldCompanionTypography.textTheme;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final initial = widget.initialMessage?.trim() ?? '';

      if (initial.isNotEmpty && !_initialMessageSent) {
        _initialMessageSent = true;
        _sendMessage(initial);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? suggestedMessage]) async {
    final message =
        (suggestedMessage ?? _messageController.text).trim();

    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          text: message,
          isUser: true,
        ),
      );

      _isLoading = true;
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      final response =
          await ApiService.sendAssistantMessage(message);

      if (!mounted) return;

      final reply = (
        response['response'] ??
        response['reply'] ??
        response['message'] ??
        response['answer'] ??
        'I received your message, but no reply was returned.'
      ).toString();

      setState(() {
        _messages.add(
          _ChatMessage(
            text: reply,
            isUser: false,
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          const _ChatMessage(
            text:
                'I couldn’t connect right now. Please check your connection and try again.',
            isUser: false,
            isError: true,
          ),
        );
      });

      debugPrint('Companion message error: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: WorldCompanionMotion.standard,
        curve: WorldCompanionMotion.standardCurve,
      );
    });
  }

  void _selectSuggestion(String suggestion) {
    _sendMessage(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorldCompanionColors.softWhite,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: WorldCompanionColors.deepOcean,
                borderRadius: BorderRadius.circular(
                  WorldCompanionRadius.medium,
                ),
              ),
              child: const Icon(
                Icons.explore_rounded,
                color: WorldCompanionColors.surface,
                size: 24,
              ),
            ),
            const SizedBox(width: WorldCompanionSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WorldCompanion',
                  style: WorldCompanionTypography.brand,
                ),
                const SizedBox(height: WorldCompanionSpacing.xxs),
                Text(
                  'YOUR TRAVEL COMPANION',
                  style: _textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(
              right: WorldCompanionSpacing.md,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: WorldCompanionSpacing.sm,
              vertical: WorldCompanionSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: WorldCompanionColors.successSurface,
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.pill,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 7,
                  color: WorldCompanionColors.success,
                ),
                SizedBox(width: WorldCompanionSpacing.xs),
                Text(
                  'READY',
                  style: TextStyle(
                    color: WorldCompanionColors.success,
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildWelcomeScreen()
                  : _buildConversation(),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        WorldCompanionSpacing.mobilePage,
        WorldCompanionSpacing.lg,
        WorldCompanionSpacing.mobilePage,
        WorldCompanionSpacing.lg,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(
            WorldCompanionSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: WorldCompanionColors.deepOcean,
            borderRadius: BorderRadius.circular(
              WorldCompanionRadius.extraLarge,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                top: -12,
                child: Icon(
                  Icons.travel_explore_rounded,
                  size: 118,
                  color: WorldCompanionColors.surface.withOpacity(0.07),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: WorldCompanionSpacing.sm,
                      vertical: WorldCompanionSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: WorldCompanionColors.surface.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(
                        WorldCompanionRadius.pill,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: WorldCompanionColors.softBlue,
                        ),
                        SizedBox(width: WorldCompanionSpacing.xs),
                        Text(
                          'YOUR JOURNEY STARTS HERE',
                          style: TextStyle(
                            color: WorldCompanionColors.surface,
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: WorldCompanionSpacing.lg),
                  Text(
                    'Where will\nyou go next?',
                    style: _textTheme.displayMedium?.copyWith(
                      color: WorldCompanionColors.surface,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: WorldCompanionSpacing.sm),
                  Text(
                    'Discover places, plan routes and make every journey count.',
                    style: _textTheme.bodyMedium?.copyWith(
                      color: WorldCompanionColors.surface.withOpacity(0.86),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: WorldCompanionSpacing.lg),
                  Container(
                    height: 3,
                    width: 54,
                    decoration: BoxDecoration(
                      color: WorldCompanionColors.softBlue,
                      borderRadius: BorderRadius.circular(
                        WorldCompanionRadius.pill,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: WorldCompanionSpacing.xl),
        Text(
          'WHAT CAN I HELP YOU WITH?',
          style: _textTheme.labelMedium?.copyWith(
            color: WorldCompanionColors.mutedText,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: WorldCompanionSpacing.sm),
        _buildSuggestion(
          icon: Icons.map_outlined,
          title: 'Plan a trip',
          description: 'Build an itinerary for your next adventure.',
          color: WorldCompanionColors.oceanBlue,
          background: WorldCompanionColors.infoSurface,
          onTap: () => _selectSuggestion('Help me plan a trip.'),
        ),
        const SizedBox(height: WorldCompanionSpacing.sm),
        _buildSuggestion(
          icon: Icons.place_outlined,
          title: 'Discover places',
          description: 'Find interesting places to explore.',
          color: WorldCompanionColors.oceanBlue,
          background: WorldCompanionColors.aiSurface,
          onTap: () =>
              _selectSuggestion('Help me discover interesting places.'),
        ),
        const SizedBox(height: WorldCompanionSpacing.sm),
        _buildSuggestion(
          icon: Icons.route_rounded,
          title: 'Find a route',
          description: 'Get help planning your journey.',
          color: WorldCompanionColors.deepOcean,
          background: WorldCompanionColors.mapSurface,
          onTap: () => _selectSuggestion('Help me plan a route.'),
        ),
        const SizedBox(height: WorldCompanionSpacing.lg),
        Center(
          child: Text(
            'YOUR WORLD. YOUR WAY.',
            style: _textTheme.labelSmall?.copyWith(
              color: WorldCompanionColors.mutedText,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestion({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: WorldCompanionColors.surface,
      borderRadius: BorderRadius.circular(
        WorldCompanionRadius.large,
      ),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(
          WorldCompanionRadius.large,
        ),
        child: Container(
          padding: const EdgeInsets.all(
            WorldCompanionSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              WorldCompanionRadius.large,
            ),
            border: Border.all(
              color: WorldCompanionColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(
                    WorldCompanionRadius.medium,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _textTheme.titleSmall?.copyWith(
                        color: WorldCompanionColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: WorldCompanionSpacing.xxs),
                    Text(
                      description,
                      style: _textTheme.bodySmall?.copyWith(
                        color: WorldCompanionColors.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: WorldCompanionSpacing.xs),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: WorldCompanionColors.oceanBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversation() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        WorldCompanionSpacing.md,
        WorldCompanionSpacing.lg,
        WorldCompanionSpacing.md,
        WorldCompanionSpacing.lg,
      ),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _messages.length) {
          return _buildTypingIndicator();
        }

        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.only(
            bottom: WorldCompanionSpacing.md,
            left: WorldCompanionSpacing.xxl,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: WorldCompanionSpacing.md,
            vertical: WorldCompanionSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: WorldCompanionColors.deepOcean,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(WorldCompanionRadius.large),
              topRight: Radius.circular(WorldCompanionRadius.large),
              bottomLeft: Radius.circular(WorldCompanionRadius.large),
              bottomRight: Radius.circular(WorldCompanionRadius.small),
            ),
            boxShadow: [
              BoxShadow(
                color: WorldCompanionColors.deepOcean.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: _textTheme.bodyMedium?.copyWith(
              color: WorldCompanionColors.surface,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    final iconColor = message.isError
        ? WorldCompanionColors.error
        : WorldCompanionColors.oceanBlue;

    final iconBackground = message.isError
        ? WorldCompanionColors.errorSurface
        : WorldCompanionColors.aiSurface;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: WorldCompanionSpacing.md,
        right: WorldCompanionSpacing.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.medium,
              ),
            ),
            child: Icon(
              message.isError
                  ? Icons.info_outline_rounded
                  : Icons.explore_rounded,
              color: iconColor,
              size: 19,
            ),
          ),
          const SizedBox(width: WorldCompanionSpacing.sm),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(
                WorldCompanionSpacing.md,
              ),
              decoration: BoxDecoration(
                color: WorldCompanionColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(WorldCompanionRadius.small),
                  topRight: Radius.circular(WorldCompanionRadius.large),
                  bottomLeft: Radius.circular(WorldCompanionRadius.large),
                  bottomRight: Radius.circular(WorldCompanionRadius.large),
                ),
                border: Border.all(
                  color: message.isError
                      ? WorldCompanionColors.error.withOpacity(0.25)
                      : WorldCompanionColors.border,
                ),
              ),
              child: MarkdownBody(
                data: message.text,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: _textTheme.bodyMedium?.copyWith(
                    color: WorldCompanionColors.primaryText,
                    height: 1.65,
                  ),
                  h1: _textTheme.headlineMedium?.copyWith(
                    color: WorldCompanionColors.deepOcean,
                  ),
                  h2: _textTheme.headlineSmall?.copyWith(
                    color: WorldCompanionColors.deepOcean,
                  ),
                  h3: _textTheme.titleLarge?.copyWith(
                    color: WorldCompanionColors.deepOcean,
                  ),
                  strong: _textTheme.titleSmall?.copyWith(
                    color: WorldCompanionColors.deepOcean,
                    fontWeight: FontWeight.w800,
                  ),
                  em: _textTheme.bodyMedium?.copyWith(
                    color: WorldCompanionColors.primaryText,
                    fontStyle: FontStyle.italic,
                  ),
                  listBullet: _textTheme.bodyMedium?.copyWith(
                    color: WorldCompanionColors.oceanBlue,
                  ),
                  code: _textTheme.bodySmall?.copyWith(
                    color: WorldCompanionColors.deepOcean,
                    backgroundColor: WorldCompanionColors.mapSurface,
                  ),
                  blockquote: _textTheme.bodySmall?.copyWith(
                    color: WorldCompanionColors.secondaryText,
                    height: 1.5,
                  ),
                  a: _textTheme.bodyMedium?.copyWith(
                    color: WorldCompanionColors.oceanBlue,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: WorldCompanionSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: WorldCompanionColors.aiSurface,
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.medium,
              ),
            ),
            child: const Icon(
              Icons.explore_rounded,
              color: WorldCompanionColors.oceanBlue,
              size: 19,
            ),
          ),
          const SizedBox(width: WorldCompanionSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: WorldCompanionSpacing.md,
              vertical: WorldCompanionSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: WorldCompanionColors.surface,
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.large,
              ),
              border: Border.all(
                color: WorldCompanionColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: WorldCompanionColors.oceanBlue,
                  ),
                ),
                const SizedBox(width: WorldCompanionSpacing.sm),
                Text(
                  'Planning your answer...',
                  style: _textTheme.labelMedium?.copyWith(
                    color: WorldCompanionColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        WorldCompanionSpacing.md,
        WorldCompanionSpacing.sm,
        WorldCompanionSpacing.md,
        WorldCompanionSpacing.md,
      ),
      decoration: BoxDecoration(
        color: WorldCompanionColors.surface,
        border: const Border(
          top: BorderSide(
            color: WorldCompanionColors.border,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: WorldCompanionColors.deepOcean.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: WorldCompanionColors.aiSurface,
                borderRadius: BorderRadius.circular(
                  WorldCompanionRadius.extraLarge,
                ),
                border: Border.all(
                  color: WorldCompanionColors.border,
                ),
              ),
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask your travel companion...',
                  hintStyle: _textTheme.bodyMedium?.copyWith(
                    color: WorldCompanionColors.mutedText,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: WorldCompanionSpacing.md,
                    vertical: WorldCompanionSpacing.sm,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: WorldCompanionSpacing.sm),
          Material(
            color: _isLoading
                ? WorldCompanionColors.softBlue
                : WorldCompanionColors.deepOcean,
            borderRadius: BorderRadius.circular(
              WorldCompanionRadius.large,
            ),
            child: InkWell(
              onTap: _isLoading ? null : () => _sendMessage(),
              borderRadius: BorderRadius.circular(
                WorldCompanionRadius.large,
              ),
              child: SizedBox(
                width: 49,
                height: 49,
                child: Icon(
                  _isLoading
                      ? Icons.hourglass_top_rounded
                      : Icons.arrow_upward_rounded,
                  color: WorldCompanionColors.surface,
                  size: 23,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
}
