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
    $user_id = isset($_POST['user_id']) ? $_POST['user_id'] : '';
    $token = isset($_POST['token']) ? $_POST['token'] : '';
    
    if (empty($user_id) || empty($token)) {
        echo json_encode([
            'success' => false,
            'message' => 'Parametri mancanti'
        ]);
        exit;
    }
    
    // Verify token
    $token_stmt = $conn->prepare("SELECT id FROM tokens WHERE token = ? AND id_utente = ?");
    if ($token_stmt === false) {
        echo json_encode([
            'success' => false,
            'message' => 'Errore di database: ' . $conn->error
        ]);
        exit;
    }
    
    $token_stmt->bind_param("si", $token, $user_id);
    $token_stmt->execute();
    $token_result = $token_stmt->get_result();
    
    if ($token_result->num_rows === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'Token non valido'
        ]);
        $token_stmt->close();
        exit;
    }
    
    $token_stmt->close();
    
    // Set user as logged out
    $update_stmt = $conn->prepare("UPDATE utenti SET Logged = FALSE WHERE id = ?");
    if ($update_stmt === false) {
        echo json_encode([
            'success' => false,
            'message' => 'Errore di database: ' . $conn->error
        ]);
        exit;
    }
    
    $update_stmt->bind_param("i", $user_id);
    $update_stmt->execute();
    $update_stmt->close();
    
    // Delete token
    $delete_stmt = $conn->prepare("DELETE FROM tokens WHERE token = ?");
    if ($delete_stmt === false) {
        echo json_encode([
            'success' => false,
            'message' => 'Errore di database: ' . $conn->error
        ]);
        exit;
    }
    
    $delete_stmt->bind_param("s", $token);
    $delete_stmt->execute();
    $delete_stmt->close();
    
    echo json_encode([
        'success' => true,
        'message' => 'Logout effettuato con successo'
    ]);
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