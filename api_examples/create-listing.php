<?php
/**
 * Create Listing API (Enhanced for Credit System)
 * URL: /api/create-listing.php
 * Method: POST (multipart/form-data)
 * 
 * This endpoint creates a new listing and returns the listing ID for credit consumption.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

try {
    // Validate required fields
    $required_fields = ['user_id', 'title', 'description', 'price', 'category_id', 'city_name'];
    foreach ($required_fields as $field) {
        if (!isset($_POST[$field]) || empty($_POST[$field])) {
            throw new Exception("Missing required field: $field");
        }
    }
    
    $user_id = intval($_POST['user_id']);
    $title = trim($_POST['title']);
    $description = trim($_POST['description']);
    $price = floatval($_POST['price']);
    $category_id = intval($_POST['category_id']);
    $city_name = trim($_POST['city_name']);
    
    // Validate data
    if ($price <= 0) {
        throw new Exception('Price must be greater than 0');
    }
    
    if (strlen($title) < 3) {
        throw new Exception('Title must be at least 3 characters long');
    }
    
    if (strlen($description) < 10) {
        throw new Exception('Description must be at least 10 characters long');
    }
    
    // Database connection
    $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Start transaction
    $pdo->beginTransaction();
    
    try {
        // Verify user exists and is active
        $stmt = $pdo->prepare("SELECT id, first_name, last_name FROM users WHERE id = ? AND is_active = 1");
        $stmt->execute([$user_id]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$user) {
            throw new Exception('User not found or inactive');
        }
        
        // Create the listing
        $stmt = $pdo->prepare("
            INSERT INTO listings (
                user_id, title, description, price, category_id, 
                city_name, status, views, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, 'active', 0, NOW(), NOW())
        ");
        $stmt->execute([
            $user_id,
            $title,
            $description,
            $price,
            $category_id,
            $city_name
        ]);
        
        $listing_id = $pdo->lastInsertId();
        
        // Handle photo uploads
        $uploaded_photos = [];
        if (isset($_FILES['photos']) && !empty($_FILES['photos']['name'][0])) {
            $upload_dir = '../uploads/listings/';
            
            // Create upload directory if it doesn't exist
            if (!is_dir($upload_dir)) {
                mkdir($upload_dir, 0755, true);
            }
            
            $photo_count = count($_FILES['photos']['name']);
            for ($i = 0; $i < $photo_count; $i++) {
                if ($_FILES['photos']['error'][$i] === UPLOAD_ERR_OK) {
                    $tmp_name = $_FILES['photos']['tmp_name'][$i];
                    $original_name = $_FILES['photos']['name'][$i];
                    $file_extension = strtolower(pathinfo($original_name, PATHINFO_EXTENSION));
                    
                    // Validate file type
                    $allowed_extensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
                    if (!in_array($file_extension, $allowed_extensions)) {
                        continue; // Skip invalid files
                    }
                    
                    // Generate unique filename
                    $new_filename = $listing_id . '_' . time() . '_' . $i . '.' . $file_extension;
                    $upload_path = $upload_dir . $new_filename;
                    
                    if (move_uploaded_file($tmp_name, $upload_path)) {
                        $photo_url = '/uploads/listings/' . $new_filename;
                        
                        // Insert photo record
                        $stmt = $pdo->prepare("
                            INSERT INTO listing_images (
                                listing_id, image_url, is_primary, sort_order, created_at
                            ) VALUES (?, ?, ?, ?, NOW())
                        ");
                        $stmt->execute([
                            $listing_id,
                            $photo_url,
                            $i === 0 ? 1 : 0, // First image is primary
                            $i
                        ]);
                        
                        $uploaded_photos[] = $photo_url;
                    }
                }
            }
        }
        
        // Get the created listing with full details
        $stmt = $pdo->prepare("
            SELECT 
                l.*,
                CONCAT(u.first_name, ' ', u.last_name) as seller_name
            FROM listings l
            JOIN users u ON l.user_id = u.id
            WHERE l.id = ?
        ");
        $stmt->execute([$listing_id]);
        $listing = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Commit transaction
        $pdo->commit();
        
        // Format response
        $response_listing = [
            'id' => intval($listing['id']),
            'title' => $listing['title'],
            'description' => $listing['description'],
            'price' => floatval($listing['price']),
            'category_id' => intval($listing['category_id']),
            'city_name' => $listing['city_name'],
            'status' => $listing['status'],
            'views' => intval($listing['views']),
            'seller_name' => $listing['seller_name'],
            'created_at' => $listing['created_at'],
            'photos' => $uploaded_photos
        ];
        
        // Return success response
        echo json_encode([
            'success' => true,
            'message' => 'Listing created successfully',
            'listing_id' => intval($listing_id),
            'listing' => $response_listing,
            'photos_uploaded' => count($uploaded_photos)
        ]);
        
    } catch (Exception $e) {
        // Rollback transaction
        $pdo->rollback();
        throw $e;
    }
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'listing_id' => null,
        'listing' => null,
        'photos_uploaded' => 0
    ]);
}
?>

<?php
/**
 * Database Schema Updates for Enhanced Listing Creation:
 * 
 * -- Add indexes for better performance
 * ALTER TABLE listings ADD INDEX idx_user_id (user_id);
 * ALTER TABLE listings ADD INDEX idx_status (status);
 * ALTER TABLE listings ADD INDEX idx_category_id (category_id);
 * ALTER TABLE listings ADD INDEX idx_created_at (created_at);
 * 
 * -- Ensure listing_images table exists
 * CREATE TABLE IF NOT EXISTS listing_images (
 *     id INT AUTO_INCREMENT PRIMARY KEY,
 *     listing_id INT NOT NULL,
 *     image_url VARCHAR(500) NOT NULL,
 *     is_primary BOOLEAN DEFAULT FALSE,
 *     sort_order INT DEFAULT 0,
 *     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 *     INDEX idx_listing_id (listing_id),
 *     FOREIGN KEY (listing_id) REFERENCES listings(id) ON DELETE CASCADE
 * );
 */
?>

<?php
/**
 * Example Response - Success:
 * {
 *   "success": true,
 *   "message": "Listing created successfully",
 *   "listing_id": 123,
 *   "listing": {
 *     "id": 123,
 *     "title": "iPhone 13 Pro Max",
 *     "description": "Excellent condition...",
 *     "price": 85000,
 *     "category_id": 11,
 *     "city_name": "Nairobi",
 *     "status": "active",
 *     "views": 0,
 *     "seller_name": "John Doe",
 *     "created_at": "2024-01-15 14:30:00",
 *     "photos": [
 *       "/uploads/listings/123_1705327800_0.jpg",
 *       "/uploads/listings/123_1705327800_1.jpg"
 *     ]
 *   },
 *   "photos_uploaded": 2
 * }
 * 
 * Example Response - Error:
 * {
 *   "success": false,
 *   "message": "Title must be at least 3 characters long",
 *   "listing_id": null,
 *   "listing": null,
 *   "photos_uploaded": 0
 * }
 */
?>

<?php
/**
 * Integration with Credit System:
 * 
 * 1. This API creates the listing and returns listing_id
 * 2. Mobile app uses listing_id to consume credit via consume-credit.php
 * 3. If credit consumption fails, consider implementing rollback
 * 4. Or mark listing as "pending credit confirmation"
 * 
 * Photo Upload Features:
 * - Supports multiple photos via photos[] array
 * - Validates file types (jpg, jpeg, png, gif, webp)
 * - Generates unique filenames to prevent conflicts
 * - First photo is automatically set as primary
 * - Stores photos in /uploads/listings/ directory
 * - Returns array of uploaded photo URLs
 * 
 * Security Features:
 * - Validates user exists and is active
 * - Sanitizes all input data
 * - Uses prepared statements to prevent SQL injection
 * - Validates file types for photo uploads
 * - Uses transactions for data consistency
 * 
 * Error Handling:
 * - Comprehensive validation of required fields
 * - Proper HTTP status codes
 * - Detailed error messages for debugging
 * - Transaction rollback on failures
 */
?>
