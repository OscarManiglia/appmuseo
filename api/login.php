<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');

include 'db_connect.php';

// Check if database connection is established
if (!isset($conn) || $conn === null) {
    echo json_encode([
        'success' => false,
        'message' => 'Errore di connessione al database'
    ]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get login data from request
    $email = isset($_POST['email']) ? $_POST['email'] : '';
    $password = isset($_POST['password']) ? $_POST['password'] : '';
    
    // Validate input
    if (empty($email) || empty($password)) {
        echo json_encode([
            'success' => false,
            'message' => 'Email e password sono obbligatori'
        ]);
        exit;
    }
    
    // Check if user exists
    $stmt = $conn->prepare("SELECT id, Nome, Cognome, Email, Password FROM utenti WHERE Email = ?");
    if ($stmt === false) {
        echo json_encode([
            'success' => false,
            'message' => 'Errore di database: ' . $conn->error
        ]);
        exit;
    }
    
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'Credenziali non valide'
        ]);
        exit;
    }
    
    $user = $result->fetch_assoc();
    
    // Verify password
    // After successful password verification
    if (!password_verify($password, $user['Password'])) {
        echo json_encode([
            'success' => false,
            'message' => 'Credenziali non valide'
        ]);
        exit;
    }
    
    // Set user as logged in
    $update_stmt = $conn->prepare("UPDATE utenti SET Logged = TRUE WHERE id = ?");
    if ($update_stmt === false) {
        echo json_encode([
            'success' => false,
            'message' => 'Errore di database: ' . $conn->error
        ]);
        exit;
    }
    
    $update_stmt->bind_param("i", $user['id']);
    $update_stmt->execute();
    $update_stmt->close();
    
    // Generate token
    $token = bin2hex(random_bytes(32));
    $user_id = $user['id'];
    $expiry = date('Y-m-d H:i:s', strtotime('+30 days'));
    
    // Create tokens table if it doesn't exist
    $create_table_sql = "CREATE TABLE IF NOT EXISTS tokens (
        id INT AUTO_INCREMENT PRIMARY KEY,
        token VARCHAR(255) NOT NULL UNIQUE,
        id_utente INT NOT NULL,
        scadenza DATETIME NOT NULL,
        FOREIGN KEY (id_utente) REFERENCES utenti(id)
    )";
    
    if ($conn->query($create_table_sql) === false) {
        echo json_encode([
            'success' => false,
            'message' => 'Errore nella creazione della tabella tokens: ' . $conn->error
        ]);
        exit;
    }
    
    // Store token in database
    $token_stmt = $conn->prepare("INSERT INTO tokens (token, id_utente, scadenza) VALUES (?, ?, ?)");
    if ($token_stmt === false) {
        echo json_encode([
            'success' => false,
            'message' => 'Errore di database: ' . $conn->error
        ]);
        exit;
    }
    
    $token_stmt->bind_param("sis", $token, $user_id, $expiry);
    $token_stmt->execute();
    
    // Remove password from user data
    unset($user['Password']);
    
    echo json_encode([
        'success' => true,
        'message' => 'Login effettuato con successo',
        'user' => $user,
        'token' => $token
    ]);
    
    $token_stmt->close();
    $stmt->close();
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Metodo non consentito'
    ]);
}

// Always safely close the connection
if (isset($conn)) {
    $conn->close();
}
?>