import 'dart:convert';
import 'dart:io';

import 'package:i_cant_cook/api/api_helper.dart';
import 'package:i_cant_cook/api/auth_api.dart';

class AiChatbotApi {
  final ApiHelper _apiHelper = ApiHelper();

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
}
