<?php
// Disabilita la visualizzazione degli errori PHP nella risposta
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Fix the path to config.php
require_once __DIR__ . '/config.php';

// Set CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    // Get request data
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    
    // Debug: Log received data
    error_log("Purchase ticket attempt - Input data: " . print_r($data, true));
    
    // Validate required fields
    $requiredFields = ['user_id', 'museum_id', 'visit_date', 'visit_time', 'prezzo_totale'];
    foreach ($requiredFields as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            echo json_encode(['success' => false, 'message' => "Campo obbligatorio mancante: $field"]);
            exit;
        }
    }
    
    // Connect to database
    $conn = new mysqli($db_host, $db_user, $db_pass, $db_name);
    
    // Check connection
    if ($conn->connect_error) {
        throw new Exception("Connessione al database fallita: " . $conn->connect_error);
    }
    
    // Verify token if provided
    if (isset($data['token']) && !empty($data['token'])) {
        $token = $data['token'];
        $userId = $data['user_id'];
        
        $stmt = $conn->prepare("SELECT id_utente, scadenza FROM tokens WHERE token = ? AND id_utente = ?");
        if (!$stmt) {
            throw new Exception("Errore nella preparazione della query token: " . $conn->error);
        }
        
        $stmt->bind_param("si", $token, $userId);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            // Debug: Log token not found
            error_log("Purchase failed: Token not found for user $userId");
            
            echo json_encode(['success' => false, 'message' => 'Token non valido o scaduto']);
            exit;
        }
        
        $tokenData = $result->fetch_assoc();
        
        // Check if token is expired
        $now = new DateTime();
        $expiry = new DateTime($tokenData['scadenza']);
        
        if ($expiry < $now) {
            // Debug: Log token expired
            error_log("Purchase failed: Token expired for user $userId. Expired at: " . $tokenData['scadenza']);
            
            echo json_encode(['success' => false, 'message' => 'Token scaduto. Effettua nuovamente il login.']);
            exit;
        }
        
        $stmt->close();
    }
    
    // Generate unique ticket token
    $ticketToken = bin2hex(random_bytes(16));
    
    // Format date and time correctly
    $visitDate = date('Y-m-d', strtotime($data['visit_date']));
    $visitTime = date('H:i:s', strtotime($data['visit_time']));
    
    // Insert ticket into database
    $query = "INSERT INTO biglietti (
        id_utente, 
        id_museo, 
        token, 
        data_visita, 
        ora_visita, 
        num_biglietti_bambini, 
        num_biglietti_giovani, 
        num_biglietti_adulti, 
        num_biglietti_anziani, 
        prezzo_totale
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
    
    $ticket_stmt = $conn->prepare($query);
    if (!$ticket_stmt) {
        throw new Exception("Errore nella preparazione della query biglietti: " . $conn->error . " - Query: " . $query);
    }
    
    // Set default values for ticket counts
    $bambini = isset($data['num_bambini']) ? intval($data['num_bambini']) : 0;
    $giovani = isset($data['num_giovani']) ? intval($data['num_giovani']) : 0;
    $adulti = isset($data['num_adulti']) ? intval($data['num_adulti']) : 0;
    $anziani = isset($data['num_anziani']) ? intval($data['num_anziani']) : 0;
    $prezzo = floatval($data['prezzo_totale']);
    
    $ticket_stmt->bind_param(
        "iisssiiiid",
        $data['user_id'],
        $data['museum_id'],
        $ticketToken,
        $visitDate,
        $visitTime,
        $bambini,
        $giovani,
        $adulti,
        $anziani,
        $prezzo
    );
    
    $result = $ticket_stmt->execute();
    if (!$result) {
        throw new Exception("Errore nell'esecuzione della query: " . $ticket_stmt->error);
    }
    
    $ticketId = $conn->insert_id;
    
    // Get museum name
    $museum_stmt = $conn->prepare("SELECT nome FROM musei WHERE id = ?");
    if (!$museum_stmt) {
        throw new Exception("Errore nella preparazione della query museo: " . $conn->error);
    }
    
    $museum_stmt->bind_param("i", $data['museum_id']);
    $museum_stmt->execute();
    $museum_result = $museum_stmt->get_result();
    $museum_data = $museum_result->fetch_assoc();
    $museum_name = $museum_data ? $museum_data['nome'] : 'Museo sconosciuto';
    
    // Generate QR code data
    $qrData = json_encode([
        'ticket_id' => $ticketId,
        'token' => $ticketToken,
        'museum_id' => $data['museum_id'],
        'museum_name' => $museum_name,
        'visit_date' => $visitDate,
        'visit_time' => $visitTime
    ]);
    
    // Return success response
    echo json_encode([
        'success' => true,
        'ticket_id' => $ticketId,
        'token' => $ticketToken,
        'museum_name' => $museum_name,
        'qr_data' => $qrData
    ]);
    
    // Close statements and connection
    if (isset($stmt)) $stmt->close();
    $ticket_stmt->close();
    $museum_stmt->close();
    $conn->close();
    
} catch (Exception $e) {
    // Log error to file
    error_log("Purchase ticket error: " . $e->getMessage());
    
    // Return error message as JSON
    echo json_encode([
        'success' => false,
        'message' => 'Si è verificato un errore durante l\'acquisto: ' . $e->getMessage()
    ]);
}
?>