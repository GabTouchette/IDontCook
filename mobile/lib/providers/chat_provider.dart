import 'package:flutter/material.dart';

class ChatProvider with ChangeNotifier {
  List<Map<String, dynamic>> _globalMessages = [];
  List<Map<String, dynamic>> _recipeMessages = [];
  int? _currentRecipeId;

  List<Map<String, dynamic>> get globalMessages => _globalMessages;
  List<Map<String, dynamic>> get recipeMessages => _recipeMessages;

  void setCurrentRecipe(int recipeId) {
    if (_currentRecipeId != recipeId) {
      _currentRecipeId = recipeId;
      _recipeMessages.clear();
      notifyListeners();
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
      final message = {
        "sender": sender,
        "text": text,
        "isLoading": isLoading,
        "isRecipeLoading": isRecipeLoading,
      };
      messages.add(message);
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
}
