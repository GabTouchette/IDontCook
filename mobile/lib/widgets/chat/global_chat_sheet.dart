import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/models/block/block.dart';
import 'package:i_cant_cook/providers/chat_provider.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/widgets/blocks/block_registry.dart';
import 'package:i_cant_cook/widgets/blocks/block_styles.dart';
import 'package:i_cant_cook/widgets/blocks/text_block_bubble.dart';
import 'package:i_cant_cook/widgets/sheets/app_sheet.dart';
import 'package:provider/provider.dart';

/// The app-wide assistant surface: a bottom sheet that runs the v2 chat and
/// carries whatever page context the current surface registered via
/// [ChatProvider.setPageContext]. Opened by [GlobalChatLauncher] from any main
/// surface; replaces the old per-recipe recipe-chat dialog.
///
/// The conversation is a single rolling thread ([ChatProvider.v2Messages]) that
/// follows the user across pages — the page context swaps underneath it, but
/// the history stays until the user taps "new chat".
class GlobalChatSheet extends StatefulWidget {
  /// Optional question auto-sent as soon as the sheet opens — used by the
  /// recipe-detail ingredient long-press ("What is this?" / "Suggest
  /// replacements") so the chat opens with the question already asked.
  final String? initialQuery;

  const GlobalChatSheet({super.key, this.initialQuery});

  @override
  State<GlobalChatSheet> createState() => _GlobalChatSheetState();
}

class _GlobalChatSheetState extends State<GlobalChatSheet> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ChatProvider>();
      _seedGreetingIfEmpty(provider);

      final initialQuery = widget.initialQuery?.trim();
      if (initialQuery != null && initialQuery.isNotEmpty) {
        provider.sendMessageV2(message: initialQuery, chatContext: 'global');
      } else {
        // Open with the input ready so the user can start typing right away.
        _inputFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  /// A few warm, generic openers. We don't name the current page here: the
  /// backend already receives the page context on every send, and a greeting
  /// that named the page would go stale the moment the user navigated away.
  static const List<String> _greetings = [
    "Hey! What are you cooking up today?",
    "Hi there. Ask me anything about food, recipes, or what's on your screen.",
    "Hey! Need a hand with something in the kitchen?",
    "Hi! What can I help you find?",
    "Hey there. What sounds good today?",
  ];

  /// Seeds an opening assistant line when the thread is empty, picking one of
  /// the stock greetings so each new chat feels a little different.
  void _seedGreetingIfEmpty(ChatProvider provider) {
    if (provider.v2Messages.isNotEmpty) return;
    final greeting = _greetings[
        DateTime.now().microsecondsSinceEpoch % _greetings.length];
    provider.addV2AssistantMessage([Block.text(text: greeting)]);
  }

  void _startNewChat() {
    HapticService.selectionClick();
    final provider = context.read<ChatProvider>();
    provider.resetV2Conversation();
    _seedGreetingIfEmpty(provider);
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    _messageController.clear();
    context.read<ChatProvider>().sendMessageV2(
          message: text,
          chatContext: 'global',
        );
    _scrollToBottomSoon();
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(kAppSheetRadius)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: screenHeight * 0.75,
            child: Column(
              children: [
                const AppSheetHandle(),
                AppSheetHeader(
                  title: 'CookBot Assistant',
                  showClose: false,
                  actions: [
                    TextButton.icon(
                      onPressed: _startNewChat,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        'New',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: cs.onSurface,
                      ),
                    ),
                  ],
                ),
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, provider, _) {
                    _scrollToBottomSoon();
                    final visible = [
                      for (final m in provider.v2Messages)
                        if (!m.hidden) m,
                    ];
                    return ListView.builder(
                      controller: _scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final message = visible[index];
                        final isStreaming = !message.isUser &&
                            index == visible.length - 1 &&
                            provider.isV2Sending;
                        return Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16.0, 0, 16.0, 10.0),
                          child: message.isUser
                              ? Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildUserBubble(context, message),
                                )
                              : _buildAssistantMessage(context, provider,
                                  message, isStreaming),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: _buildInputBar(context, cs),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserBubble(BuildContext context, ChatV2Message message) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        message.plainText,
        style: GoogleFonts.spaceGrotesk(
          color: cs.onPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildAssistantMessage(
    BuildContext context,
    ChatProvider provider,
    ChatV2Message message,
    bool isStreaming,
  ) {
    final hasContent = message.blocks.isNotEmpty;

    // Nothing streamed yet: avatar beside the working indicator.
    if (!hasContent && (isStreaming || message.isLoading)) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AssistantAvatar(),
          const SizedBox(width: 10),
          Expanded(child: _WorkingIndicator(provider: provider)),
        ],
      );
    }

    final callbacks = BlockCallbacks(
      onChatPromptTap: (promptText) {
        provider.sendMessageV2(message: promptText, chatContext: 'global');
        _scrollToBottomSoon();
      },
    );
    final blocks = message.blocks;
    final hasLeadingText = blocks.isNotEmpty && blocks[0] is TextBlock;
    final restStart = hasLeadingText ? 1 : 0;
    final trailing = blocks.sublist(restStart);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding:
              EdgeInsets.only(bottom: trailing.isNotEmpty ? kBlockFeedGap : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AssistantAvatar(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isStreaming) ...[
                      _WorkingIndicator(provider: provider),
                      if (hasLeadingText) const SizedBox(height: kBlockFeedGap),
                    ],
                    if (hasLeadingText)
                      TextBlockBubble(text: (blocks[0] as TextBlock).text),
                  ],
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < trailing.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == trailing.length - 1 ? 0 : kBlockFeedGap,
            ),
            child: BlockRegistry.build(context, trailing[i],
                callbacks: callbacks),
          ),
      ],
    );
  }

  Widget _buildInputBar(BuildContext context, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(
          color: cs.outline.withAlpha((0.25 * 255).toInt()),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _inputFocus,
              style: GoogleFonts.spaceGrotesk(
                color: cs.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Ask or suggest something…',
                hintStyle: GoogleFonts.spaceGrotesk(
                  color: cs.onSurface.withAlpha((0.35 * 255).toInt()),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14.0,
                  horizontal: 16.0,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              color: cs.onSurface,
              child: Icon(
                Icons.arrow_forward,
                color: cs.surface,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small lime avatar marking every assistant turn (mirrors the home feed's
/// assistant avatar).
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

/// Compact "assistant is working" line: a spinner plus the current stage label
/// (Thinking… / Searching the cookbook… / Writing…), fed by
/// [ChatProvider.v2Stages].
class _WorkingIndicator extends StatelessWidget {
  final ChatProvider provider;
  const _WorkingIndicator({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stages = provider.v2Stages;
    final label = stages.isNotEmpty ? stages.last.label : 'Thinking…';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(cs.onSurface),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            color: cs.onSurface.withAlpha((0.6 * 255).toInt()),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
