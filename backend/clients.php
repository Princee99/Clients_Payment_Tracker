<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");
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

// Helper function to get input JSON for PUT/POST
function getInputData() {
    return json_decode(file_get_contents('php://input'), true);
}

switch ($method) {
    case 'GET':
        // Require authentication for all GET requests
        requireAuth();
        $currentUserId = getCurrentUserId();
        
        // Fetch all clients, by id, or search by name/phone (filtered by user)
        if (isset($_GET['id'])) {
            $id = $_GET['id'];
            $stmt = $conn->prepare("SELECT * FROM clients WHERE id = ? AND user_id = ?");
            $stmt->bind_param("ii", $id, $currentUserId);
        } elseif (isset($_GET['search']) && !empty($_GET['search'])) {
            $search = '%' . $_GET['search'] . '%';
            $stmt = $conn->prepare("SELECT * FROM clients WHERE (name LIKE ? OR phone LIKE ?) AND user_id = ?");
            $stmt->bind_param("ssi", $search, $search, $currentUserId);
        } else {
            $stmt = $conn->prepare("SELECT * FROM clients WHERE user_id = ? ORDER BY name");
            $stmt->bind_param("i", $currentUserId);
        }
        $stmt->execute();
        $result = $stmt->get_result();
        $clients = $result->fetch_all(MYSQLI_ASSOC);
        echo json_encode(['success' => true, 'data' => $clients]);
        break;

    case 'POST':
        // Require authentication for adding clients
        requireAuth();
        $currentUserId = getCurrentUserId();
        
        // Add new client
        $data = getInputData();
        if (!isset($data['name'], $data['phone'], $data['address'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Missing required fields']);
            exit;
        }
        $name = $data['name'];
        $phone = $data['phone'];
        $address = $data['address'];

        $stmt = $conn->prepare("INSERT INTO clients (user_id, name, phone, address) VALUES (?, ?, ?, ?)");
        $stmt->bind_param("isss", $currentUserId, $name, $phone, $address);
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Client added successfully', 'id' => $stmt->insert_id]);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to add client']);
        }
        break;

    case 'PUT':
        // Require authentication for updating clients
        requireAuth();
        $currentUserId = getCurrentUserId();
        
        // Update client
        $data = getInputData();
        if (!isset($data['id'], $data['name'], $data['phone'], $data['address'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Missing required fields']);
            exit;
        }
        $id = $data['id'];
        $name = $data['name'];
        $phone = $data['phone'];
        $address = $data['address'];

        // Check if client belongs to current user
        $checkStmt = $conn->prepare("SELECT id FROM clients WHERE id = ? AND user_id = ?");
        $checkStmt->bind_param("ii", $id, $currentUserId);
        $checkStmt->execute();
        $result = $checkStmt->get_result();
        if ($result->num_rows === 0) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Client not found or access denied']);
            $checkStmt->close();
            exit;
        }
        $checkStmt->close();

        $stmt = $conn->prepare("UPDATE clients SET name = ?, phone = ?, address = ? WHERE id = ? AND user_id = ?");
        $stmt->bind_param("sssii", $name, $phone, $address, $id, $currentUserId);
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Client updated successfully']);
        } else {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to update client']);
        }
        break;

    case 'DELETE':
        // Require authentication for deleting clients
        requireAuth();
        $currentUserId = getCurrentUserId();
        
        // Delete client by id passed as query param
        if (!isset($_GET['id'])) {
            http_response_code(400);
            echo json_encode(['success' => false, 'message' => 'Missing client ID']);
            exit;
        }
        $id = intval($_GET['id']);

        // Check if client exists and belongs to current user
        $checkStmt = $conn->prepare("SELECT id FROM clients WHERE id = ? AND user_id = ?");
        $checkStmt->bind_param("ii", $id, $currentUserId);
        $checkStmt->execute();
        $result = $checkStmt->get_result();
        if ($result->num_rows === 0) {
            http_response_code(404);
            echo json_encode(['success' => false, 'message' => 'Client not found or access denied']);
            $checkStmt->close();
            exit;
        }
        $checkStmt->close();

        // Use stored procedure for safe deletion with all relationships
        try {
            // Call the stored procedure for safe deletion
            $stmt = $conn->prepare("CALL DeleteClientWithRelations(?, ?)");
            if (!$stmt) {
                throw new Exception('Failed to prepare delete procedure: ' . $conn->error);
            }
            
            $stmt->bind_param("ii", $currentUserId, $id);
            if (!$stmt->execute()) {
                throw new Exception('Failed to execute delete procedure: ' . $stmt->error);
            }
            
            $stmt->close();
            echo json_encode(['success' => true, 'message' => 'Client and all related records deleted successfully']);
            
        } catch (Exception $ex) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Delete failed: ' . $ex->getMessage()]);
        }
        break;

    default:
        http_response_code(405);
        echo json_encode(['success' => false, 'message' => 'Method not allowed']);
        break;
}

$conn->close();
?>
