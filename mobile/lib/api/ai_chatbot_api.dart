import 'dart:convert';
import 'dart:io';

import 'package:mobile/api/api_helper.dart';
import 'package:mobile/api/auth_api.dart';

class AiChatbotApi {
  final ApiHelper _apiHelper = ApiHelper();

  get http => null;

  Stream<String> chatWithBotStream(
      String query, List<Map<String, String>>? chatHistory) async* {
    var data = jsonEncode({
      'query': query,
      'chat_history': chatHistory ?? [],
    });

    final headers = await AuthApi.getAuthHeader();

    var url = Uri.parse('${_apiHelper.baseUrl}/ai/chat/');
    var request = http.Request("POST", url)
      ..headers.addAll(headers, {
        'Accept': 'text/event-stream',
      })
      ..body = data;

    var streamedResponse = await http.Client().send(request);

    if (streamedResponse.statusCode == 200) {
      var stream = streamedResponse.stream.transform(utf8.decoder);

      await for (var chunk in stream) {
        yield chunk;
      }
    } else {
      throw Exception(
          'Failed to connect to chatbot: ${streamedResponse.statusCode}');
    }
  }

  Future<Map<String, dynamic>> uploadRecipeImage(File image) async {
    return await _apiHelper.uploadFile(
      'ai/ocr/',
      image,
    );
  }
}
