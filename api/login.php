<?php
// Disabilita la visualizzazione degli errori PHP nella risposta
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Fix the path to config.php
require_once __DIR__ . '/config.php';

// Set CORS headers
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

try {
    // Get login data from request
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);
    
    // Debug: Log received data
    error_log("Login attempt - Input data: " . print_r($data, true));
    
    // Se non è JSON, prova con i dati POST
    if (json_last_error() !== JSON_ERROR_NONE) {
        $email = isset($_POST['email']) ? $_POST['email'] : '';
        $password = isset($_POST['password']) ? $_POST['password'] : '';
    } else {
        $email = isset($data['email']) ? $data['email'] : '';
        $password = isset($data['password']) ? $data['password'] : '';
    }
    
    // Debug: Log extracted credentials
    error_log("Login attempt - Email: $email, Password length: " . strlen($password));
    
    // Validate input
    if (empty($email) || empty($password)) {
        echo json_encode([
            'success' => false,
            'message' => 'Email e password sono obbligatori'
        ]);
        exit;
    }
    
    // Connect to database
    $conn = new mysqli($db_host, $db_user, $db_pass, $db_name);
    
    // Check connection
    if ($conn->connect_error) {
        throw new Exception("Connessione al database fallita: " . $conn->connect_error);
    }
    
    // Check if user exists - IMPORTANT: Case-insensitive email comparison
    $stmt = $conn->prepare("SELECT id, Nome, Cognome, Email, Password FROM utenti WHERE LOWER(Email) = LOWER(?)");
    if (!$stmt) {
        throw new Exception("Errore nella preparazione della query: " . $conn->error);
    }
    
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        // Debug: Log user not found
        error_log("Login failed: User with email $email not found");
        
        echo json_encode([
            'success' => false,
            'message' => 'Credenziali non valide'
        ]);
        exit;
    }
    
    $user = $result->fetch_assoc();
    
    // Debug: Log user found
    error_log("User found: ID=" . $user['id'] . ", Email=" . $user['Email']);
    
    // Verify password - Try multiple methods to be safe
    $passwordValid = false;
    
    // Method 1: Direct comparison (for plain text passwords)
    if ($password === $user['Password']) {
        $passwordValid = true;
        error_log("Password verified with direct comparison");
    }
    
    // Method 2: password_verify (for hashed passwords)
    if (!$passwordValid && function_exists('password_verify') && password_verify($password, $user['Password'])) {
        $passwordValid = true;
        error_log("Password verified with password_verify");
    }
    
    // Method 3: md5 (older hash method, not recommended but checking for compatibility)
    if (!$passwordValid && md5($password) === $user['Password']) {
        $passwordValid = true;
        error_log("Password verified with md5");
    }
    
    if (!$passwordValid) {
        // Debug: Log password mismatch
        error_log("Login failed: Password mismatch for user " . $user['Email']);
        
        echo json_encode([
            'success' => false,
            'message' => 'Credenziali non valide'
        ]);
        exit;
    }
    
    // Generate token
    $token = bin2hex(random_bytes(32));
    $expiry = date('Y-m-d H:i:s', strtotime('+1 day'));
    
    // Store token in database
    $token_stmt = $conn->prepare("INSERT INTO tokens (token, id_utente, scadenza) VALUES (?, ?, ?)");
    if (!$token_stmt) {
        throw new Exception("Errore nella preparazione della query token: " . $conn->error);
    }
    
    $token_stmt->bind_param("sis", $token, $user['id'], $expiry);
    $token_stmt->execute();
    
    // Set user as logged in
    $update_stmt = $conn->prepare("UPDATE utenti SET Logged = 1 WHERE id = ?");
    if (!$update_stmt) {
        throw new Exception("Errore nella preparazione della query update: " . $conn->error);
    }
    
    $update_stmt->bind_param("i", $user['id']);
    $update_stmt->execute();
    
    // Return user data and token
    echo json_encode([
        'success' => true,
        'message' => 'Login effettuato con successo',
        'user' => [
            'id' => $user['id'],
            'nome' => $user['Nome'],
            'cognome' => $user['Cognome'],
            'email' => $user['Email']
        ],
        'token' => $token
    ]);
    
    // Close statements and connection
    $stmt->close();
    $token_stmt->close();
    $update_stmt->close();
    $conn->close();
    
} catch (Exception $e) {
    // Log error to file
    error_log("Login error: " . $e->getMessage());
    
    // Return error message as JSON
    echo json_encode([
        'success' => false,
        'message' => 'Si è verificato un errore durante il login: ' . $e->getMessage()
    ]);
}
?>