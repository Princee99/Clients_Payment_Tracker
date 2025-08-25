<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

session_start();

// Clear the session
session_destroy();

echo json_encode([
    'success' => true, 
    'message' => 'Logged out successfully'
]);
?>
