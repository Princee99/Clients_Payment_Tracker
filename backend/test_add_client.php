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

// Test session state
session_start();
echo "Session ID: " . session_id() . "\n";
echo "Session data: " . print_r($_SESSION, true) . "\n";

// Check if user is authenticated
if (!isAuthenticated()) {
    echo json_encode(['success' => false, 'message' => 'User not authenticated']);
    exit;
}

$currentUserId = getCurrentUserId();
echo "Current User ID: " . $currentUserId . "\n";

// Try to add a test client
$testName = "Test Client " . date('Y-m-d H:i:s');
$testPhone = "+1234567890";
$testAddress = "Test Address";

$stmt = $conn->prepare("INSERT INTO clients (user_id, name, phone, address) VALUES (?, ?, ?, ?)");
if ($stmt) {
    $stmt->bind_param("isss", $currentUserId, $testName, $testPhone, $testAddress);
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true, 
            'message' => 'Test client added successfully', 
            'id' => $stmt->insert_id,
            'user_id' => $currentUserId
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to add test client: ' . $stmt->error]);
    }
    $stmt->close();
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to prepare statement: ' . $conn->error]);
}

$conn->close();
?>
