<?php
// Include the configuration file
require_once 'config.php';

// Create connection
$conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

// Check connection
if ($conn->connect_error) {
    die(json_encode(['success' => false, 'error' => "Connection failed: " . $conn->connect_error]));
}

// Get user ID from request
$user_id = isset($_POST['user_id']) ? $_POST['user_id'] : '';

if (empty($user_id)) {
    echo json_encode(['success' => false, 'error' => 'User ID is required', 'logged' => false]);
    $conn->close();
    exit;
}

// Check if user is logged in
$stmt = $conn->prepare("SELECT Logged FROM utenti WHERE ID = ?");
$stmt->bind_param("s", $user_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    $logged = ($row['Logged'] == '1' || $row['Logged'] == 'True') ? true : false;
    echo json_encode(['success' => true, 'logged' => $logged]);
} else {
    echo json_encode(['success' => false, 'error' => 'User not found', 'logged' => false]);
}

$stmt->close();
$conn->close();
?>