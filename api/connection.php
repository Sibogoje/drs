<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

class DatabaseConnection {
    private $host = '195.35.53.20';
    private $dbname = 'u747325399_rds';
    private $username = 'u747325399_rds';
    private $password = '>Z?WBT=twD9';
    private $pdo;
    
    public function __construct() {
        try {
            $this->pdo = new PDO(
                "mysql:host={$this->host};dbname={$this->dbname};charset=utf8",
                $this->username,
                $this->password,
                [
                    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES => false,
                ]
            );
        } catch (PDOException $e) {
            $this->sendErrorResponse("Database connection failed: " . $e->getMessage(), 500);
        }
    }
    
    public function getConnection() {
        return $this->pdo;
    }
    
    public function sendResponse($data, $statusCode = 200, $message = 'Success') {
        http_response_code($statusCode);
        echo json_encode([
            'status' => $statusCode < 400 ? 'success' : 'error',
            'message' => $message,
            'data' => $data
        ]);
        exit;
    }
    
    public function sendErrorResponse($message, $statusCode = 400) {
        http_response_code($statusCode);
        echo json_encode([
            'status' => 'error',
            'message' => $message,
            'data' => null
        ]);
        exit;
    }
}

// Initialize database connection
$db = new DatabaseConnection();
$pdo = $db->getConnection();

// Function to validate required fields
function validateRequired($data, $requiredFields) {
    $missing = [];
    foreach ($requiredFields as $field) {
        if (!isset($data[$field]) || empty($data[$field])) {
            $missing[] = $field;
        }
    }
    return $missing;
}

// Function to sanitize input
function sanitizeInput($data) {
    return htmlspecialchars(strip_tags(trim($data)));
}
?>
