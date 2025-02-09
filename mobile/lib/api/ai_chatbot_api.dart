import 'dart:io';

import 'package:mobile/api/api_helper.dart';

class AiChatbotApi {
  final ApiHelper _apiHelper = ApiHelper();

  Future<Map<String, dynamic>?> chatWithBot(String query, List<Map<String, String>>? chatHistory) async {
    var data = {
      'query': query,
      'chat_history': chatHistory ?? [],
    };
    return await _apiHelper.postRequest('ai/chat/', data);
  }

  Future<Map<String, dynamic>?> generateRecipe(String query) async {
    var data = {
      'query': query,
    };
    return await _apiHelper.postRequest('ai/chat/', data);
  }

  Future<Map<String, dynamic>?> getRecipe(String recipeName) async {
    var data = {
      'query': recipeName,
    };
    return await _apiHelper.postRequest('ai/chat/', data);
  }

    Future<Map<String, dynamic>?> uploadRecipeImage(File image) async {
    var response = await _apiHelper.uploadFile(
      'ai/ocr/',
      image,
    );

    return response;
  }
}
