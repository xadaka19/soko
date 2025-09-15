<?php
/**
 * API Endpoint: Get Plans
 * URL: /api/get-plans.php
 * Method: GET
 * 
 * This endpoint returns all available subscription plans for the mobile app.
 * Plans are fetched from the database and can be managed through the admin dashboard.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

try {
    // For testing purposes, use sample data instead of database
    // In production, uncomment the database code below

    /*
    // Database connection (adjust according to your setup)
    $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Fetch all active plans from database
    $stmt = $pdo->prepare("
        SELECT
            id,
            name,
            price,
            period,
            features,
            is_active,
            sort_order,
            created_at,
            updated_at
        FROM subscription_plans
        WHERE is_active = 1
        ORDER BY sort_order ASC, price ASC
    ");

    $stmt->execute();
    $plans = $stmt->fetchAll(PDO::FETCH_ASSOC);
    */

    // Sample plans data for testing
    $plans = [
        [
            'id' => 1,
            'name' => 'free',
            'price' => 0,
            'period' => 'forever',
            'features' => json_encode(['5 listings', 'Basic support', 'Standard visibility']),
            'is_active' => 1,
            'sort_order' => 1
        ],
        [
            'id' => 2,
            'name' => 'basic',
            'price' => 500,
            'period' => 'month',
            'features' => json_encode(['20 listings', 'Priority support', 'Enhanced visibility', 'Featured badge']),
            'is_active' => 1,
            'sort_order' => 2
        ],
        [
            'id' => 3,
            'name' => 'premium',
            'price' => 1500,
            'period' => 'month',
            'features' => json_encode(['Unlimited listings', 'Premium support', 'Maximum visibility', 'Featured badge', 'Top placement']),
            'is_active' => 1,
            'sort_order' => 3
        ]
    ];
    
    // Format plans for mobile app
    $formattedPlans = [];
    foreach ($plans as $plan) {
        $formattedPlans[] = [
            'id' => $plan['id'],
            'name' => strtoupper($plan['name']),
            'price' => 'KES ' . number_format($plan['price']),
            'period' => $plan['period'] ? '/ ' . $plan['period'] : '',
            'color' => '#2196F3', // Blue color (can be customized per plan)
            'features' => json_decode($plan['features'], true) ?: [],
            'type' => strtolower($plan['name']), // Add type field for featured plan detection
        ];
    }
    
    // Return success response
    echo json_encode([
        'success' => true,
        'message' => 'Plans loaded successfully',
        'plans' => $formattedPlans,
        'count' => count($formattedPlans),
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    
} catch (PDOException $e) {
    // Database error
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage(),
        'plans' => [],
        'count' => 0
    ]);
    
} catch (Exception $e) {
    // General error
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage(),
        'plans' => [],
        'count' => 0
    ]);
}
?>

<?php
/**
 * Database Schema for subscription_plans table:
 * 
 * CREATE TABLE subscription_plans (
 *     id VARCHAR(50) PRIMARY KEY,
 *     name VARCHAR(100) NOT NULL,
 *     price DECIMAL(10,2) NOT NULL,
 *     period VARCHAR(20) DEFAULT NULL, -- 'month', 'year', etc.
 *     features JSON NOT NULL, -- Array of features
 *     is_active BOOLEAN DEFAULT TRUE,
 *     sort_order INT DEFAULT 0,
 *     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 *     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
 * );
 * 
 * Sample data:
 * INSERT INTO subscription_plans (id, name, price, period, features, sort_order) VALUES
 * ('free', 'Free Plan', 0.00, NULL, '["Ads auto-renew Every 48 hours", "7 free credits(ads)"]', 1),
 * ('top', 'Top', 250.00, NULL, '["7 days listing", "1 credit (ad)", "Ads auto-renew Every 24 hours"]', 2),
 * ('top_featured', 'Top Featured', 400.00, 'month', '["1 credit (ad)", "Ads auto-renew Every 16 hours"]', 3),
 * ('starter', 'Starter', 3000.00, 'month', '["10 credits (ads)", "Ads auto-renew Every 12 hours"]', 4),
 * ('basic', 'Basic', 5000.00, 'month', '["27 credits (ads)", "Ads auto-renew Every 10 hours"]', 5),
 * ('premium', 'Premium', 7000.00, 'month', '["45 credits (ads)", "Ads auto-renew Every 8 hours"]', 6),
 * ('business', 'Business', 10000.00, 'month', '["74 credits (ads)", "Ads auto-renew Every 6 hours"]', 7);
 */
?>

<?php
/**
 * Example Response:
 * {
 *   "success": true,
 *   "message": "Plans loaded successfully",
 *   "plans": [
 *     {
 *       "id": "free",
 *       "name": "FREE PLAN",
 *       "price": "KES 0",
 *       "period": "",
 *       "color": "#2196F3",
 *       "features": [
 *         "Ads auto-renew Every 48 hours",
 *         "7 free credits(ads)"
 *       ]
 *     },
 *     {
 *       "id": "top",
 *       "name": "TOP",
 *       "price": "KES 250",
 *       "period": "",
 *       "color": "#2196F3",
 *       "features": [
 *         "7 days listing",
 *         "1 credit (ad)",
 *         "Ads auto-renew Every 24 hours"
 *       ]
 *     }
 *   ],
 *   "count": 7,
 *   "timestamp": "2024-01-15 10:30:00"
 * }
 */
?>

<?php
/**
 * Admin Dashboard Integration:
 * 
 * The admin dashboard should have a "Plans Management" section where admins can:
 * 1. Add new plans
 * 2. Edit existing plans (name, price, features)
 * 3. Enable/disable plans
 * 4. Reorder plans (sort_order)
 * 5. View plan usage statistics
 * 
 * When plans are updated in the admin dashboard, the mobile app will automatically
 * fetch the latest plans when users visit the plan selection screen.
 * 
 * Features to implement in admin dashboard:
 * - Plan CRUD operations
 * - Feature management (add/remove features per plan)
 * - Pricing updates
 * - Plan activation/deactivation
 * - Usage analytics per plan
 */
?>
