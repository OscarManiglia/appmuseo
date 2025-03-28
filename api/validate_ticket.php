<?php
require_once 'db_connect.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Recupera i dati dal POST
    $token = isset($_POST['token']) ? $_POST['token'] : '';
    $signature = isset($_POST['signature']) ? $_POST['signature'] : '';
    
    if (empty($token)) {
        echo json_encode([
            'success' => false,
            'message' => 'Token del biglietto mancante'
        ]);
        exit;
    }
    
    // Recupera i dati del biglietto
    $stmt = $conn->prepare("SELECT b.*, m.Nome as nome_museo 
                           FROM biglietti b 
                           JOIN musei m ON b.id_museo = m.id 
                           WHERE b.token = ?");
    
    if ($stmt === false) {
        echo json_encode([
            'success' => false,
            'message' => 'Errore nella preparazione della query: ' . $conn->error
        ]);
        exit;
    }
    
    $stmt->bind_param("s", $token);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'Biglietto non trovato'
        ]);
        exit;
    }
    
    $ticket = $result->fetch_assoc();
    
    // Verifica lo stato del biglietto
    if ($ticket['stato'] !== 'valido') {
        echo json_encode([
            'success' => false,
            'message' => 'Biglietto già utilizzato o scaduto',
            'status' => $ticket['stato']
        ]);
        exit;
    }
    
    // Verifica la data di validità
    $today = date('Y-m-d');
    if ($ticket['data_visita'] < $today) {
        // Aggiorna lo stato del biglietto a scaduto
        $update_stmt = $conn->prepare("UPDATE biglietti SET stato = 'scaduto' WHERE id = ?");
        $update_stmt->bind_param("i", $ticket['id']);
        $update_stmt->execute();
        $update_stmt->close();
        
        echo json_encode([
            'success' => false,
            'message' => 'Biglietto scaduto',
            'status' => 'scaduto'
        ]);
        exit;
    }
    
    // Verifica la firma se fornita
    if (!empty($signature)) {
        $secret_key = 'museo7_secret_key_2023';
        
        // Ricrea i dati originali
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
        
        $json_data = json_encode($qr_data);
        $expected_signature = hash_hmac('sha256', $json_data, $secret_key);
        
        if ($signature !== $expected_signature) {
            echo json_encode([
                'success' => false,
                'message' => 'Firma del biglietto non valida'
            ]);
            exit;
        }
    }
    
    // Aggiorna lo stato del biglietto a utilizzato
    $update_stmt = $conn->prepare("UPDATE biglietti SET stato = 'utilizzato' WHERE id = ?");
    $update_stmt->bind_param("i", $ticket['id']);
    $update_stmt->execute();
    $update_stmt->close();
    
    // Restituisci i dati del biglietto validato
    echo json_encode([
        'success' => true,
        'message' => 'Biglietto validato con successo',
        'ticket' => [
            'id' => $ticket['id'],
            'museum' => $ticket['nome_museo'],
            'visit_date' => $ticket['data_visita'],
            'visit_time' => $ticket['ora_visita'],
            'child_tickets' => $ticket['num_biglietti_bambini'],
            'youth_tickets' => $ticket['num_biglietti_giovani'],
            'adult_tickets' => $ticket['num_biglietti_adulti'],
            'senior_tickets' => $ticket['num_biglietti_anziani'],
            'total_tickets' => $ticket['num_biglietti_bambini'] + $ticket['num_biglietti_giovani'] + 
                              $ticket['num_biglietti_adulti'] + $ticket['num_biglietti_anziani'],
            'total_price' => $ticket['prezzo_totale']
        ]
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