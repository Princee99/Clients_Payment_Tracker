<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

require_once 'jwt_helper.php';
require_once 'auth_helper.php';

echo "=== Token Authentication Test ===\n\n";

// Generate a test token
$testPayload = [
    'user_id' => 123,
    'username' => 'testuser',
    'exp' => time() + 3600, // 1 hour from now
    'iat' => time()
];

$testToken = JWT::encode($testPayload);
echo "Generated test token: " . $testToken . "\n\n";

// Test 1: Direct JWT decode
echo "1. Testing direct JWT decode:\n";
$decoded = JWT::decode($testToken);
if ($decoded) {
    echo "   SUCCESS: " . json_encode($decoded) . "\n";
} else {
    echo "   FAILED\n";
}

echo "\n";

// Test 2: Test authentication with the token
echo "2. Testing authentication with token:\n";
$_SERVER['HTTP_AUTHORIZATION'] = 'Bearer ' . $testToken;

$isAuth = isAuthenticated();
echo "   Authentication result: " . ($isAuth ? 'SUCCESS' : 'FAILED') . "\n";

if ($isAuth) {
    $userId = getCurrentUserId();
    $username = getCurrentUsername();
    echo "   User ID: $userId\n";
    echo "   Username: $username\n";
}

echo "\n";

// Test 3: Test without token
echo "3. Testing without token:\n";
unset($_SERVER['HTTP_AUTHORIZATION']);

$isAuth = isAuthenticated();
echo "   Authentication result: " . ($isAuth ? 'SUCCESS' : 'FAILED') . "\n";

echo "\n=== Test Complete ===\n";
?>
