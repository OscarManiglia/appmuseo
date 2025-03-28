<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');

include 'db_connect.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get user data from request
    $nome = isset($_POST['nome']) ? $_POST['nome'] : '';
    $cognome = isset($_POST['cognome']) ? $_POST['cognome'] : '';
    $email = isset($_POST['email']) ? $_POST['email'] : '';
    $telefono = isset($_POST['telefono']) ? $_POST['telefono'] : '';
    $password = isset($_POST['password']) ? $_POST['password'] : '';
    
    // Validate input
    if (empty($nome) || empty($cognome) || empty($email) || empty($telefono) || empty($password)) {
        echo json_encode([
            'success' => false,
            'message' => 'Tutti i campi sono obbligatori'
        ]);
        exit;
    }
    
    // Validate email format
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        echo json_encode([
            'success' => false,
            'message' => 'Formato email non valido'
        ]);
        exit;
    }
    
    // Check if email already exists
    $stmt = $conn->prepare("SELECT id FROM utenti WHERE Email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        echo json_encode([
            'success' => false,
            'message' => 'Email già registrata'
        ]);
        exit;
    }
    
    // Check if phone already exists
    $stmt = $conn->prepare("SELECT id FROM utenti WHERE Telefono = ?");
    $stmt->bind_param("s", $telefono);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        echo json_encode([
            'success' => false,
            'message' => 'Numero di telefono già registrato'
        ]);
        exit;
    }
    
    // Hash password
    $hashed_password = password_hash($password, PASSWORD_DEFAULT);
    
    // Insert new user
    $stmt = $conn->prepare("INSERT INTO utenti (Nome, Cognome, Email, Telefono, Password) VALUES (?, ?, ?, ?, ?)");
    $stmt->bind_param("sssss", $nome, $cognome, $email, $telefono, $hashed_password);
    
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Registrazione completata con successo'
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Errore durante la registrazione: ' . $stmt->error
        ]);
    }
    
    $stmt->close();
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Metodo non consentito'
    ]);
}

$conn->close();
?>