<?php
require_once 'db_connect.php';
require_once 'check_login.php';

// Verifica se l'utente è autenticato
$user = checkLogin($conn);
if (!$user) {
    echo json_encode([
        'success' => false,
        'message' => 'Utente non autenticato'
    ]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $ticket_id = isset($_GET['ticket_id']) ? intval($_GET['ticket_id']) : 0;
    
    if ($ticket_id <= 0) {
        echo json_encode([
            'success' => false,
            'message' => 'ID biglietto non valido'
        ]);
        exit;
    }
    
    // Recupera i dati del biglietto
    $stmt = $conn->prepare("SELECT b.*, m.Nome as nome_museo 
                           FROM biglietti b 
                           JOIN musei m ON b.id_museo = m.id 
                           WHERE b.id = ? AND b.id_utente = ?");
    
    if ($stmt === false) {
        echo json_encode([
            'success' => false,
            'message' => 'Errore nella preparazione della query: ' . $conn->error
        ]);
        exit;
    }
    
    $stmt->bind_param("ii", $ticket_id, $user['id']);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'Biglietto non trovato o non autorizzato'
        ]);
        exit;
    }
    
    $ticket = $result->fetch_assoc();
    
    // Crea la directory per i QR code se non esiste
    $qr_dir = '../qrcodes';
    if (!file_exists($qr_dir)) {
        mkdir($qr_dir, 0777, true);
    }
    
    // Crea i dati da codificare nel QR
    $qr_data = [
        'ticket_id' => $ticket['id'],
        'token' => $ticket['token'],
        'museum_id' => $ticket['id_museo'],
        'museum_name' => $ticket['nome_museo'],
        'visit_date' => $ticket['data_visita'],
        'visit_time' => $ticket['ora_visita'],
        'total_tickets' => $ticket['num_biglietti_bambini'] + $ticket['num_biglietti_giovani'] + 
                          $ticket['num_biglietti_adulti'] + $ticket['num_biglietti_anziani']
    ];
    
    // Converti in JSON e firma con una chiave segreta
    $secret_key = 'museo7_secret_key_2023'; // In produzione, usa una chiave più sicura
    $json_data = json_encode($qr_data);
    $signature = hash_hmac('sha256', $json_data, $secret_key);
    
    // Aggiungi la firma ai dati
    $qr_data['signature'] = $signature;
    $final_json = json_encode($qr_data);
    
    // Nome del file QR
    $qr_filename = 'ticket_' . $ticket['id'] . '_' . $ticket['token'] . '.png';
    $qr_path = $qr_dir . '/' . $qr_filename;
    $relative_path = 'qrcodes/' . $qr_filename;
    
    // Aggiorna il percorso del QR nel database
    $update_stmt = $conn->prepare("UPDATE biglietti SET qr_code_path = ? WHERE id = ?");
    $update_stmt->bind_param("si", $relative_path, $ticket_id);
    $update_stmt->execute();
    $update_stmt->close();
    
    // Restituisci i dati per generare il QR sul client
    echo json_encode([
        'success' => true,
        'qr_data' => $final_json,
        'ticket' => $ticket
    ]);
    
    $stmt->close();
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Metodo non supportato'
    ]);
}

$conn->close();
?>