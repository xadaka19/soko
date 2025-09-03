<?php
/**
 * Get Listings API
 * URL: /api/get-listings.php
 * Method: GET
 * Parameters: search (optional), category_id (optional), page (optional), limit (optional)
 * 
 * This endpoint returns a list of active listings with pagination support.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

try {
    // Database credentials (should be in a config file in production)
    $username = 'sokofiti_user';
    $password = 'sokofiti_password';
    
    // Get parameters
    $search = isset($_GET['search']) ? trim($_GET['search']) : '';
    $category_id = isset($_GET['category_id']) ? intval($_GET['category_id']) : null;
    $page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
    $limit = isset($_GET['limit']) ? min(50, max(1, intval($_GET['limit']))) : 20;
    $offset = ($page - 1) * $limit;
    
    // Database connection
    $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Build query
    $where_conditions = ["l.status = 'active'"];
    $params = [];
    
    // Add search condition
    if (!empty($search)) {
        $where_conditions[] = "(l.title LIKE ? OR l.description LIKE ? OR l.city LIKE ?)";
        $search_param = '%' . $search . '%';
        $params[] = $search_param;
        $params[] = $search_param;
        $params[] = $search_param;
    }
    
    // Add category filter
    if ($category_id) {
        $where_conditions[] = "l.category_id = ?";
        $params[] = $category_id;
    }
    
    $where_clause = implode(' AND ', $where_conditions);
    
    // Get total count for pagination
    $count_sql = "
        SELECT COUNT(*) as total
        FROM listings l
        JOIN users u ON l.user_id = u.id
        WHERE $where_clause
    ";
    $count_stmt = $pdo->prepare($count_sql);
    $count_stmt->execute($params);
    $total_count = $count_stmt->fetch(PDO::FETCH_ASSOC)['total'];
    
    // Get listings with seller info and primary image
    $sql = "
        SELECT 
            l.id,
            l.title,
            l.description,
            l.price,
            l.category_id,
            l.condition,
            l.city,
            l.county,
            l.views,
            l.created_at,
            l.updated_at,
            u.first_name as seller_first_name,
            u.last_name as seller_last_name,
            CONCAT(u.first_name, ' ', u.last_name) as seller_name,
            (SELECT image_url FROM listing_images WHERE listing_id = l.id AND is_primary = 1 LIMIT 1) as primary_image,
            (SELECT COUNT(*) FROM listing_images WHERE listing_id = l.id) as image_count,
            c.name as category_name
        FROM listings l
        JOIN users u ON l.user_id = u.id
        LEFT JOIN categories c ON l.category_id = c.id
        WHERE $where_clause
        ORDER BY l.created_at DESC
        LIMIT ? OFFSET ?
    ";
    
    $params[] = $limit;
    $params[] = $offset;
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $listings = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Format listings data
    $formatted_listings = [];
    foreach ($listings as $listing) {
        $formatted_listings[] = [
            'id' => intval($listing['id']),
            'title' => $listing['title'],
            'description' => $listing['description'],
            'price' => floatval($listing['price']),
            'formatted_price' => 'KES ' . number_format($listing['price'], 0),
            'category_id' => intval($listing['category_id']),
            'category' => $listing['category_name'] ?? 'Uncategorized',
            'condition' => $listing['condition'],
            'city' => $listing['city'],
            'county' => $listing['county'],
            'location' => $listing['city'] . ', ' . $listing['county'],
            'views' => intval($listing['views']),
            'image' => $listing['primary_image'] ?? '',
            'image_count' => intval($listing['image_count']),
            'seller_name' => $listing['seller_name'],
            'created_at' => $listing['created_at'],
            'updated_at' => $listing['updated_at'],
            'plan' => 'free' // Default plan, can be enhanced later
        ];
    }
    
    // Calculate pagination info
    $total_pages = ceil($total_count / $limit);
    $has_next = $page < $total_pages;
    $has_prev = $page > 1;
    
    // Return success response
    echo json_encode([
        'success' => true,
        'message' => 'Listings retrieved successfully',
        'listings' => $formatted_listings,
        'pagination' => [
            'current_page' => $page,
            'total_pages' => $total_pages,
            'total_count' => intval($total_count),
            'per_page' => $limit,
            'has_next' => $has_next,
            'has_prev' => $has_prev
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'listings' => [],
        'pagination' => [
            'current_page' => 1,
            'total_pages' => 0,
            'total_count' => 0,
            'per_page' => 20,
            'has_next' => false,
            'has_prev' => false
        ]
    ]);
}
?>

<?php
/**
 * Example Response:
 * {
 *   "success": true,
 *   "message": "Listings retrieved successfully",
 *   "listings": [
 *     {
 *       "id": 123,
 *       "title": "iPhone 13 Pro Max 256GB",
 *       "description": "Excellent condition iPhone 13 Pro Max...",
 *       "price": 85000,
 *       "formatted_price": "KES 85,000",
 *       "category_id": 1,
 *       "category": "Electronics",
 *       "condition": "Like New",
 *       "city": "Nairobi",
 *       "county": "Nairobi",
 *       "location": "Nairobi, Nairobi",
 *       "views": 45,
 *       "image": "https://example.com/image1.jpg",
 *       "image_count": 3,
 *       "seller_name": "John Doe",
 *       "created_at": "2024-01-15 10:30:00",
 *       "updated_at": "2024-01-15 14:35:00",
 *       "plan": "free"
 *     }
 *   ],
 *   "pagination": {
 *     "current_page": 1,
 *     "total_pages": 5,
 *     "total_count": 95,
 *     "per_page": 20,
 *     "has_next": true,
 *     "has_prev": false
 *   }
 * }
 */
?>

<?php
/**
 * Database Schema Requirements:
 * 
 * CREATE TABLE listings (
 *     id INT AUTO_INCREMENT PRIMARY KEY,
 *     user_id INT NOT NULL,
 *     title VARCHAR(255) NOT NULL,
 *     description TEXT NOT NULL,
 *     price DECIMAL(10,2) NOT NULL,
 *     category_id INT,
 *     condition ENUM('new', 'like_new', 'good', 'fair', 'poor') DEFAULT 'good',
 *     city VARCHAR(100) NOT NULL,
 *     county VARCHAR(100) NOT NULL,
 *     status ENUM('active', 'inactive', 'sold', 'expired') DEFAULT 'active',
 *     views INT DEFAULT 0,
 *     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 *     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 *     INDEX idx_status (status),
 *     INDEX idx_category (category_id),
 *     INDEX idx_created (created_at),
 *     INDEX idx_city (city),
 *     FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
 *     FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
 * );
 * 
 * CREATE TABLE categories (
 *     id INT AUTO_INCREMENT PRIMARY KEY,
 *     name VARCHAR(100) NOT NULL,
 *     slug VARCHAR(100) NOT NULL UNIQUE,
 *     description TEXT,
 *     parent_id INT NULL,
 *     sort_order INT DEFAULT 0,
 *     is_active BOOLEAN DEFAULT TRUE,
 *     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 *     INDEX idx_parent (parent_id),
 *     INDEX idx_active (is_active),
 *     FOREIGN KEY (parent_id) REFERENCES categories(id) ON DELETE SET NULL
 * );
 */
?>
