import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'user_session.dart';

class AuthService {
  static const String _refreshTokenEndpoint = '/backend/refresh_token.php';
  
  // Check if current token is valid and refresh if needed
  static Future<bool> ensureValidToken() async {
    print('AuthService.ensureValidToken called');
    
    final userInfo = await UserSession.getUserInfo();
    print('AuthService.ensureValidToken - userInfo: $userInfo');
    
    // Print memory cache status
    UserSession.printMemoryCacheStatus();
    
    // If we have no user info, don't attempt validation
    if (userInfo == null || userInfo['token'] == null || userInfo['token'].isEmpty) {
      print('AuthService.ensureValidToken - No user info or token, returning false');
      return false;
    }
    
    try {
      print('AuthService.ensureValidToken - Attempting to refresh token');
      // Try to refresh the token
      final response = await http.post(
        Uri.parse('http://$ip$_refreshTokenEndpoint'),
        headers: {
          'Authorization': 'Bearer ${userInfo['token']}',
          'Content-Type': 'application/json',
        },
      );
      
      print('AuthService.ensureValidToken - Refresh response status: ${response.statusCode}');
      print('AuthService.ensureValidToken - Refresh response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print('AuthService.ensureValidToken - Token refresh successful, updating session');
          // Update the stored token
          await UserSession.setUserSession(
            responseData['user_id'],
            responseData['username'],
            responseData['token'],
          );
          
          // Print memory cache status after updating
          UserSession.printMemoryCacheStatus();
          
          return true;
        } else {
          print('AuthService.ensureValidToken - Token refresh failed: ${responseData['message']}');
        }
      } else {
        print('AuthService.ensureValidToken - Token refresh failed with status: ${response.statusCode}');
      }
      
      // IMPORTANT CHANGE: Don't automatically clear session on first failure
      // Only clear if status code indicates authentication issue (401)
      if (response.statusCode == 401) {
        print('AuthService.ensureValidToken - Clearing session due to authentication failure');
        await UserSession.clearSession();
      } else {
        print('AuthService.ensureValidToken - Not clearing session despite refresh failure');
      }
      
      return false;
    } catch (e) {
      print('AuthService.ensureValidToken - Error during token refresh: $e');
      // Don't clear session on network errors
      return false;
    }
  }
  
  // Handle 401 responses by attempting token refresh
  static Future<bool> handleUnauthorized() async {
    return await ensureValidToken();
  }
}
