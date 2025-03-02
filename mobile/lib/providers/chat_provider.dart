import 'package:flutter/material.dart';

class ChatProvider with ChangeNotifier {
  List<Map<String, dynamic>> _messages = [];

  List<Map<String, dynamic>> get messages => _messages;

  void addMessage(
      {String sender = "ai",
      String text = "",
      bool isLoading = false,
      bool isRecipeLoading = false}) {
    if (_messages.isEmpty || _messages.last["text"] != "") {
      final message = {
        "sender": sender,
        "text": text,
        "isLoading": isLoading,
        "isRecipeLoading": isRecipeLoading,
      };
      _messages.add(message);
      notifyListeners();
    }
  }

  void updateLastMessage(String text) {
    if (_messages.isNotEmpty) {
      _messages.last["text"] = text;
      _messages.last["isLoading"] = false;
      _messages.last["isRecipeLoading"] = false;

      notifyListeners();
    }
  }

  void setLastMessageLoadingState(bool isLoading) {
    if (_messages.isNotEmpty) {
      _messages.last["isLoading"] = isLoading;
      notifyListeners();
    }
  }

  void setLastMessageRecipeLoadingState(bool isRecipeLoading) {
    if (_messages.isNotEmpty) {
      _messages.last["isRecipeLoading"] = isRecipeLoading;
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages.clear();
    notifyListeners();
  }

  void removeLastMessage() {
    if (_messages.isNotEmpty) {
      _messages.removeLast();
      notifyListeners();
    }
  }
}
