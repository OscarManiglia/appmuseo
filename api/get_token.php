<?php
require_once 'config.php';

// Set CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Get user ID from request
$data = json_decode(file_get_contents('php://input'), true);
$userId = isset($data['user_id']) ? $data['user_id'] : null;

if (!$userId) {
    echo json_encode(['success' => false, 'message' => 'ID utente non fornito']);
    exit;
}

try {
    // Connect to database
    $conn = new PDO("mysql:host=$db_host;dbname=$db_name", $db_user, $db_pass);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Debug: Log the query and parameters
    error_log("Checking token for user ID: $userId");
    
    // Get current token for user - modified to get all token details
    $stmt = $conn->prepare("SELECT token, scadenza FROM tokens WHERE id_utente = ? ORDER BY scadenza DESC LIMIT 1");
    $stmt->execute([$userId]);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($result && isset($result['token'])) {
        // Debug: Log token details
        error_log("Token found for user ID: $userId, expires: " . $result['scadenza']);
        
        // Check if token is still valid
        $now = new DateTime();
        $expiry = new DateTime($result['scadenza']);
        
        if ($expiry > $now) {
            // Token is valid
            error_log("Token is valid until: " . $result['scadenza']);
            echo json_encode(['success' => true, 'token' => $result['token']]);
        } else {
            // Token has expired, generate a new one
            error_log("Token expired on: " . $result['scadenza']);
            generateNewToken($conn, $userId);
        }
    } else {
        // No token found, generate a new one
        error_log("No token found for user ID: $userId");
        generateNewToken($conn, $userId);
    }
} catch (PDOException $e) {
    error_log("Database error: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'Errore del database: ' . $e->getMessage()]);
}

// Function to generate a new token
function generateNewToken($conn, $userId) {
    try {
        $newToken = bin2hex(random_bytes(32));
        $expiryDate = date('Y-m-d H:i:s', strtotime('+1 day')); // Token expires in 1 day
        
        $insertStmt = $conn->prepare("INSERT INTO tokens (token, id_utente, scadenza) VALUES (?, ?, ?)");
        $insertResult = $insertStmt->execute([$newToken, $userId, $expiryDate]);
        
        if ($insertResult) {
            error_log("New token generated for user ID: $userId, expires: $expiryDate");
            echo json_encode(['success' => true, 'token' => $newToken]);
        } else {
            error_log("Failed to generate new token for user ID: $userId");
            echo json_encode(['success' => false, 'message' => 'Impossibile generare un nuovo token']);
        }
    } catch (Exception $e) {
        error_log("Error generating token: " . $e->getMessage());
        echo json_encode(['success' => false, 'message' => 'Errore nella generazione del token: ' . $e->getMessage()]);
    }
}
?>