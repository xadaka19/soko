<?php
/**
 * Get Listing Details API
 * URL: /api/get-listing-details.php
 * Method: GET
 * Parameters: listing_id, user_id (optional)
 * 
 * This endpoint returns detailed information about a specific listing.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

try {
    // Validate required parameters
    if (!isset($_GET['listing_id']) || empty($_GET['listing_id'])) {
        throw new Exception('Listing ID is required');
    }
    
    $listing_id = intval($_GET['listing_id']);
    $user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : null;
    
    // Database connection
    $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Get detailed listing information
    $stmt = $pdo->prepare("
        SELECT 
            l.*,
            u.first_name as seller_first_name,
            u.last_name as seller_last_name,
            u.created_at as seller_joined,
            u.phone as seller_phone,
            u.email as seller_email,
            CONCAT(u.first_name, ' ', u.last_name) as seller_name
        FROM listings l
        JOIN users u ON l.user_id = u.id
        WHERE l.id = ? AND l.status = 'active'
    ");
    $stmt->execute([$listing_id]);
    $listing = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$listing) {
        throw new Exception('Listing not found or inactive');
    }
    
    // Get listing images
    $stmt = $pdo->prepare("
        SELECT image_url, is_primary, sort_order
        FROM listing_images 
        WHERE listing_id = ?
        ORDER BY is_primary DESC, sort_order ASC
    ");
    $stmt->execute([$listing_id]);
    $images = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Format images array
    $formatted_images = [];
    foreach ($images as $image) {
        $formatted_images[] = $image['image_url'];
    }
    
    // Check if user has favorited this listing
    $is_favorite = false;
    if ($user_id) {
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as count 
            FROM user_favorites 
            WHERE user_id = ? AND listing_id = ?
        ");
        $stmt->execute([$user_id, $listing_id]);
        $is_favorite = $stmt->fetch(PDO::FETCH_ASSOC)['count'] > 0;
    }
    
    // Increment view count
    $stmt = $pdo->prepare("
        UPDATE listings 
        SET views = views + 1, updated_at = NOW()
        WHERE id = ?
    ");
    $stmt->execute([$listing_id]);
    
    // Log view if user is logged in
    if ($user_id) {
        $stmt = $pdo->prepare("
            INSERT INTO listing_views (listing_id, user_id, viewed_at)
            VALUES (?, ?, NOW())
            ON DUPLICATE KEY UPDATE viewed_at = NOW()
        ");
        $stmt->execute([$listing_id, $user_id]);
    }
    
    // Format listing data
    $formatted_listing = [
        'id' => $listing['id'],
        'title' => $listing['title'],
        'description' => $listing['description'],
        'price' => floatval($listing['price']),
        'formatted_price' => 'KES ' . number_format($listing['price'], 0),
        'category' => $listing['category'],
        'condition' => $listing['condition'],
        'city' => $listing['city'],
        'county' => $listing['county'],
        'status' => $listing['status'],
        'views' => intval($listing['views']) + 1, // Include the current view
        'created_at' => $listing['created_at'],
        'updated_at' => $listing['updated_at'],
        'images' => $formatted_images,
        'seller_id' => $listing['user_id'],
        'seller_name' => $listing['seller_name'],
        'seller_first_name' => $listing['seller_first_name'],
        'seller_last_name' => $listing['seller_last_name'],
        'seller_joined' => $listing['seller_joined'],
        'seller_phone' => $listing['seller_phone'], // Now available to all users
        'seller_email' => $listing['seller_email'], // Now available to all users
        'seller_whatsapp' => $listing['seller_phone'], // WhatsApp uses same number
    ];

    // Note: Contact info is now available to all users (including visitors)
    // This encourages engagement and makes the platform more accessible
    
    // Return success response
    echo json_encode([
        'success' => true,
        'message' => 'Listing details retrieved successfully',
        'listing' => $formatted_listing,
        'is_favorite' => $is_favorite,
        'can_contact' => true, // All users can now contact sellers
        'is_owner' => $user_id && $user_id == $listing['user_id'],
        'visitor_mode' => $user_id === null
    ]);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'listing' => null,
        'is_favorite' => false,
        'can_contact' => false,
        'is_owner' => false
    ]);
}
?>

<?php
/**
 * Database Schema for supporting tables:
 * 
 * CREATE TABLE listing_images (
 *     id INT AUTO_INCREMENT PRIMARY KEY,
 *     listing_id INT NOT NULL,
 *     image_url VARCHAR(500) NOT NULL,
 *     is_primary BOOLEAN DEFAULT FALSE,
 *     sort_order INT DEFAULT 0,
 *     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 *     INDEX idx_listing_id (listing_id),
 *     FOREIGN KEY (listing_id) REFERENCES listings(id) ON DELETE CASCADE
 * );
 * 
 * CREATE TABLE user_favorites (
 *     id INT AUTO_INCREMENT PRIMARY KEY,
 *     user_id INT NOT NULL,
 *     listing_id INT NOT NULL,
 *     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 *     UNIQUE KEY unique_favorite (user_id, listing_id),
 *     INDEX idx_user_id (user_id),
 *     INDEX idx_listing_id (listing_id),
 *     FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
 *     FOREIGN KEY (listing_id) REFERENCES listings(id) ON DELETE CASCADE
 * );
 * 
 * CREATE TABLE listing_views (
 *     id INT AUTO_INCREMENT PRIMARY KEY,
 *     listing_id INT NOT NULL,
 *     user_id INT,
 *     ip_address VARCHAR(45),
 *     viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 *     UNIQUE KEY unique_user_view (listing_id, user_id),
 *     INDEX idx_listing_id (listing_id),
 *     INDEX idx_user_id (user_id),
 *     FOREIGN KEY (listing_id) REFERENCES listings(id) ON DELETE CASCADE,
 *     FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
 * );
 */
?>

<?php
/**
 * Example Response:
 * {
 *   "success": true,
 *   "message": "Listing details retrieved successfully",
 *   "listing": {
 *     "id": 123,
 *     "title": "iPhone 13 Pro Max 256GB",
 *     "description": "Excellent condition iPhone 13 Pro Max...",
 *     "price": 85000,
 *     "formatted_price": "KES 85,000",
 *     "category": "Electronics",
 *     "condition": "Like New",
 *     "city": "Nairobi",
 *     "county": "Nairobi",
 *     "status": "active",
 *     "views": 45,
 *     "created_at": "2024-01-15 10:30:00",
 *     "updated_at": "2024-01-15 14:35:00",
 *     "images": [
 *       "https://example.com/image1.jpg",
 *       "https://example.com/image2.jpg"
 *     ],
 *     "seller_id": 456,
 *     "seller_name": "John Doe",
 *     "seller_first_name": "John",
 *     "seller_last_name": "Doe",
 *     "seller_joined": "2023-06-15 09:00:00",
 *     "seller_phone": "+254712345678",
 *     "seller_email": "john@example.com",
 *     "seller_whatsapp": "+254712345678"
 *   },
 *   "is_favorite": true,
 *   "can_contact": true,
 *   "is_owner": false,
 *   "visitor_mode": false
 * }
 */
?>

<?php
/**
 * Features:
 * 
 * 1. Detailed listing information with seller details
 * 2. Image gallery support with primary image ordering
 * 3. Favorite status for logged-in users
 * 4. View tracking and analytics
 * 5. Contact information privacy (only for logged-in users)
 * 6. Owner detection for edit/delete permissions
 * 
 * Privacy & Security:
 * - Seller contact info now available to all users (including visitors)
 * - WhatsApp integration for easy messaging
 * - View tracking for analytics
 * - Prevents access to inactive listings
 * - Proper error handling for missing listings
 * 
 * Analytics:
 * - Tracks listing views
 * - Records user interactions
 * - Supports business intelligence
 * - Helps with recommendation systems
 */
?>
