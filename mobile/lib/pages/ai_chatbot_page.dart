import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:i_cant_cook/api/ai_chatbot_api.dart';
import 'package:i_cant_cook/providers/chat_provider.dart';
import 'package:i_cant_cook/theme/colors.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String query, ChatProvider chatProvider) async {
    if (query.isNotEmpty) {
      chatProvider.addMessage(sender: "user", text: query);

      _searchController.clear();
      _scrollToBottom();

      try {
        List<Map<String, String>> chatHistory = [];
        int historyLength = chatProvider.messages.length - 1;
        int start = (historyLength >= 5) ? historyLength - 5 : 0;

        for (int i = historyLength - 1; i >= start; i--) {
          chatHistory.insert(0, {
            "message": chatProvider.messages[i]['text'] ?? '',
            "sender": chatProvider.messages[i]['sender'] ?? ''
          });
        }

        chatProvider.addMessage(isLoading: true, isRecipeLoading: true);
        final stream = AiChatbotApi().chatWithBotStream(query, chatHistory);

        bool recipeTagOpen = false;
        String recipeBuffer = "";

        await for (String token in stream) {
          if (recipeTagOpen) {
            recipeBuffer += token;
            if (token.trim() == "**" || token.trim() == "&&") {
              chatProvider.addMessage();
              recipeTagOpen = false;
              chatProvider.updateLastMessage(recipeBuffer);
              recipeBuffer = "";
            }
          } else {
            if (token.trim() == "**" || token.trim() == "&&") {
              recipeTagOpen = true;
              recipeBuffer += token;
              chatProvider.addMessage(isRecipeLoading: true);
            } else {
              chatProvider.updateLastMessage(
                  (chatProvider.messages.last["text"] ?? "") + token);
            }
          }
        }
      } catch (e) {
        chatProvider.removeLastMessage();
        chatProvider.addMessage(text: "Error: ${e.toString()}");
      } finally {
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(builder: (context, provider, child) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            'CookBot',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 32,
              color: ColorPalette.offWhite,
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: IconButton(
              icon: Icon(
                Icons.assignment_add,
                color: ColorPalette.offWhite,
                size: 32,
              ),
              onPressed: () {
                provider.clearMessages();
              },
            ),
          ),
          actions: [
            UserMenuWidget(),
          ],
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: LayoutBuilder(builder: (context, constraints) {
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/ai_chat_page_background.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 120.0),
                  child: Column(
                    children: [
                      if (provider.messages.isEmpty) ...[
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
                                      color: ColorPalette.darkergray,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                          color: ColorPalette.darkgray),
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      style: TextStyle(
                                        color: ColorPalette.offWhite,
                                      ),
                                      decoration: InputDecoration(
                                        icon: const Icon(
                                          Icons.search,
                                          color: ColorPalette.placeholdergray,
                                        ),
                                        hintText: 'Ask a question...',
                                        hintStyle: TextStyle(
                                          color: ColorPalette.placeholdergray,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 16.0, horizontal: 8.0),
                                      ),
                                      onSubmitted: (query) =>
                                          _sendMessage(query, provider),
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
                                        _buildBreadcrumb(
                                            'New Idea',
                                            FontAwesomeIcons.lightbulb,
                                            ColorPalette.mustard, () {
                                          _sendMessage(
                                              'Can you suggest a new recipe idea?',
                                              provider);
                                        }),
                                        _buildBreadcrumb(
                                            'Something I have',
                                            FontAwesomeIcons.file,
                                            Colors.green, () {
                                          _sendMessage(
                                              'Can you suggest a recipe that I have?',
                                              provider);
                                        }),
                                        _buildBreadcrumb(
                                            'A popular choice',
                                            FontAwesomeIcons.fire,
                                            Colors.orange, () {
                                          _sendMessage(
                                              'Can you suggest a popular recipe at the moment?',
                                              provider);
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
                      if (provider.messages.isNotEmpty) ...[
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.zero,
                            itemCount: provider.messages.length,
                            itemBuilder: (context, index) {
                              final message = provider.messages[index];
                              final bool isUser = message['sender'] == 'user';
                              final bool isLoading =
                                  message['isLoading'] == true;
                              final bool isRecipeLoading =
                                  message['isRecipeLoading'] == true;

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
                                          isLoading: isLoading,
                                          isRecipeLoading: isRecipeLoading,
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            decoration: BoxDecoration(
                              color: ColorPalette.darkgray,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: ColorPalette.placeholdergray),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(
                                color: ColorPalette.offWhite,
                              ),
                              decoration: InputDecoration(
                                icon: const Icon(
                                  Icons.search,
                                  color: ColorPalette.placeholdergray,
                                ),
                                hintText: 'Ask a question...',
                                hintStyle: TextStyle(
                                  color: ColorPalette.placeholdergray,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    vertical: 16.0, horizontal: 8.0),
                              ),
                              onSubmitted: (query) =>
                                  _sendMessage(query, provider),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      );
    });
  }

  Widget _buildBreadcrumb(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: ColorPalette.darkgray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              color: color,
              size: 18,
            ),
            SizedBox(width: 6.0),
            Text(
              title,
              style: TextStyle(
                color: ColorPalette.lightgray,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
