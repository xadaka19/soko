<?php
/**
 * Check Listing Eligibility API
 * URL: /api/check-listing-eligibility.php
 * Method: GET
 * Parameters: user_id
 * 
 * This endpoint checks if a user can create a listing (has credits and active plan).
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

try {
    // Validate required parameters
    if (!isset($_GET['user_id']) || empty($_GET['user_id'])) {
        throw new Exception('User ID is required');
    }
    
    $user_id = intval($_GET['user_id']);
    
    // Database connection
    $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Get user's active subscription
    $stmt = $pdo->prepare("
        SELECT 
            s.*,
            p.name as plan_name,
            p.period as plan_period
        FROM user_subscriptions s
        JOIN subscription_plans p ON s.plan_id = p.id
        WHERE s.user_id = ? AND s.status = 'active'
        ORDER BY s.created_at DESC
        LIMIT 1
    ");
    $stmt->execute([$user_id]);
    $subscription = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$subscription) {
        // No active subscription
        echo json_encode([
            'can_create' => false,
            'credits_remaining' => 0,
            'plan_name' => 'No Plan',
            'plan_status' => 'inactive',
            'message' => 'No active subscription. Please select a plan to start creating listings.',
            'requires_plan' => true
        ]);
        exit;
    }
    
    // Check if subscription has expired (for paid plans)
    $is_expired = false;
    if ($subscription['end_date'] !== null) {
        $end_date = strtotime($subscription['end_date']);
        $current_time = time();
        $is_expired = $current_time > $end_date;
    }
    
    if ($is_expired) {
        // Mark subscription as expired
        $stmt = $pdo->prepare("
            UPDATE user_subscriptions 
            SET status = 'expired', updated_at = NOW()
            WHERE id = ?
        ");
        $stmt->execute([$subscription['id']]);
        
        echo json_encode([
            'can_create' => false,
            'credits_remaining' => 0,
            'plan_name' => $subscription['plan_name'],
            'plan_status' => 'expired',
            'message' => 'Your subscription has expired. Please renew your plan to continue creating listings.',
            'requires_plan' => true
        ]);
        exit;
    }
    
    // Check credits
    $credits_remaining = intval($subscription['credits_remaining']);
    $can_create = $credits_remaining > 0;
    
    $message = '';
    if ($can_create) {
        $message = $credits_remaining === 1 
            ? 'You have 1 credit remaining.'
            : "You have {$credits_remaining} credits remaining.";
    } else {
        $message = 'You have no credits remaining. Please upgrade your plan or purchase more credits.';
    }
    
    // Return response
    echo json_encode([
        'can_create' => $can_create,
        'credits_remaining' => $credits_remaining,
        'plan_name' => $subscription['plan_name'],
        'plan_status' => 'active',
        'plan_id' => $subscription['plan_id'],
        'subscription_id' => $subscription['id'],
        'end_date' => $subscription['end_date'],
        'message' => $message,
        'requires_plan' => false
    ]);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'can_create' => false,
        'credits_remaining' => 0,
        'plan_name' => 'Error',
        'plan_status' => 'error',
        'message' => 'Error checking eligibility: ' . $e->getMessage(),
        'requires_plan' => true
    ]);
}
?>

<?php
/**
 * Example Responses:
 * 
 * User can create listing:
 * {
 *   "can_create": true,
 *   "credits_remaining": 5,
 *   "plan_name": "Starter Plan",
 *   "plan_status": "active",
 *   "plan_id": "starter",
 *   "subscription_id": 123,
 *   "end_date": "2024-02-15 14:30:00",
 *   "message": "You have 5 credits remaining.",
 *   "requires_plan": false
 * }
 * 
 * No credits remaining:
 * {
 *   "can_create": false,
 *   "credits_remaining": 0,
 *   "plan_name": "Starter Plan",
 *   "plan_status": "active",
 *   "plan_id": "starter",
 *   "subscription_id": 123,
 *   "end_date": "2024-02-15 14:30:00",
 *   "message": "You have no credits remaining. Please upgrade your plan or purchase more credits.",
 *   "requires_plan": false
 * }
 * 
 * No active subscription:
 * {
 *   "can_create": false,
 *   "credits_remaining": 0,
 *   "plan_name": "No Plan",
 *   "plan_status": "inactive",
 *   "message": "No active subscription. Please select a plan to start creating listings.",
 *   "requires_plan": true
 * }
 * 
 * Expired subscription:
 * {
 *   "can_create": false,
 *   "credits_remaining": 0,
 *   "plan_name": "Starter Plan",
 *   "plan_status": "expired",
 *   "message": "Your subscription has expired. Please renew your plan to continue creating listings.",
 *   "requires_plan": true
 * }
 */
?>

<?php
/**
 * Usage in Mobile App:
 * 
 * Call this endpoint before showing the create listing screen:
 * 
 * 1. If can_create = true: Allow user to create listing
 * 2. If can_create = false && requires_plan = true: Redirect to plan selection
 * 3. If can_create = false && requires_plan = false: Show upgrade message
 * 
 * Integration Points:
 * - Create listing screen: Check eligibility on screen load
 * - Navigation: Check before navigating to create listing
 * - Home screen: Show user's credit count
 * - Profile screen: Display subscription status
 * 
 * Error Handling:
 * - Network errors: Allow offline creation with sync later
 * - Server errors: Show generic error message
 * - Invalid user: Redirect to login
 */
?>
