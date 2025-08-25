<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

echo "=== Header Debugging ===\n\n";

// Show all $_SERVER variables
echo "All \$_SERVER variables:\n";
foreach ($_SERVER as $key => $value) {
    if (strpos($key, 'HTTP_') === 0 || strpos($key, 'REDIRECT_') === 0) {
        echo "$key => $value\n";
    }
}

echo "\n";

// Test getallheaders function
echo "getallheaders() function exists: " . (function_exists('getallheaders') ? 'YES' : 'NO') . "\n";
if (function_exists('getallheaders')) {
    $allHeaders = getallheaders();
    echo "getallheaders() result: " . json_encode($allHeaders) . "\n";
} else {
    echo "getallheaders() not available\n";
}

echo "\n";

// Test our custom function
echo "Testing our getRequestHeaders() function:\n";
require_once 'auth_helper.php';
$headers = getRequestHeaders();
echo "getRequestHeaders() result: " . json_encode($headers) . "\n";

echo "\n";

// Test specific header locations
echo "Checking specific header locations:\n";
echo "HTTP_AUTHORIZATION: " . (isset($_SERVER['HTTP_AUTHORIZATION']) ? $_SERVER['HTTP_AUTHORIZATION'] : 'NOT SET') . "\n";
echo "REDIRECT_HTTP_AUTHORIZATION: " . (isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION']) ? $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] : 'NOT SET') . "\n";

echo "\n";

// Test JWT with a known token
echo "Testing JWT with a test token:\n";
require_once 'jwt_helper.php';

$testPayload = [
    'user_id' => 123,
    'username' => 'testuser',
    'exp' => time() + 3600,
    'iat' => time()
];

$testToken = JWT::encode($testPayload);
echo "Generated test token: " . $testToken . "\n";

// Test if we can decode it
$decoded = JWT::decode($testToken);
echo "JWT decode test: " . ($decoded ? 'SUCCESS' : 'FAILED') . "\n";
if ($decoded) {
    echo "Decoded payload: " . json_encode($decoded) . "\n";
}

echo "\n=== Debug Complete ===\n";
?>
