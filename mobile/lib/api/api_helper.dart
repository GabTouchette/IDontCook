import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiHelper {
  final String baseUrl = 'http://192.168.0.110:8000/api';

  Future<dynamic> getRequest(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$endpoint'));
      return _handleResponse(response);
    } catch (e) {
      print('GET request error: $e');
      return null;
    }
  }

  Future<dynamic> postRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      print('POST request error: $e');
      return null;
    }
  }

  Future<dynamic> putRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      print('PUT request error: $e');
      return null;
    }
  }

  Future<bool> deleteRequest(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {"Content-Type": "application/json"},
      );
      return response.statusCode == 204;
    } catch (e) {
      print('DELETE request error: $e');
      return false;
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
