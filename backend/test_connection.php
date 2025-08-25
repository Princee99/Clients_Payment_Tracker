<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

$host = "localhost";
$user = "root";
$password = "";
$db = "flutter_auth";

$conn = new mysqli($host, $user, $password, $db);
if ($conn->connect_error) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed: ' . $conn->connect_error]);
    exit;
}

// Test clients table
$clients_result = $conn->query("SELECT COUNT(*) as count FROM clients");
$clients_count = $clients_result->fetch_assoc()['count'];

// Test payments table
$payments_result = $conn->query("SELECT COUNT(*) as count FROM payments");
$payments_count = $payments_result->fetch_assoc()['count'];

// Get sample data
$sample_clients = $conn->query("SELECT * FROM clients LIMIT 3");
$sample_payments = $conn->query("SELECT * FROM payments LIMIT 3");

$clients_data = [];
while ($row = $sample_clients->fetch_assoc()) {
    $clients_data[] = $row;
}

$payments_data = [];
while ($row = $sample_payments->fetch_assoc()) {
    $payments_data[] = $row;
}

echo json_encode([
    'success' => true,
    'database' => 'Connected successfully',
    'clients_count' => $clients_count,
    'payments_count' => $payments_count,
    'sample_clients' => $clients_data,
    'sample_payments' => $payments_data
]);

$conn->close();
?> 