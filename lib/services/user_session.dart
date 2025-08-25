import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _tokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';

  // In-memory cache as fallback
  static int? _cachedUserId;
  static String? _cachedUsername;
  static String? _cachedToken;
  static bool? _cachedLoginStatus;

  // Store user session data with improved persistence
  static Future<bool> setUserSession(
    int userId,
    String username,
    String token,
  ) async {
    print(
      'UserSession.setUserSession called with: userId=$userId, username=$username, token=${token.isNotEmpty ? "EXISTS (${token.length} chars)" : "EMPTY"}',
    );

    try {
      final prefs = await SharedPreferences.getInstance();

      // First store the token (most important value)
      final tokenStored = await prefs.setString(_tokenKey, token);
      print('Token stored result: $tokenStored');

      if (!tokenStored) {
        print('CRITICAL ERROR: Failed to store token!');
        return false;
      }

      // Then store other values
      await prefs.setInt(_userIdKey, userId);
      await prefs.setString(_usernameKey, username);
      await prefs.setBool(_isLoggedInKey, true);

      // Force commit/flush changes
      await prefs.commit();

      // Verify token storage immediately
      final verifyToken = prefs.getString(_tokenKey);
      print(
        'Token verification after storage: ${verifyToken != null ? "SUCCESS (${verifyToken.length} chars)" : "FAILED"}',
      );

      // Update cache
      _cachedUserId = userId;
      _cachedUsername = username;
      _cachedToken = token;
      _cachedLoginStatus = true;

      return verifyToken != null;
    } catch (e) {
      print('Exception in setUserSession: $e');
      return false;
    }
  }

  // Get current user ID
  static Future<int?> getUserId() async {
    // Try in-memory cache first
    if (_cachedUserId != null) {
      return _cachedUserId;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);

    // Update cache
    _cachedUserId = userId;

    return userId;
  }

  // Get current username
  static Future<String?> getUsername() async {
    // Try in-memory cache first
    if (_cachedUsername != null) {
      return _cachedUsername;
    }

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey);

    // Update cache
    _cachedUsername = username;

    return username;
  }

  // Check if user is logged in with token validation
  static Future<bool> isLoggedIn() async {
    print('UserSession.isLoggedIn called');

    // Try memory cache first
    if (_cachedLoginStatus != null) {
      final hasToken = _cachedToken != null && _cachedToken!.isNotEmpty;
      print(
        'UserSession.isLoggedIn - Using cached status: $_cachedLoginStatus (has token: $hasToken)',
      );

      // Only return true if we have both login status and token
      if (_cachedLoginStatus! && hasToken) {
        return true;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final loginStatus = prefs.getBool(_isLoggedInKey) ?? false;

    // Also verify token exists
    final token = prefs.getString(_tokenKey);
    final hasValidStatus = loginStatus && token != null && token.isNotEmpty;

    // Update cache
    _cachedLoginStatus = hasValidStatus;
    if (token != null && token.isNotEmpty) {
      _cachedToken = token;
    }

    print('UserSession.isLoggedIn - Verified status: $hasValidStatus');
    return hasValidStatus;
  }

  // Clear user session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_tokenKey);
    await prefs.setBool(_isLoggedInKey, false);

    // Clear in-memory cache
    _cachedUserId = null;
    _cachedUsername = null;
    _cachedToken = null;
    _cachedLoginStatus = null;

    print('UserSession.clearSession - Session and cache cleared');
  }

  // Debug method to clear in-memory cache only
  static void clearMemoryCache() {
    _cachedUserId = null;
    _cachedUsername = null;
    _cachedToken = null;
    _cachedLoginStatus = null;
    print('UserSession.clearMemoryCache - In-memory cache cleared');
  }

  // Debug method to print in-memory cache status
  static void printMemoryCacheStatus() {
    print('=== In-Memory Cache Status ===');
    print('_cachedUserId: $_cachedUserId');
    print('_cachedUsername: $_cachedUsername');
    print(
      '_cachedToken: ${_cachedToken != null ? "EXISTS (${_cachedToken!.length} chars)" : "NULL"}',
    );
    print('_cachedLoginStatus: $_cachedLoginStatus');
    print('=============================');
  }

  // Get user session info
  static Future<Map<String, dynamic>?> getUserInfo() async {
    print('UserSession.getUserInfo called');

    // Print memory cache status
    printMemoryCacheStatus();

    // Get login status first
    final isLoggedInStatus = await isLoggedIn();
    print('isLoggedIn status: $isLoggedInStatus');

    if (isLoggedInStatus) {
      // Use cached values if available, otherwise get from SharedPreferences
      int? userId = _cachedUserId;
      String? username = _cachedUsername;
      String? token = _cachedToken;

      // If any cached values are missing, get them from SharedPreferences
      if (userId == null || username == null || token == null) {
        print('Some cached values missing, getting from SharedPreferences');
        final prefs = await SharedPreferences.getInstance();
        userId = userId ?? prefs.getInt(_userIdKey);
        username = username ?? prefs.getString(_usernameKey);
        token = token ?? prefs.getString(_tokenKey);

        // Update cache with fetched values
        _cachedUserId = userId;
        _cachedUsername = username;
        _cachedToken = token;
      }

      // IMPORTANT FIX: Return valid map even if token is null/empty
      if (userId != null && username != null) {
        final result = {
          'user_id': userId,
          'username': username,
          'token': token ?? '', // Empty string if token is null
        };
        print('Returning user info: $result');
        return result;
      }
    }

    return null;
  }

  // Get auth token - with improved reliability
  static Future<String?> getToken() async {
    print('UserSession.getToken called');

    try {
      // Try memory cache first
      if (_cachedToken != null && _cachedToken!.isNotEmpty) {
        print('Using cached token (${_cachedToken!.length} chars)');
        return _cachedToken;
      }

      // If no memory cache, try SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token != null && token.isNotEmpty) {
        // Update memory cache
        _cachedToken = token;
        print('Retrieved token from SharedPreferences (${token.length} chars)');
        return token;
      }

      print('No token found in cache or SharedPreferences');
      return null;
    } catch (e) {
      print('Exception during getToken: $e');
      return null;
    }
  }

  // Debug method to check all stored values
  static Future<void> debugPrintAllValues() async {
    final prefs = await SharedPreferences.getInstance();
    print('=== DEBUG: All SharedPreferences Values ===');
    print('_userIdKey ($_userIdKey): ${prefs.getInt(_userIdKey)}');
    print('_usernameKey ($_usernameKey): ${prefs.getString(_usernameKey)}');
    print(
      '_tokenKey ($_tokenKey): ${prefs.getString(_tokenKey) != null ? "EXISTS (${prefs.getString(_tokenKey)!.length} chars)" : "NULL"}',
    );
    print('_isLoggedInKey ($_isLoggedInKey): ${prefs.getBool(_isLoggedInKey)}');

    // Also check if there are any other keys
    final allKeys = prefs.getKeys();
    print('All keys in SharedPreferences: $allKeys');
    print('==========================================');
  }

  // Test method to verify SharedPreferences is working
  static Future<bool> testStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // Test storing and retrieving a simple value
    const testKey = 'test_key';
    const testValue = 'test_value';

    final stored = await prefs.setString(testKey, testValue);
    final retrieved = prefs.getString(testKey);
    final success = stored && retrieved == testValue;

    // Clean up test value
    await prefs.remove(testKey);

    print('SharedPreferences test: ${success ? "PASSED" : "FAILED"}');
    return success;
  }

  // Test method specifically for token storage
  static Future<bool> testTokenStorage() async {
    final prefs = await SharedPreferences.getInstance();

    const testToken =
        'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.test_token_for_testing_purposes_only';

    print('Testing token storage...');
    print('Storing test token: $testToken');

    final stored = await prefs.setString(_tokenKey, testToken);
    print('Token storage result: $stored');

    // Force commit
    await prefs.commit();

    // Retrieve immediately
    final retrieved = prefs.getString(_tokenKey);
    print(
      'Immediate retrieval: ${retrieved != null ? "EXISTS (${retrieved.length} chars)" : "NULL"}',
    );

    // Wait a bit and retrieve again
    await Future.delayed(Duration(milliseconds: 100));
    final retrievedAfterDelay = prefs.getString(_tokenKey);
    print(
      'Retrieval after delay: ${retrievedAfterDelay != null ? "EXISTS (${retrievedAfterDelay.length} chars)" : "NULL"}',
    );

    // Clean up
    await prefs.remove(_tokenKey);

    final success =
        stored && retrieved == testToken && retrievedAfterDelay == testToken;
    print('Token storage test: ${success ? "PASSED" : "FAILED"}');

    return success;
  }

  // Method to force reload SharedPreferences
  static Future<void> forceReload() async {
    print('UserSession.forceReload called');
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    print('SharedPreferences reloaded');
  }

  // Method to refresh cache from SharedPreferences
  static Future<void> refreshCache() async {
    print('UserSession.refreshCache called');
    final prefs = await SharedPreferences.getInstance();

    _cachedUserId = prefs.getInt(_userIdKey);
    _cachedUsername = prefs.getString(_usernameKey);
    _cachedToken = prefs.getString(_tokenKey);
    _cachedLoginStatus = prefs.getBool(_isLoggedInKey);

    print('Cache refreshed from SharedPreferences');
    printMemoryCacheStatus();
  }

  // Method to check SharedPreferences instance
  static Future<void> checkSharedPreferencesInstance() async {
    print('UserSession.checkSharedPreferencesInstance called');
    final prefs1 = await SharedPreferences.getInstance();
    final prefs2 = await SharedPreferences.getInstance();

    print('SharedPreferences instance 1: ${prefs1.hashCode}');
    print('SharedPreferences instance 2: ${prefs2.hashCode}');
    print('Instances are same: ${prefs1 == prefs2}');

    // Check if we can access the same data from both instances
    await prefs1.setString('test_instance_key', 'test_value');
    final value1 = prefs1.getString('test_instance_key');
    final value2 = prefs2.getString('test_instance_key');

    print('Value from instance 1: $value1');
    print('Value from instance 2: $value2');
    print('Values match: ${value1 == value2}');

    // Clean up
    await prefs1.remove('test_instance_key');
  }

  // Method to manually verify token storage
  static Future<void> verifyTokenStorage() async {
    print('UserSession.verifyTokenStorage called');
    final prefs = await SharedPreferences.getInstance();

    print('=== Token Storage Verification ===');
    print('All keys: ${prefs.getKeys()}');
    print('auth_token value: ${prefs.getString(_tokenKey)}');
    print('auth_token exists: ${prefs.containsKey(_tokenKey)}');
    print('===============================');
  }

  // Force update token only
  static Future<bool> updateToken(String token) async {
    print('UserSession.updateToken called with token length: ${token.length}');

    final prefs = await SharedPreferences.getInstance();

    // Store token with the correct key
    final stored = await prefs.setString(_tokenKey, token);

    // Force commit changes
    await prefs.commit();

    // Update cache
    _cachedToken = token;

    // Verify storage
    final storedToken = prefs.getString(_tokenKey);
    final success = storedToken != null && storedToken == token;

    print('Token updated successfully: $success');
    return success;
  }
}
