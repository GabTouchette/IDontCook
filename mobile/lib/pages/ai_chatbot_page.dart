import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mobile/api/ai_chatbot_api.dart';
import 'package:mobile/theme/colors.dart';

class AiChatBotPage extends StatefulWidget {
  const AiChatBotPage({super.key});

  @override
  AiChatBotPageState createState() => AiChatBotPageState();
}

class AiChatBotPageState extends State<AiChatBotPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<Map<String, String>> _messages = []; // List of messages for chat

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Function to handle sending the message when "Send" is pressed
  void _sendMessage(String query) {
    if (query.isNotEmpty) {
      // Add user message to chat
      setState(() {
        _messages.add({"sender": "user", "text": query});
      });

      // Simulate AI response (mock)
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _messages
              .add({"sender": "ai", "text": "Mock AI response to: '$query'"});
        });
      });

      // Clear the input after sending
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'AI Chatbot',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: ColorPalette.offWhite,
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.chevron_left,
            size: 32,
            color: ColorPalette.offWhite,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const FaIcon(
              FontAwesomeIcons.sliders,
              color: ColorPalette.offWhite,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
          ),
        ],
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
            padding: const EdgeInsets.only(top: 120.0), // Reduced top padding
            child: Column(
              children: [
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
                // Breadcrumbs
                _messages.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Align(
                          alignment: Alignment
                              .centerLeft, // Align the breadcrumbs to the left
                          child: Wrap(
                            spacing: 16.0,
                            runSpacing: 12.0,
                            children: [
                              _buildBreadcrumb(
                                  'New Idea',
                                  FontAwesomeIcons.lightbulb,
                                  ColorPalette.mustard),
                              _buildBreadcrumb('Something I have',
                                  FontAwesomeIcons.file, Colors.green),
                              _buildBreadcrumb('A popular choice',
                                  FontAwesomeIcons.fire, Colors.orange),
                            ],
                          ),
                        ),
                      )
                    : Container(),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return Align(
                        alignment: message['sender'] == 'user'
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 16.0),
                            decoration: BoxDecoration(
                              color: message['sender'] == 'user'
                                  ? ColorPalette.lightgray
                                  : ColorPalette.darkgray,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              message['text']!,
                              style: TextStyle(
                                color: message['sender'] == 'user'
                                    ? ColorPalette.offBlack
                                    : ColorPalette.offWhite,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16.0), // Added bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to build breadcrumb tags
  Widget _buildBreadcrumb(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {},
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
