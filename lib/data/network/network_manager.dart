import 'dart:convert';

import 'package:elkitap/data/network/api_edpoints.dart';
import 'package:elkitap/data/network/token_managet.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class NetworkManager extends GetxController {
  final TokenManager _tokenManager = Get.find<TokenManager>();
  Map<String, String> _getHeaders({bool sendToken = false}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'content-language': _getAcceptLanguage(),
    };
    if (sendToken) {
      final token = _tokenManager.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  String _getAcceptLanguage() {
    final locale = Get.locale;
    if (locale == null) return 'tk';
    final languageCode = locale.languageCode;
    if (languageCode == 'tr') {
      return 'tk';
    }

    return languageCode;
  }

  // GET Request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool sendToken = false,
    Map<String, String>? queryParameters,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.getFullUrl(endpoint))
          .replace(queryParameters: queryParameters);

      final response = await http.get(
        uri,
        headers: _getHeaders(sendToken: sendToken),
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // POST Request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    required Map<String, dynamic> body,
    bool sendToken = false,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.getFullUrl(endpoint));

      final response = await http.post(
        uri,
        headers: _getHeaders(sendToken: sendToken),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // PUT Request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    required Map<String, dynamic> body,
    bool sendToken = false,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.getFullUrl(endpoint));

      final response = await http.put(
        uri,
        headers: _getHeaders(sendToken: sendToken),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // DELETE Request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool sendToken = false,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.getFullUrl(endpoint));

      final response = await http.delete(
        uri,
        headers: _getHeaders(sendToken: sendToken),
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // PATCH Request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    required Map<String, dynamic> body,
    bool sendToken = false,
  }) async {
    try {
      final uri = Uri.parse(ApiEndpoints.getFullUrl(endpoint));

      final response = await http.patch(
        uri,
        headers: _getHeaders(sendToken: sendToken),
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  // Handle response
  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    try {
      final data = jsonDecode(response.body);

      if (statusCode >= 200 && statusCode < 300) {
        return {
          'success': true,
          'statusCode': statusCode,
          'message': data['message'] ?? 'Success',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'statusCode': statusCode,
          'error': data['message'] ?? 'Request failed',
          'data': data,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'statusCode': statusCode,
        'error': 'Failed to parse response',
        'data': response.body,
      };
    }
  }

  // Handle errors
  Map<String, dynamic> _handleError(dynamic error) {
    return {
      'success': false,
      'statusCode': 0,
      'error': error.toString(),
      'data': null,
    };
  }
}
