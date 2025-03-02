import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'auth_api.dart';

class ApiHelper {
  final String baseUrl = 'http://192.168.0.12:8000/api';
  // final String baseUrl = 'https://i-cant-cook-1500fc1d933c.herokuapp.com/api';

  Future<dynamic> getRequest(
    String endpoint, {
    bool requiresAuth = true,
    Map<String, String>? queryParams,
  }) async {
    try {
      final headers = requiresAuth
          ? await AuthApi.getAuthHeader()
          : {'Content-Type': 'application/json'};

      final uri = Uri.parse('$baseUrl/$endpoint').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: headers,
      );
      return _handleResponse(response);
    } catch (e) {
      print('GET request error: $e');
      return null;
    }
  }

  Future<dynamic> postRequest(String endpoint, Map<String, dynamic> data,
      {bool requiresAuth = true}) async {
    try {
      final headers = requiresAuth
          ? await AuthApi.getAuthHeader()
          : {'Content-Type': 'application/json'};

      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      print('POST request error: $e');
      return null;
    }
  }

  Future<dynamic> putRequest(String endpoint, Map<String, dynamic> data,
      {bool requiresAuth = true}) async {
    try {
      final headers = requiresAuth
          ? await AuthApi.getAuthHeader()
          : {'Content-Type': 'application/json'};

      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      print('PUT request error: $e');
      return null;
    }
  }

  Future<dynamic> patchRequest(String endpoint, Map<String, dynamic> data,
      {bool requiresAuth = true}) async {
    try {
      final headers = requiresAuth
          ? await AuthApi.getAuthHeader()
          : {'Content-Type': 'application/json'};

      final response = await http.patch(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      print('PATCH request error: $e');
      return null;
    }
  }

  Future<bool> deleteRequest(String endpoint,
      {bool requiresAuth = true}) async {
    try {
      final headers = requiresAuth
          ? await AuthApi.getAuthHeader()
          : {'Content-Type': 'application/json'};

      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
      );
      return response.statusCode == 204;
    } catch (e) {
      print('DELETE request error: $e');
      return false;
    }
  }

  Future<dynamic> uploadFile(String endpoint, File file,
      {bool requiresAuth = true}) async {
    try {
      var uri = Uri.parse('$baseUrl/$endpoint');
      var request = http.MultipartRequest('POST', uri);

      if (requiresAuth) {
        final headers = await AuthApi.getAuthHeader();
        request.headers.addAll(headers);
      }

      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      print('File upload error: $e');
      return null;
    }
  }

  Future<String> imageRequest(String endpoint, File imageFile,
      {bool requiresAuth = true}) async {
    try {
      Uri url = Uri.parse('$baseUrl/$endpoint');
      final Map<String, String> headers = requiresAuth
          ? (await AuthApi.getAuthHeader()).cast<String, String>()
          : {};

      var request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);

      var mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      var contentType = MediaType.parse(mimeType);

      request.files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: contentType,
      ));

      var streamedResponse = await request.send();
      dynamic response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data["image_url"];
      } else {
        return "";
      }
    } catch (e) {
      print('Error uploading image: $e');
      return "";
    }
  }

  Stream<String> streamResponse(
      String endpoint, String data, Map<String, String> headers) async* {
    Uri url = Uri.parse('$baseUrl/$endpoint');

    var request = http.Request("POST", url)
      ..headers.addAll(headers)
      ..body = data;

    var client = http.Client();

    try {
      var streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        throw Exception(
            'Failed to connect to chatbot: ${streamedResponse.statusCode}');
      }

      var stream = streamedResponse.stream.transform(utf8.decoder);

      await for (var chunk in stream) {
        for (var line in chunk.split("\n")) {
          if (line.startsWith("data:")) {
            var jsonData = line.substring(5).trim();
            if (jsonData.isNotEmpty) {
              try {
                var decoded = jsonDecode(jsonData);
                if (decoded is Map<String, dynamic> &&
                    decoded.containsKey("token")) {
                  yield decoded["token"];
                }
              } catch (e) {
                print("JSON parse error: $e");
              }
            }
          }
        }
      }
    } finally {
      client.close();
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('API response: ${response.statusCode}, ${response.body}');
      return response.body.isNotEmpty ? json.decode(response.body) : null;
    } else {
      print('API error: ${response.statusCode}, ${response.body}');
      return null;
    }
  }
}
