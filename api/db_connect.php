<?php
// Database connection parameters
$servername = "192.168.178.95";  
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
    } else {
        // Set charset to utf8
        $conn->set_charset("utf8");
    }
} catch (Exception $e) {
    error_log("Exception in db_connect.php: " . $e->getMessage());
    $conn = null;
}
?>