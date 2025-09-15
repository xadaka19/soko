<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
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

try {
    // Validate required fields
    $user_id = isset($input['user_id']) ? intval($input['user_id']) : 0;
    if ($user_id <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Valid user ID is required'
        ]);
        exit;
    }

    // Extract profile data
    $first_name = isset($input['first_name']) ? trim($input['first_name']) : '';
    $last_name = isset($input['last_name']) ? trim($input['last_name']) : '';
    $email = isset($input['email']) ? trim($input['email']) : '';
    $phone = isset($input['phone']) ? trim($input['phone']) : '';
    $mpesa_phone = isset($input['mpesa_phone']) ? trim($input['mpesa_phone']) : '';
    $city = isset($input['city']) ? trim($input['city']) : '';
    $county = isset($input['county']) ? trim($input['county']) : '';

    // Validate required fields
    if (empty($first_name) || empty($last_name) || empty($email)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'First name, last name, and email are required'
        ]);
        exit;
    }

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
    if (!empty($phone) && !preg_match('/^(\+254|254|0)[0-9]{9}$/', $phone)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid phone number format. Use Kenyan format (e.g., +254712345678)'
        ]);
        exit;
    }

    // Validate M-Pesa phone number if provided
    if (!empty($mpesa_phone) && !preg_match('/^(\+254|254|0)[0-9]{9}$/', $mpesa_phone)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid M-Pesa phone number format. Use Kenyan format (e.g., +254712345678)'
        ]);
        exit;
    }

    // Normalize phone numbers to international format
    if (!empty($phone)) {
        $phone = preg_replace('/^0/', '254', $phone);
        $phone = preg_replace('/^\+/', '', $phone);
        if (!str_starts_with($phone, '254')) {
            $phone = '254' . $phone;
        }
    }

    if (!empty($mpesa_phone)) {
        $mpesa_phone = preg_replace('/^0/', '254', $mpesa_phone);
        $mpesa_phone = preg_replace('/^\+/', '', $mpesa_phone);
        if (!str_starts_with($mpesa_phone, '254')) {
            $mpesa_phone = '254' . $mpesa_phone;
        }
    }

    // For testing purposes, simulate successful update
    // In production, you would update the database
    
    /*
    // Database update code for production:
    $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Check if email is already taken by another user
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ? AND id != ?");
    $stmt->execute([$email, $user_id]);
    if ($stmt->fetch()) {
        http_response_code(409);
        echo json_encode([
            'success' => false,
            'message' => 'Email address is already in use by another account'
        ]);
        exit;
    }
    
    // Update user profile
    $stmt = $pdo->prepare("
        UPDATE users SET 
            first_name = ?, 
            last_name = ?, 
            email = ?, 
            phone = ?, 
            mpesa_phone = ?, 
            city = ?, 
            county = ?,
            updated_at = NOW()
        WHERE id = ?
    ");
    
    $result = $stmt->execute([
        $first_name, 
        $last_name, 
        $email, 
        $phone, 
        $mpesa_phone, 
        $city, 
        $county, 
        $user_id
    ]);
    
    if (!$result) {
        throw new Exception('Failed to update profile in database');
    }
    */

    // Return updated profile data
    $updated_profile = [
        'id' => $user_id,
        'first_name' => $first_name,
        'last_name' => $last_name,
        'email' => $email,
        'phone' => $phone,
        'mpesa_phone' => $mpesa_phone,
        'city' => $city,
        'county' => $county,
        'updated_at' => date('Y-m-d H:i:s')
    ];

    echo json_encode([
        'success' => true,
        'message' => 'Profile updated successfully',
        'data' => $updated_profile,
        'user' => $updated_profile // For compatibility
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}

/*
USAGE:
POST /api/update-profile.php

JSON BODY:
{
  "user_id": 123,
  "first_name": "John",
  "last_name": "Doe",
  "email": "john.doe@example.com",
  "phone": "+254712345678",
  "mpesa_phone": "+254712345678",
  "city": "Nairobi",
  "county": "Nairobi"
}

RESPONSE FORMAT:
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": 123,
    "first_name": "John",
    "last_name": "Doe",
    "email": "john.doe@example.com",
    "phone": "254712345678",
    "mpesa_phone": "254712345678",
    "city": "Nairobi",
    "county": "Nairobi",
    "updated_at": "2024-01-01 12:00:00"
  },
  "user": {...}
}

ERROR RESPONSE:
{
  "success": false,
  "message": "Error description"
}
*/
?>
