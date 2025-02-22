import 'dart:convert';
import 'dart:io';

import 'package:i_cant_cook/api/api_helper.dart';
import 'package:i_cant_cook/api/auth_api.dart';

class AiChatbotApi {
  final ApiHelper _apiHelper = ApiHelper();

  Stream<String> chatWithBotStream(
      String query, List<Map<String, String>>? chatHistory) async* {
    var data = jsonEncode({
      'query': query,
      'chat_history': chatHistory ?? [],
    });

    final headers = await AuthApi.getAuthHeader();
    yield* _apiHelper.streamResponse('ai/chat/', data, headers);
  }

  Future<Map<String, dynamic>> uploadRecipeImage(File image) async {
    return await _apiHelper.uploadFile(
      'ai/ocr/',
      image,
    );
  }
}
