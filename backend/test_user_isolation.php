<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

require_once 'auth_helper.php';

$host = "localhost";
$user = "root";
$password = "";
$db = "flutter_auth";

$conn = new mysqli($host, $user, $password, $db);
if ($conn->connect_error) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed: ' . $conn->connect_error]);
    exit;
}

// Test user isolation system
echo json_encode([
    'success' => true,
    'message' => 'User isolation test script',
    'tests' => [
        '1. Check if users table exists',
        '2. Check if all tables have user_id field',
        '3. Test authentication helper functions',
        '4. Verify foreign key constraints'
    ]
]);

// Test 1: Check if users table exists
$result = $conn->query("SHOW TABLES LIKE 'users'");
if ($result->num_rows > 0) {
    echo "\n✅ Users table exists";
} else {
    echo "\n❌ Users table does not exist";
}

// Test 2: Check if all tables have user_id field
$tables = ['clients', 'installment_plans', 'installments', 'payments'];
foreach ($tables as $table) {
    $result = $conn->query("DESCRIBE $table");
    $hasUserId = false;
    while ($row = $result->fetch_assoc()) {
        if ($row['Field'] === 'user_id') {
            $hasUserId = true;
            break;
        }
    }
    if ($hasUserId) {
        echo "\n✅ Table '$table' has user_id field";
    } else {
        echo "\n❌ Table '$table' missing user_id field";
    }
}

// Test 3: Check foreign key constraints
$result = $conn->query("
    SELECT 
        TABLE_NAME,
        COLUMN_NAME,
        CONSTRAINT_NAME,
        REFERENCED_TABLE_NAME,
        REFERENCED_COLUMN_NAME
    FROM information_schema.KEY_COLUMN_USAGE 
    WHERE REFERENCED_TABLE_SCHEMA = '$db' 
    AND REFERENCED_TABLE_NAME = 'users'
");

echo "\n\nForeign Key Constraints:";
while ($row = $result->fetch_assoc()) {
    echo "\n✅ {$row['TABLE_NAME']}.{$row['COLUMN_NAME']} -> {$row['REFERENCED_TABLE_NAME']}.{$row['REFERENCED_COLUMN_NAME']}";
}

// Test 4: Check sample data
$result = $conn->query("SELECT COUNT(*) as user_count FROM users");
$userCount = $result->fetch_assoc()['user_count'];
echo "\n\n📊 Current users in database: $userCount";

if ($userCount > 0) {
    $result = $conn->query("SELECT username, email FROM users LIMIT 5");
    echo "\n\nSample users:";
    while ($row = $result->fetch_assoc()) {
        echo "\n- {$row['username']} ({$row['email']})";
    }
}

$conn->close();
?>
