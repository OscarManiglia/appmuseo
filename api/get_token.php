<?php
// Disabilita la visualizzazione degli errori PHP nella risposta
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Include config file
require_once __DIR__ . '/config.php';

// Set CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
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

    // Get user token from tokens table
    $stmt = $conn->prepare("SELECT token FROM tokens WHERE id_utente = ? ORDER BY id DESC LIMIT 1");
    if (!$stmt) {
        throw new Exception("Errore nella preparazione della query: " . $conn->error);
    }

    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        // No token found, generate a new one
        $newToken = bin2hex(random_bytes(32));
        
        // Insert new token
        $insertStmt = $conn->prepare("INSERT INTO tokens (id_utente, token) VALUES (?, ?)");
        if (!$insertStmt) {
            throw new Exception("Errore nella preparazione della query di inserimento: " . $conn->error);
        }
        
        $insertStmt->bind_param("is", $userId, $newToken);
        $insertStmt->execute();
        $insertStmt->close();
        
        echo json_encode([
            'success' => true,
            'token' => $newToken,
            'message' => 'Nuovo token generato'
        ]);
    } else {
        $tokenData = $result->fetch_assoc();
        echo json_encode([
            'success' => true,
            'token' => $tokenData['token'],
            'message' => 'Token recuperato con successo'
        ]);
    }

    $stmt->close();
    $conn->close();

} catch (Exception $e) {
    // Log error to file
    error_log("Get token error: " . $e->getMessage());

    // Return error message as JSON
    echo json_encode([
        'success' => false,
        'message' => 'Si è verificato un errore: ' . $e->getMessage()
    ]);
}
?>