<?php
header('Content-Type: application/json');

// Connessione al database
$servername = "192.168.178.95"; 
$username = "root";
$password = "";
$dbname = "app_musei";

// Crea connessione
$conn = new mysqli($servername, $username, $password, $dbname);

// Verifica connessione
if ($conn->connect_error) {
    die(json_encode(['error' => 'Connection failed: ' . $conn->connect_error]));
}

// Ottieni l'ID del museo dalla richiesta
$id = isset($_GET['id']) ? intval($_GET['id']) : 0;

if ($id <= 0) {
    echo json_encode(['error' => 'Invalid museum ID']);
    exit;
}

// Prepara la query
$sql = "SELECT * FROM musei WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    // Ottieni i dati del museo
    $museum = $result->fetch_assoc();
    echo json_encode($museum);
} else {
    echo json_encode(['error' => 'Museum not found']);
}

$stmt->close();
$conn->close();
?>