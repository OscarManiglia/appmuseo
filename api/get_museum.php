<?php
// Disable display errors to prevent HTML in JSON output
ini_set('display_errors', 0);
error_reporting(0);

// Still log errors to error log
ini_set('log_errors', 1);
error_log("Starting get_museum.php");

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

// Make sure no output before this point
if (ob_get_level()) ob_clean();

// Check if db_connect.php exists
if (!file_exists('db_connect.php')) {
    error_log("db_connect.php file not found");
    echo json_encode([
        'success' => false,
        'message' => 'Database configuration file not found'
    ]);
    exit;
}

include 'db_connect.php';

// Check if connection was successful
if (!isset($conn) || $conn === null) {
    error_log("Database connection failed in get_museum.php");
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed'
    ]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        if (isset($_GET['id'])) {
            $id = $_GET['id'];
            
            $stmt = $conn->prepare("SELECT id, Nome, Descrizione, Orari, Chiuso, Coordinate_Maps, URL_immagine, Bambini, Giovani, Adulti, Senior FROM musei WHERE id = ?");
            $stmt->bind_param("i", $id);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows > 0) {
                $museum = $result->fetch_assoc();
                echo json_encode([
                    'success' => true,
                    'museum' => $museum
                ]);
            } else {
                echo json_encode([
                    'success' => false,
                    'message' => 'Museum not found'
                ]);
            }
            
            $stmt->close();
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Museum ID is required'
            ]);
        }
    } catch (Exception $e) {
        error_log("Exception: " . $e->getMessage());
        echo json_encode([
            'success' => false,
            'message' => 'Database error: ' . $e->getMessage()
        ]);
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid request method'
    ]);
}

if (isset($conn)) {
    $conn->close();
}
?>