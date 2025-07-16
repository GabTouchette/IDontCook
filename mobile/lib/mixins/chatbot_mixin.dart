import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/ai_chatbot_api.dart';
import 'package:i_cant_cook/providers/chat_provider.dart';

mixin ChatBotMixin<T extends StatefulWidget> on State<T> {
  final TextEditingController chatController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  void sendMessageWithContext(
    String query,
    ChatProvider provider, {
    int? recipeId,
    bool isRecipeChat = false,
  }) async {
    if (query.isEmpty) return;

    provider.addMessage(
        sender: "user", text: query, isRecipeChat: isRecipeChat);
    chatController.clear();
    scrollToBottom();

    try {
      List<Map<String, String>> history = [];
      final messages =
          isRecipeChat ? provider.recipeMessages : provider.globalMessages;
      int historyLength = messages.length - 1;
      int start = (historyLength >= 5) ? historyLength - 5 : 0;

      for (int i = start; i < historyLength; i++) {
        history.add({
          "message": messages[i]['text'] ?? '',
          "sender": messages[i]['sender'] ?? ''
        });
      }

      provider.addMessage(
          isLoading: true, isRecipeLoading: true, isRecipeChat: isRecipeChat);
      final stream =
          AiChatbotApi().chatWithBotStream(query, history, recipeId: recipeId);

      bool recipeTagOpen = false;
      String recipeBuffer = "";

      await for (String token in stream) {
        if (recipeTagOpen) {
          recipeBuffer += token;
          if (token.trim() == "\$\$" ||
              token.trim() == "&&" ||
              token.trim() == "@@") {
            provider.addMessage(isRecipeChat: isRecipeChat);
            recipeTagOpen = false;
            provider.updateLastMessage(recipeBuffer,
                isRecipeChat: isRecipeChat);
            recipeBuffer = "";
          }
        } else {
          if (token.trim() == "\$\$" ||
              token.trim() == "&&" ||
              token.trim() == "@@") {
            recipeTagOpen = true;
            recipeBuffer += token;
            provider.addMessage(
                isRecipeLoading: true, isRecipeChat: isRecipeChat);
          } else {
            provider.updateLastMessage(
              (isRecipeChat
                      ? provider.recipeMessages.last['text'] ?? ''
                      : provider.globalMessages.last['text'] ?? '') +
                  token,
              isRecipeChat: isRecipeChat,
            );
          }
        }
      }
    } catch (e) {
      provider.removeLastMessage(isRecipeChat: isRecipeChat);
      provider.addMessage(
          text: "Error: ${e.toString()}", isRecipeChat: isRecipeChat);
    } finally {
      scrollToBottom();
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    chatController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
