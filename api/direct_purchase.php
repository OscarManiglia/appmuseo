<?php
require_once 'config.php';

// Set CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Get request data
$data = json_decode(file_get_contents('php://input'), true);

// Validate required fields
$requiredFields = ['email', 'password', 'user_id', 'museum_id', 'visit_date', 'visit_time', 'prezzo_totale', 'payment_method'];
foreach ($requiredFields as $field) {
    if (!isset($data[$field])) {
        echo json_encode(['success' => false, 'message' => "Campo obbligatorio mancante: $field"]);
        exit;
    }
}

try {
    // Connect to database
    $conn = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Verify user credentials
    $stmt = $conn->prepare("SELECT id, password FROM utenti WHERE email = ?");
    $stmt->execute([$data['email']]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Check if user exists and password matches
    if (!$user || !password_verify($data['password'], $user['password'])) {
        // For plain text passwords (not recommended but for testing)
        $stmt = $conn->prepare("SELECT id FROM utenti WHERE email = ? AND password = ?");
        $stmt->execute([$data['email'], $data['password']]);
        $plainUser = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$plainUser) {
            echo json_encode(['success' => false, 'message' => 'Credenziali non valide']);
            exit;
        }
    }
    
    // Generate ticket token
    $ticketToken = bin2hex(random_bytes(16));
    
    // Insert ticket into database
    $stmt = $conn->prepare("INSERT INTO biglietti (id_utente, id_museo, data_visita, ora_visita, num_bambini, num_giovani, num_adulti, num_anziani, prezzo_totale, metodo_pagamento, token, data_acquisto) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())");
    
    $stmt->execute([
        $data['user_id'],
        $data['museum_id'],
        $data['visit_date'],
        $data['visit_time'],
        $data['num_bambini'] ?? 0,
        $data['num_giovani'] ?? 0,
        $data['num_adulti'] ?? 0,
        $data['num_anziani'] ?? 0,
        $data['prezzo_totale'],
        $data['payment_method'],
        $ticketToken
    ]);
    
    $ticketId = $conn->lastInsertId();
    
    // Generate QR code data
    $qrData = json_encode([
        'ticket_id' => $ticketId,
        'token' => $ticketToken,
        'museum_id' => $data['museum_id'],
        'visit_date' => $data['visit_date'],
        'visit_time' => $data['visit_time']
    ]);
    
    echo json_encode([
        'success' => true,
        'ticket_id' => $ticketId,
        'token' => $ticketToken,
        'qr_data' => $qrData
    ]);
    
} catch (PDOException $e) {
    error_log("Database error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'Errore del database: ' . $e->getMessage()]);
}
?>