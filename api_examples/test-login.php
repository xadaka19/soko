<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

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

$email = $input['email'] ?? '';
$password = $input['password'] ?? '';

// Basic validation
if (empty($email) || empty($password)) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => 'Email and password are required'
    ]);
    exit;
}

// Simple test credentials (in real app, check against database)
$test_users = [
    'test@sokofiti.ke' => [
        'password' => 'password123',
        'user' => [
            'id' => 1,
            'email' => 'test@sokofiti.ke',
            'first_name' => 'Test',
            'last_name' => 'User',
            'phone' => '+254712345678',
            'verified' => true,
            'created_at' => '2024-01-01 00:00:00'
        ]
    ],
    'admin@sokofiti.ke' => [
        'password' => 'admin123',
        'user' => [
            'id' => 2,
            'email' => 'admin@sokofiti.ke',
            'first_name' => 'Admin',
            'last_name' => 'User',
            'phone' => '+254712345679',
            'verified' => true,
            'created_at' => '2024-01-01 00:00:00'
        ]
    ]
];

// Check credentials
if (isset($test_users[$email]) && $test_users[$email]['password'] === $password) {
    // Generate a simple token (in real app, use JWT or similar)
    $token = base64_encode($email . ':' . time());
    
    echo json_encode([
        'success' => true,
        'message' => 'Login successful',
        'user' => $test_users[$email]['user'],
        'token' => $token
    ]);
} else {
    http_response_code(401);
    echo json_encode([
        'success' => false,
        'message' => 'Invalid email or password'
    ]);
}
?>
