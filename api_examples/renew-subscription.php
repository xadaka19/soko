<?php
/**
 * Renew Subscription API
 * URL: /api/renew-subscription.php
 * Method: POST
 * 
 * This endpoint renews an expired subscription or extends an active one.
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
        
        // Verify payment amount
        if ($amount != $plan['price']) {
            throw new Exception("Payment amount mismatch. Expected: {$plan['price']}, Received: {$amount}");
        }
        
        // Get user's current subscription
        $stmt = $pdo->prepare("
            SELECT * FROM user_subscriptions 
            WHERE user_id = ? AND status IN ('active', 'expired')
            ORDER BY created_at DESC 
            LIMIT 1
        ");
        $stmt->execute([$user_id]);
        $current_subscription = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Calculate new subscription dates
        $start_date = date('Y-m-d H:i:s');
        $end_date = null;
        
        // If extending active subscription, start from current end date
        if ($current_subscription && $current_subscription['status'] === 'active' && $current_subscription['end_date']) {
            $current_end = strtotime($current_subscription['end_date']);
            $now = time();
            if ($current_end > $now) {
                $start_date = $current_subscription['end_date'];
            }
        }
        
        // Calculate end date based on plan period
        if ($plan['period'] === 'month') {
            $end_date = date('Y-m-d H:i:s', strtotime($start_date . ' +1 month'));
        } elseif ($plan['period'] === 'year') {
            $end_date = date('Y-m-d H:i:s', strtotime($start_date . ' +1 year'));
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
        
        // Preserve existing credits if extending active subscription
        $total_credits = $credits;
        if ($current_subscription && $current_subscription['status'] === 'active') {
            $total_credits += $current_subscription['credits_remaining'];
            
            // Mark current subscription as renewed
            $stmt = $pdo->prepare("
                UPDATE user_subscriptions 
                SET status = 'renewed', updated_at = NOW()
                WHERE id = ?
            ");
            $stmt->execute([$current_subscription['id']]);
        } else {
            // Mark any existing subscriptions as expired
            $stmt = $pdo->prepare("
                UPDATE user_subscriptions 
                SET status = 'expired', updated_at = NOW()
                WHERE user_id = ? AND status = 'active'
            ");
            $stmt->execute([$user_id]);
        }
        
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
            $total_credits
        ]);
        
        $subscription_id = $pdo->lastInsertId();
        
        // Log credit addition
        $stmt = $pdo->prepare("
            INSERT INTO credit_history (
                user_id, subscription_id, credits_added, credits_used,
                action_type, description, created_at
            ) VALUES (?, ?, ?, 0, 'subscription_renewal', ?, NOW())
        ");
        $stmt->execute([
            $user_id,
            $subscription_id,
            $credits,
            "Subscription renewed: {$plan['name']} plan"
        ]);
        
        // Log payment transaction
        $stmt = $pdo->prepare("
            INSERT INTO payment_transactions (
                user_id, transaction_id, amount, payment_type, 
                payment_method, status, description, created_at
            ) VALUES (?, ?, ?, 'renewal', 'mpesa', 'completed', ?, NOW())
        ");
        $stmt->execute([
            $user_id,
            $transaction_id,
            $amount,
            "Subscription renewal: {$plan['name']} plan"
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
            'message' => 'Subscription renewed successfully',
            'subscription' => $formatted_subscription,
            'credits_added' => $credits,
            'total_credits' => $total_credits,
            'transaction_id' => $transaction_id,
            'renewal_type' => $current_subscription && $current_subscription['status'] === 'active' ? 'extension' : 'renewal'
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
        'credits_added' => 0,
        'total_credits' => 0
    ]);
}
?>

<?php
/**
 * Example Response - Renewal:
 * {
 *   "success": true,
 *   "message": "Subscription renewed successfully",
 *   "subscription": {
 *     "id": 125,
 *     "plan_id": "starter",
 *     "plan_name": "Starter Plan",
 *     "plan_period": "month",
 *     "start_date": "2024-01-15 14:30:00",
 *     "end_date": "2024-02-15 14:30:00",
 *     "status": "active",
 *     "credits_remaining": 10,
 *     "auto_renew": false
 *   },
 *   "credits_added": 10,
 *   "total_credits": 10,
 *   "transaction_id": "NLJ7RT61SV",
 *   "renewal_type": "renewal"
 * }
 * 
 * Example Response - Extension:
 * {
 *   "success": true,
 *   "message": "Subscription renewed successfully",
 *   "subscription": {
 *     "id": 126,
 *     "plan_id": "starter",
 *     "plan_name": "Starter Plan",
 *     "plan_period": "month",
 *     "start_date": "2024-02-15 14:30:00",
 *     "end_date": "2024-03-15 14:30:00",
 *     "status": "active",
 *     "credits_remaining": 15,
 *     "auto_renew": false
 *   },
 *   "credits_added": 10,
 *   "total_credits": 15,
 *   "transaction_id": "NLJ7RT61SV",
 *   "renewal_type": "extension"
 * }
 */
?>

<?php
/**
 * Renewal Types:
 * 
 * 1. Renewal: User had expired subscription
 *    - Creates new subscription starting now
 *    - Adds plan credits only
 *    - Previous credits are lost
 * 
 * 2. Extension: User has active subscription
 *    - Extends current subscription period
 *    - Preserves existing credits + adds new credits
 *    - Seamless continuation of service
 * 
 * Business Logic:
 * - Extensions preserve unused credits
 * - Renewals start fresh with plan credits
 * - All transactions are logged for audit
 * - Supports both monthly and yearly plans
 * - Auto-renew is disabled by default
 * 
 * Integration Notes:
 * - Call after successful M-Pesa payment
 * - Updates user session with new subscription
 * - Enables immediate listing creation
 * - Supports subscription analytics
 */
?>
