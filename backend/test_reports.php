<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type");

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

// Require authentication
requireAuth();
$currentUserId = getCurrentUserId();

// Test the same query as all_clients_summary.php (filtered by user)
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
    echo json_encode(['success' => false, 'message' => 'Query preparation failed']);
    exit;
}

$stmt->bind_param("i", $currentUserId);
$stmt->execute();
$result = $stmt->get_result();

if (!$result) {
    echo json_encode(['success' => false, 'message' => 'Query failed: ' . $conn->error]);
    exit;
}

$clients_summary = [];
$total_debit = 0;
$total_credit = 0;
$total_outstanding = 0;
$clients_with_balance = 0;

while ($row = $result->fetch_assoc()) {
    $clients_summary[] = $row;
    $total_debit += $row['total_debit'];
    $total_credit += $row['total_credit'];
    $total_outstanding += $row['outstanding_balance'];
    if ($row['outstanding_balance'] != 0) {
        $clients_with_balance++;
    }
}

echo json_encode([
    'success' => true,
    'total_clients' => count($clients_summary),
    'clients_with_balance' => $clients_with_balance,
    'total_debit' => $total_debit,
    'total_credit' => $total_credit,
    'total_outstanding' => $total_outstanding,
    'clients_summary' => $clients_summary
]);

$conn->close();
?> 