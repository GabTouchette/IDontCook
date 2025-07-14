import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:i_cant_cook/mixins/chatbot_mixin.dart';
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

class AiChatBotPageState extends State<AiChatBotPage> with ChatBotMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
                      if (provider.globalMessages.isEmpty) ...[
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
                                          sendMessageWithContext(
                                              query, provider),
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
                                          sendMessageWithContext(
                                              'Can you suggest a new recipe idea?',
                                              provider);
                                        }),
                                        _buildBreadcrumb(
                                            'Something I have',
                                            FontAwesomeIcons.file,
                                            Colors.green, () {
                                          sendMessageWithContext(
                                              'Can you suggest a recipe that I have?',
                                              provider);
                                        }),
                                        _buildBreadcrumb(
                                            'A popular choice',
                                            FontAwesomeIcons.fire,
                                            Colors.orange, () {
                                          sendMessageWithContext(
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
                      if (provider.globalMessages.isNotEmpty) ...[
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.zero,
                            itemCount: provider.globalMessages.length,
                            itemBuilder: (context, index) {
                              final message = provider.globalMessages[index];
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
                                          isLoading:
                                              message['isLoading'] == true,
                                          isRecipeLoading:
                                              message['isRecipeLoading'] ==
                                                  true,
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
                                  sendMessageWithContext(query, provider),
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
