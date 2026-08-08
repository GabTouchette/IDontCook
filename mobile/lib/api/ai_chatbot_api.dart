import 'dart:convert';
import 'dart:io';

import 'package:i_cant_cook/api/api_helper.dart';
import 'package:i_cant_cook/api/auth_api.dart';
import 'package:i_cant_cook/models/chat_v2_event/chat_v2_event.dart';
import 'package:i_cant_cook/models/mood/mood.dart';

class AiChatbotApi {
  final ApiHelper _apiHelper = ApiHelper();

  /// Chat SSE protocol v2 (plan §1.6): `POST /api/ai/chat/v2/` with typed
  /// events instead of the v1 `$$`/`&&`/`@@` delimiter protocol.
  ///
  /// [context] is one of `"home" | "global" | "recipe_edit"`; [recipeId] is
  /// only meaningful for `recipe_edit`; [homeFeed] is the raw feed response
  /// the user is replying to (home context). Conversation history is kept
  /// server-side — only the new [message] and [conversationId] are sent.
  ///
  /// Malformed events are skipped; unknown event types come through as
  /// [ChatV2Event.unknown].
  Stream<ChatV2Event> chatWithBotStreamV2({
    required String message,
    int? conversationId,
    String context = 'global',
    int? recipeId,
    Mood? mood,
    Map<String, dynamic>? homeFeed,
  }) async* {
    final payload = {
      'message': message,
      'conversation_id': conversationId,
      'context': context,
      if (recipeId != null) 'recipe_id': recipeId,
      'mood': mood?.wireValue,
      'home_feed': homeFeed,
    };

    final data = jsonEncode(payload);
    final headers = await AuthApi.getAuthHeader();

    await for (final rawEvent
        in _apiHelper.streamSseEvents('ai/chat/v2/', data, headers)) {
      ChatV2Event event;
      try {
        event = ChatV2Event.fromJson(rawEvent);
      } catch (_) {
        // A malformed event must never kill the stream.
        continue;
      }
      yield event;
    }
  }

  Stream<String> chatWithBotStream(
    String query,
    List<Map<String, String>>? chatHistory, {
    int? recipeId,
  }) async* {
    final payload = {
      'query': query,
      'chat_history': chatHistory ?? [],
      if (recipeId != null) 'recipe_id': recipeId,
    };

    var data = jsonEncode(payload);
    final headers = await AuthApi.getAuthHeader();
    yield* _apiHelper.streamResponse('ai/chat/', data, headers);
  }

  Future<Map<String, dynamic>?> uploadRecipeImages(List<File> images) async {
    final result = await _apiHelper.uploadMultipleFiles('ai/ocr/', images);
    if (result == null) return null;
    return result as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> importRecipeFromUrl(String url) async {
    return await _apiHelper.postRequest('ai/import-url/', {'url': url});
  }
}
