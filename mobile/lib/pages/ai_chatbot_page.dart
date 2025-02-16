import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/api/ai_chatbot_api.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/widgets/chatbot/ai_response_bubble.dart';
import 'package:mobile/widgets/chatbot/chat_message.dart';

class AiChatBotPage extends StatefulWidget {
  const AiChatBotPage({super.key});

  @override
  AiChatBotPageState createState() => AiChatBotPageState();
}

class AiChatBotPageState extends State<AiChatBotPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;
  List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String query) async {
    if (query.isNotEmpty) {
      setState(() {
        _messages.add({"sender": "user", "text": query});
        _messages.add({"sender": "ai", "text": "loading"});
      });

      _searchController.clear();
      _scrollToBottom();

      try {
        List<Map<String, String>> chatHistory = [];
        for (int i = _messages.length - 2; i >= 0; i--) {
          chatHistory.insert(0, {
            "message": _messages[i]['text'] ?? '',
            "sender": _messages[i]['sender'] ?? ''
          });
        }
        final response = await AiChatbotApi().chatWithBot(query, chatHistory);

        setState(() {
          _messages.removeLast();
          _messages.add({"sender": "ai", "text": response});
        });
      } catch (e) {
        setState(() {
          _messages.removeLast();
          _messages.add({"sender": "ai", "text": "Error: ${e.toString()}"});
        });
      }

      _scrollToBottom();
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'CookBot',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: ColorPalette.offWhite,
          ),
        ),
      ),
      body: Stack(
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
                if (_messages.isEmpty) ...[
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              decoration: BoxDecoration(
                                color: ColorPalette.darkergray,
                                borderRadius: BorderRadius.circular(30),
                                border:
                                    Border.all(color: ColorPalette.darkgray),
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
                                onSubmitted: _sendMessage,
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
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
                                        'Can you suggest a new recipe idea?');
                                  }),
                                  _buildBreadcrumb('Something I have',
                                      FontAwesomeIcons.file, Colors.green, () {
                                    _sendMessage(
                                        'Can you suggest a recipe that i have?');
                                  }),
                                  _buildBreadcrumb('A popular choice',
                                      FontAwesomeIcons.fire, Colors.orange, () {
                                    _sendMessage(
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
                if (_messages.isNotEmpty) ...[
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.zero,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final bool isUser = message['sender'] == 'user';
                        final bool isLoading = message['sender'] == 'ai' &&
                            message['text'] == 'loading';

                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: isLoading
                                ? const AiResponseBubble()
                                : message['sender'] == 'ai'
                                    ? AiResponseBubble(
                                        message: message['text']!)
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
                        color: ColorPalette.darkgray,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: ColorPalette.placeholdergray),
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
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
