<?php
// Database connection parameters
$servername = "localhost";
$username = "root";  // Default XAMPP username
$password = "";      // Default XAMPP password
$dbname = "app_musei";

// Create connection with error handling
$conn = null;
try {
    $conn = new mysqli($servername, $username, $password, $dbname);
    
    // Check connection
    if ($conn->connect_error) {
        error_log("Connection failed: " . $conn->connect_error);
        $conn = null;
    }
} catch (Exception $e) {
    error_log("Exception in db_connect.php: " . $e->getMessage());
    $conn = null;
}
?>