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
$required_fields = ['google_id', 'email', 'first_name', 'last_name', 'phone'];
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

$google_id = $input['google_id'];
$email = $input['email'];
$first_name = $input['first_name'];
$last_name = $input['last_name'];
$phone = $input['phone'];
$photo_url = $input['photo_url'] ?? '';

try {
    // Validate email format
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid email format'
        ]);
        exit;
    }
    
    // Validate phone number (Kenyan format)
    if (!preg_match('/^(\+254|254|0)[0-9]{9}$/', $phone)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid phone number format. Use Kenyan format (e.g., +254712345678)'
        ]);
        exit;
    }
    
    // Normalize phone number to international format
    $phone = preg_replace('/^0/', '254', $phone);
    $phone = preg_replace('/^\+/', '', $phone);
    if (!str_starts_with($phone, '254')) {
        $phone = '254' . $phone;
    }
    
    // Database connection (adjust according to your setup)
    // $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    // $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // For testing purposes, simulate database operations
    // In production, implement proper database queries
    
    // Check if user already exists
    $existing_users = [
        'existing@gmail.com' => true,
        'test@gmail.com' => true
    ];
    
    if (isset($existing_users[$email])) {
        http_response_code(409);
        echo json_encode([
            'success' => false,
            'message' => 'User with this email already exists'
        ]);
        exit;
    }
    
    // Simulate user creation
    $user_id = rand(1000, 9999); // In production, this would be the actual database ID
    $created_at = date('Y-m-d H:i:s');
    
    $user_data = [
        'id' => $user_id,
        'google_id' => $google_id,
        'email' => $email,
        'first_name' => $first_name,
        'last_name' => $last_name,
        'phone' => $phone,
        'photo_url' => $photo_url,
        'verified' => true, // Google users are pre-verified
        'created_at' => $created_at
    ];
    
    // Generate token
    $token = base64_encode($email . ':' . time());
    
    echo json_encode([
        'success' => true,
        'message' => 'Registration successful',
        'user' => $user_data,
        'token' => $token,
        'is_new_user' => true
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}

/* 
PRODUCTION IMPLEMENTATION NOTES:

1. Database Schema:
   CREATE TABLE users (
       id INT PRIMARY KEY AUTO_INCREMENT,
       google_id VARCHAR(255) UNIQUE,
       email VARCHAR(255) UNIQUE NOT NULL,
       first_name VARCHAR(100) NOT NULL,
       last_name VARCHAR(100) NOT NULL,
       phone VARCHAR(20) UNIQUE NOT NULL,
       photo_url TEXT,
       verified BOOLEAN DEFAULT FALSE,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
       INDEX idx_google_id (google_id),
       INDEX idx_email (email),
       INDEX idx_phone (phone)
   );

2. Proper Database Implementation:
   - Check for existing users by email, phone, or google_id
   - Insert new user with proper error handling
   - Handle unique constraint violations
   - Use transactions for data consistency

3. Security Enhancements:
   - Implement proper JWT token generation
   - Add rate limiting for registration attempts
   - Validate and sanitize all inputs
   - Use prepared statements
   - Implement proper logging

4. Additional Features:
   - Send welcome email
   - Set up user preferences
   - Create user profile
   - Initialize user settings
*/
?>
