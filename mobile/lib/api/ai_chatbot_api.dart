import 'dart:io';

import 'package:mobile/api/api_helper.dart';

class AiChatbotApi {
  final ApiHelper _apiHelper = ApiHelper();

  Future<String> chatWithBot(
      String query, List<Map<String, String>>? chatHistory) async {
    var data = {
      'query': query,
      'chat_history': chatHistory ?? [],
    };
    return await _apiHelper.postRequest('ai/chat/', data);
  }

  Future<Map<String, dynamic>> uploadRecipeImage(File image) async {
    return await _apiHelper.uploadFile(
      'ai/ocr/',
      image,
    );
  }
}
