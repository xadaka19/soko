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

try {
    // Check if file was uploaded
    if (!isset($_FILES['profile_picture']) || $_FILES['profile_picture']['error'] !== UPLOAD_ERR_OK) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'No file uploaded or upload error occurred'
        ]);
        exit;
    }

    // Get user ID from POST data
    $user_id = isset($_POST['user_id']) ? intval($_POST['user_id']) : 0;
    if ($user_id <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Valid user ID is required'
        ]);
        exit;
    }

    $file = $_FILES['profile_picture'];
    
    // Validate file type
    $allowed_types = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'];
    if (!in_array($file['type'], $allowed_types)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'Invalid file type. Only JPEG, PNG, and GIF are allowed.'
        ]);
        exit;
    }

    // Validate file size (max 5MB)
    $max_size = 5 * 1024 * 1024; // 5MB
    if ($file['size'] > $max_size) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'File size too large. Maximum size is 5MB.'
        ]);
        exit;
    }

    // Create upload directory if it doesn't exist
    $upload_dir = 'uploads/profile_pictures/';
    if (!is_dir($upload_dir)) {
        mkdir($upload_dir, 0755, true);
    }

    // Generate unique filename
    $file_extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    $filename = 'profile_' . $user_id . '_' . time() . '.' . $file_extension;
    $upload_path = $upload_dir . $filename;

    // Move uploaded file
    if (move_uploaded_file($file['tmp_name'], $upload_path)) {
        // For testing purposes, simulate successful upload
        // In production, you would save the file path to the database
        
        /*
        // Database update code for production:
        $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        
        $stmt = $pdo->prepare("UPDATE users SET profile_picture = ? WHERE id = ?");
        $stmt->execute([$upload_path, $user_id]);
        */
        
        // Generate full URL for the uploaded image
        $base_url = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http') . 
                   '://' . $_SERVER['HTTP_HOST'] . dirname($_SERVER['REQUEST_URI']);
        $image_url = $base_url . '/' . $upload_path;
        
        echo json_encode([
            'success' => true,
            'message' => 'Profile picture uploaded successfully',
            'data' => [
                'image_url' => $image_url,
                'filename' => $filename,
                'file_size' => $file['size'],
                'upload_time' => date('Y-m-d H:i:s')
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to save uploaded file'
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
USAGE:
POST /api/upload-profile-picture.php

FORM DATA:
- profile_picture: File (image file)
- user_id: Integer (user ID)

RESPONSE FORMAT:
{
  "success": true,
  "message": "Profile picture uploaded successfully",
  "data": {
    "image_url": "http://example.com/uploads/profile_pictures/profile_123_1640995200.jpg",
    "filename": "profile_123_1640995200.jpg",
    "file_size": 245760,
    "upload_time": "2024-01-01 12:00:00"
  }
}

ERROR RESPONSE:
{
  "success": false,
  "message": "Error description"
}

REQUIREMENTS:
- File must be JPEG, PNG, or GIF
- File size must be under 5MB
- Valid user_id must be provided
- Server must have write permissions to uploads directory
*/
?>
