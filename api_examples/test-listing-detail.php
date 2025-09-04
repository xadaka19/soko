<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// Get listing ID from query parameters
$listing_id = $_GET['listing_id'] ?? $_GET['id'] ?? null;

if (!$listing_id) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => 'Missing listing_id parameter'
    ]);
    exit;
}

// Sample detailed listing data
$sample_listing = [
    'id' => $listing_id,
    'title' => 'iPhone 13 Pro Max 256GB - Excellent Condition',
    'description' => 'This iPhone 13 Pro Max is in excellent condition with minimal signs of use. Comes with original box, charger, and screen protector already applied. Battery health is at 95%. No scratches on the screen and only minor wear on the edges.',
    'price' => 85000,
    'formatted_price' => 'KES 85,000',
    'category_id' => 1,
    'category' => 'Electronics',
    'subcategory' => 'Mobile Phones',
    'condition' => 'like_new',
    'city' => 'Nairobi',
    'county' => 'Nairobi',
    'location' => 'Nairobi, Nairobi',
    'views' => 127,
    'images' => [
        'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=800',
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800',
        'https://images.unsplash.com/photo-1565849904461-04a58ad377e0?w=800'
    ],
    'image' => 'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=800',
    'image_count' => 3,
    'seller' => [
        'id' => 123,
        'name' => 'John Doe',
        'phone' => '+254712345678',
        'email' => 'john@example.com',
        'verified' => true,
        'rating' => 4.8,
        'total_reviews' => 24,
        'member_since' => '2023-01-15',
        'response_rate' => 95,
        'response_time' => 'within 2 hours'
    ],
    'created_at' => '2024-01-15 10:30:00',
    'updated_at' => '2024-01-15 14:35:00',
    'plan' => 'premium',
    'features' => [
        'Original box included',
        'Screen protector applied',
        '95% battery health',
        'No water damage',
        'All functions working'
    ],
    'specifications' => [
        'Storage' => '256GB',
        'Color' => 'Graphite',
        'Network' => '5G',
        'Condition' => 'Like New',
        'Warranty' => 'No warranty'
    ],
    'is_available' => true,
    'is_featured' => true,
    'boost_level' => 2
];

// Return the listing data
echo json_encode([
    'success' => true,
    'listing' => $sample_listing,
    'is_favorite' => false,
    'similar_listings' => [
        [
            'id' => 2,
            'title' => 'iPhone 12 Pro 128GB',
            'price' => 65000,
            'image' => 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400',
            'location' => 'Nairobi'
        ],
        [
            'id' => 3,
            'title' => 'Samsung Galaxy S22 Ultra',
            'price' => 75000,
            'image' => 'https://images.unsplash.com/photo-1565849904461-04a58ad377e0?w=400',
            'location' => 'Mombasa'
        ]
    ]
]);
?>
