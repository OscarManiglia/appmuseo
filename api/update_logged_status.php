<?php
// Include the configuration file with database credentials
require_once 'config.php';  // Changed from '../config.php' to 'config.php'

// Create connection
$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

// Check connection
if ($conn->connect_error) {
    die(json_encode(['success' => false, 'error' => "Connection failed: " . $conn->connect_error]));
}

// Get parameters from request
$user_id = isset($_POST['user_id']) ? $_POST['user_id'] : '';
$logged = isset($_POST['logged']) ? $_POST['logged'] : '0';

// Debug information
error_log("Updating logged status for user_id: $user_id to logged: $logged");

if (empty($user_id)) {
    echo json_encode(['success' => false, 'error' => 'User ID is required']);
    $conn->close();
    exit;
}

// Update user login status - using prepared statement for security
$stmt = $conn->prepare("UPDATE utenti SET Logged = ? WHERE ID = ?");
$stmt->bind_param("ss", $logged, $user_id);

if ($stmt->execute()) {
    // Check if any rows were affected
    if ($stmt->affected_rows > 0) {
        echo json_encode(['success' => true, 'message' => 'Login status updated successfully']);
    } else {
        echo json_encode(['success' => true, 'message' => 'No changes needed. Status already set.']);
    }
} else {
    echo json_encode(['success' => false, 'error' => $stmt->error]);
}

$stmt->close();
$conn->close();
?>