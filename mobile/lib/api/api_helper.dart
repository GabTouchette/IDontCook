import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'auth_api.dart';
import 'api_config.dart';

class ApiHelper {
  Future<dynamic> getRequest(
    String endpoint, {
    bool requiresAuth = true,
    Map<String, String>? queryParams,
  }) async {
    try {
      final headers = requiresAuth
          ? await AuthApi.getAuthHeader()
          : {'Content-Type': 'application/json'};

      final uri = ApiConfig.buildApiUri(
        endpoint,
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
          ApiConfig.buildApiUri(endpoint),
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
          ApiConfig.buildApiUri(endpoint),
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
          ApiConfig.buildApiUri(endpoint),
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
          ApiConfig.buildApiUri(endpoint),
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
      var uri = ApiConfig.buildApiUri(endpoint);
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

  Future<dynamic> uploadMultipleFiles(String endpoint, List<File> files,
      {bool requiresAuth = true}) async {
    try {
      var uri = ApiConfig.buildApiUri(endpoint);
      var request = http.MultipartRequest('POST', uri);

      if (requiresAuth) {
        final headers = await AuthApi.getAuthHeader();
        request.headers.addAll(headers);
      }

      for (final file in files) {
        request.files.add(await http.MultipartFile.fromPath('images', file.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      print('Multiple file upload error: $e');
      return null;
    }
  }

  Future<String> imageRequest(String endpoint, File imageFile,
      {bool requiresAuth = true}) async {
    try {
      Uri url = ApiConfig.buildApiUri(endpoint);
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
        var data = jsonDecode(utf8.decode(response.bodyBytes));
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
    Uri url = ApiConfig.buildApiUri(endpoint);

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

  /// Streams SSE `data:` lines as decoded JSON objects (chat v2 protocol,
  /// plan §1.6). Unlike [streamResponse], this buffers across chunk
  /// boundaries so a JSON event split over two chunks still parses, and it
  /// yields the whole decoded event instead of just a `token` field.
  Stream<Map<String, dynamic>> streamSseEvents(
      String endpoint, String data, Map<String, String> headers) async* {
    Uri url = ApiConfig.buildApiUri(endpoint);

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

      String buffer = '';
      await for (var chunk in streamedResponse.stream.transform(utf8.decoder)) {
        buffer += chunk;
        int newlineIndex;
        while ((newlineIndex = buffer.indexOf('\n')) != -1) {
          final line = buffer.substring(0, newlineIndex);
          buffer = buffer.substring(newlineIndex + 1);
          final event = _decodeSseDataLine(line);
          if (event != null) yield event;
        }
      }

      // Flush a trailing data line without a final newline.
      final event = _decodeSseDataLine(buffer);
      if (event != null) yield event;
    } finally {
      client.close();
    }
  }

  Map<String, dynamic>? _decodeSseDataLine(String rawLine) {
    final line = rawLine.trim();
    if (!line.startsWith('data:')) return null;
    final jsonData = line.substring(5).trim();
    if (jsonData.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonData);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (e) {
      print('SSE JSON parse error: $e');
    }
    return null;
  }

  dynamic _handleResponse(http.Response response) {
    // response.body decodes using the response's declared charset, which
    // defaults to Latin-1 when absent — Django's JSON responses don't
    // declare one, so any non-ASCII character (em dashes, curly quotes,
    // accents) gets mangled. Decode the raw bytes as UTF-8 explicitly.
    final body = utf8.decode(response.bodyBytes);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('API response: ${response.statusCode}, $body');
      return body.isNotEmpty ? json.decode(body) : null;
    } else {
      print('API error: ${response.statusCode}, $body');
      return null;
    }
  }
}
