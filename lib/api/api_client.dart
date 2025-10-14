import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../utils/network_utils.dart';
import '../data/services/auth_service.dart';
// HTTP logging utilities

class ApiClient {
  final String baseUrl;
  final String? token;

  ApiClient({required this.baseUrl, this.token});

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams, String? customBaseUrl, Map<String, String>? headers}) async {
    try {
      // Check internet connection first
      final isConnected = await NetworkUtils.isConnected();
      if (!isConnected) {
        throw Exception(ApiConfig.noInternetMessage);
      }

      final url = customBaseUrl ?? baseUrl;
      final uri = Uri.parse('$url$endpoint').replace(queryParameters: queryParams);
      
      final requestHeaders = await _buildHeaders(headers);
      
      // Log request details
      _logRequest('GET', uri, requestHeaders, null);

      final response = await http.get(uri, headers: requestHeaders).timeout(
        ApiConfig.connectionTimeout,
        onTimeout: () => throw TimeoutException(ApiConfig.connectionTimeoutMessage),
      );
      
      // Log response details
      _logResponse('GET', response);
      
      return _handleResponse(response);
    } on SocketException {
      throw Exception(ApiConfig.noInternetMessage);
    } on TimeoutException {
      throw Exception(ApiConfig.connectionTimeoutMessage);
    } catch (e) {
      debugPrint('❌ GET $endpoint - API Error: $e');
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
      
      final requestHeaders = await _buildHeaders(headers);
      final requestBody = body != null ? jsonEncode(body) : null;
      
      // Log request details
      _logRequest('POST', uri, requestHeaders, requestBody);

      final response = await http
          .post(
            uri,
            headers: requestHeaders,
            body: requestBody,
          )
          .timeout(
        ApiConfig.connectionTimeout,
        onTimeout: () => throw TimeoutException(ApiConfig.connectionTimeoutMessage),
      );

      // Log response details
      _logResponse('POST', response);

      return _handleResponse(response);
    } on SocketException {
      throw Exception(ApiConfig.noInternetMessage);
    } on TimeoutException {
      throw Exception(ApiConfig.connectionTimeoutMessage);
    } catch (e) {
      debugPrint('❌ POST $endpoint - API Error: $e');
      rethrow;
    }
  }

  /// Performs a PUT request
  Future<dynamic> put({
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
      
      final requestHeaders = await _buildHeaders(headers);
      final requestBody = body != null ? jsonEncode(body) : null;
      
      // Log request details
      _logRequest('PUT', uri, requestHeaders, requestBody);

      final response = await http
          .put(
            uri,
            headers: requestHeaders,
            body: requestBody,
          )
          .timeout(
        ApiConfig.connectionTimeout,
        onTimeout: () => throw TimeoutException(ApiConfig.connectionTimeoutMessage),
      );

      // Log response details
      _logResponse('PUT', response);

      return _handleResponse(response);
    } on SocketException {
      throw Exception(ApiConfig.noInternetMessage);
    } on TimeoutException {
      throw Exception(ApiConfig.connectionTimeoutMessage);
    } catch (e) {
      debugPrint('❌ PUT $endpoint - API Error: $e');
      rethrow;
    }
  }

  /// Performs a DELETE request
  Future<dynamic> delete(String endpoint, {Map<String, String>? queryParams, String? customBaseUrl, Map<String, String>? headers}) async {
    try {
      // Check internet connection first
      final isConnected = await NetworkUtils.isConnected();
      if (!isConnected) {
        throw Exception(ApiConfig.noInternetMessage);
      }

      final url = customBaseUrl ?? baseUrl;
      final uri = Uri.parse('$url$endpoint').replace(queryParameters: queryParams);
      
      final requestHeaders = await _buildHeaders(headers);
      
      // Log request details
      _logRequest('DELETE', uri, requestHeaders, null);

      final response = await http.delete(uri, headers: requestHeaders).timeout(
        ApiConfig.connectionTimeout,
        onTimeout: () => throw TimeoutException(ApiConfig.connectionTimeoutMessage),
      );
      
      // Log response details
      _logResponse('DELETE', response);
      
      return _handleResponse(response);
    } on SocketException {
      throw Exception(ApiConfig.noInternetMessage);
    } on TimeoutException {
      throw Exception(ApiConfig.connectionTimeoutMessage);
    } catch (e) {
      debugPrint('❌ DELETE $endpoint - API Error: $e');
      rethrow;
    }
  }

  /// Builds request headers by combining default headers with optional headers
  Future<Map<String, String>> _buildHeaders(Map<String, String>? additionalHeaders) async {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    
    // Fetch token automatically if not provided
    final currentToken = token ?? await AuthService.getToken();
    if (currentToken != null && currentToken.isNotEmpty) {
      // Remove "Bearer " prefix if it exists, as the API expects just the token
      final cleanToken = currentToken.startsWith('Bearer ') 
          ? currentToken.substring(7) 
          : currentToken;
      headers['Authorization'] = cleanToken;
    }
    
    // Add additional headers if provided
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    
    return headers;
  }

  /// Logs request details for debugging
  void _logRequest(String method, Uri uri, Map<String, String> headers, String? body) {
    if (kDebugMode) {
      debugPrint('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📤 API REQUEST');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔹 Method:   $method');
      debugPrint('🔹 URL:      $uri');
      debugPrint('🔹 BaseURL:  $baseUrl');
      debugPrint('\n📋 Headers:');
      _formatHeaders(headers).split('\n').forEach((line) => debugPrint('   $line'));
      if (body != null) {
        debugPrint('\n📦 Request Body:');
        try {
          final decoded = jsonDecode(body);
          final prettyJson = JsonEncoder.withIndent('  ').convert(decoded);
          prettyJson.split('\n').forEach((line) => debugPrint('   $line'));
        } catch (e) {
          debugPrint('   $body');
        }
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    }
  }

  /// Logs response details for debugging
  void _logResponse(String method, http.Response response) {
    if (kDebugMode) {
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      final icon = isSuccess ? '✅' : '❌';
      final statusColor = isSuccess ? '🟢' : '🔴';
      
      debugPrint('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('$icon API RESPONSE');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('$statusColor Status:  ${response.statusCode} ${_getStatusText(response.statusCode)}');
      debugPrint('🔹 Method:  $method');
      debugPrint('🔹 URL:     ${response.request?.url}');
      debugPrint('\n📋 Response Headers:');
      _formatHeaders(response.headers).split('\n').forEach((line) => debugPrint('   $line'));
      debugPrint('\n📦 Response Body:');
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          final prettyJson = JsonEncoder.withIndent('  ').convert(decoded);
          prettyJson.split('\n').forEach((line) => debugPrint('   $line'));
        } catch (e) {
          debugPrint('   ${response.body}');
        }
      } else {
        debugPrint('   (empty)');
      }
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    }
  }

  /// Get status text for HTTP status codes
  String _getStatusText(int statusCode) {
    switch (statusCode) {
      case 200: return 'OK';
      case 201: return 'Created';
      case 202: return 'Accepted';
      case 204: return 'No Content';
      case 400: return 'Bad Request';
      case 401: return 'Unauthorized';
      case 403: return 'Forbidden';
      case 404: return 'Not Found';
      case 422: return 'Unprocessable Entity';
      case 429: return 'Too Many Requests';
      case 500: return 'Internal Server Error';
      case 502: return 'Bad Gateway';
      case 503: return 'Service Unavailable';
      default: return '';
    }
  }

  /// Formats headers for logging (hides sensitive information)
  String _formatHeaders(Map<String, String> headers) {
    final sanitized = Map<String, String>.from(headers);
    
    // Hide sensitive headers
    if (sanitized.containsKey('Authorization')) {
      final authValue = sanitized['Authorization']!;
      sanitized['Authorization'] = authValue.length > 10 
          ? '${authValue.substring(0, 10)}...[hidden]'
          : '[hidden]';
    }
    
    return sanitized.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
  }

  /// Extracts error message from response body
  String _extractErrorMessage(dynamic responseBody, String defaultMessage) {
    if (responseBody == null) return defaultMessage;
    
    if (responseBody is Map<String, dynamic>) {
      // Try different common error message fields
      return responseBody['message'] ?? 
             responseBody['error'] ?? 
             responseBody['detail'] ?? 
             responseBody['title'] ?? 
             defaultMessage;
    }
    
    if (responseBody is String) {
      return responseBody.isNotEmpty ? responseBody : defaultMessage;
    }
    
    return defaultMessage;
  }

  dynamic _handleResponse(http.Response response) {
    final responseBody = response.body.isNotEmpty 
        ? jsonDecode(utf8.decode(response.bodyBytes)) 
        : null;
    
    switch (response.statusCode) {
      case 200: // Success
      case 201: // Created
      case 202: // Accepted
        return responseBody;
      case 204: // No Content
        return null;
      case 400: // Bad Request
        throw Exception(_extractErrorMessage(responseBody, 'طلب غير صالح'));
      case 401: // Unauthorized
        throw Exception(_extractErrorMessage(responseBody, ApiConfig.unauthorizedMessage));
      case 403: // Forbidden
        throw Exception(_extractErrorMessage(responseBody, 'غير مصرح لك بالوصول إلى هذا المورد'));
      case 404: // Not Found
        throw Exception(_extractErrorMessage(responseBody, ApiConfig.notFoundMessage));
      case 422: // Unprocessable Entity
        throw Exception(_extractErrorMessage(responseBody, 'بيانات غير صالحة'));
      case 429: // Too Many Requests
        throw Exception(_extractErrorMessage(responseBody, 'تم تجاوز الحد المسموح من الطلبات'));
      case 500: // Internal Server Error
      case 502: // Bad Gateway
      case 503: // Service Unavailable
      default:
        throw Exception(_extractErrorMessage(responseBody, ApiConfig.serverErrorMessage));
    }
  }
}
