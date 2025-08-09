import 'dart:math';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i_cant_cook/providers/chat_provider.dart';
import 'package:i_cant_cook/widgets/appbar/appbar_user_menu.dart';
import 'package:i_cant_cook/widgets/chatbot/ai_response_bubble.dart';
import 'package:i_cant_cook/widgets/chatbot/chat_message.dart';
import 'package:provider/provider.dart';

class AiChatBotPage extends StatefulWidget {
  const AiChatBotPage({super.key});

  @override
  AiChatBotPageState createState() => AiChatBotPageState();
}

class AiChatBotPageState extends State<AiChatBotPage> {
  // Pool of quick questions with associated icons
  final List<Map<String, dynamic>> _allQuickQuestions = [
    {
      'text': 'Suggest a 15-minute dinner',
      'icon': FontAwesomeIcons.clock,
      'query': 'Suggest a 15-minute dinner.'
    },
    {
      'text': 'Low-calorie meal ideas',
      'icon': FontAwesomeIcons.heart,
      'query': 'Give me low-calorie meal ideas.'
    },
    {
      'text': 'Vegetarian with broccoli',
      'icon': FontAwesomeIcons.carrot,
      'query': 'Suggest a vegetarian recipe that uses broccoli.'
    },
    {
      'text': 'Gluten-free dessert',
      'icon': FontAwesomeIcons.cakeCandles,
      'query': 'Recommend a gluten-free dessert.'
    },
    {
      'text': 'Chicken and rice ideas',
      'icon': FontAwesomeIcons.bowlFood,
      'query': 'What can I cook with chicken and rice?'
    },
    {
      'text': 'High-protein lunch',
      'icon': FontAwesomeIcons.dumbbell,
      'query': 'Suggest a high-protein lunch.'
    },
    {
      'text': 'One-pot dinner',
      'icon': FontAwesomeIcons.utensils,
      'query': 'Give me a one-pot dinner idea.'
    },
    {
      'text': 'Budget-friendly meals',
      'icon': FontAwesomeIcons.dollarSign,
      'query': 'Suggest budget-friendly meal ideas.'
    },
    {
      'text': 'Kid-friendly dinner',
      'icon': FontAwesomeIcons.faceSmile,
      'query': 'Recommend a kid-friendly dinner.'
    },
    {
      'text': 'Meal prep for the week',
      'icon': FontAwesomeIcons.calendarDays,
      'query': 'Plan a simple meal prep for the week.'
    },
    {
      'text': 'Spicy recipes',
      'icon': FontAwesomeIcons.pepperHot,
      'query': 'Suggest some spicy recipes.'
    },
    {
      'text': 'Breakfast ideas',
      'icon': FontAwesomeIcons.egg,
      'query': 'Give me some breakfast ideas.'
    },
    {
      'text': 'Dairy-free options',
      'icon': FontAwesomeIcons.ban,
      'query': 'Recommend dairy-free recipe options.'
    },
    {
      'text': 'Under 500 calories',
      'icon': FontAwesomeIcons.scaleBalanced,
      'query': 'Suggest meals under 500 calories.'
    },
    {
      'text': 'Popular right now',
      'icon': FontAwesomeIcons.fire,
      'query': 'What are popular recipes right now?'
    },
  ];

  List<Map<String, dynamic>> _visibleQuickQuestions = [];

  @override
  void initState() {
    super.initState();
    // Ensure we're in global chat mode when this page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().setGlobalChat();
    });
    _refreshQuickQuestions();
  }

  void _refreshQuickQuestions() {
    final rng = Random();
    final count = 2 + rng.nextInt(3); // 2..4
    final pool = List<Map<String, dynamic>>.from(_allQuickQuestions);
    pool.shuffle(rng);
    setState(() {
      _visibleQuickQuestions = pool.take(count).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(builder: (context, provider, child) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          centerTitle: true,
          leading: IconButton(
            padding: const EdgeInsets.only(left: 16.0),
            onPressed: () {
              provider.clearMessages(isRecipeChat: false);
            },
            icon: Container(
              padding: const EdgeInsets.all(16),
              child: FaIcon(
                Icons.assignment_add,
                color: Theme.of(context).colorScheme.primary,
                size: 36,
              ),
            ),
          ),
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'CookBot',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                fontSize: 28,
                letterSpacing: -0.5,
              ),
            ),
          ),
          actions: [UserMenuWidget()],
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: LayoutBuilder(builder: (context, constraints) {
            return Stack(
              children: [
                Positioned.fill(
                  child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor),
                ),
                Column(
                  children: [
                    if (provider.currentMessages.isEmpty) ...[
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withOpacity(0.3),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.1),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: provider.chatController,
                                    style: GoogleFonts.nunito(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: InputDecoration(
                                      icon: Icon(
                                        Icons.search,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      hintText: 'Ask a question...',
                                      hintStyle: GoogleFonts.nunito(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 16.0, horizontal: 8.0),
                                    ),
                                    onSubmitted: (query) =>
                                        provider.sendMessage(query: query),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Wrap(
                                    spacing: 16.0,
                                    runSpacing: 12.0,
                                    children: _visibleQuickQuestions
                                        .map((q) => _buildBreadcrumb(
                                              q['text'] as String,
                                              q['icon'] as IconData,
                                              () => provider.sendMessage(
                                                  query: q['query'] as String),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (provider.currentMessages.isNotEmpty) ...[
                      Expanded(
                        child: ListView.builder(
                          controller: provider.scrollController,
                          padding: EdgeInsets.zero,
                          itemCount: provider.currentMessages.length,
                          itemBuilder: (context, index) {
                            final message = provider.currentMessages[index];
                            final bool isUser = message['sender'] == 'user';

                            return Align(
                              alignment: isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0),
                                child: message['sender'] == 'ai'
                                    ? AiResponseBubble(
                                        message: message['text'],
                                        isLoading: message['isLoading'] == true,
                                        isRecipeLoading:
                                            message['isRecipeLoading'] == true,
                                      )
                                    : MessageWidget(
                                        messageText: message['text']!,
                                        isUser: isUser,
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: provider.chatController,
                            style: GoogleFonts.nunito(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              icon: Icon(
                                Icons.search,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              hintText: 'Ask a question...',
                              hintStyle: GoogleFonts.nunito(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 16.0, horizontal: 8.0),
                            ),
                            onSubmitted: (query) =>
                                provider.sendMessage(query: query),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          }),
        ),
      );
    });
  }

  Widget _buildBreadcrumb(String title, IconData icon, VoidCallback onTap) {
    // Define accent colors for each type
    Color iconColor;
    switch (icon) {
      case FontAwesomeIcons.lightbulb:
        iconColor = Colors.amber;
        break;
      case FontAwesomeIcons.file:
        iconColor = Colors.green;
        break;
      case FontAwesomeIcons.fire:
        iconColor = Colors.orange;
        break;
      case FontAwesomeIcons.clock:
        iconColor = Colors.blue;
        break;
      case FontAwesomeIcons.heart:
        iconColor = Colors.pink;
        break;
      case FontAwesomeIcons.carrot:
        iconColor = Colors.deepOrange;
        break;
      case FontAwesomeIcons.cakeCandles:
        iconColor = Colors.purple;
        break;
      case FontAwesomeIcons.bowlFood:
        iconColor = Colors.teal;
        break;
      case FontAwesomeIcons.dumbbell:
        iconColor = Colors.indigo;
        break;
      case FontAwesomeIcons.utensils:
        iconColor = Colors.brown;
        break;
      case FontAwesomeIcons.dollarSign:
        iconColor = Colors.green;
        break;
      case FontAwesomeIcons.faceSmile:
        iconColor = Colors.amber;
        break;
      case FontAwesomeIcons.calendarDays:
        iconColor = Colors.cyan;
        break;
      case FontAwesomeIcons.pepperHot:
        iconColor = Colors.red;
        break;
      case FontAwesomeIcons.egg:
        iconColor = Colors.orange;
        break;
      case FontAwesomeIcons.ban:
        iconColor = Colors.grey;
        break;
      case FontAwesomeIcons.scaleBalanced:
        iconColor = Colors.lightGreen;
        break;
      default:
        iconColor = Theme.of(context).colorScheme.primary;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              color: iconColor,
              size: 16,
            ),
            const SizedBox(width: 6.0),
            Text(
              title,
              style: GoogleFonts.nunito(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
