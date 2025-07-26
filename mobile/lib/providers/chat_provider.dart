import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/ai_chatbot_api.dart';
import 'package:i_cant_cook/mixins/scroll_mixin.dart';

class ChatProvider extends ChangeNotifier with ScrollMixin {
  final TextEditingController chatController = TextEditingController();

  List<Map<String, dynamic>> _globalMessages = [];
  Map<int, List<Map<String, dynamic>>> _recipeChats = {};
  int? _currentRecipeId;

  List<Map<String, dynamic>> get globalMessages => _globalMessages;
  
  List<Map<String, dynamic>> get recipeMessages {
    if (_currentRecipeId == null) return [];
    return _recipeChats[_currentRecipeId!] ?? [];
  }

  List<Map<String, dynamic>> get currentMessages =>
      _currentRecipeId != null ? recipeMessages : _globalMessages;

  void setCurrentRecipe(int recipeId) {
    if (_currentRecipeId != recipeId) {
      _currentRecipeId = recipeId;
      // Initialize empty chat for this recipe if it doesn't exist
      if (!_recipeChats.containsKey(recipeId)) {
        _recipeChats[recipeId] = [];
      }
      notifyListeners();
    }
  }

  void setGlobalChat() {
    if (_currentRecipeId != null) {
      _currentRecipeId = null;
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
      final messages = isRecipeChat ? recipeMessages : _globalMessages;
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
                    ? recipeMessages.last['text']
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
    if (isRecipeChat && _currentRecipeId != null) {
      if (!_recipeChats.containsKey(_currentRecipeId!)) {
        _recipeChats[_currentRecipeId!] = [];
      }
      final messages = _recipeChats[_currentRecipeId!]!;
      
      if (messages.isEmpty || messages.last["text"] != "") {
        messages.add({
          "sender": sender,
          "text": text,
          "isLoading": isLoading,
          "isRecipeLoading": isRecipeLoading,
        });
        notifyListeners();
      }
    } else if (!isRecipeChat) {
      if (_globalMessages.isEmpty || _globalMessages.last["text"] != "") {
        _globalMessages.add({
          "sender": sender,
          "text": text,
          "isLoading": isLoading,
          "isRecipeLoading": isRecipeLoading,
        });
        notifyListeners();
      }
    }
  }

  void updateLastMessage(String text, {bool isRecipeChat = false}) {
    if (isRecipeChat && _currentRecipeId != null) {
      final messages = _recipeChats[_currentRecipeId!];
      if (messages != null && messages.isNotEmpty) {
        messages.last["text"] = text;
        messages.last["isLoading"] = false;
        messages.last["isRecipeLoading"] = false;
        notifyListeners();
      }
    } else if (!isRecipeChat) {
      if (_globalMessages.isNotEmpty) {
        _globalMessages.last["text"] = text;
        _globalMessages.last["isLoading"] = false;
        _globalMessages.last["isRecipeLoading"] = false;
        notifyListeners();
      }
    }
  }

  void setLastMessageLoadingState(bool isLoading, {bool isRecipeChat = false}) {
    if (isRecipeChat && _currentRecipeId != null) {
      final messages = _recipeChats[_currentRecipeId!];
      if (messages != null && messages.isNotEmpty) {
        messages.last["isLoading"] = isLoading;
        notifyListeners();
      }
    } else if (!isRecipeChat && _globalMessages.isNotEmpty) {
      _globalMessages.last["isLoading"] = isLoading;
      notifyListeners();
    }
  }

  void setLastMessageRecipeLoadingState(bool isRecipeLoading,
      {bool isRecipeChat = false}) {
    if (isRecipeChat && _currentRecipeId != null) {
      final messages = _recipeChats[_currentRecipeId!];
      if (messages != null && messages.isNotEmpty) {
        messages.last["isRecipeLoading"] = isRecipeLoading;
        notifyListeners();
      }
    } else if (!isRecipeChat && _globalMessages.isNotEmpty) {
      _globalMessages.last["isRecipeLoading"] = isRecipeLoading;
      notifyListeners();
    }
  }

  void clearMessages({bool isRecipeChat = false}) {
    if (isRecipeChat && _currentRecipeId != null) {
      _recipeChats[_currentRecipeId!] = [];
      notifyListeners();
    } else if (!isRecipeChat) {
      _globalMessages.clear();
      notifyListeners();
    }
  }

  void removeLastMessage({bool isRecipeChat = false}) {
    if (isRecipeChat && _currentRecipeId != null) {
      final messages = _recipeChats[_currentRecipeId!];
      if (messages != null && messages.isNotEmpty) {
        messages.removeLast();
        notifyListeners();
      }
    } else if (!isRecipeChat && _globalMessages.isNotEmpty) {
      _globalMessages.removeLast();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    disposeScroll(); // from ScrollMixin
    super.dispose();
  }
}
