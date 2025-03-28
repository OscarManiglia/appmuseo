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
    
    // Verify token and check if user is logged in
    $stmt = $conn->prepare("
        SELECT u.id, u.Nome, u.Cognome, u.Email, u.Logged 
        FROM utenti u
        JOIN tokens t ON u.id = t.id_utente
        WHERE t.token = ? AND u.id = ? AND t.scadenza > NOW()
    ");
    
    if ($stmt === false) {
        echo json_encode([
            'success' => false,
            'message' => 'Errore di database: ' . $conn->error
        ]);
        exit;
    }
    
    $stmt->bind_param("si", $token, $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'Utente non autenticato'
        ]);
        $stmt->close();
        exit;
    }
    
    $user = $result->fetch_assoc();
    
    echo json_encode([
        'success' => true,
        'message' => 'Utente autenticato',
        'user' => [
            'id' => $user['id'],
            'name' => $user['Nome'] . ' ' . $user['Cognome'],
            'email' => $user['Email'],
            'logged' => (bool)$user['Logged']
        ]
    ]);
    
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