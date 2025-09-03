<?php
/**
 * Activate Free Plan API
 * URL: /api/activate-free-plan.php
 * Method: POST
 * 
 * This endpoint activates the free plan for a user.
 * It creates a subscription record and adds free credits.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

try {
    // Get request data
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        throw new Exception('Invalid JSON input');
    }
    
    // Validate required fields
    if (!isset($input['user_id']) || empty($input['user_id'])) {
        throw new Exception('User ID is required');
    }
    
    $user_id = intval($input['user_id']);
    
    // Database connection
    $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Start transaction
    $pdo->beginTransaction();
    
    try {
        // Get free plan details
        $stmt = $pdo->prepare("
            SELECT * FROM subscription_plans 
            WHERE id = 'free' AND is_active = 1
        ");
        $stmt->execute();
        $plan = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$plan) {
            throw new Exception('Free plan not found or inactive');
        }
        
        // Check if user already has an active free plan
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as count 
            FROM user_subscriptions 
            WHERE user_id = ? AND plan_id = 'free' AND status = 'active'
        ");
        $stmt->execute([$user_id]);
        $existing_free = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
        
        if ($existing_free > 0) {
            throw new Exception('User already has an active free plan');
        }
        
        // Extract credits from plan features
        $features = json_decode($plan['features'], true) ?? [];
        $credits = 0;
        foreach ($features as $feature) {
            if (preg_match('/(\d+)\s+(?:free\s+)?credits?/i', $feature, $matches)) {
                $credits = (int)$matches[1];
                break;
            }
        }
        
        // Set default credits if not found in features
        if ($credits === 0) {
            $credits = 7; // Default free credits
        }
        
        // Deactivate existing active subscriptions for this user
        $stmt = $pdo->prepare("
            UPDATE user_subscriptions 
            SET status = 'expired', updated_at = NOW()
            WHERE user_id = ? AND status = 'active'
        ");
        $stmt->execute([$user_id]);
        
        // Create new free subscription (no end date for free plan)
        $stmt = $pdo->prepare("
            INSERT INTO user_subscriptions (
                user_id, plan_id, transaction_id, start_date, end_date,
                status, credits_remaining, auto_renew, created_at
            ) VALUES (?, 'free', NULL, NOW(), NULL, 'active', ?, FALSE, NOW())
        ");
        $stmt->execute([$user_id, $credits]);
        
        $subscription_id = $pdo->lastInsertId();
        
        // Log credit addition
        $stmt = $pdo->prepare("
            INSERT INTO credit_history (
                user_id, subscription_id, credits_added, credits_used,
                action_type, description, created_at
            ) VALUES (?, ?, ?, 0, 'plan_activation', 'Free plan activation', NOW())
        ");
        $stmt->execute([$user_id, $subscription_id, $credits]);
        
        // Get the created subscription with plan details
        $stmt = $pdo->prepare("
            SELECT 
                s.*,
                p.name as plan_name,
                p.period as plan_period,
                p.features as plan_features
            FROM user_subscriptions s
            JOIN subscription_plans p ON s.plan_id = p.id
            WHERE s.id = ?
        ");
        $stmt->execute([$subscription_id]);
        $subscription = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Commit transaction
        $pdo->commit();
        
        // Format subscription data
        $formatted_subscription = [
            'id' => $subscription['id'],
            'plan_id' => $subscription['plan_id'],
            'plan_name' => $subscription['plan_name'],
            'plan_period' => $subscription['plan_period'],
            'plan_features' => json_decode($subscription['plan_features'], true),
            'start_date' => $subscription['start_date'],
            'end_date' => $subscription['end_date'],
            'status' => $subscription['status'],
            'credits_remaining' => intval($subscription['credits_remaining']),
            'auto_renew' => (bool)$subscription['auto_renew'],
            'created_at' => $subscription['created_at']
        ];
        
        // Return success response
        echo json_encode([
            'success' => true,
            'message' => 'Free plan activated successfully',
            'subscription' => $formatted_subscription,
            'credits_added' => $credits
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
        'subscription' => null,
        'credits_added' => 0
    ]);
}
?>

<?php
/**
 * Example Response:
 * {
 *   "success": true,
 *   "message": "Free plan activated successfully",
 *   "subscription": {
 *     "id": 124,
 *     "plan_id": "free",
 *     "plan_name": "Free Plan",
 *     "plan_period": null,
 *     "plan_features": [
 *       "Ads auto-renew Every 48 hours",
 *       "7 free credits(ads)"
 *     ],
 *     "start_date": "2024-01-15 14:30:00",
 *     "end_date": null,
 *     "status": "active",
 *     "credits_remaining": 7,
 *     "auto_renew": false,
 *     "created_at": "2024-01-15 14:30:00"
 *   },
 *   "credits_added": 7
 * }
 */
?>

<?php
/**
 * Free Plan Features:
 * 
 * 1. No payment required
 * 2. No expiration date (end_date = NULL)
 * 3. Limited credits (usually 7)
 * 4. Can only have one active free plan per user
 * 5. Automatically deactivates other active subscriptions
 * 
 * Credit Extraction Patterns:
 * - "7 free credits(ads)" → extracts 7 credits
 * - "5 credits" → extracts 5 credits
 * - "10 free credits" → extracts 10 credits
 * 
 * Default Behavior:
 * - If no credits found in features, defaults to 7 credits
 * - Free plan never expires (end_date = NULL)
 * - Auto-renew is always FALSE for free plans
 */
?>

<?php
/**
 * Usage in Mobile App:
 *
 * When user selects free plan:
 * 1. Call this endpoint to activate free plan
 * 2. Credits are added to user account
 * 3. User can immediately start creating listings
 * 4. Each listing creation will consume 1 credit
 *
 * Integration with Payment Flow:
 * - Free plans skip M-Pesa payment
 * - Directly activate subscription
 * - Show success message with credits added
 * - Redirect to create listing screen
 */
?>
