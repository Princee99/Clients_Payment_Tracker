import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/user_session.dart';
import 'dart:developer' as developer;

class BaseService {
  // Store BuildContext for error handling if needed
  static BuildContext? _context;

  static void setContext(BuildContext context) {
    _context = context;
  }

  static void _logRequest(
    String method,
    String url,
    Map<String, String>? headers,
    dynamic body,
  ) {
    developer.log('REQUEST: $method $url');
    developer.log('HEADERS: $headers');
    if (body != null) developer.log('BODY: $body');
  }

  static void _logResponse(http.Response response) {
    developer.log('RESPONSE CODE: ${response.statusCode}');
    developer.log('RESPONSE HEADERS: ${response.headers}');
    developer.log('RESPONSE BODY: ${response.body}');
  }

  static Future<Map<String, String>> _baseHeaders() async {
    return {
      'Content-Type': 'application/json',
    };
  }

  static Future<int?> _currentUserId() async {
    return await UserSession.getUserId();
  }

  // GET with user_id query param
  static Future<http.Response> authenticatedGet(String url) async {
    final headers = await _baseHeaders();
    final userId = await _currentUserId();

    final uri = Uri.parse(url);
    final newUri = uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        if (userId != null) 'user_id': userId.toString(),
      },
    );

    _logRequest('GET', newUri.toString(), headers, null);
    final response = await http.get(newUri, headers: headers);
    _logResponse(response);
    return response;
  }

  // POST with user_id in body
  static Future<http.Response> authenticatedPost(
    String url, {
    dynamic body,
  }) async {
    final headers = await _baseHeaders();
    final userId = await _currentUserId();

    dynamic finalBody = body;
    if (body is Map<String, dynamic>) {
      finalBody = {
        ...body,
        if (userId != null) 'user_id': userId,
      };
    }

    _logRequest('POST', url, headers, finalBody);
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(finalBody),
    );
    _logResponse(response);
    return response;
  }

  // PUT with user_id in body
  static Future<http.Response> authenticatedPut(
    String url, {
    dynamic body,
  }) async {
    final headers = await _baseHeaders();
    final userId = await _currentUserId();

    dynamic finalBody = body;
    if (body is Map<String, dynamic>) {
      finalBody = {
        ...body,
        if (userId != null) 'user_id': userId,
      };
    }

    _logRequest('PUT', url, headers, finalBody);
    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(finalBody),
    );
    _logResponse(response);
    return response;
  }

  // DELETE with user_id query param
  static Future<http.Response> authenticatedDelete(String url) async {
    final headers = await _baseHeaders();
    final userId = await _currentUserId();

    final uri = Uri.parse(url);
    final newUri = uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        if (userId != null) 'user_id': userId.toString(),
      },
    );

    _logRequest('DELETE', newUri.toString(), headers, null);
    final response = await http.delete(newUri, headers: headers);
    _logResponse(response);
    return response;
  }
}
