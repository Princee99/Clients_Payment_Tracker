<?php
// filepath: d:\INTERNSHIP\INTERNSHIP_AGEVOLE\Apps\cash_in_out\Cash_in_out\backend\validate_token.php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

require_once 'auth_helper.php';

// Simple endpoint to validate token
try {
    $userId = getCurrentUserId(); // Will throw exception if token invalid
    
    if ($userId) {
        echo json_encode(['success' => true, 'user_id' => $userId]);
    } else {
        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid token']);
    }
} catch (Exception $e) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
?>