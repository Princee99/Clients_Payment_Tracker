<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

require_once 'jwt_helper.php';
require_once 'auth_helper.php';

echo "=== Authentication Test ===\n";

// Test 1: Check if JWT helper is working
echo "\n1. Testing JWT helper:\n";
$testPayload = [
    'user_id' => 123,
    'username' => 'testuser',
    'exp' => time() + 3600,
    'iat' => time()
];

$testToken = JWT::encode($testPayload);
echo "Generated test token: " . $testToken . "\n";

$decodedPayload = JWT::decode($testToken);
echo "Decoded payload: " . json_encode($decodedPayload) . "\n";

// Test 2: Check authentication with valid token
echo "\n2. Testing authentication with valid token:\n";
$_SERVER['HTTP_AUTHORIZATION'] = 'Bearer ' . $testToken;
$isAuth = isAuthenticated();
echo "Authentication result: " . ($isAuth ? 'SUCCESS' : 'FAILED') . "\n";

if ($isAuth) {
    $userId = getCurrentUserId();
    $username = getCurrentUsername();
    echo "User ID: $userId\n";
    echo "Username: $username\n";
}

// Test 3: Check authentication without token
echo "\n3. Testing authentication without token:\n";
unset($_SERVER['HTTP_AUTHORIZATION']);
$isAuth = isAuthenticated();
echo "Authentication result: " . ($isAuth ? 'SUCCESS' : 'FAILED') . "\n";

// Test 4: Check authentication with invalid token
echo "\n4. Testing authentication with invalid token:\n";
$_SERVER['HTTP_AUTHORIZATION'] = 'Bearer invalid_token_here';
$isAuth = isAuthenticated();
echo "Authentication result: " . ($isAuth ? 'SUCCESS' : 'FAILED') . "\n";

echo "\n=== Test Complete ===\n";
?>
