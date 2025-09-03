<?php
/**
 * Activate User Subscription API
 * URL: /api/activate-subscription.php
 * Method: POST
 * 
 * This endpoint activates a paid subscription after successful M-Pesa payment.
 * It creates a subscription record and adds credits to the user's account.
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
    $required_fields = ['user_id', 'plan_id', 'transaction_id', 'amount'];
    foreach ($required_fields as $field) {
        if (!isset($input[$field]) || empty($input[$field])) {
            throw new Exception("Missing required field: $field");
        }
    }
    
    $user_id = intval($input['user_id']);
    $plan_id = $input['plan_id'];
    $transaction_id = $input['transaction_id'];
    $amount = floatval($input['amount']);
    
    // Database connection
    $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Start transaction
    $pdo->beginTransaction();
    
    try {
        // Get plan details
        $stmt = $pdo->prepare("SELECT * FROM subscription_plans WHERE id = ? AND is_active = 1");
        $stmt->execute([$plan_id]);
        $plan = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$plan) {
            throw new Exception('Plan not found or inactive');
        }
        
        // Calculate subscription dates
        $start_date = date('Y-m-d H:i:s');
        $end_date = null;
        
        if ($plan['period'] === 'month') {
            $end_date = date('Y-m-d H:i:s', strtotime('+1 month'));
        } elseif ($plan['period'] === 'year') {
            $end_date = date('Y-m-d H:i:s', strtotime('+1 year'));
        }
        
        // Extract credits from plan features
        $features = json_decode($plan['features'], true) ?? [];
        $credits = 0;
        foreach ($features as $feature) {
            if (preg_match('/(\d+)\s+credits?/i', $feature, $matches)) {
                $credits = (int)$matches[1];
                break;
            }
        }
        
        // Deactivate existing active subscriptions for this user
        $stmt = $pdo->prepare("
            UPDATE user_subscriptions 
            SET status = 'expired', updated_at = NOW()
            WHERE user_id = ? AND status = 'active'
        ");
        $stmt->execute([$user_id]);
        
        // Create new subscription
        $stmt = $pdo->prepare("
            INSERT INTO user_subscriptions (
                user_id, plan_id, transaction_id, start_date, end_date,
                status, credits_remaining, auto_renew, created_at
            ) VALUES (?, ?, ?, ?, ?, 'active', ?, FALSE, NOW())
        ");
        $stmt->execute([
            $user_id,
            $plan_id,
            $transaction_id,
            $start_date,
            $end_date,
            $credits
        ]);
        
        $subscription_id = $pdo->lastInsertId();
        
        // Log credit addition
        $stmt = $pdo->prepare("
            INSERT INTO credit_history (
                user_id, subscription_id, credits_added, credits_used,
                action_type, description, created_at
            ) VALUES (?, ?, ?, 0, 'plan_activation', ?, NOW())
        ");
        $stmt->execute([
            $user_id,
            $subscription_id,
            $credits,
            "Credits added from {$plan['name']} plan activation"
        ]);
        
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
            'message' => 'Subscription activated successfully',
            'subscription' => $formatted_subscription,
            'credits_added' => $credits,
            'transaction_id' => $transaction_id
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
 * Database Schema for credit_history table:
 * 
 * CREATE TABLE credit_history (
 *     id INT AUTO_INCREMENT PRIMARY KEY,
 *     user_id INT NOT NULL,
 *     subscription_id INT,
 *     listing_id INT,
 *     credits_added INT DEFAULT 0,
 *     credits_used INT DEFAULT 0,
 *     action_type ENUM('plan_activation', 'listing_creation', 'manual_adjustment', 'refund') NOT NULL,
 *     description TEXT,
 *     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 *     INDEX idx_user_id (user_id),
 *     INDEX idx_action_type (action_type),
 *     FOREIGN KEY (user_id) REFERENCES users(id),
 *     FOREIGN KEY (subscription_id) REFERENCES user_subscriptions(id),
 *     FOREIGN KEY (listing_id) REFERENCES listings(id)
 * );
 */
?>

<?php
/**
 * Example Response:
 * {
 *   "success": true,
 *   "message": "Subscription activated successfully",
 *   "subscription": {
 *     "id": 123,
 *     "plan_id": "starter",
 *     "plan_name": "Starter Plan",
 *     "plan_period": "month",
 *     "plan_features": [
 *       "10 credits (ads)",
 *       "Ads auto-renew Every 12 hours"
 *     ],
 *     "start_date": "2024-01-15 14:30:00",
 *     "end_date": "2024-02-15 14:30:00",
 *     "status": "active",
 *     "credits_remaining": 10,
 *     "auto_renew": false,
 *     "created_at": "2024-01-15 14:30:00"
 *   },
 *   "credits_added": 10,
 *   "transaction_id": "NLJ7RT61SV"
 * }
 */
?>

<?php
/**
 * Integration Notes:
 * 
 * 1. This endpoint should be called after successful M-Pesa payment
 * 2. It automatically deactivates any existing active subscriptions
 * 3. Credits are extracted from plan features using regex
 * 4. All actions are logged in credit_history table
 * 5. Transaction rollback ensures data consistency
 * 
 * Plan Feature Format:
 * - "10 credits (ads)" → extracts 10 credits
 * - "27 credits (ads)" → extracts 27 credits
 * - Features without credits are ignored
 * 
 * Subscription Status:
 * - 'active': Currently active subscription
 * - 'expired': Subscription has ended
 * - 'cancelled': Manually cancelled subscription
 */
?>
