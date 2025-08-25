<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);
require_once 'jwt_helper.php';

// Function to check if user is authenticated
function isAuthenticated() {
    // Check for authorization header (JWT path)
    $headers = getRequestHeaders();
    error_log("Request headers: " . json_encode($headers));
    if (isset($headers['Authorization'])) {
        $token = str_replace('Bearer ', '', $headers['Authorization']);
        error_log("Token received: " . $token);
        $isValid = validateToken($token);
        error_log("Token validation result: " . ($isValid ? 'true' : 'false'));
        return $isValid;
    }

    // Fallback path: allow user_id from request (query/body/json)
    $userId = getUserIdFromRequest();
    if ($userId !== null) {
        error_log("Authenticated via user_id param: $userId");
        return true;
    }

    error_log("No Authorization header or user_id param found");
    return false;
}

// Helper function to get request headers (works on more servers)
function getRequestHeaders() {
    $headers = [];
    
    // Try getallheaders first
    if (function_exists('getallheaders')) {
        $headers = getallheaders();
        error_log("Using getallheaders(): " . json_encode($headers));
    } else {
        // Fallback for servers that don't support getallheaders
        foreach ($_SERVER as $key => $value) {
            if (substr($key, 0, 5) == 'HTTP_') {
                $header = str_replace(' ', '-', ucwords(str_replace('_', ' ', strtolower(substr($key, 5)))));
                $headers[$header] = $value;
            }
        }
        error_log("Using fallback headers from \$_SERVER: " . json_encode($headers));
    }
    
    // Also check for Authorization in $_SERVER directly
    if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $headers['Authorization'] = $_SERVER['HTTP_AUTHORIZATION'];
        error_log("Found Authorization in \$_SERVER['HTTP_AUTHORIZATION']: " . $_SERVER['HTTP_AUTHORIZATION']);
    }
    
    // Check for Authorization in $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] (common on some servers)
    if (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $headers['Authorization'] = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
        error_log("Found Authorization in \$_SERVER['REDIRECT_HTTP_AUTHORIZATION']: " . $_SERVER['REDIRECT_HTTP_AUTHORIZATION']);
    }
    
    error_log("Final headers array: " . json_encode($headers));
    return $headers;
}

// Function to get current user ID
function getCurrentUserId() {
    // Prefer JWT if provided
    $headers = getRequestHeaders();
    if (isset($headers['Authorization'])) {
        $token = str_replace('Bearer ', '', $headers['Authorization']);
        $userId = getUserIdFromToken($token);
        if ($userId) {
            return $userId;
        }
    }

    // Otherwise, read from request params/body
    return getUserIdFromRequest();
}

// Function to get current username
function getCurrentUsername() {
    // Check for authorization header
    $headers = getRequestHeaders();
    if (isset($headers['Authorization'])) {
        $token = str_replace('Bearer ', '', $headers['Authorization']);
        $username = getUsernameFromToken($token);
        if ($username) {
            return $username;
        }
    }
    
    return null;
}

// Function to require authentication
function requireAuth() {
    if (!isAuthenticated()) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Authentication required']);
        exit;
    }
}

// Function to send unauthorized response
function sendUnauthorized() {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Authentication required']);
    exit;
}

// JWT token validation
function validateToken($token) {
    error_log("Validating token: " . $token);
    $payload = JWT::decode($token);
    error_log("JWT decode result: " . json_encode($payload));
    
    if ($payload && isset($payload['user_id'])) {
        error_log("Token validation successful for user ID: " . $payload['user_id']);
        return true;
    }
    
    error_log("Token validation failed");
    return false;
}

// Get user ID from JWT token
function getUserIdFromToken($token) {
    $payload = JWT::decode($token);
    if ($payload && isset($payload['user_id'])) {
        return $payload['user_id'];
    }
    return null;
}

// Get username from JWT token
function getUsernameFromToken($token) {
    $payload = JWT::decode($token);
    if ($payload && isset($payload['username'])) {
        return $payload['username'];
    }
    return null;
}

// Helper to extract user_id from request when not using JWT
function getUserIdFromRequest() {
    // 1) Query string
    if (isset($_GET['user_id'])) {
        return intval($_GET['user_id']);
    }
    // 2) Form-encoded POST
    if (isset($_POST['user_id'])) {
        return intval($_POST['user_id']);
    }
    // 3) JSON body
    $raw = file_get_contents('php://input');
    if ($raw) {
        $json = json_decode($raw, true);
        if (json_last_error() === JSON_ERROR_NONE && isset($json['user_id'])) {
            return intval($json['user_id']);
        }
    }
    return null;
}
?>
