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
    $start_date = isset($_GET['start_date']) ? $_GET['start_date'] : null;
    $end_date = isset($_GET['end_date']) ? $_GET['end_date'] : null;
    
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
    
    // Build the query with date filters and user isolation
    $query = "SELECT 
                p.id,
                p.client_id,
                p.timestamp as date,
                CONCAT(p.tag, ' - ', p.note) as description,
                CASE 
                    WHEN p.amount < 0 THEN ABS(p.amount)
                    ELSE 0 
                END as debit,
                CASE 
                    WHEN p.amount > 0 THEN p.amount
                    ELSE 0 
                END as credit,
                p.amount as running_balance,
                p.tag as reference,
                p.note as notes
              FROM payments p 
              WHERE p.client_id = ? AND p.user_id = ?";
    
    $params = [$client_id, $currentUserId];
    $types = "ii";
    
    if ($start_date) {
        $query .= " AND DATE(p.timestamp) >= ?";
        $params[] = $start_date;
        $types .= "s";
    }
    
    if ($end_date) {
        $query .= " AND DATE(p.timestamp) <= ?";
        $params[] = $end_date;
        $types .= "s";
    }
    
    $query .= " ORDER BY p.timestamp ASC";
    
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Query preparation failed']);
        exit;
    }
    
    $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $ledger_entries = [];
    $running_balance = 0;
    
    while ($row = $result->fetch_assoc()) {
        // Calculate running balance by adding the current payment amount
        $payment_amount = floatval($row['running_balance']);
        $running_balance += $payment_amount;
        $row['running_balance'] = $running_balance;
        $ledger_entries[] = $row;
    }
    
    echo json_encode(['success' => true, 'data' => $ledger_entries]);
    
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

$conn->close();
?> 