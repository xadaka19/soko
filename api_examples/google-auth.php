<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Only accept POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode([
        'success' => false,
        'message' => 'Method not allowed'
    ]);
    exit;
}

// Get POST data
$input = json_decode(file_get_contents('php://input'), true);

if (!$input) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid JSON data'
    ]);
    exit;
}

// Validate required fields
$required_fields = ['id_token', 'google_id', 'email', 'first_name', 'last_name'];
foreach ($required_fields as $field) {
    if (!isset($input[$field]) || empty($input[$field])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => "Missing required field: $field"
        ]);
        exit;
    }
}

$id_token = $input['id_token'];
$google_id = $input['google_id'];
$email = $input['email'];
$first_name = $input['first_name'];
$last_name = $input['last_name'];
$photo_url = $input['photo_url'] ?? '';

try {
    // Verify Google ID token (in production, you should verify this with Google's API)
    // For now, we'll simulate the verification
    
    // Database connection (adjust according to your setup)
    // $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    // $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // For testing purposes, simulate database operations
    // In production, implement proper database queries
    
    // Check if user exists by Google ID or email
    $user_exists = false;
    $user_data = null;
    
    // Simulate checking for existing user
    $test_users = [
        'test@gmail.com' => [
            'id' => 1,
            'google_id' => 'test_google_id_123',
            'email' => 'test@gmail.com',
            'first_name' => 'Test',
            'last_name' => 'User',
            'phone' => '+254712345678',
            'photo_url' => '',
            'verified' => true,
            'created_at' => '2024-01-01 00:00:00'
        ]
    ];
    
    // Check if user exists
    if (isset($test_users[$email])) {
        $user_exists = true;
        $user_data = $test_users[$email];
    }
    
    if ($user_exists) {
        // User exists, log them in
        $token = base64_encode($email . ':' . time());
        
        echo json_encode([
            'success' => true,
            'message' => 'Login successful',
            'user' => $user_data,
            'token' => $token,
            'is_new_user' => false
        ]);
    } else {
        // User doesn't exist, they need to register
        echo json_encode([
            'success' => false,
            'message' => 'User not found. Please complete registration.',
            'requires_registration' => true,
            'google_data' => [
                'google_id' => $google_id,
                'email' => $email,
                'first_name' => $first_name,
                'last_name' => $last_name,
                'photo_url' => $photo_url
            ]
        ]);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}

/* 
PRODUCTION IMPLEMENTATION NOTES:

1. Verify Google ID Token:
   - Use Google's tokeninfo endpoint or Google API Client Library
   - Verify the token signature, issuer, audience, and expiration
   
2. Database Schema:
   CREATE TABLE users (
       id INT PRIMARY KEY AUTO_INCREMENT,
       google_id VARCHAR(255) UNIQUE,
       email VARCHAR(255) UNIQUE NOT NULL,
       first_name VARCHAR(100) NOT NULL,
       last_name VARCHAR(100) NOT NULL,
       phone VARCHAR(20),
       photo_url TEXT,
       verified BOOLEAN DEFAULT FALSE,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
   );

3. Proper Database Queries:
   - Check for existing user by google_id or email
   - Update user info if they exist
   - Handle edge cases (email conflicts, etc.)

4. Security:
   - Implement proper JWT token generation
   - Add rate limiting
   - Validate all inputs
   - Use prepared statements
   - Implement proper error handling
*/
?>
