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
  @override
  void initState() {
    super.initState();
    // Ensure we're in global chat mode when this page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().setGlobalChat();
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
                                    children: [
                                      _buildBreadcrumb('New Idea',
                                          FontAwesomeIcons.lightbulb, () {
                                        provider.sendMessage(
                                            query:
                                                'Can you suggest a new recipe idea?');
                                      }),
                                      _buildBreadcrumb('Something I have',
                                          FontAwesomeIcons.file, () {
                                        provider.sendMessage(
                                            query:
                                                'Can you suggest a recipe that I have?');
                                      }),
                                      _buildBreadcrumb('A popular choice',
                                          FontAwesomeIcons.fire, () {
                                        provider.sendMessage(
                                            query:
                                                'Can you suggest a popular recipe at the moment?');
                                      }),
                                    ],
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
