import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'user_session.dart';
import 'package:flutter/material.dart';
import '../screens/login.dart';

class AuthManager {
  // Static flag to prevent multiple auth checks at once
  static bool _isCheckingAuth = false;

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final isLoggedIn = await UserSession.isLoggedIn();
    if (!isLoggedIn) return false;

    final token = await UserSession.getToken();
    return token != null && token.isNotEmpty;
  }

  // Get authentication headers
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await UserSession.getToken() ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Handle 401 errors
  static Future<bool> handleAuthError(BuildContext context) async {
    // If already checking auth, don't do it again
    if (_isCheckingAuth) return false;

    _isCheckingAuth = true;
    try {
      // Clear session and redirect to login
      await UserSession.clearSession();

      // Show message and navigate to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please login again.')),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );

      return true;
    } finally {
      _isCheckingAuth = false;
    }
  }

  // Re-authenticate user by testing token
  static Future<bool> validateToken() async {
    try {
      final token = await UserSession.getToken();
      if (token == null || token.isEmpty) return false;

      final response = await http.get(
        Uri.parse('http://$ip/backend/validate_token.php'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200 &&
          json.decode(response.body)['success'] == true;
    } catch (e) {
      print('Error validating token: $e');
      return false;
    }
  }
}
