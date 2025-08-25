<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

require_once 'auth_helper.php';

$host = "localhost";
$user = "root";
$password = "";
$db = "flutter_auth";

$conn = new mysqli($host, $user, $password, $db);
if ($conn->connect_error) {
    echo json_encode(["success" => false, "message" => "Connection failed"]);
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];

// ====================== POST: Create a Plan + Monthly Installments ======================
if ($method === 'POST') {
    // Require authentication for POST requests
    requireAuth();
    $currentUserId = getCurrentUserId();
    
    $data = json_decode(file_get_contents("php://input"), true);

    if (!isset($data['client_id'], $data['amount'], $data['months'], $data['start_date'])) {
        echo json_encode(["success" => false, "message" => "Missing fields"]);
        exit();
    }

    $client_id = intval($data['client_id']);
    $amount = floatval($data['amount']);
    $months = intval($data['months']);
    $start_date = new DateTime($data['start_date']);
    $monthly_amount = round($amount / $months, 2);

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

    // Insert into installment_plans
    $planStmt = $conn->prepare("INSERT INTO installment_plans (user_id, client_id, total_amount, months, start_date) VALUES (?, ?, ?, ?, ?)");
    $planStmt->bind_param("iidss", $currentUserId, $client_id, $amount, $months, $data['start_date']);
    $planStmt->execute();

    if ($planStmt->error) {
        echo json_encode(["success" => false, "message" => "Plan insert failed: " . $planStmt->error]);
        exit();
    }

    $plan_id = $planStmt->insert_id;

    // Insert monthly installments
    $stmt = $conn->prepare("INSERT INTO installments (user_id, plan_id, month_year, amount, status) VALUES (?, ?, ?, ?, 'pending')");
    for ($i = 0; $i < $months; $i++) {
        $monthYear = $start_date->format('Y-m');
        $stmt->bind_param("iisd", $currentUserId, $plan_id, $monthYear, $monthly_amount);
        $stmt->execute();
        $start_date->modify('+1 month');
    }

    echo json_encode(["success" => true, "message" => "Installment plan created"]);
    exit;
}

// ====================== GET: Fetch Plans or Monthly Installments ======================
if ($method === 'GET') {
    // Require authentication for GET requests
    requireAuth();
    $currentUserId = getCurrentUserId();
    
    $type = $_GET['type'] ?? null;

    // ✅ Fetch installment plans (all or filtered by client)
    if ($type === 'plans') {
        if (isset($_GET['client_id'])) {
            $client_id = intval($_GET['client_id']);
            $stmt = $conn->prepare("
                SELECT p.*, 
                       COUNT(i.id) AS total_installments,
                       SUM(CASE WHEN i.status = 'paid' THEN 1 ELSE 0 END) AS paid_installments
                FROM installment_plans p
                LEFT JOIN installments i ON p.id = i.plan_id AND p.user_id = i.user_id
                WHERE p.client_id = ? AND p.user_id = ?
                GROUP BY p.id
            ");
            $stmt->bind_param("ii", $client_id, $currentUserId);
        } else {
            $stmt = $conn->prepare("
                SELECT p.*, 
                       COUNT(i.id) AS total_installments,
                       SUM(CASE WHEN i.status = 'paid' THEN 1 ELSE 0 END) AS paid_installments
                FROM installment_plans p
                LEFT JOIN installments i ON p.id = i.plan_id AND p.user_id = i.user_id
                WHERE p.user_id = ?
                GROUP BY p.id
            ");
            $stmt->bind_param("i", $currentUserId);
        }

        $stmt->execute();
        $result = $stmt->get_result();

        $plans = [];
        while ($row = $result->fetch_assoc()) {
            $total = intval($row['total_installments'] ?? 0);
            $paid = intval($row['paid_installments'] ?? 0);
            $row['is_completed'] = ($total > 0 && $paid >= $total) || (isset($row['status']) && $row['status'] === 'completed');
            $plans[] = $row;
        }

        echo json_encode(["success" => true, "data" => $plans]);
        exit;
    }

    // ✅ Fetch monthly installments by plan_id
    if ($type === 'installments' && isset($_GET['plan_id'])) {
        $plan_id = intval($_GET['plan_id']);
        $stmt = $conn->prepare("SELECT * FROM installments WHERE plan_id = ? AND user_id = ?");
        $stmt->bind_param("ii", $plan_id, $currentUserId);
        $stmt->execute();

        $result = $stmt->get_result();
        $installments = [];

        while ($row = $result->fetch_assoc()) {
            $installments[] = $row;
        }

        echo json_encode(["success" => true, "data" => $installments]);
        exit;
    }

    // ✅ Fetch pending installments by client_id (for AddPaymentPage)
    if ($type === 'pending' && isset($_GET['client_id'])) {
        $client_id = intval($_GET['client_id']);
        $stmt = $conn->prepare("
            SELECT i.id, i.month_year, i.amount 
            FROM installments i
            JOIN installment_plans p ON i.plan_id = p.id AND i.user_id = p.user_id
            WHERE i.status = 'pending' AND p.client_id = ? AND i.user_id = ?
            ORDER BY i.month_year ASC
        ");
        $stmt->bind_param("ii", $client_id, $currentUserId);
        $stmt->execute();

        $result = $stmt->get_result();
        $pending = [];

        while ($row = $result->fetch_assoc()) {
            $pending[] = $row;
        }

        echo json_encode(["success" => true, "data" => $pending]);
        exit;
    }

    echo json_encode(["success" => false, "message" => "Invalid GET request"]);
    exit;
}

echo json_encode(["success" => false, "message" => "Invalid request method"]);
$conn->close();
