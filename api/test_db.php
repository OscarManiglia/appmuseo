<?php
require_once 'db_connect.php';
header('Content-Type: application/json');

if (!isset($conn) || $conn === null) {
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed'
    ]);
    exit;
}

echo json_encode([
    'success' => true,
    'message' => 'Database connection successful',
    'server_info' => $conn->server_info
]);

$conn->close();
?>