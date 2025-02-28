import 'dart:async';
import 'package:flutter/material.dart';

class ChatProvider with ChangeNotifier {
  List<Map<String, dynamic>> _messages = [];
  Timer? _debounceTimer;

  List<Map<String, dynamic>> get messages => _messages;

  void addMessage(Map<String, dynamic> message) {
    _messages.add(message);
    notifyListeners();
  }

  void updateLastMessage(String text) {
    if (_messages.isNotEmpty) {
      _messages.last["text"] = text;
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

  void onSearchChanged(String query, Function(String) sendMessage) {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        sendMessage(query);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}