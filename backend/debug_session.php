<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");

session_start();

echo json_encode([
    'session_id' => session_id(),
    'session_data' => $_SESSION,
    'user_id' => $_SESSION['user_id'] ?? 'NOT SET',
    'username' => $_SESSION['username'] ?? 'NOT SET',
    'is_authenticated' => isset($_SESSION['user_id']) && !empty($_SESSION['user_id']),
    'cookies' => $_COOKIE,
    'request_method' => $_SERVER['REQUEST_METHOD'],
    'content_type' => $_SERVER['CONTENT_TYPE'] ?? 'NOT SET'
]);
?>
