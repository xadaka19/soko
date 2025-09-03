<?php
/**
 * Analytics Dashboard API
 * URL: /api/analytics-dashboard.php
 * Method: GET
 * Parameters: user_id (optional), date_from, date_to, metrics
 * 
 * This endpoint provides comprehensive analytics for the platform.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

try {
    // Get parameters
    $user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : null;
    $date_from = $_GET['date_from'] ?? date('Y-m-d', strtotime('-30 days'));
    $date_to = $_GET['date_to'] ?? date('Y-m-d');
    $metrics = $_GET['metrics'] ?? 'all'; // all, subscriptions, listings, revenue, users
    
    // Database connection
    $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $analytics = [];
    
    // User-specific analytics
    if ($user_id) {
        $analytics['user_analytics'] = getUserAnalytics($pdo, $user_id, $date_from, $date_to);
    }
    
    // Platform-wide analytics (admin only)
    if (!$user_id || $metrics === 'all') {
        if ($metrics === 'all' || $metrics === 'subscriptions') {
            $analytics['subscription_analytics'] = getSubscriptionAnalytics($pdo, $date_from, $date_to);
        }
        
        if ($metrics === 'all' || $metrics === 'listings') {
            $analytics['listing_analytics'] = getListingAnalytics($pdo, $date_from, $date_to);
        }
        
        if ($metrics === 'all' || $metrics === 'revenue') {
            $analytics['revenue_analytics'] = getRevenueAnalytics($pdo, $date_from, $date_to);
        }
        
        if ($metrics === 'all' || $metrics === 'users') {
            $analytics['user_growth'] = getUserGrowthAnalytics($pdo, $date_from, $date_to);
        }
    }
    
    echo json_encode([
        'success' => true,
        'date_range' => ['from' => $date_from, 'to' => $date_to],
        'analytics' => $analytics
    ]);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'analytics' => null
    ]);
}

function getUserAnalytics($pdo, $user_id, $date_from, $date_to) {
    $analytics = [];
    
    // User's subscription history
    $stmt = $pdo->prepare("
        SELECT 
            s.plan_id,
            p.name as plan_name,
            s.status,
            s.credits_remaining,
            s.start_date,
            s.end_date,
            s.created_at
        FROM user_subscriptions s
        JOIN subscription_plans p ON s.plan_id = p.id
        WHERE s.user_id = ? AND DATE(s.created_at) BETWEEN ? AND ?
        ORDER BY s.created_at DESC
    ");
    $stmt->execute([$user_id, $date_from, $date_to]);
    $analytics['subscriptions'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // User's listings
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_listings,
            SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) as active_listings,
            SUM(views) as total_views,
            AVG(views) as avg_views_per_listing
        FROM listings 
        WHERE user_id = ? AND DATE(created_at) BETWEEN ? AND ?
    ");
    $stmt->execute([$user_id, $date_from, $date_to]);
    $analytics['listings'] = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // User's credit usage
    $stmt = $pdo->prepare("
        SELECT 
            SUM(credits_added) as total_credits_purchased,
            SUM(credits_used) as total_credits_used,
            COUNT(CASE WHEN action_type = 'listing_creation' THEN 1 END) as listings_created,
            COUNT(CASE WHEN action_type = 'credit_purchase' THEN 1 END) as credit_purchases
        FROM credit_history 
        WHERE user_id = ? AND DATE(created_at) BETWEEN ? AND ?
    ");
    $stmt->execute([$user_id, $date_from, $date_to]);
    $analytics['credit_usage'] = $stmt->fetch(PDO::FETCH_ASSOC);
    
    return $analytics;
}

function getSubscriptionAnalytics($pdo, $date_from, $date_to) {
    $analytics = [];
    
    // Subscription overview
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_subscriptions,
            COUNT(CASE WHEN status = 'active' THEN 1 END) as active_subscriptions,
            COUNT(CASE WHEN status = 'expired' THEN 1 END) as expired_subscriptions,
            COUNT(CASE WHEN plan_id = 'free' THEN 1 END) as free_subscriptions,
            COUNT(CASE WHEN plan_id != 'free' THEN 1 END) as paid_subscriptions
        FROM user_subscriptions 
        WHERE DATE(created_at) BETWEEN ? AND ?
    ");
    $stmt->execute([$date_from, $date_to]);
    $analytics['overview'] = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Plan popularity
    $stmt = $pdo->prepare("
        SELECT 
            s.plan_id,
            p.name as plan_name,
            COUNT(*) as subscription_count,
            COUNT(CASE WHEN s.status = 'active' THEN 1 END) as active_count
        FROM user_subscriptions s
        JOIN subscription_plans p ON s.plan_id = p.id
        WHERE DATE(s.created_at) BETWEEN ? AND ?
        GROUP BY s.plan_id, p.name
        ORDER BY subscription_count DESC
    ");
    $stmt->execute([$date_from, $date_to]);
    $analytics['plan_popularity'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    return $analytics;
}

function getListingAnalytics($pdo, $date_from, $date_to) {
    $analytics = [];
    
    // Listing overview
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_listings,
            COUNT(CASE WHEN status = 'active' THEN 1 END) as active_listings,
            SUM(views) as total_views,
            AVG(views) as avg_views_per_listing,
            AVG(price) as avg_listing_price
        FROM listings 
        WHERE DATE(created_at) BETWEEN ? AND ?
    ");
    $stmt->execute([$date_from, $date_to]);
    $analytics['overview'] = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Category distribution
    $stmt = $pdo->prepare("
        SELECT 
            category_id,
            COUNT(*) as listing_count,
            AVG(price) as avg_price,
            SUM(views) as total_views
        FROM listings 
        WHERE DATE(created_at) BETWEEN ? AND ?
        GROUP BY category_id
        ORDER BY listing_count DESC
    ");
    $stmt->execute([$date_from, $date_to]);
    $analytics['category_distribution'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Daily listing creation
    $stmt = $pdo->prepare("
        SELECT 
            DATE(created_at) as date,
            COUNT(*) as listings_created
        FROM listings 
        WHERE DATE(created_at) BETWEEN ? AND ?
        GROUP BY DATE(created_at)
        ORDER BY date
    ");
    $stmt->execute([$date_from, $date_to]);
    $analytics['daily_creation'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    return $analytics;
}

function getRevenueAnalytics($pdo, $date_from, $date_to) {
    $analytics = [];
    
    // Revenue overview
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_transactions,
            SUM(amount) as total_revenue,
            AVG(amount) as avg_transaction_value,
            COUNT(CASE WHEN payment_type = 'subscription' THEN 1 END) as subscription_payments,
            COUNT(CASE WHEN payment_type = 'credit_purchase' THEN 1 END) as credit_purchases,
            SUM(CASE WHEN payment_type = 'subscription' THEN amount ELSE 0 END) as subscription_revenue,
            SUM(CASE WHEN payment_type = 'credit_purchase' THEN amount ELSE 0 END) as credit_revenue
        FROM payment_transactions 
        WHERE status = 'completed' AND DATE(created_at) BETWEEN ? AND ?
    ");
    $stmt->execute([$date_from, $date_to]);
    $analytics['overview'] = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Daily revenue
    $stmt = $pdo->prepare("
        SELECT 
            DATE(created_at) as date,
            COUNT(*) as transaction_count,
            SUM(amount) as daily_revenue
        FROM payment_transactions 
        WHERE status = 'completed' AND DATE(created_at) BETWEEN ? AND ?
        GROUP BY DATE(created_at)
        ORDER BY date
    ");
    $stmt->execute([$date_from, $date_to]);
    $analytics['daily_revenue'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    return $analytics;
}

function getUserGrowthAnalytics($pdo, $date_from, $date_to) {
    $analytics = [];
    
    // User registration growth
    $stmt = $pdo->prepare("
        SELECT 
            DATE(created_at) as date,
            COUNT(*) as new_users
        FROM users 
        WHERE DATE(created_at) BETWEEN ? AND ?
        GROUP BY DATE(created_at)
        ORDER BY date
    ");
    $stmt->execute([$date_from, $date_to]);
    $analytics['daily_registrations'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // User activity
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(DISTINCT user_id) as active_users,
            COUNT(DISTINCT CASE WHEN DATE(created_at) = CURDATE() THEN user_id END) as daily_active_users
        FROM listings 
        WHERE DATE(created_at) BETWEEN ? AND ?
    ");
    $stmt->execute([$date_from, $date_to]);
    $analytics['user_activity'] = $stmt->fetch(PDO::FETCH_ASSOC);
    
    return $analytics;
}
?>

<?php
/**
 * Example Response:
 * {
 *   "success": true,
 *   "date_range": {
 *     "from": "2024-01-01",
 *     "to": "2024-01-31"
 *   },
 *   "analytics": {
 *     "subscription_analytics": {
 *       "overview": {
 *         "total_subscriptions": 150,
 *         "active_subscriptions": 120,
 *         "expired_subscriptions": 30,
 *         "free_subscriptions": 80,
 *         "paid_subscriptions": 70
 *       },
 *       "plan_popularity": [
 *         {
 *           "plan_id": "starter",
 *           "plan_name": "Starter Plan",
 *           "subscription_count": 45,
 *           "active_count": 38
 *         }
 *       ]
 *     },
 *     "revenue_analytics": {
 *       "overview": {
 *         "total_transactions": 85,
 *         "total_revenue": 12500.00,
 *         "avg_transaction_value": 147.06,
 *         "subscription_revenue": 10000.00,
 *         "credit_revenue": 2500.00
 *       }
 *     }
 *   }
 * }
 */
?>
