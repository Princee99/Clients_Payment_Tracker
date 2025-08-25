<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require_once 'jwt_helper.php';
require_once 'auth_helper.php';

$host = "localhost";
$user = "root";
$password = "";
$db = "flutter_auth";

$conn = new mysqli($host, $user, $password, $db);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Check if user is authenticated
    if (!isAuthenticated()) {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Authentication required']);
        exit;
    }
    
    $currentUserId = getCurrentUserId();
    $currentUsername = getCurrentUsername();
    
    if ($currentUserId && $currentUsername) {
        // Generate new JWT token
        $payload = [
            'user_id' => $currentUserId,
            'username' => $currentUsername,
            'exp' => time() + (24 * 60 * 60), // 24 hours expiration
            'iat' => time()
        ];
        
        $token = JWT::encode($payload);
        
        echo json_encode([
            'success' => true, 
            'user_id' => $currentUserId,
            'username' => $currentUsername,
            'token' => $token
        ]);
    } else {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid user data']);
    }
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?>
