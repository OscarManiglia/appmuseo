<?php
// Disabilita la visualizzazione degli errori PHP nella risposta
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Include config file
require_once __DIR__ . '/config.php';

// Set CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    // Check if user_id is provided
    if (!isset($_GET['user_id']) || empty($_GET['user_id'])) {
        echo json_encode(['success' => false, 'message' => 'ID utente mancante']);
        exit;
    }

    $userId = intval($_GET['user_id']);

    // Connect to database
    $conn = new mysqli($db_host, $db_user, $db_pass, $db_name);

    // Check connection
    if ($conn->connect_error) {
        throw new Exception("Connessione al database fallita: " . $conn->connect_error);
    }

    // Get user data
    $stmt = $conn->prepare("SELECT id, Nome, Cognome, Email FROM utenti WHERE id = ?");
    if (!$stmt) {
        throw new Exception("Errore nella preparazione della query: " . $conn->error);
    }

    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        echo json_encode(['success' => false, 'message' => 'Utente non trovato']);
        exit;
    }

    $userData = $result->fetch_assoc();
    
    echo json_encode([
        'success' => true,
        'user' => $userData
    ]);

    $stmt->close();
    $conn->close();

} catch (Exception $e) {
    // Log error to file
    error_log("Get user data error: " . $e->getMessage());

    // Return error message as JSON
    echo json_encode([
        'success' => false,
        'message' => 'Si è verificato un errore: ' . $e->getMessage()
    ]);
}
?>