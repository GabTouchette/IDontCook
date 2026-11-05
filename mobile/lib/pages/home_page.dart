import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/block/block.dart';
import 'package:i_cant_cook/models/home_module/module_payloads.dart';
import 'package:i_cant_cook/models/mood/mood.dart';
import 'package:i_cant_cook/providers/chat_provider.dart';
import 'package:i_cant_cook/providers/home_feed_provider.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/widgets/blocks/block_registry.dart';
import 'package:i_cant_cook/widgets/blocks/block_styles.dart';
import 'package:i_cant_cook/widgets/blocks/text_block_bubble.dart';
import 'package:i_cant_cook/widgets/toasts/information_toast.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late TextEditingController _messageController;
  late ScrollController _scrollController;

  /// The mood whose conversation is currently open (null = the home feed is
  /// showing). Set the instant a pill is tapped so it highlights immediately
  /// and drives the header↔conversation cross-fade. Reset to null on "back to
  /// home". Local to the page: a conversation persisted in [ChatProvider]
  /// across tab revisits still shows, just without a highlighted pill.
  Mood? _activeMood;

  /// Whether the message list is scrolled near its bottom. Drives the
  /// visibility of the "scroll to latest" affordance.
  bool _isNearBottom = true;

  /// Set when new content arrives while the user is scrolled away from the
  /// bottom (mood switch, refresh, or a streaming reply) — cleared once
  /// they return to the bottom.
  bool _hasNewContent = false;

  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController()..addListener(_handleScroll);

    // Load the home feed (rendered directly as the header + home body — the
    // chat thread stays empty until a mood is picked or the user types).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHome();
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions) {
      return;
    }
    final position = _scrollController.position;
    final distanceFromBottom = position.maxScrollExtent - position.pixels;
    final nearBottom = distanceFromBottom < 100;
    if (nearBottom != _isNearBottom) {
      setState(() {
        _isNearBottom = nearBottom;
        if (nearBottom) _hasNewContent = false;
      });
    }
  }

  Future<void> _initializeHome() async {
    final homeFeedProvider = context.read<HomeFeedProvider>();
    // The dashboard recreates HomePage's State on every tab revisit, but the
    // feed is cached on the (long-lived) provider.
    //
    //  - First visit (no feed yet): load and show the spinner.
    //  - Revisit while the feed is still fresh: keep it (no network churn).
    //  - Revisit after the freshness window: silently refresh in the
    //    background — the old feed stays on screen until the reshuffled one
    //    arrives, so Home feels alive without a spinner flash.
    //
    // Skip the background refresh while a mood conversation is open so we don't
    // swap the feed out from under an active thread.
    if (homeFeedProvider.feed == null) {
      await homeFeedProvider.loadFeed();
      return;
    }
    final inConversation = context.read<ChatProvider>().v2Messages.isNotEmpty;
    if (!inConversation && homeFeedProvider.isStale) {
      // Fire-and-forget: keeps the current feed visible during the refetch.
      unawaited(homeFeedProvider.refresh());
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (_scrollController.hasClients &&
          _scrollController.position.hasContentDimensions) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Handles a chat prompt tap: sends the prompt text as a user message.
  void _handleChatPromptTap(String promptText) {
    HapticService.lightImpact();
    _messageController.text = promptText;
    _sendMessage();
  }

  /// Handles a mood-pill tap. The pill becomes a conversation starter:
  ///
  ///  - Tapping the mood that's already open toggles back to the home feed.
  ///  - Otherwise the current conversation (if any) is cleared and a fresh one
  ///    starts from scratch — so switching moods never mixes suggestions from
  ///    two different intents. The kick-off prompt is sent *hidden*, so the
  ///    thread reads as the assistant simply opening the topic rather than the
  ///    user "saying" a line they never typed.
  ///
  /// [ChatProvider.resetV2Conversation] invalidates any in-flight stream, so
  /// switching moods mid-reply is safe.
  void _handleMoodSelected(Mood mood) {
    HapticService.lightImpact();

    // Tapping the already-open mood again → back to the home feed.
    if (_activeMood == mood) {
      _handleBackToHome();
      return;
    }

    final chatProvider = context.read<ChatProvider>();
    final homeFeedProvider = context.read<HomeFeedProvider>();
    final feedPayload = homeFeedProvider.feed?.toJson();

    chatProvider.resetV2Conversation();
    setState(() => _activeMood = mood);

    chatProvider.sendMessageV2(
      message: _moodPrompt(mood),
      chatContext: 'home',
      mood: mood,
      homeFeed: feedPayload,
      hideUserMessage: true,
      onError: (errorMessage) {
        if (!mounted) return;
        InformationToast.error(context, errorMessage);
      },
    );

    _scrollToBottom();
  }

  /// Returns to the main home feed: clears the conversation (which also
  /// cancels any in-flight stream) and drops the active-mood highlight. The
  /// body cross-fades back to the feed via the [AnimatedSwitcher] in [build].
  void _handleBackToHome() {
    HapticService.lightImpact();
    context.read<ChatProvider>().resetV2Conversation();
    setState(() {
      _activeMood = null;
      _hasNewContent = false;
    });
  }

  /// Natural-language prompt sent on a mood tap — reads as if the user typed
  /// their intent. The structured [Mood] is also sent alongside (see
  /// [ChatProvider.sendMessageV2]) so the backend has both signals.
  static String _moodPrompt(Mood mood) {
    switch (mood) {
      case Mood.rushed:
        return "I'm short on time tonight — suggest a few quick recipes I could make.";
      case Mood.ambitious:
        return "I'm feeling ambitious — suggest a few recipes worth the effort.";
      case Mood.cookingForSomeone:
        return "I'm cooking for someone tonight — suggest a few recipes that would impress.";
      case Mood.comfort:
        return "I want something comforting — suggest a few cozy recipes.";
      case Mood.healthy:
        return "I want to eat healthy — suggest a few nutritious recipes.";
      case Mood.surpriseMe:
        return "Surprise me — suggest a few recipes I might not expect.";
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty || context.read<ChatProvider>().isV2Sending) return;

    HapticService.mediumImpact();
    _messageController.clear();

    final chatProvider = context.read<ChatProvider>();
    final homeFeedProvider = context.read<HomeFeedProvider>();
    final feed = homeFeedProvider.feed;

    // Send the message; include homeFeed only on the first user message
    final isFirstUserMessage =
        chatProvider.v2Messages.length == 1 && chatProvider.v2Messages[0].sender == 'ai';
    final feedPayload = isFirstUserMessage ? feed?.toJson() : null;

    chatProvider.sendMessageV2(
      message: message,
      chatContext: 'home',
      // The active pill is the live mood selection; fall back to the
      // provider's mood for any legacy path.
      mood: _activeMood ?? homeFeedProvider.currentMood,
      homeFeed: feedPayload,
      onError: (errorMessage) {
        InformationToast.error(context, errorMessage);
      },
    );

    _scrollToBottom();
  }

  /// Pull-to-refresh on the home feed. Only meaningful in feed mode (the
  /// [RefreshIndicator] only wraps the feed view), so it just re-fetches.
  Future<void> _handleRefresh() async {
    await context.read<HomeFeedProvider>().refresh();
  }

  void _scrollToLatest() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    setState(() => _hasNewContent = false);
  }

  /// Stable per-block key derived from the block's own content (module id
  /// when available, otherwise a content hash) plus its position. Freezed
  /// generates value-based `==`/`hashCode` for [Block], so identical content
  /// keeps the same key (no needless remount) while changed/replaced content
  /// — a mood switch or a pull-to-refresh swapping message 0's blocks — gets
  /// a fresh key. `ListView.builder`/`Column` otherwise reuse the same
  /// widget identity on a data-only rebuild, which is why the per-block
  /// `.animate().fadeIn()` wasn't replaying after those swaps.
  Key _blockKey(Block block, int index) => ValueKey('$index-${block.hashCode}');

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeFeedProvider, ChatProvider>(
      builder: (context, homeFeedProvider, chatProvider, _) {
        final inConversation = chatProvider.v2Messages.isNotEmpty;

        // Track message-count growth to know when new content arrived while
        // the user was scrolled away from the bottom — drives the "scroll to
        // latest" affordance. Plain field mutation (no setState) is safe: this
        // build is already running because Consumer2 is reacting to the
        // provider's own notifyListeners.
        final messageCount = chatProvider.v2Messages.length;
        if (messageCount > _lastMessageCount && !_isNearBottom) {
          _hasNewContent = true;
        }
        _lastMessageCount = messageCount;

        final showScrollToLatest = inConversation &&
            !_isNearBottom &&
            (chatProvider.isV2Sending || _hasNewContent);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: Text(
              'HOME',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: 2.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          body: Column(
            children: [
              // Fixed header: greeting + quick-pills. Persists across the
              // feed↔conversation switch so only the section beneath it
              // changes (no full-page swap).
              _buildHeader(context, homeFeedProvider, inConversation),
              // Body cross-fades between the home feed and the mood
              // conversation.
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: inConversation
                      ? _buildConversationView(
                          context,
                          chatProvider,
                          showScrollToLatest: showScrollToLatest,
                          key: const ValueKey('conversation'),
                        )
                      : _buildHomeFeedView(
                          context,
                          homeFeedProvider,
                          key: const ValueKey('home'),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildInputBar(context, chatProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The pinned top section — only present while a mood conversation is open.
  /// It carries the "Back to home" control plus the mood pills, so the user
  /// can switch moods (or bail out) mid-thread without scrolling.
  ///
  /// On the home feed itself there is no pinned header: the greeting and the
  /// mood pills are the first items inside the feed's own scroll view (see
  /// [_buildHomeFeedView]), so they scroll away with the rest of the page.
  Widget _buildHeader(
    BuildContext context,
    HomeFeedProvider homeFeedProvider,
    bool inConversation,
  ) {
    if (!inConversation) return const SizedBox.shrink();

    final feed = homeFeedProvider.feed;
    if (feed == null) return const SizedBox.shrink();

    // The mood-question module carries the pills; render it via the registry
    // so it stays a single source of truth (icons, colors, marquee).
    final moodBlock = _findMoodBlock(feed.renderableBlocks);

    final callbacks = BlockCallbacks(
      onChatPromptTap: _handleChatPromptTap,
      onMoodSelected: _handleMoodSelected,
      selectedMood: _activeMood,
    );

    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: onSurface.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _BackToHomeButton(onTap: _handleBackToHome),
          if (moodBlock != null) ...[
            const SizedBox(height: 14),
            BlockRegistry.build(context, moodBlock, callbacks: callbacks),
          ],
        ],
      ),
    );
  }

  /// The first `MoodQuestionPayload` module in [blocks], or null.
  Block? _findMoodBlock(List<Block> blocks) {
    for (final block in blocks) {
      if (block is ModuleBlock && block.module.payload is MoodQuestionPayload) {
        return block;
      }
    }
    return null;
  }

  /// The home feed body: the ranked module cards (everything except the
  /// greeting text and the mood pills, which live in the pinned header).
  Widget _buildHomeFeedView(
    BuildContext context,
    HomeFeedProvider homeFeedProvider, {
    Key? key,
  }) {
    final feed = homeFeedProvider.feed;
    if (feed == null) {
      return Center(
        key: key,
        child: homeFeedProvider.isLoading
            ? const CircularProgressIndicator()
            : const SizedBox.shrink(),
      );
    }

    // Pull out the greeting text and the mood-question module — they lead the
    // scroll (avatar + greeting, then the mood pills) rather than sitting in a
    // pinned header, so they scroll away with the modules beneath them.
    String greeting = feed.greeting;
    var capturedGreeting = false;
    final modules = <Block>[];
    for (final block in feed.renderableBlocks) {
      if (!capturedGreeting && block is TextBlock) {
        greeting = block.text;
        capturedGreeting = true;
        continue;
      }
      if (block is ModuleBlock && block.module.payload is MoodQuestionPayload) {
        continue;
      }
      modules.add(block);
    }
    final moodBlock = _findMoodBlock(feed.renderableBlocks);

    final callbacks = BlockCallbacks(
      onChatPromptTap: _handleChatPromptTap,
      onMoodSelected: _handleMoodSelected,
      selectedMood: _activeMood,
    );

    final onSurface = Theme.of(context).colorScheme.onSurface;

    return RefreshIndicator(
      key: key,
      onRefresh: _handleRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        children: [
          // Greeting (assistant avatar + comment) — now part of the scroll.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AssistantAvatar(),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  greeting,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: onSurface,
                  ),
                ),
              ),
            ],
          ),
          if (moodBlock != null) ...[
            const SizedBox(height: 14),
            BlockRegistry.build(context, moodBlock, callbacks: callbacks),
          ],
          // Divider echoing the old pinned-header seam, so the lead-in still
          // reads as distinct from the ranked modules below it.
          Container(
            margin: const EdgeInsets.fromLTRB(0, 16, 0, 4),
            height: 1,
            color: onSurface.withValues(alpha: 0.08),
          ),
          for (var index = 0; index < modules.length; index++)
            Padding(
              key: _blockKey(modules[index], index),
              padding: EdgeInsets.only(
                bottom: index == modules.length - 1 ? 0 : kBlockFeedGap,
              ),
              child: BlockRegistry.build(context, modules[index],
                      callbacks: callbacks)
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.06, curve: Curves.easeOut, duration: 300.ms),
            ),
        ],
      ),
    );
  }

  /// The mood conversation body: the assistant's streamed turns (and any typed
  /// follow-ups). Hidden turns — the synthetic mood kick-off prompt — are
  /// filtered out so the thread reads as the assistant opening the topic.
  Widget _buildConversationView(
    BuildContext context,
    ChatProvider chatProvider, {
    required bool showScrollToLatest,
    Key? key,
  }) {
    final visible = [
      for (final m in chatProvider.v2Messages)
        if (!m.hidden) m,
    ];

    return Stack(
      key: key,
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final message = visible[index];
            return Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 10.0),
              child: message.isUser
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: _buildUserMessageBubble(message),
                    )
                  : _buildAssistantMessage(context, message),
            );
          },
        ),
        if (showScrollToLatest)
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Center(
              child: _ScrollToLatestPill(
                isSending: chatProvider.isV2Sending,
                onTap: _scrollToLatest,
              ),
            ),
          ),
      ],
    );
  }

  /// Builds an assistant turn in the conversation: the avatar beside the
  /// leading text, then the reply's remaining blocks (recipe cards, etc.) at
  /// full width. Each block is keyed by its own content ([_blockKey]) so its
  /// fade+slide entrance replays when new streamed content swaps in.
  Widget _buildAssistantMessage(BuildContext context, ChatV2Message message) {
    // The avatar marks "the agent is speaking" and sits only beside the
    // leading text — it must NOT indent the module/recipe cards below it,
    // which span the full row width like the rest of the page.
    if (message.isLoading) {
      final activityLabel = context.watch<ChatProvider>().v2ActivityLabel;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AssistantAvatar(),
          const SizedBox(width: 10),
          Expanded(child: _TypingIndicator(activityLabel: activityLabel)),
        ],
      );
    }

    final callbacks = BlockCallbacks(
      onChatPromptTap: _handleChatPromptTap,
      onMoodSelected: _handleMoodSelected,
      selectedMood: _activeMood,
    );
    final blocks = message.blocks;

    final hasLeadingText = blocks.isNotEmpty && blocks[0] is TextBlock;
    final restStart = hasLeadingText ? 1 : 0;

    Widget animated(Widget child) =>
        child.animate().fadeIn(duration: 300.ms).slideY(
              begin: 0.08,
              curve: Curves.easeOut,
              duration: 300.ms,
            );

    final leadingText = hasLeadingText
        ? animated(
            TextBlockBubble(
              key: _blockKey(blocks[0], 0),
              text: (blocks[0] as TextBlock).text,
            ),
          )
        : const SizedBox.shrink();

    final trailing = blocks.sublist(restStart);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(
              bottom: trailing.isNotEmpty ? kBlockFeedGap : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AssistantAvatar(),
              const SizedBox(width: 10),
              Expanded(child: leadingText),
            ],
          ),
        ),
        for (var i = 0; i < trailing.length; i++)
          Padding(
            key: _blockKey(trailing[i], restStart + i),
            padding: EdgeInsets.only(
              bottom: i == trailing.length - 1 ? 0 : kBlockFeedGap,
            ),
            child: animated(
              BlockRegistry.build(context, trailing[i], callbacks: callbacks),
            ),
          ),
      ],
    );
  }

  /// Builds a user message bubble (simple text).
  Widget _buildUserMessageBubble(ChatV2Message message) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        message.plainText,
        style: GoogleFonts.spaceGrotesk(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(
          begin: 0.15,
          curve: Curves.easeOut,
          duration: 200.ms,
        );
  }

  /// Builds the input bar: text field + send button.
  Widget _buildInputBar(BuildContext context, ChatProvider chatProvider) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color:
                      Theme.of(context).colorScheme.outline.withAlpha((0.25 * 255).toInt()),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.spaceGrotesk(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ask or suggest something…',
                        hintStyle: GoogleFonts.spaceGrotesk(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha((0.35 * 255).toInt()),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 14.0, horizontal: 16.0),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _messageController,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return GestureDetector(
                        onTap: () {
                          HapticService.lightImpact();
                          _messageController.clear();
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          color: Colors.transparent,
                          child: Icon(
                            Icons.close,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha((0.45 * 255).toInt()),
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      color: Theme.of(context).colorScheme.onSurface,
                      child: Icon(
                        Icons.arrow_forward,
                        color: Theme.of(context).colorScheme.surface,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small, stable avatar marking every assistant turn — a permanent "this
/// is the agent" cue, independent of content or time of day (replacing the
/// old per-text-block day-part weather icon, which looked like a literal
/// weather cloud for half the day and gave no cue on non-greeting replies).
class _AssistantAvatar extends StatelessWidget {
  const _AssistantAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kBlockAccent(context),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.smart_toy_outlined,
        size: 16,
        color: kBlockAccentInk(context),
      ),
    );
  }
}

/// "Back to home" control shown in the header while a mood conversation is
/// open — the explicit way back to the main feed (in addition to re-tapping
/// the active pill).
class _BackToHomeButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackToHomeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chevron_left, size: 20, color: onSurface),
              const SizedBox(width: 2),
              Text(
                'Back to home',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Restyled "assistant is responding" indicator — three dots pulsing in a
/// staggered wave, an unambiguous "in progress" pattern (replaces the bare
/// `CircularProgressIndicator`, which reads more like a stuck loading state
/// than active streaming).
class _TypingIndicator extends StatelessWidget {
  /// Human label for the data tool currently in flight (e.g. "Searching the
  /// cookbook…", from [ChatProvider.v2ActivityLabel]) — shown above the
  /// dots. `null` falls back to the original bare-dots appearance, which
  /// still covers plain streaming pauses and gaps between tool calls.
  final String? activityLabel;

  const _TypingIndicator({this.activityLabel});

  @override
  Widget build(BuildContext context) {
    final dotColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);

    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 5),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .scaleXY(
                  begin: 0.6,
                  end: 1.0,
                  duration: 500.ms,
                  delay: (i * 150).ms,
                  curve: Curves.easeInOut,
                )
                .then()
                .scaleXY(
                  begin: 1.0,
                  end: 0.6,
                  duration: 500.ms,
                  curve: Curves.easeInOut,
                ),
          ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: activityLabel == null
          ? dots
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(activityLabel!, style: reasonTextStyle(context)),
                const SizedBox(width: 8),
                dots,
              ],
            ),
    );
  }
}

/// "Scroll to latest" affordance shown when the user has scrolled away from
/// the bottom of the thread while a reply is streaming or new content just
/// arrived — otherwise there's no way to know there's something new to see.
class _ScrollToLatestPill extends StatelessWidget {
  final bool isSending;
  final VoidCallback onTap;

  const _ScrollToLatestPill({required this.isSending, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surface = Theme.of(context).colorScheme.surface;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: onSurface.withValues(alpha: 0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_downward, size: 15, color: onSurface),
            const SizedBox(width: 6),
            Text(
              isSending ? 'Responding…' : 'New content',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2, curve: Curves.easeOut);
  }
}
