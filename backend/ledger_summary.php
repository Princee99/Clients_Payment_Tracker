<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

require_once 'auth_helper.php';

$host = "localhost";
$user = "root";
$password = "";
$db = "flutter_auth";

$conn = new mysqli($host, $user, $password, $db);
if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit;
}

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    // Require authentication for GET requests
    requireAuth();
    $currentUserId = getCurrentUserId();
    
    $client_id = isset($_GET['client_id']) ? intval($_GET['client_id']) : null;
    
    if (!$client_id) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Client ID is required']);
        exit;
    }
    
    // Check if client belongs to current user
    $checkStmt = $conn->prepare("SELECT id FROM clients WHERE id = ? AND user_id = ?");
    $checkStmt->bind_param("ii", $client_id, $currentUserId);
    $checkStmt->execute();
    $result = $checkStmt->get_result();
    if ($result->num_rows === 0) {
        http_response_code(403);
        echo json_encode(['success' => false, 'message' => 'Client not found or access denied']);
        $checkStmt->close();
        exit;
    }
    $checkStmt->close();
    
    // Get summary data for the client (filtered by user)
    $query = "SELECT 
                SUM(CASE WHEN amount < 0 THEN ABS(amount) ELSE 0 END) as total_debit,
                SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as total_credit,
                SUM(amount) as outstanding_balance,
                MAX(timestamp) as last_transaction_date
              FROM payments 
              WHERE client_id = ? AND user_id = ?";
    
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Query preparation failed']);
        exit;
    }
    
    $stmt->bind_param("ii", $client_id, $currentUserId);
    $stmt->execute();
    $result = $stmt->get_result();
    $summary = $result->fetch_assoc();
    
    // Convert null values to 0
    $summary['total_debit'] = $summary['total_debit'] ?? 0;
    $summary['total_credit'] = $summary['total_credit'] ?? 0;
    $summary['outstanding_balance'] = $summary['outstanding_balance'] ?? 0;
    $summary['last_transaction_date'] = $summary['last_transaction_date'] ?? null;
    
    echo json_encode(['success' => true, 'data' => $summary]);
    
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?> 