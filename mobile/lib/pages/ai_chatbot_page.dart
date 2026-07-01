import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/providers/chat_provider.dart';
import 'package:i_cant_cook/services/haptic_service.dart';
import 'package:i_cant_cook/services/quick_options_service.dart';
import 'package:i_cant_cook/widgets/appbar/appbar_user_menu.dart';
import 'package:i_cant_cook/widgets/chatbot/ai_response_bubble.dart';
import 'package:i_cant_cook/widgets/chatbot/chat_message.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AiChatBotPage extends StatefulWidget {
  const AiChatBotPage({super.key});

  @override
  AiChatBotPageState createState() => AiChatBotPageState();
}

class AiChatBotPageState extends State<AiChatBotPage>
    with SingleTickerProviderStateMixin {
  static const List<Map<String, dynamic>> _allQuickQuestions = [
    {
      'text': 'INVENT RECIPE',
      'query': 'Invent a creative and unique recipe for me.',
      'icon': Icons.auto_fix_high,
    },
    {
      'text': 'MY RECIPES',
      'query':
          'I want to cook one of my saved recipes. Can you help me pick one?',
      'icon': Icons.book_outlined,
    },
    {
      'text': 'LOW-CAL OPTION',
      'query': 'Suggest a delicious low-calorie meal option.',
      'icon': Icons.monitor_weight_outlined,
    },
    {
      'text': 'LUNCH IDEAS',
      'query': 'Give me some great lunch ideas.',
      'icon': Icons.lunch_dining,
    },
    {
      'text': 'DINNER IDEAS',
      'query': 'Suggest something tasty for dinner tonight.',
      'icon': Icons.dinner_dining,
    },
    {
      'text': 'MEAL PREP',
      'query': 'Help me plan a simple and efficient meal prep for the week.',
      'icon': Icons.calendar_month,
    },
    {
      'text': '15-MINUTE MEAL',
      'query': 'Suggest a quick meal I can make in 15 minutes.',
      'icon': Icons.timer,
    },
    {
      'text': 'HIGH-PROTEIN',
      'query': 'Suggest a high-protein meal.',
      'icon': Icons.fitness_center,
    },
    {
      'text': 'VEGETARIAN',
      'query': 'Recommend a delicious vegetarian recipe.',
      'icon': Icons.eco,
    },
    {
      'text': 'ONE-POT DINNER',
      'query': 'Give me a hearty one-pot dinner idea.',
      'icon': Icons.soup_kitchen,
    },
    {
      'text': 'BUDGET-FRIENDLY',
      'query': 'Suggest budget-friendly meal ideas.',
      'icon': Icons.savings,
    },
    {
      'text': 'GLUTEN-FREE',
      'query': 'Recommend a tasty gluten-free recipe.',
      'icon': Icons.no_food,
    },
    {
      'text': 'SPICY RECIPES',
      'query': 'Suggest some bold and spicy recipes.',
      'icon': Icons.whatshot,
    },
    {
      'text': 'BREAKFAST IDEAS',
      'query': 'Give me some creative breakfast ideas.',
      'icon': Icons.free_breakfast,
    },
    {
      'text': 'KID-FRIENDLY',
      'query': 'Recommend a kid-friendly meal the whole family will enjoy.',
      'icon': Icons.child_care,
    },
  ];

  List<Map<String, dynamic>> _visibleQuickQuestions = [];

  late final AnimationController _menuController;
  late final Animation<double> _menuAnimation;
  bool _menuOpen = false;

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _speechInitialized = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _menuAnimation = CurvedAnimation(
      parent: _menuController,
      curve: Curves.easeInOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().setGlobalChat();
    });
    _refreshQuickQuestions();
  }

  Future<void> _initSpeech() async {
    _speechInitialized = true;
    final available = await _speech.initialize(
      onError: (_) => _setListening(false),
      onStatus: (status) {
        if (status == stt.SpeechToText.doneStatus ||
            status == stt.SpeechToText.notListeningStatus) {
          _setListening(false);
        }
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  void _setListening(bool value) {
    if (mounted) setState(() => _isListening = value);
  }

  Future<void> _toggleListening(TextEditingController controller) async {
    if (!_speechInitialized) await _initSpeech();
    if (!_speechAvailable) return;
    if (_isListening) {
      HapticService.lightImpact();
      await _speech.stop();
      _setListening(false);
      return;
    }
    HapticService.lightImpact();
    final baseText = controller.text;
    _setListening(true);
    await _speech.listen(
      onResult: (result) {
        final recognized = result.recognizedWords;
        final prefix = baseText.isEmpty ? '' : '$baseText ';
        controller.text = '$prefix$recognized';
        controller.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _menuController.dispose();
    super.dispose();
  }

  void _openMenu() {
    HapticService.lightImpact();
    setState(() => _menuOpen = true);
    _menuController.forward();
  }

  void _closeMenu() {
    _menuController.reverse().then((_) {
      if (mounted) setState(() => _menuOpen = false);
    });
  }

  Future<void> _refreshQuickQuestions() async {
    final options = await QuickOptionsService.getSmartOptions(
      _allQuickQuestions,
      5,
    );
    if (mounted) {
      setState(() {
        _visibleQuickQuestions = options;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(builder: (context, provider, child) {
      final double menuWidth = MediaQuery.of(context).size.width * 0.5;
      return Stack(
        children: [
          // ── Side menu (always rendered, behind the page) ──────────────
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: menuWidth,
            child: _buildSideMenu(context, provider, menuWidth),
          ),

          // ── Main page content (slides right to reveal menu) ───────────
          AnimatedBuilder(
            animation: _menuAnimation,
            builder: (context, _) {
              final slide = _menuAnimation.value * menuWidth;
              return Transform.translate(
                offset: Offset(slide, 0),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: _menuAnimation.value > 0
                        ? [
                            BoxShadow(
                              color: Colors.black
                                  .withOpacity(0.35 * _menuAnimation.value),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(-8, 0),
                            ),
                          ]
                        : const [],
                  ),
                  child: Stack(
                    children: [
                      Scaffold(
                        appBar: AppBar(
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          surfaceTintColor: Colors.transparent,
                          automaticallyImplyLeading: false,
                          elevation: 0,
                          leading: IconButton(
                            padding: const EdgeInsets.only(left: 16.0),
                            onPressed: _openMenu,
                            icon: Icon(
                              Icons.menu,
                              color: Theme.of(context).colorScheme.primary,
                              size: 26,
                            ),
                          ),
                          title: Text(
                            'COOKBOT',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                              fontSize: 22,
                              letterSpacing: 2.5,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          centerTitle: true,
                          actions: [UserMenuWidget()],
                        ),
                        body: Column(
                            children: [
                              if (provider.currentMessages.isEmpty) ...[
                                Expanded(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'WHAT ARE\nWE COOKING?',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 36,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.5,
                                              height: 1.05,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 28),
                                          _buildInput(context, provider),
                                          const SizedBox(height: 16),
                                          Wrap(
                                            spacing: 8.0,
                                            runSpacing: 8.0,
                                            children: _visibleQuickQuestions
                                                .map((q) => _buildChip(
                                                      context,
                                                      q['text']! as String,
                                                      q['icon'] as IconData?,
                                                      () {
                                                        QuickOptionsService
                                                            .trackUsage(
                                                                q['text']!
                                                                    as String);
                                                        provider.sendMessage(
                                                            query: q['query']!
                                                                as String);
                                                      },
                                                    ))
                                                .toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                Expanded(
                                  child: ListView.builder(
                                    controller: provider.scrollController,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: provider.currentMessages.length,
                                    itemBuilder: (context, index) {
                                      final message =
                                          provider.currentMessages[index];
                                      final bool isUser =
                                          message['sender'] == 'user';
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0),
                                        child: Align(
                                          alignment: isUser
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                          child: message['sender'] == 'ai'
                                              ? AiResponseBubble(
                                                  message: message['text'],
                                                  isLoading:
                                                      message['isLoading'] ==
                                                          true,
                                                  isRecipeLoading: message[
                                                          'isRecipeLoading'] ==
                                                      true,
                                                ).animate()
                                                  .fadeIn(duration: 300.ms)
                                                  .slideY(begin: 0.08, curve: Curves.easeOut, duration: 300.ms)
                                              : MessageWidget(
                                                  messageText: message['text']!,
                                                  isUser: isUser,
                                                ).animate()
                                                  .fadeIn(duration: 200.ms)
                                                  .slideX(begin: 0.15, curve: Curves.easeOut, duration: 200.ms),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: _buildInput(context, provider),
                                ),
                              ],
                            ],
                          ),
                        ),
                      // Tap-to-close overlay when menu is open
                      if (_menuOpen)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _closeMenu,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      );
    });
  }

  Widget _buildInput(BuildContext context, ChatProvider provider) {
    const highlightColor = Color(0xFFCAFF00);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...[
          GestureDetector(
            onTap: () => _toggleListening(provider.chatController),
            child: Container(
              width: 48,
              color: highlightColor,
              child: _isListening
                  ? const Icon(Icons.mic, color: Colors.black, size: 22)
                      .animate(onPlay: (c) => c.repeat())
                      .fade(begin: 1, end: 0.3, duration: 600.ms, curve: Curves.easeInOut)
                  : const Icon(Icons.mic_none, color: Colors.black, size: 22),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: provider.chatController,
                    style: GoogleFonts.spaceGrotesk(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: _isListening ? 'Listening…' : 'Ask or paste a URL…',
                      hintStyle: GoogleFonts.spaceGrotesk(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 14.0, horizontal: 16.0),
                    ),
                    onSubmitted: (query) => provider.sendMessage(query: query),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: provider.chatController,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () {
                        HapticService.lightImpact();
                        provider.chatController.clear();
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        color: Colors.transparent,
                        child: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                          size: 18,
                        ),
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: () {
                    final query = provider.chatController.text.trim();
                    if (query.isNotEmpty) {
                      HapticService.mediumImpact();
                      provider.sendMessage(query: query);
                    }
                  },
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

  Widget _buildChip(
      BuildContext context, String label, IconData? icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticService.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.25),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 14, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Side-menu helpers ─────────────────────────────────────────────────

  Widget _buildSideMenu(
      BuildContext context, ChatProvider provider, double menuWidth) {
    return Container(
      width: menuWidth,
      height: double.infinity,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Text(
                'CONVERSATIONS',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 1.5,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // New chat button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: () {
                  provider.startNewChat();
                  _closeMenu();
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                  color: const Color(0xFFCAFF00),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 16, color: Colors.black),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'NEW CHAT',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.8,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Builder(builder: (context) {
              final hasActive = provider.globalMessages.isNotEmpty;
              final hasSaved = provider.savedChats.isNotEmpty;
              if (!hasActive && !hasSaved) return const Spacer();
              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                      child: Text(
                        'CHATS',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          letterSpacing: 1.5,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.4),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          if (hasActive)
                            _buildActiveChatItem(context, provider),
                          ...provider.savedChats
                              .asMap()
                              .entries
                              .map((e) => _buildChatHistoryItem(
                                    context,
                                    provider,
                                    e.value,
                                    e.key,
                                  )),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChatItem(BuildContext context, ChatProvider provider) {
    final firstUserMsg = provider.globalMessages.firstWhere(
      (m) => m['sender'] == 'user',
      orElse: () => {'text': 'New conversation'},
    );
    final rawTitle =
        (firstUserMsg['text'] as String?)?.trim() ?? 'New conversation';
    final title =
        rawTitle.length > 40 ? '${rawTitle.substring(0, 40)}\u2026' : rawTitle;

    return GestureDetector(
      onTap: _closeMenu,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Active',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHistoryItem(
    BuildContext context,
    ChatProvider provider,
    ChatSession session,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        provider.restoreSession(index);
        _closeMenu();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _formatSessionDate(session.createdAt),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSessionDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$min $period';
    if (diff == 0) return 'Today · $timeStr';
    if (diff == 1) return 'Yesterday · $timeStr';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day} · $timeStr';
  }

}
