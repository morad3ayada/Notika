import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/network_utils.dart';

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
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

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
      if (token != null) {
        requestHeaders['Authorization'] = 'Bearer $token';
      }
      if (headers != null) {
        requestHeaders.addAll(headers);
      }

      final response = await http.post(
        uri,
        headers: requestHeaders,
        body: jsonEncode(body),
      ).timeout(
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
