<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

require_once 'auth_helper.php';

// Turn off error messages as HTML
// DEBUG: Show all errors (remove in production)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

$host = "localhost";
$user = "root";
$password = "";
$db = "flutter_auth"; // your DB

$conn = new mysqli($host, $user, $password, $db);
if ($conn->connect_error) {
    echo json_encode(["success" => false, "message" => "Connection failed", "error" => $conn->connect_error]);
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        // Require authentication for GET requests
        requireAuth();
        $currentUserId = getCurrentUserId();
        
        // Return list with client names (filtered by user)
        $query = "SELECT p.*, c.name as client_name, c.phone as client_phone 
                  FROM payments p 
                  LEFT JOIN clients c ON p.client_id = c.id AND p.user_id = c.user_id
                  WHERE p.user_id = ? 
                  ORDER BY p.timestamp DESC";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $currentUserId);
        $stmt->execute();
        $result = $stmt->get_result();

        if (!$result) {
            echo json_encode(["success" => false, "message" => "Query failed", "error" => $conn->error]);
            $conn->close();
            exit();
        }

        $data = [];
        while ($row = $result->fetch_assoc()) {
            $data[] = $row;
        }

        echo json_encode(["success" => true, "data" => $data]);
        break;

    case 'POST':
        // Require authentication for POST requests
        requireAuth();
        $currentUserId = getCurrentUserId();
        
        // INSERT payment
        $json = file_get_contents("php://input");
        $data = json_decode($json, true);

        if (!$data) {
            echo json_encode(["success" => false, "message" => "Invalid JSON", "raw" => $json]);
            exit();
        }

        // Validate
        $required = ['client_id', 'amount', 'timestamp', 'tag', 'note', 'status']; // installment_id optional
        foreach ($required as $field) {
            if (!isset($data[$field])) {
                echo json_encode(["success" => false, "message" => "Missing field: $field"]);
                exit();
            }
        }

        $client_id = intval($data['client_id']);
        $amount = floatval($data['amount']);
        $timestamp = $data['timestamp'];  // ISO 8601 string
        $tag = $data['tag'];
        $note = $data['note'];
        $status = $data['status'];
        $installment_id = isset($data['installment_id']) ? intval($data['installment_id']) : null;

        // Check if client belongs to current user
        $checkStmt = $conn->prepare("SELECT id FROM clients WHERE id = ? AND user_id = ?");
        $checkStmt->bind_param("ii", $client_id, $currentUserId);
        $checkStmt->execute();
        $result = $checkStmt->get_result();
        if ($result->num_rows === 0) {
            echo json_encode(["success" => false, "message" => "Client not found or access denied"]);
            $checkStmt->close();
            exit();
        }
        $checkStmt->close();

        // Normalize amount sign based on status for consistent reporting
        // 'sent' => debit (negative), 'received' => credit (positive)
        if ($status === 'sent') {
            $amount = -abs($amount);
        } else if ($status === 'received') {
            $amount = abs($amount);
        }

        $stmt = $conn->prepare("INSERT INTO payments (user_id, client_id, amount, timestamp, tag, note, status, installment_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        if (!$stmt) {
            echo json_encode(["success" => false, "message" => "Prepare failed", "error" => $conn->error]);
            exit();
        }

        $stmt->bind_param("iidssssi", $currentUserId, $client_id, $amount, $timestamp, $tag, $note, $status, $installment_id);
        $success = $stmt->execute();
        
        if ($success && $installment_id) {
            // Update installment status (check if it belongs to current user)
            $updateStmt = $conn->prepare("UPDATE installments SET status = 'paid' WHERE id = ? AND user_id = ?");
            $updateStmt->bind_param("ii", $installment_id, $currentUserId);
            $updateStmt->execute();
            $updateStmt->close();

            // Fetch plan_id of this installment
            $planStmt = $conn->prepare("SELECT plan_id FROM installments WHERE id = ? AND user_id = ?");
            $planStmt->bind_param("ii", $installment_id, $currentUserId);
            $planStmt->execute();
            $planResult = $planStmt->get_result();
            if ($planRow = $planResult->fetch_assoc()) {
                $plan_id = intval($planRow['plan_id']);
                // Check if any pending installments remain for this plan
                $pendingStmt = $conn->prepare("SELECT COUNT(*) AS pending_count FROM installments WHERE plan_id = ? AND user_id = ? AND status <> 'paid'");
                $pendingStmt->bind_param("ii", $plan_id, $currentUserId);
                $pendingStmt->execute();
                $pendingRes = $pendingStmt->get_result();
                $pendingRow = $pendingRes->fetch_assoc();
                $pendingCount = intval($pendingRow['pending_count'] ?? 0);
                $pendingStmt->close();

                if ($pendingCount === 0) {
                    // Mark plan as completed
                    $completeStmt = $conn->prepare("UPDATE installment_plans SET status = 'completed' WHERE id = ? AND user_id = ?");
                    $completeStmt->bind_param("ii", $plan_id, $currentUserId);
                    $completeStmt->execute();
                    $completeStmt->close();
                }
            }
            $planStmt->close();
        }
        
        if ($success) {
            echo json_encode(["success" => true, "message" => "Payment added"]);
        } else {
            echo json_encode(["success" => false, "message" => "Insert failed", "error" => $stmt->error]);
        }

        $stmt->close();
        break;

    default:
        http_response_code(405);
        echo json_encode(['success' => false, 'message' => 'Method not allowed']);
        break;
}

$conn->close();
?>
