<?php
require_once 'jwt_helper.php';

echo "Testing JWT implementation...\n";

// Test data
$payload = [
    'user_id' => 123,
    'username' => 'testuser',
    'exp' => time() + 3600, // 1 hour
    'iat' => time()
];

echo "Original payload: " . json_encode($payload) . "\n";

// Encode
$token = JWT::encode($payload);
echo "Generated token: " . $token . "\n";

// Decode
$decoded = JWT::decode($token);
echo "Decoded payload: " . json_encode($decoded) . "\n";

// Test validation
if ($decoded && isset($decoded['user_id'])) {
    echo "Token validation: SUCCESS\n";
    echo "User ID: " . $decoded['user_id'] . "\n";
    echo "Username: " . $decoded['username'] . "\n";
} else {
    echo "Token validation: FAILED\n";
}

// Test expired token
$expiredPayload = [
    'user_id' => 123,
    'username' => 'testuser',
    'exp' => time() - 3600, // 1 hour ago
    'iat' => time() - 7200
];

$expiredToken = JWT::encode($expiredPayload);
$expiredDecoded = JWT::decode($expiredToken);

if ($expiredDecoded === false) {
    echo "Expired token validation: SUCCESS (correctly rejected)\n";
} else {
    echo "Expired token validation: FAILED (should have been rejected)\n";
}
?>
