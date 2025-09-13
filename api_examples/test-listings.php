<?php
/**
 * Test Listings API - Returns sample data for testing with real-time timestamps
 * URL: /api/test-listings.php
 * Method: GET
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

// Generate current timestamp for real-time testing
$current_time = date('Y-m-d H:i:s');
$timestamp = time();

// Sample listings data for testing
$sample_listings = [
    [
        'id' => 1,
        'title' => "iPhone 13 Pro Max 256GB - Updated $current_time",
        'description' => "Excellent condition iPhone 13 Pro Max with 256GB storage. Last updated at $current_time to test real-time sync.",
        'price' => 85000,
        'formatted_price' => 'KES 85,000',
        'category_id' => 1,
        'category' => 'Electronics',
        'condition' => 'like_new',
        'city' => 'Nairobi',
        'county' => 'Nairobi',
        'location' => 'Nairobi, Nairobi',
        'views' => 45,
        'image' => 'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=400',
        'image_count' => 3,
        'seller_name' => 'John Doe',
        'created_at' => $current_time,
        'updated_at' => $current_time,
        'timestamp' => $timestamp,
        'plan' => 'premium'
    ],
    [
        'id' => 2,
        'title' => 'Toyota Corolla 2018',
        'description' => 'Well maintained Toyota Corolla 2018 model. Low mileage, excellent condition.',
        'price' => 1800000,
        'formatted_price' => 'KES 1,800,000',
        'category_id' => 2,
        'category' => 'Vehicles',
        'condition' => 'good',
        'city' => 'Mombasa',
        'county' => 'Mombasa',
        'location' => 'Mombasa, Mombasa',
        'views' => 123,
        'image' => 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=400',
        'image_count' => 5,
        'seller_name' => 'Jane Smith',
        'created_at' => '2024-01-14 09:15:00',
        'updated_at' => '2024-01-14 16:20:00',
        'plan' => 'basic'
    ],
    [
        'id' => 3,
        'title' => 'MacBook Pro 2021',
        'description' => 'MacBook Pro 2021 with M1 chip, 16GB RAM, 512GB SSD. Perfect for professionals.',
        'price' => 180000,
        'formatted_price' => 'KES 180,000',
        'category_id' => 1,
        'category' => 'Electronics',
        'condition' => 'like_new',
        'city' => 'Kisumu',
        'county' => 'Kisumu',
        'location' => 'Kisumu, Kisumu',
        'views' => 67,
        'image' => 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=400',
        'image_count' => 4,
        'seller_name' => 'Mike Johnson',
        'created_at' => '2024-01-13 14:45:00',
        'updated_at' => '2024-01-13 18:30:00',
        'plan' => 'free'
    ],
    [
        'id' => 4,
        'title' => 'Samsung Galaxy S23',
        'description' => 'Brand new Samsung Galaxy S23 with warranty. All accessories included.',
        'price' => 95000,
        'formatted_price' => 'KES 95,000',
        'category_id' => 1,
        'category' => 'Electronics',
        'condition' => 'new',
        'city' => 'Nakuru',
        'county' => 'Nakuru',
        'location' => 'Nakuru, Nakuru',
        'views' => 89,
        'image' => 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=400',
        'image_count' => 6,
        'seller_name' => 'Sarah Wilson',
        'created_at' => '2024-01-12 11:20:00',
        'updated_at' => '2024-01-12 15:45:00',
        'plan' => 'starter'
    ]
];

// Filter by search if provided
$search = isset($_GET['search']) ? trim($_GET['search']) : '';
if (!empty($search)) {
    $sample_listings = array_filter($sample_listings, function($listing) use ($search) {
        return stripos($listing['title'], $search) !== false || 
               stripos($listing['description'], $search) !== false ||
               stripos($listing['city'], $search) !== false;
    });
    $sample_listings = array_values($sample_listings); // Re-index array
}

// Pagination
$page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
$limit = isset($_GET['limit']) ? min(50, max(1, intval($_GET['limit']))) : 20;
$offset = ($page - 1) * $limit;

$total_count = count($sample_listings);
$paginated_listings = array_slice($sample_listings, $offset, $limit);

// Calculate pagination info
$total_pages = ceil($total_count / $limit);
$has_next = $page < $total_pages;
$has_prev = $page > 1;

// Return response
echo json_encode([
    'success' => true,
    'message' => 'Test listings retrieved successfully',
    'listings' => $paginated_listings,
    'pagination' => [
        'current_page' => $page,
        'total_pages' => $total_pages,
        'total_count' => $total_count,
        'per_page' => $limit,
        'has_next' => $has_next,
        'has_prev' => $has_prev
    ],
    'debug_info' => [
        'search_query' => $search,
        'api_endpoint' => '/api/test-listings.php',
        'timestamp' => date('Y-m-d H:i:s')
    ]
]);
?>
