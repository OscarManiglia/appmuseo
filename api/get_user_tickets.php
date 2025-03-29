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

    // Verify token if provided in Authorization header
    $headers = getallheaders();
    if (isset($headers['Authorization'])) {
        $authHeader = $headers['Authorization'];
        $token = str_replace('Bearer ', '', $authHeader);

        $stmt = $conn->prepare("SELECT id_utente, scadenza FROM tokens WHERE token = ? AND id_utente = ?");
        if (!$stmt) {
            throw new Exception("Errore nella preparazione della query token: " . $conn->error);
        }

        $stmt->bind_param("si", $token, $userId);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows === 0) {
            echo json_encode(['success' => false, 'message' => 'Token non valido o scaduto']);
            exit;
        }

        $tokenData = $result->fetch_assoc();

        // Check if token is expired
        $now = new DateTime();
        $expiry = new DateTime($tokenData['scadenza']);

        if ($expiry < $now) {
            echo json_encode(['success' => false, 'message' => 'Token scaduto. Effettua nuovamente il login.']);
            exit;
        }

        $stmt->close();
    } else {
        echo json_encode(['success' => false, 'message' => 'Token di autorizzazione mancante']);
        exit;
    }

    // Get user tickets
    $query = "SELECT b.*, m.nome as nome_museo 
              FROM biglietti b 
              JOIN musei m ON b.id_museo = m.id 
              WHERE b.id_utente = ? 
              ORDER BY b.data_visita DESC, b.ora_visita DESC";
    
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        throw new Exception("Errore nella preparazione della query biglietti: " . $conn->error);
    }

    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();

    $tickets = [];
    while ($row = $result->fetch_assoc()) {
        $tickets[] = $row;
    }

    echo json_encode([
        'success' => true,
        'tickets' => $tickets
    ]);

    $stmt->close();
    $conn->close();

} catch (Exception $e) {
    // Log error to file
    error_log("Get user tickets error: " . $e->getMessage());

    // Return error message as JSON
    echo json_encode([
        'success' => false,
        'message' => 'Si è verificato un errore: ' . $e->getMessage()
    ]);
}
?>