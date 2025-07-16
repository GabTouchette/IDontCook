import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/ai_chatbot_api.dart';
import 'package:i_cant_cook/mixins/scroll_mixin.dart';

class ChatProvider extends ChangeNotifier with ScrollMixin {
  final TextEditingController chatController = TextEditingController();

  List<Map<String, dynamic>> _globalMessages = [];
  List<Map<String, dynamic>> _recipeMessages = [];
  int? _currentRecipeId;

  List<Map<String, dynamic>> get globalMessages => _globalMessages;
  List<Map<String, dynamic>> get recipeMessages => _recipeMessages;

  List<Map<String, dynamic>> get currentMessages =>
      _currentRecipeId != null ? _recipeMessages : _globalMessages;

  void setCurrentRecipe(int recipeId) {
    if (_currentRecipeId != recipeId) {
      _currentRecipeId = recipeId;
      _recipeMessages.clear();
      notifyListeners();
    }
  }

  Future<void> sendMessage({
    required String query,
    int? recipeId,
    bool isRecipeChat = false,
  }) async {
    if (query.trim().isEmpty) return;

    addMessage(sender: "user", text: query, isRecipeChat: isRecipeChat);
    scrollToBottom();

    try {
      List<Map<String, String>> history = [];
      final messages = isRecipeChat ? _recipeMessages : _globalMessages;
      int historyLength = messages.length - 1;
      int start = (historyLength >= 5) ? historyLength - 5 : 0;

      for (int i = start; i < historyLength; i++) {
        history.add({
          "message": messages[i]['text'] ?? '',
          "sender": messages[i]['sender'] ?? '',
        });
      }

      chatController.clear();

      addMessage(
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
            addMessage(isRecipeChat: isRecipeChat);
            recipeTagOpen = false;
            updateLastMessage(recipeBuffer, isRecipeChat: isRecipeChat);
            recipeBuffer = "";
          }
        } else {
          if (token.trim() == "\$\$" ||
              token.trim() == "&&" ||
              token.trim() == "@@") {
            recipeTagOpen = true;
            recipeBuffer += token;
            addMessage(isRecipeLoading: true, isRecipeChat: isRecipeChat);
          } else {
            final currentText = (isRecipeChat
                    ? _recipeMessages.last['text']
                    : _globalMessages.last['text']) ??
                '';
            updateLastMessage(currentText + token, isRecipeChat: isRecipeChat);
          }
        }
      }
    } catch (e) {
      removeLastMessage(isRecipeChat: isRecipeChat);
      addMessage(text: "Error: ${e.toString()}", isRecipeChat: isRecipeChat);
    } finally {
      scrollToBottom();
    }
  }

  void addMessage({
    bool isRecipeChat = false,
    String sender = "ai",
    String text = "",
    bool isLoading = false,
    bool isRecipeLoading = false,
  }) {
    final messages = isRecipeChat ? _recipeMessages : _globalMessages;

    if (messages.isEmpty || messages.last["text"] != "") {
      messages.add({
        "sender": sender,
        "text": text,
        "isLoading": isLoading,
        "isRecipeLoading": isRecipeLoading,
      });
      notifyListeners();
    }
  }

  void updateLastMessage(String text, {bool isRecipeChat = false}) {
    final messages = isRecipeChat ? _recipeMessages : _globalMessages;

    if (messages.isNotEmpty) {
      messages.last["text"] = text;
      messages.last["isLoading"] = false;
      messages.last["isRecipeLoading"] = false;
      notifyListeners();
    }
  }

  void setLastMessageLoadingState(bool isLoading, {bool isRecipeChat = false}) {
    final messages = isRecipeChat ? _recipeMessages : _globalMessages;

    if (messages.isNotEmpty) {
      messages.last["isLoading"] = isLoading;
      notifyListeners();
    }
  }

  void setLastMessageRecipeLoadingState(bool isRecipeLoading,
      {bool isRecipeChat = false}) {
    final messages = isRecipeChat ? _recipeMessages : _globalMessages;

    if (messages.isNotEmpty) {
      messages.last["isRecipeLoading"] = isRecipeLoading;
      notifyListeners();
    }
  }

  void clearMessages({bool isRecipeChat = false}) {
    final messages = isRecipeChat ? _recipeMessages : _globalMessages;
    messages.clear();
    notifyListeners();
  }

  void removeLastMessage({bool isRecipeChat = false}) {
    final messages = isRecipeChat ? _recipeMessages : _globalMessages;

    if (messages.isNotEmpty) {
      messages.removeLast();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disposeScroll(); // from ScrollMixin
    super.dispose();
  }
}
