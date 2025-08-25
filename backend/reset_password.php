<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

$host = "localhost";
$user = "root";
$password = "";
$db = "flutter_auth";

$conn = new mysqli($host, $user, $password, $db);
if ($conn->connect_error) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed: ' . $conn->connect_error]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Invalid request']);
    $conn->close();
    exit;
}

$raw = file_get_contents('php://input');
$data = json_decode($raw, true);

$username = isset($data['username']) ? trim($data['username']) : '';
$newPassword = isset($data['new_password']) ? $data['new_password'] : '';

if ($username === '' || $newPassword === '') {
    echo json_encode(['success' => false, 'message' => 'Username and new_password are required']);
    $conn->close();
    exit;
}

$stmt = $conn->prepare("SELECT id FROM users WHERE username = ?");
if (!$stmt) {
    echo json_encode(['success' => false, 'message' => 'Query prepare failed: ' . $conn->error]);
    $conn->close();
    exit;
}
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();
if ($result->num_rows === 0) {
    echo json_encode(['success' => false, 'message' => 'User not found']);
    $stmt->close();
    $conn->close();
    exit;
}
$stmt->close();

$hashed = password_hash($newPassword, PASSWORD_DEFAULT);
$update = $conn->prepare("UPDATE users SET password = ? WHERE username = ?");
if (!$update) {
    echo json_encode(['success' => false, 'message' => 'Update prepare failed: ' . $conn->error]);
    $conn->close();
    exit;
}
$update->bind_param("ss", $hashed, $username);
if ($update->execute()) {
    echo json_encode(['success' => true, 'message' => 'Password updated successfully']);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to update password']);
}
$update->close();
$conn->close();
?>


