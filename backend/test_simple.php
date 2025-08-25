<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

require_once 'jwt_helper.php';

echo "=== Simple JWT Test ===\n";

// Test 1: Generate a token
$testPayload = [
    'user_id' => 123,
    'username' => 'testuser',
    'exp' => time() + 3600, // 1 hour from now
    'iat' => time()
];

$token = JWT::encode($testPayload);
echo "\nGenerated token: " . $token . "\n";

// Test 2: Decode the token
$decoded = JWT::decode($token);
echo "\nDecoded payload: " . json_encode($decoded) . "\n";

// Test 3: Test with Authorization header
$headers = [];
if (function_exists('getallheaders')) {
    $headers = getallheaders();
} else {
    foreach ($_SERVER as $key => $value) {
        if (substr($key, 0, 5) == 'HTTP_') {
            $header = str_replace(' ', '-', ucwords(str_replace('_', ' ', strtolower(substr($key, 5)))));
            $headers[$header] = $value;
        }
    }
}

echo "\nRequest headers: " . json_encode($headers) . "\n";

if (isset($headers['Authorization'])) {
    $authToken = str_replace('Bearer ', '', $headers['Authorization']);
    echo "\nAuthorization token: " . $authToken . "\n";
    
    $decodedAuth = JWT::decode($authToken);
    if ($decodedAuth) {
        echo "Authorization token valid: " . json_encode($decodedAuth) . "\n";
    } else {
        echo "Authorization token invalid\n";
    }
} else {
    echo "\nNo Authorization header found\n";
}

echo "\n=== Test Complete ===\n";
?>
