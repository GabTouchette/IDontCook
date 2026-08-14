import 'dart:async';

import 'package:flutter/material.dart';
import 'package:i_cant_cook/api/ai_chatbot_api.dart';
import 'package:i_cant_cook/mixins/scroll_mixin.dart';
import 'package:i_cant_cook/models/block/block.dart';
import 'package:i_cant_cook/models/mood/mood.dart';

/// A chat v2 message: an ordered list of typed [Block]s (plan §1.1/§1.6).
/// The streamed assistant text is itself one or more `text` blocks,
/// interleaved with tool-produced blocks (recipe, recipe_ref, ...).
class ChatV2Message {
  final String sender; // 'user' | 'ai'
  final List<Block> blocks;
  final bool isLoading;

  /// When true, the turn is part of the conversation (and is sent to the
  /// backend as history) but should NOT be rendered — used for the synthetic
  /// user prompt behind a mood-pill tap, so the conversation reads as the
  /// assistant simply opening the topic rather than the user "saying" a line
  /// they never typed.
  final bool hidden;

  const ChatV2Message({
    required this.sender,
    this.blocks = const <Block>[],
    this.isLoading = false,
    this.hidden = false,
  });

  bool get isUser => sender == 'user';

  /// Concatenated text of all text blocks (e.g. for history previews).
  String get plainText =>
      blocks.whereType<TextBlock>().map((block) => block.text).join('\n');

  ChatV2Message copyWith({List<Block>? blocks, bool? isLoading, bool? hidden}) {
    return ChatV2Message(
      sender: sender,
      blocks: blocks ?? this.blocks,
      isLoading: isLoading ?? this.isLoading,
      hidden: hidden ?? this.hidden,
    );
  }
}

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
  ChatProvider({AiChatbotApi? api}) : _api = api ?? AiChatbotApi();

  final AiChatbotApi _api;
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

  /// Detects if a message contains a URL
  bool _containsUrl(String text) {
    final urlPattern = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)',
      caseSensitive: false,
    );
    return urlPattern.hasMatch(text);
  }

  /// Extracts URL from text (assumes single URL)
  String? _extractUrl(String text) {
    final urlPattern = RegExp(
      r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)',
      caseSensitive: false,
    );
    final match = urlPattern.firstMatch(text);
    return match?.group(0);
  }

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

    final trimmedQuery = query.trim();

    // Check if message contains a URL — auto-route to recipe import
    if (_containsUrl(trimmedQuery)) {
      final url = _extractUrl(trimmedQuery);
      if (url != null) {
        addMessage(sender: "user", text: trimmedQuery, isRecipeChat: isRecipeChat);
        scrollToBottom();
        await importRecipeFromUrl(url);
        return;
      }
    }

    // Otherwise, handle as normal chat message
    addMessage(sender: "user", text: trimmedQuery, isRecipeChat: isRecipeChat);
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

      final stream = _api
          .chatWithBotStream(trimmedQuery, history, recipeId: recipeId)
          .timeout(const Duration(seconds: 30));

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
    } on TimeoutException {
      removeLastMessage(isRecipeChat: isRecipeChat);
      addMessage(
        text: "Request timed out. Please check your connection and try again.",
        isRecipeChat: isRecipeChat,
      );
    } catch (e) {
      removeLastMessage(isRecipeChat: isRecipeChat);
      addMessage(text: "Error: ${e.toString()}", isRecipeChat: isRecipeChat);
    } finally {
      scrollToBottom();
    }
  }

  // ---------------------------------------------------------------------
  // Chat v2 (typed SSE events, plan §1.6) — used by the conversational home
  // (Wave 2). The v1 delimiter path above stays functional until then.
  // ---------------------------------------------------------------------

  final List<ChatV2Message> _v2Messages = [];
  int? _v2ConversationId;
  bool _isV2Sending = false;
  String? _v2LastError;
  String? _v2ActivityLabel;

  /// Monotonic id bumped every time the conversation is reset (or otherwise
  /// invalidated). Each [sendMessageV2] call captures the current value; an
  /// in-flight stream whose captured id no longer matches has been superseded
  /// (e.g. the user switched moods mid-stream) and stops touching state,
  /// which prevents it writing to a now-cleared message list.
  int _v2Generation = 0;

  List<ChatV2Message> get v2Messages => List.unmodifiable(_v2Messages);
  int? get v2ConversationId => _v2ConversationId;
  bool get isV2Sending => _isV2Sending;

  /// Human-readable label for the "data tool" (e.g. `search_recipes`)
  /// currently in flight for the message being streamed — e.g. "Searching
  /// the cookbook…" — or `null` when no tool call is active. Used by the
  /// typing indicator to replace the bare dots with a labeled state (plan
  /// §1.3 / WS-P4). Cleared on `done`, `error`, and at the start of every
  /// new [sendMessageV2] call so it never lingers into an unrelated turn.
  String? get v2ActivityLabel => _v2ActivityLabel;

  /// Maps a `tool_activity` event's raw tool name to a human label. New
  /// data tools only need an entry here; unrecognized names (forward-compat
  /// — a server rollout may add tools before this app is updated) fall back
  /// to a generic in-progress label rather than showing nothing or crashing.
  static String _activityLabelFor(String tool) {
    switch (tool) {
      case 'search_recipes':
        return 'Searching the cookbook…';
      default:
        return 'Working on it…';
    }
  }

  /// Last v2 error message, for surfacing via `InformationToast.show(...,
  /// type: ToastType.error)` — see also the `onError` callback of
  /// [sendMessageV2].
  String? get v2LastError => _v2LastError;

  /// Seeds the v2 thread with an assistant message (e.g. the home feed's
  /// greeting + module blocks rendered as the opening message in Wave 2).
  void addV2AssistantMessage(List<Block> blocks) {
    _v2Messages.add(ChatV2Message(sender: 'ai', blocks: blocks));
    notifyListeners();
  }

  /// Appends a plain user turn without hitting the network — used for
  /// client-side actions the user takes that should still read as part of
  /// the conversation (e.g. picking a mood), as opposed to [sendMessageV2]
  /// which round-trips to the chat v2 endpoint.
  void addV2UserMessage(String text) {
    _v2Messages.add(ChatV2Message(sender: 'user', blocks: [Block.text(text: text)]));
    notifyListeners();
  }

  /// Replaces the blocks of the message at [index] in place, keeping its
  /// position in the thread. Used when a mood selection (or "change mood")
  /// re-ranks the feed: message 0's cards update where they sit instead of a
  /// duplicate feed being appended below. No-ops if [index] is out of range.
  void replaceV2Message(int index, List<Block> blocks) {
    if (index < 0 || index >= _v2Messages.length) return;
    _v2Messages[index] = _v2Messages[index].copyWith(blocks: blocks);
    notifyListeners();
  }

  /// Clears the v2 thread and forgets the server-side conversation id.
  void resetV2Conversation() {
    // Invalidate any in-flight stream so it stops mutating the (now cleared)
    // message list, and drop the sending flag so a fresh turn can start
    // immediately (e.g. switching moods while a reply is still streaming).
    _v2Generation++;
    _v2Messages.clear();
    _v2ConversationId = null;
    _v2LastError = null;
    _v2ActivityLabel = null;
    _isV2Sending = false;
    notifyListeners();
  }

  /// Sends [message] over the chat v2 protocol and builds the assistant
  /// reply from typed SSE events: `text_delta`s accumulate into text blocks,
  /// each `block` event appends a typed [Block], `error` surfaces through
  /// [onError] (wire it to the app's `InformationToast` error toast), and
  /// `done` finalizes the message.
  ///
  /// [chatContext] is one of `"home" | "global" | "recipe_edit"` (plan
  /// §1.6); [homeFeed] is the raw feed response being replied to.
  Future<void> sendMessageV2({
    required String message,
    String chatContext = 'global',
    int? recipeId,
    Mood? mood,
    Map<String, dynamic>? homeFeed,
    bool hideUserMessage = false,
    void Function(String errorMessage)? onError,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || _isV2Sending) return;

    // Snapshot the generation; a reset (e.g. mood switch) bumps it and this
    // send treats itself as superseded — see [_v2Generation].
    final int myGen = _v2Generation;

    _v2LastError = null;
    _isV2Sending = true;
    _v2ActivityLabel = null;
    _v2Messages.add(ChatV2Message(
        sender: 'user',
        blocks: [Block.text(text: trimmed)],
        hidden: hideUserMessage));
    _v2Messages
        .add(const ChatV2Message(sender: 'ai', isLoading: true));
    notifyListeners();
    scrollToBottom();

    final assistantIndex = _v2Messages.length - 1;
    // Whether the next text_delta extends the trailing text block or opens a
    // new one (a block event in between splits the text).
    bool appendToOpenTextBlock = false;

    void updateAssistant(
        ChatV2Message Function(ChatV2Message current) update) {
      // Superseded by a reset, or the list was cleared out from under us.
      if (myGen != _v2Generation || assistantIndex >= _v2Messages.length) {
        return;
      }
      _v2Messages[assistantIndex] = update(_v2Messages[assistantIndex]);
      notifyListeners();
    }

    void appendErrorText(String errorMessage) {
      // A superseded send (mood switch / reset) must not surface its error —
      // the conversation it belonged to is already gone.
      if (myGen != _v2Generation) return;
      _v2LastError = errorMessage;
      _v2ActivityLabel = null;
      appendToOpenTextBlock = false;
      updateAssistant((current) => current.copyWith(
            blocks: [...current.blocks, Block.text(text: errorMessage)],
            isLoading: false,
          ));
      onError?.call(errorMessage);
    }

    try {
      final stream = _api
          .chatWithBotStreamV2(
            message: trimmed,
            conversationId: _v2ConversationId,
            context: chatContext,
            recipeId: recipeId,
            mood: mood,
            homeFeed: homeFeed,
          )
          .timeout(const Duration(seconds: 30));

      await for (final event in stream) {
        // Superseded mid-stream (mood switch / reset): stop consuming so we
        // don't mutate a conversation that's already been torn down.
        if (myGen != _v2Generation) break;
        event.when(
          messageStart: (conversationId) {
            if (conversationId != null) {
              _v2ConversationId = conversationId;
            }
          },
          textDelta: (text) {
            updateAssistant((current) {
              final blocks = List<Block>.of(current.blocks);
              if (appendToOpenTextBlock &&
                  blocks.isNotEmpty &&
                  blocks.last is TextBlock) {
                final openBlock = blocks.last as TextBlock;
                blocks[blocks.length - 1] =
                    Block.text(text: openBlock.text + text);
              } else {
                blocks.add(Block.text(text: text));
                appendToOpenTextBlock = true;
              }
              return current.copyWith(blocks: blocks, isLoading: false);
            });
            scrollToBottom();
          },
          block: (block) {
            appendToOpenTextBlock = false;
            _v2ActivityLabel = null;
            updateAssistant((current) => current.copyWith(
                  blocks: [...current.blocks, block],
                  isLoading: false,
                ));
            scrollToBottom();
          },
          toolActivity: (tool) {
            _v2ActivityLabel = _activityLabelFor(tool);
            notifyListeners();
          },
          error: (errorMessage) {
            appendErrorText(errorMessage.isEmpty
                ? 'Something went wrong. Please try again.'
                : errorMessage);
          },
          done: () {
            _v2ActivityLabel = null;
            updateAssistant((current) => current.copyWith(isLoading: false));
          },
          unknown: () {
            // Forward-compat: ignore event types this app version
            // doesn't know about.
          },
        );
      }
    } on TimeoutException {
      appendErrorText(
          'Request timed out. Please check your connection and try again.');
    } catch (e) {
      appendErrorText('Error: ${e.toString()}');
    } finally {
      // Only clean up if this send is still the current one — a superseding
      // reset already reset these flags and cleared the list.
      if (myGen == _v2Generation) {
        if (assistantIndex < _v2Messages.length &&
            _v2Messages[assistantIndex].isLoading) {
          _v2Messages[assistantIndex] =
              _v2Messages[assistantIndex].copyWith(isLoading: false);
        }
        _isV2Sending = false;
        _v2ActivityLabel = null;
        notifyListeners();
        scrollToBottom();
      }
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

  void clearRecipeChat() {
    if (_currentRecipeId != null) {
      _recipeChats[_currentRecipeId!] = [];
      notifyListeners();
    }
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

  Future<void> importRecipeFromUrl(String url) async {
    addMessage(isLoading: true, isRecipeLoading: true);
    scrollToBottom();

    try {
      final result = await _api.importRecipeFromUrl(url);
      final response = result?['response'] as String?;

      if (response == null || response.trim() == '\$\$ null \$\$' || response.trim().isEmpty) {
        updateLastMessage("Sorry, I couldn't find a recipe at that URL.");
        return;
      }

      updateLastMessage(response);
    } catch (e) {
      updateLastMessage("Failed to import recipe: ${e.toString()}");
    } finally {
      scrollToBottom();
    }
  }

  @override
  void dispose() {
    disposeScroll(); // from ScrollMixin
    super.dispose();
  }
}
