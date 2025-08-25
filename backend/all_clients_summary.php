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
    
    // Get summary data for all clients (filtered by user)
    $query = "SELECT 
                c.id as client_id,
                c.name as client_name,
                c.phone as client_phone,
                COALESCE(SUM(CASE WHEN p.amount < 0 THEN ABS(p.amount) ELSE 0 END), 0) as total_debit,
                COALESCE(SUM(CASE WHEN p.amount > 0 THEN p.amount ELSE 0 END), 0) as total_credit,
                COALESCE(SUM(p.amount), 0) as outstanding_balance,
                MAX(p.timestamp) as last_transaction_date
              FROM clients c
              LEFT JOIN payments p ON c.id = p.client_id AND c.user_id = p.user_id
              WHERE c.user_id = ?
              GROUP BY c.id, c.name, c.phone
              ORDER BY outstanding_balance DESC";
    
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Query preparation failed']);
        exit;
    }
    
    $stmt->bind_param("i", $currentUserId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if (!$result) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Query failed: ' . $conn->error]);
        exit;
    }
    
    $clients_summary = [];
    while ($row = $result->fetch_assoc()) {
        $clients_summary[] = $row;
    }
    
    echo json_encode(['success' => true, 'data' => $clients_summary]);
    
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?> 