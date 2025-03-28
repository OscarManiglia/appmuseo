<?php
require_once 'db_connect.php';

// Get POST data
$user_id = $_POST['user_id'] ?? '';
$museum_id = $_POST['museum_id'] ?? '';
$ticket_type = $_POST['ticket_type'] ?? '';
$price = $_POST['price'] ?? '';

// Validate inputs
if (empty($user_id) || empty($museum_id) || empty($ticket_type) || empty($price)) {
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit;
}

try {
    // Check if connection is established
    if (!$conn) {
        throw new Exception("Database connection failed");
    }
    
    // Generate a unique ticket ID
    $ticket_id = uniqid('TICKET-');
    $purchase_date = date('Y-m-d H:i:s');
    
    // Create QR data (ticket information encoded as JSON)
    $qr_data = json_encode([
        'ticket_id' => $ticket_id,
        'user_id' => $user_id,
        'museum_id' => $museum_id,
        'ticket_type' => $ticket_type,
        'purchase_date' => $purchase_date,
        'valid_until' => date('Y-m-d H:i:s', strtotime('+1 day')),
    ]);
    
    // Insert ticket into database
    $stmt = $conn->prepare("INSERT INTO tickets (ticket_id, user_id, museum_id, ticket_type, price, purchase_date, qr_data) 
                           VALUES (?, ?, ?, ?, ?, ?, ?)");
    
    if (!$stmt) {
        throw new Exception("Prepare statement failed: " . $conn->error);
    }
    
    $stmt->bind_param("siisdss", $ticket_id, $user_id, $museum_id, $ticket_type, $price, $purchase_date, $qr_data);
    
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true, 
            'ticket_id' => $ticket_id,
            'purchase_date' => $purchase_date,
            'qr_data' => $qr_data
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to save ticket: ' . $stmt->error]);
    }
    
    $stmt->close();
    
} catch (Exception $e) {
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

if ($conn) {
    $conn->close();
}
?>