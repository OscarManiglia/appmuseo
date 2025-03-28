<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Database connection
$conn = new mysqli('localhost', 'root', '', 'app_musei');

if ($conn->connect_error) {
    die(json_encode(['error' => 'Connection failed: ' . $conn->connect_error]));
}

$conn->set_charset('utf8');

// Query modificata per selezionare tutti i campi necessari
$result = $conn->query('SELECT id, Nome, Descrizione, Orari, Coordinate_Maps, URL_immagine, Bambini, Giovani, Adulti, Senior FROM musei LIMIT 10');

$museums = [];
if ($result->num_rows > 0) {
    while($row = $result->fetch_assoc()) {
        $museums[] = $row;
    }
}

echo json_encode($museums);
$conn->close();
?>