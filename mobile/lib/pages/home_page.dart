import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/enums/toast_type.dart';
import 'package:i_cant_cook/models/block/block.dart';
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

  /// Locally tracked mood selection, set synchronously the instant a mood
  /// pill is tapped — before the feed refetch resolves — so the tap always
  /// reads as registered, never as "nothing happened". Highlights the
  /// tapped pill on the original seeded message, which keeps its
  /// mood-question card available for picking a different mood again later.
  Mood? _pendingMood;

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

    // Load the initial feed and seed the chat thread
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
    final chatProvider = context.read<ChatProvider>();

    // The dashboard recreates HomePage's State every time this tab is
    // reselected (AnimatedSwitcher keys on the tab index), but ChatProvider
    // is a long-lived top-level provider. Only seed the conversation once —
    // otherwise every tab revisit appends another copy of the feed.
    if (chatProvider.v2Messages.isNotEmpty) return;

    final homeFeedProvider = context.read<HomeFeedProvider>();
    await homeFeedProvider.loadFeed();

    if (homeFeedProvider.feed != null) {
      final feed = homeFeedProvider.feed!;
      final blocksToSeed = feed.renderableBlocks;
      if (blocksToSeed.isNotEmpty) {
        chatProvider.addV2AssistantMessage(blocksToSeed);
      }
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

  /// Handles mood selection by re-ranking the feed **in place**: it refetches
  /// `/api/home/feed/?mood=` and swaps the cards of the opening message
  /// (message 0) where they sit, rather than appending the whole feed again
  /// underneath (which duplicated the entire page and slammed the viewport to
  /// the bottom). The tapped pill is filled synchronously for instant
  /// feedback, and a persistent [_MoodChosenIndicator] confirms the choice so
  /// the in-place re-rank never reads as "nothing happened". The changed cards
  /// still fade in via their per-block [_blockKey] identity.
  Future<void> _handleMoodSelected(Mood mood) async {
    HapticService.lightImpact();

    // Immediate tap feedback: fill the tapped pill before the refetch resolves.
    final previousMood = _pendingMood;
    setState(() => _pendingMood = mood);

    final homeFeedProvider = context.read<HomeFeedProvider>();
    final chatProvider = context.read<ChatProvider>();

    await homeFeedProvider.selectMood(mood);

    if (!mounted) return;

    if (homeFeedProvider.feed != null) {
      final blocks = homeFeedProvider.feed!.renderableBlocks;
      if (blocks.isNotEmpty) {
        chatProvider.replaceV2Message(0, blocks);
      }
    } else if (homeFeedProvider.error != null) {
      // Revert the optimistic pill fill; the feed didn't actually change.
      setState(() => _pendingMood = previousMood);
      InformationToast.show(
        context: context,
        message: homeFeedProvider.error ?? 'Failed to load feed',
        type: ToastType.error,
      );
    }
  }

  /// Clears the active mood and re-ranks the opening message back to its
  /// no-mood state in place (which brings the mood-question pills back). Wired
  /// to the "change" affordance on [_MoodChosenIndicator].
  Future<void> _handleMoodCleared() async {
    HapticService.lightImpact();
    setState(() => _pendingMood = null);

    final homeFeedProvider = context.read<HomeFeedProvider>();
    final chatProvider = context.read<ChatProvider>();

    await homeFeedProvider.loadFeed();

    if (!mounted) return;

    if (homeFeedProvider.feed != null) {
      final blocks = homeFeedProvider.feed!.renderableBlocks;
      if (blocks.isNotEmpty) {
        chatProvider.replaceV2Message(0, blocks);
      }
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
      mood: homeFeedProvider.currentMood,
      homeFeed: feedPayload,
      onError: (errorMessage) {
        InformationToast.show(
          context: context,
          message: errorMessage,
          type: ToastType.error,
        );
      },
    );

    _scrollToBottom();
  }

  Future<void> _handleRefresh() async {
    final homeFeedProvider = context.read<HomeFeedProvider>();
    final chatProvider = context.read<ChatProvider>();

    // Only allow refresh if not actively sending and no conversation beyond the opening
    if (chatProvider.isV2Sending) return;
    if (chatProvider.v2Messages.length > 1) return;

    await homeFeedProvider.refresh();

    if (!mounted) return;

    if (homeFeedProvider.feed != null) {
      final feed = homeFeedProvider.feed!;
      final blocksToSeed = feed.renderableBlocks;

      chatProvider.resetV2Conversation();
      if (blocksToSeed.isNotEmpty) {
        chatProvider.addV2AssistantMessage(blocksToSeed);
      }
      if (!_isNearBottom) setState(() => _hasNewContent = true);
    }
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
        // Track message-count growth to know when new content arrived while
        // the user was scrolled away from the bottom — drives the "scroll to
        // latest" affordance below. Plain field mutation (no setState) is
        // safe here: this build is already running because Consumer2 is
        // reacting to the provider's own notifyListeners.
        final messageCount = chatProvider.v2Messages.length;
        if (messageCount > _lastMessageCount && !_isNearBottom) {
          _hasNewContent = true;
        }
        _lastMessageCount = messageCount;

        final showScrollToLatest = !_isNearBottom &&
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
          body: RefreshIndicator(
            onRefresh: _handleRefresh,
            child: Column(
              children: [
                // Thread of messages
                Expanded(
                  child: Stack(
                    children: [
                      chatProvider.v2Messages.isEmpty
                          ? Center(
                              child: homeFeedProvider.isLoading
                                  ? const CircularProgressIndicator()
                                  : const SizedBox.shrink(),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: chatProvider.v2Messages.length,
                              itemBuilder: (context, index) {
                                final message = chatProvider.v2Messages[index];
                                final isUser = message.isUser;

                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16.0, 0, 16.0, 10.0),
                                  child: isUser
                                      ? Align(
                                          alignment: Alignment.centerRight,
                                          child:
                                              _buildUserMessageBubble(message),
                                        )
                                      : _buildAssistantMessage(
                                          context,
                                          message,
                                          isFirstMessage: index == 0,
                                        ),
                                );
                              },
                            ),
                      // "Scroll to latest" affordance — visible when the
                      // user has scrolled away from the bottom AND either a
                      // reply is streaming or new content just arrived.
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
                  ),
                ),
                // Input bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _buildInputBar(context, chatProvider),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds an assistant message: renders blocks using BlockRegistry with
  /// callbacks, with breathing room between consecutive blocks (the feed's
  /// only source of inter-item spacing — block widgets themselves stay
  /// margin-free to avoid doubling the gap).
  ///
  /// Each block is wrapped in a `ValueKey` derived from its own content
  /// ([_blockKey]) so that when message 0's blocks are swapped wholesale
  /// (mood switch, pull-to-refresh), changed/replaced blocks get a fresh
  /// widget identity and their fade+slide entrance actually replays — a
  /// plain data-only rebuild otherwise reuses the same widget/element and
  /// the animation never restarts.
  Widget _buildAssistantMessage(
    BuildContext context,
    ChatV2Message message, {
    bool isFirstMessage = false,
  }) {
    // The avatar marks "the agent is speaking" and sits only beside the
    // message's leading text (the greeting, or an ordinary reply's opening
    // line) — it must NOT indent module cards below it, which span the
    // full row width like the rest of the page.
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
      selectedMood: _pendingMood,
    );
    final blocks = message.blocks;

    final hasLeadingText = blocks.isNotEmpty && blocks[0] is TextBlock;
    final restStart = hasLeadingText ? 1 : 0;
    final hasTrailingContent = restStart < blocks.length;

    Widget animated(Widget child) => child.animate().fadeIn(duration: 300.ms).slideY(
          begin: 0.08,
          curve: Curves.easeOut,
          duration: 300.ms,
        );

    final leadingText = hasLeadingText
        ? animated(
            TextBlockBubble(
              key: _blockKey(blocks[0], 0),
              text: (blocks[0] as TextBlock).text,
              isGreeting: isFirstMessage,
            ),
          )
        : const SizedBox.shrink();

    // On the opening message, once a mood is chosen the mood-question pills
    // drop out of the re-ranked feed — this persistent indicator is what
    // replaces them, both confirming the choice and offering a way back.
    final showMoodIndicator = isFirstMessage && _pendingMood != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMoodIndicator)
          Padding(
            padding: const EdgeInsets.only(bottom: kBlockFeedGap),
            child: _MoodChosenIndicator(
              label: _moodLabel(_pendingMood!),
              onChange: _handleMoodCleared,
            ),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: hasTrailingContent ? kBlockFeedGap : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AssistantAvatar(),
              const SizedBox(width: 10),
              Expanded(child: leadingText),
            ],
          ),
        ),
        for (var i = restStart; i < blocks.length; i++)
          Padding(
            key: _blockKey(blocks[i], i),
            padding: EdgeInsets.only(
              bottom: i == blocks.length - 1 ? 0 : kBlockFeedGap,
            ),
            child: animated(
              BlockRegistry.build(context, blocks[i], callbacks: callbacks),
            ),
          ),
      ],
    );
  }

  static String _moodLabel(Mood mood) {
    switch (mood) {
      case Mood.rushed:
        return 'Rushed';
      case Mood.ambitious:
        return 'Ambitious';
      case Mood.cookingForSomeone:
        return 'Cooking for someone';
      case Mood.comfort:
        return 'Comfort';
      case Mood.healthy:
        return 'Healthy';
      case Mood.surpriseMe:
        return 'Surprise me';
    }
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
      decoration: const BoxDecoration(
        color: kBlockAccent,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.smart_toy_outlined,
        size: 16,
        color: kBlockAccentInk,
      ),
    );
  }
}

/// Persistent trace of the chosen mood, shown at the top of the opening
/// message after a mood is picked (the mood-question pills disappear from the
/// re-ranked feed). Confirms the selection and offers a "change" tap target
/// that clears the mood and brings the pills back.
class _MoodChosenIndicator extends StatelessWidget {
  final String label;
  final VoidCallback onChange;

  const _MoodChosenIndicator({required this.label, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final accent = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.mood, size: 16, color: accent),
        const SizedBox(width: 6),
        Text(
          'Feeling: $label',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        const SizedBox(width: 8),
        Text('·', style: TextStyle(color: onSurface.withValues(alpha: 0.4))),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onChange,
          behavior: HitTestBehavior.opaque,
          child: Text(
            'change',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: onSurface.withValues(alpha: 0.6),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
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
