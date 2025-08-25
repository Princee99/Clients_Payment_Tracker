<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

require_once 'jwt_helper.php';

$host = "localhost";
$user = "root";
$password = "";
$db = "flutter_auth";

$conn = new mysqli($host, $user, $password, $db);

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $username = $_POST['username'];
    $password = $_POST['password'];

    $query = "SELECT * FROM users WHERE username=?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("s", $username);
    $stmt->execute();

    $result = $stmt->get_result();

    if ($result->num_rows === 1) {
        $user = $result->fetch_assoc();
        
        if (password_verify($password, $user['password'])) {
            // Generate JWT token
            $payload = [
                'user_id' => $user['id'],
                'username' => $user['username'],
                'exp' => time() + (24 * 60 * 60), // 24 hours expiration
                'iat' => time()
            ];
            
            $token = JWT::encode($payload);
            
            echo json_encode([
                'success' => true, 
                'user_id' => $user['id'],
                'username' => $user['username'],
                'token' => $token
            ]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Invalid password']);
        }
    } else {
        echo json_encode(['success' => false, 'message' => 'User not found']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request']);
}

$conn->close();
?>
