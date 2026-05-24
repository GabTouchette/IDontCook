import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/ai_chatbot_api.dart';
import 'package:i_cant_cook/mixins/scroll_mixin.dart';

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<Map<String, dynamic>> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
  });
}

class ChatProvider extends ChangeNotifier with ScrollMixin {
  final TextEditingController chatController = TextEditingController();

  List<Map<String, dynamic>> _globalMessages = [];
  Map<int, List<Map<String, dynamic>>> _recipeChats = {};
  int? _currentRecipeId;
  final List<ChatSession> _savedChats = [];

  List<Map<String, dynamic>> get globalMessages => _globalMessages;
  
  List<Map<String, dynamic>> get recipeMessages {
    if (_currentRecipeId == null) return [];
    return _recipeChats[_currentRecipeId!] ?? [];
  }

  List<Map<String, dynamic>> get currentMessages =>
      _currentRecipeId != null ? recipeMessages : _globalMessages;

  List<ChatSession> get savedChats => List.unmodifiable(_savedChats);

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

      const delimiters = [r'$$', '&&', '@@'];
      String accumulated = "";
      bool inRecipe = false;
      String openDelim = "";

      await for (String token in stream) {
        accumulated += token;

        if (!inRecipe) {
          // Scan for the earliest opening delimiter
          String? found;
          int foundIdx = -1;
          for (final d in delimiters) {
            final idx = accumulated.indexOf(d);
            if (idx != -1 && (foundIdx == -1 || idx < foundIdx)) {
              found = d;
              foundIdx = idx;
            }
          }

          if (found != null) {
            // Transition to recipe buffering mode
            final beforeText = accumulated.substring(0, foundIdx);
            if (beforeText.trim().isNotEmpty) {
              updateLastMessage(beforeText, isRecipeChat: isRecipeChat);
              addMessage(isRecipeLoading: true, isRecipeChat: isRecipeChat);
            }
            // If no text before, the initial isRecipeLoading bubble remains
            inRecipe = true;
            openDelim = found;
            accumulated = accumulated.substring(foundIdx);
            scrollToBottom();
          } else {
            // Plain text — update bubble in real-time
            updateLastMessage(accumulated, isRecipeChat: isRecipeChat);
            scrollToBottom();
          }
        } else {
          // Inside recipe block — wait for closing delimiter
          final closeIdx = accumulated.indexOf(openDelim, openDelim.length);
          if (closeIdx != -1) {
            final delimLen = openDelim.length;
            final recipeBlock =
                accumulated.substring(0, closeIdx + delimLen);
            updateLastMessage(recipeBlock, isRecipeChat: isRecipeChat);

            inRecipe = false;
            openDelim = "";
            accumulated =
                accumulated.substring(closeIdx + delimLen).trim();

            if (accumulated.isNotEmpty) {
              addMessage(isRecipeChat: isRecipeChat);
              updateLastMessage(accumulated, isRecipeChat: isRecipeChat);
            }
            scrollToBottom();
          }
          // Still buffering — keep isRecipeLoading animation visible, no update
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

  void _saveCurrentToHistory() {
    if (_globalMessages.isEmpty) return;
    final firstUserMsg = _globalMessages.firstWhere(
      (m) => m['sender'] == 'user',
      orElse: () => {'text': 'New chat'},
    );
    final rawTitle = (firstUserMsg['text'] as String?)?.trim() ?? 'New chat';
    final title =
        rawTitle.length > 40 ? '${rawTitle.substring(0, 40)}\u2026' : rawTitle;
    final session = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      createdAt: DateTime.now(),
      messages: List<Map<String, dynamic>>.from(
        _globalMessages.map((m) => Map<String, dynamic>.from(m)),
      ),
    );
    _savedChats.insert(0, session);
    if (_savedChats.length > 5) _savedChats.removeLast();
  }

  void startNewChat() {
    _saveCurrentToHistory();
    _globalMessages.clear();
    notifyListeners();
  }

  void restoreSession(int index) {
    if (index < 0 || index >= _savedChats.length) return;
    _saveCurrentToHistory();
    final session = _savedChats.removeAt(index);
    _globalMessages = List<Map<String, dynamic>>.from(
      session.messages.map((m) => Map<String, dynamic>.from(m)),
    );
    notifyListeners();
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
