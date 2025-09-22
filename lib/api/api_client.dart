import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/network_utils.dart';
import '../data/services/auth_service.dart';

class ApiClient {
  final String baseUrl;
  final String? token;

  ApiClient({required this.baseUrl, this.token});

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams, String? customBaseUrl}) async {
    try {
      // Check internet connection first
      final isConnected = await NetworkUtils.isConnected();
      if (!isConnected) {
        throw Exception(ApiConfig.noInternetMessage);
      }

      final url = customBaseUrl ?? baseUrl;
      final uri = Uri.parse('$url$endpoint').replace(queryParameters: queryParams);
      
      final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
      // Fetch token automatically if not provided
      final currentToken = token ?? await AuthService.getToken();
      if (currentToken != null && currentToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $currentToken';
      }
      // Log token before sending request to confirm it's not null
      debugPrint('ApiClient GET $endpoint - token: ${currentToken ?? 'NULL'}');
      // Log the actual Authorization header value
      debugPrint('Authorization header: ${headers['Authorization']}');

      final response = await http.get(uri, headers: headers).timeout(
        ApiConfig.connectionTimeout,
        onTimeout: () => throw TimeoutException(ApiConfig.connectionTimeoutMessage),
      );
      
      return _handleResponse(response);
    } on SocketException {
      throw Exception(ApiConfig.noInternetMessage);
    } on TimeoutException {
      throw Exception(ApiConfig.connectionTimeoutMessage);
    } catch (e) {
      debugPrint('API Error: $e');
      rethrow;
    }
  }

  Future<dynamic> post({
    required String endpoint, 
    Map<String, dynamic>? body, 
    String? customBaseUrl,
    Map<String, String>? headers,
  }) async {
    try {
      // Check internet connection first
      final isConnected = await NetworkUtils.isConnected();
      if (!isConnected) {
        throw Exception(ApiConfig.noInternetMessage);
      }

      final url = customBaseUrl ?? baseUrl;
      final uri = Uri.parse('$url$endpoint');
      
      final requestHeaders = Map<String, String>.from(ApiConfig.defaultHeaders);
      // Fetch token automatically if not provided
      final currentToken = token ?? await AuthService.getToken();
      if (currentToken != null && currentToken.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer $currentToken';
      }
      if (headers != null) {
        requestHeaders.addAll(headers);
      }

      // Log token before sending request to confirm it's not null
      debugPrint('ApiClient POST $endpoint - token: ${currentToken ?? 'NULL'}');
      // Optional debug: show URL and header keys
      try {
        final headerKeys = requestHeaders.keys.join(', ');
        debugPrint('ApiClient POST url: $uri, headers: [$headerKeys]');
      } catch (_) {}

      // Log the actual Authorization header value
      debugPrint('Authorization header: ${requestHeaders['Authorization']}');

      // Only include a body if provided; avoid sending the literal string 'null'
      final response = await http
          .post(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(
        ApiConfig.connectionTimeout,
        onTimeout: () => throw TimeoutException(ApiConfig.connectionTimeoutMessage),
      );

      return _handleResponse(response);
    } on SocketException {
      throw Exception(ApiConfig.noInternetMessage);
    } on TimeoutException {
      throw Exception(ApiConfig.connectionTimeoutMessage);
    } catch (e) {
      debugPrint('API Error: $e');
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    final responseBody = response.body.isNotEmpty 
        ? jsonDecode(utf8.decode(response.bodyBytes)) 
        : null;
    
    switch (response.statusCode) {
      case 200: // Success
      case 201: // Created
      case 204: // No Content
        return responseBody;
      case 400: // Bad Request
        throw Exception(responseBody?['message'] ?? 'طلب غير صالح');
      case 401: // Unauthorized
        throw Exception(ApiConfig.unauthorizedMessage);
      case 403: // Forbidden
        throw Exception('غير مصرح لك بالوصول إلى هذا المورد');
      case 404: // Not Found
        throw Exception(ApiConfig.notFoundMessage);
      case 500: // Internal Server Error
      default:
        throw Exception(responseBody?['message'] ?? ApiConfig.serverErrorMessage);
    }
  }
}
