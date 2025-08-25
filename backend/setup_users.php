<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

$host = "localhost";
$user = "root";
$password = "";
$db = "flutter_auth";

$conn = new mysqli($host, $user, $password, $db);
if ($conn->connect_error) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed: ' . $conn->connect_error]);
    exit;
}

// Check if users table exists
$result = $conn->query("SHOW TABLES LIKE 'users'");
if ($result->num_rows === 0) {
    echo json_encode(['success' => false, 'message' => 'Users table does not exist. Please run the database_schema.sql first.']);
    exit;
}

// Check if users already exist
$result = $conn->query("SELECT COUNT(*) as count FROM users");
$userCount = $result->fetch_assoc()['count'];

if ($userCount > 0) {
    echo json_encode(['success' => false, 'message' => "Users already exist ($userCount users found). No need to setup."]);
    exit;
}

// Create test users
$testUsers = [
    [
        'username' => 'admin',
        'password' => 'password123',
        'email' => 'admin@example.com'
    ],
    [
        'username' => 'user1',
        'password' => 'password123',
        'email' => 'user1@example.com'
    ],
    [
        'username' => 'user2',
        'password' => 'password123',
        'email' => 'user2@example.com'
    ]
];

$successCount = 0;
$errors = [];

foreach ($testUsers as $userData) {
    $username = $userData['username'];
    $password = password_hash($userData['password'], PASSWORD_DEFAULT);
    $email = $userData['email'];
    
    $stmt = $conn->prepare("INSERT INTO users (username, password, email) VALUES (?, ?, ?)");
    if ($stmt) {
        $stmt->bind_param("sss", $username, $password, $email);
        if ($stmt->execute()) {
            $successCount++;
        } else {
            $errors[] = "Failed to create user $username: " . $stmt->error;
        }
        $stmt->close();
    } else {
        $errors[] = "Failed to prepare statement for user $username: " . $conn->error;
    }
}

if ($successCount > 0) {
    echo json_encode([
        'success' => true,
        'message' => "Successfully created $successCount test users",
        'users_created' => $successCount,
        'login_credentials' => [
            'username' => 'admin',
            'password' => 'password123',
            'note' => 'Use these credentials to test the system'
        ]
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Failed to create any users',
        'errors' => $errors
    ]);
}

$conn->close();
?>
