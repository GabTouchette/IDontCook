import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_api.dart';

class ApiHelper {
  final String baseUrl = 'http://192.168.0.110:8000/api';

  Future<dynamic> getRequest(String endpoint,
      {bool requiresAuth = true}) async {
    try {
      final headers = requiresAuth
          ? await AuthApi.getAuthHeader()
          : {'Content-Type': 'application/json'};

      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
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

  Future<Map<String, dynamic>?> uploadFile(String endpoint, File file,
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

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print("Image upload failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print('File upload error: $e');
      return null;
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
