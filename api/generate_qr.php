<?php
require_once 'db_connect.php';
header('Content-Type: application/json');

// Check if database connection is established
if (!isset($conn) || $conn === null) {
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit;
}

// Get authorization header
$headers = getallheaders();
$auth_header = isset($headers['Authorization']) ? $headers['Authorization'] : '';

// Check if token is provided
if (empty($auth_header) || !preg_match('/Bearer\s(\S+)/', $auth_header, $matches)) {
    echo json_encode(['success' => false, 'message' => 'Token non fornito']);
    exit;
}

$token = $matches[1];

// Verify token - MODIFICATO PER USARE LA TABELLA tokens INVECE DI user_tokens
$stmt = $conn->prepare("SELECT id_utente FROM tokens WHERE token = ? AND scadenza > NOW()");
if (!$stmt) {
    echo json_encode(['success' => false, 'message' => 'Prepare statement failed: ' . ($conn->error ?? 'Unknown error')]);
    exit;
}
$stmt->bind_param("s", $token);
$stmt->execute();
$result = $stmt->get_result();

if (!$result || $result->num_rows === 0) {
    echo json_encode(['success' => false, 'message' => 'Token non valido o scaduto']);
    if ($stmt) $stmt->close();
    if (isset($conn) && $conn !== null) $conn->close();
    exit;
}

$user = $result->fetch_assoc();
$user_id = $user['id_utente'] ?? 0; // Modificato da user_id a id_utente
if ($user_id <= 0) {
    echo json_encode(['success' => false, 'message' => 'User ID non valido']);
    if ($stmt) $stmt->close();
    if (isset($conn) && $conn !== null) $conn->close();
    exit;
}
if ($stmt) $stmt->close();

// Get ticket token from query parameter
$ticket_token = $_GET['ticket_id'] ?? '';

if (empty($ticket_token)) {
    echo json_encode(['success' => false, 'message' => 'ID biglietto mancante']);
    exit;
}

// Get ticket details
$stmt = $conn->prepare("
    SELECT b.*, m.nome as museum_name 
    FROM biglietti b
    JOIN musei m ON b.id_museo = m.id
    WHERE b.token = ? AND b.id_utente = ?
");
if (!$stmt) {
    echo json_encode(['success' => false, 'message' => 'Prepare statement failed: ' . ($conn->error ?? 'Unknown error')]);
    if (isset($conn) && $conn !== null) $conn->close();
    exit;
}
$stmt->bind_param("si", $ticket_token, $user_id);
$stmt->execute();
$result = $stmt->get_result();

if (!$result || $result->num_rows === 0) {
    echo json_encode(['success' => false, 'message' => 'Biglietto non trovato']);
    if ($stmt) $stmt->close();
    if (isset($conn) && $conn !== null) $conn->close();
    exit;
}

$ticket = $result->fetch_assoc();
if ($stmt) $stmt->close();

// Generate QR code data
$qr_data = json_encode([
    'ticket_id' => $ticket['id'] ?? '',
    'token' => $ticket['token'] ?? '',
    'museum_id' => $ticket['id_museo'] ?? '',
    'museum_name' => $ticket['museum_name'] ?? '',
    'visit_date' => $ticket['data_visita'] ?? '',
    'visit_time' => $ticket['ora_visita'] ?? '',
    'status' => $ticket['stato'] ?? 'valido'
]);

if ($qr_data === false) {
    echo json_encode(['success' => false, 'message' => 'Errore nella generazione del QR code']);
    if (isset($conn) && $conn !== null) $conn->close();
    exit;
}

echo json_encode([
    'success' => true,
    'qr_data' => $qr_data,
    'ticket' => $ticket
]);

if (isset($conn) && $conn !== null) {
    $conn->close();
}
?>