<?php
/**
 * Purchase Credits API
 * URL: /api/purchase-credits.php
 * Method: POST
 * 
 * This endpoint allows users to purchase additional credits for their account.
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
    $required_fields = ['user_id', 'credit_package', 'transaction_id', 'amount'];
    foreach ($required_fields as $field) {
        if (!isset($input[$field]) || empty($input[$field])) {
            throw new Exception("Missing required field: $field");
        }
    }
    
    $user_id = intval($input['user_id']);
    $credit_package = $input['credit_package'];
    $transaction_id = $input['transaction_id'];
    $amount = floatval($input['amount']);
    
    // Database connection
    $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Start transaction
    $pdo->beginTransaction();
    
    try {
        // Verify user exists
        $stmt = $pdo->prepare("SELECT id FROM users WHERE id = ? AND is_active = 1");
        $stmt->execute([$user_id]);
        if (!$stmt->fetch()) {
            throw new Exception('User not found or inactive');
        }
        
        // Define credit packages
        $credit_packages = [
            'small' => ['credits' => 5, 'price' => 100],
            'medium' => ['credits' => 15, 'price' => 250],
            'large' => ['credits' => 30, 'price' => 450],
            'extra_large' => ['credits' => 60, 'price' => 800],
        ];
        
        if (!isset($credit_packages[$credit_package])) {
            throw new Exception('Invalid credit package');
        }
        
        $package_info = $credit_packages[$credit_package];
        $credits_to_add = $package_info['credits'];
        $expected_amount = $package_info['price'];
        
        // Verify payment amount
        if ($amount != $expected_amount) {
            throw new Exception("Payment amount mismatch. Expected: {$expected_amount}, Received: {$amount}");
        }
        
        // Get user's current active subscription
        $stmt = $pdo->prepare("
            SELECT id, credits_remaining 
            FROM user_subscriptions 
            WHERE user_id = ? AND status = 'active'
            ORDER BY created_at DESC 
            LIMIT 1
        ");
        $stmt->execute([$user_id]);
        $subscription = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$subscription) {
            throw new Exception('No active subscription found. Please activate a plan first.');
        }
        
        $new_credits = $subscription['credits_remaining'] + $credits_to_add;
        
        // Update subscription with new credits
        $stmt = $pdo->prepare("
            UPDATE user_subscriptions 
            SET credits_remaining = ?, updated_at = NOW()
            WHERE id = ?
        ");
        $stmt->execute([$new_credits, $subscription['id']]);
        
        // Log credit purchase
        $stmt = $pdo->prepare("
            INSERT INTO credit_history (
                user_id, subscription_id, credits_added, credits_used,
                action_type, description, transaction_id, created_at
            ) VALUES (?, ?, ?, 0, 'credit_purchase', ?, ?, NOW())
        ");
        $stmt->execute([
            $user_id,
            $subscription['id'],
            $credits_to_add,
            "Purchased {$credits_to_add} credits ({$credit_package} package)",
            $transaction_id
        ]);
        
        // Log payment transaction
        $stmt = $pdo->prepare("
            INSERT INTO payment_transactions (
                user_id, transaction_id, amount, payment_type, 
                payment_method, status, description, created_at
            ) VALUES (?, ?, ?, 'credit_purchase', 'mpesa', 'completed', ?, NOW())
        ");
        $stmt->execute([
            $user_id,
            $transaction_id,
            $amount,
            "Credit purchase: {$credit_package} package ({$credits_to_add} credits)"
        ]);
        
        // Commit transaction
        $pdo->commit();
        
        // Return success response
        echo json_encode([
            'success' => true,
            'message' => 'Credits purchased successfully',
            'credits_added' => $credits_to_add,
            'credits_remaining' => $new_credits,
            'package' => $credit_package,
            'transaction_id' => $transaction_id,
            'amount_paid' => $amount
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
        'credits_added' => 0,
        'credits_remaining' => 0
    ]);
}
?>

<?php
/**
 * Database Schema for payment_transactions table:
 * 
 * CREATE TABLE payment_transactions (
 *     id INT AUTO_INCREMENT PRIMARY KEY,
 *     user_id INT NOT NULL,
 *     transaction_id VARCHAR(100) NOT NULL,
 *     amount DECIMAL(10,2) NOT NULL,
 *     payment_type ENUM('subscription', 'credit_purchase', 'renewal') NOT NULL,
 *     payment_method ENUM('mpesa', 'card', 'bank') NOT NULL,
 *     status ENUM('pending', 'completed', 'failed', 'cancelled') NOT NULL,
 *     description TEXT,
 *     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 *     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 *     INDEX idx_user_id (user_id),
 *     INDEX idx_transaction_id (transaction_id),
 *     INDEX idx_status (status),
 *     FOREIGN KEY (user_id) REFERENCES users(id)
 * );
 */
?>

<?php
/**
 * Credit Packages Available:
 * 
 * Small Package: 5 credits for KES 100
 * Medium Package: 15 credits for KES 250 (Best Value)
 * Large Package: 30 credits for KES 450
 * Extra Large Package: 60 credits for KES 800 (Most Popular)
 * 
 * Example Response - Success:
 * {
 *   "success": true,
 *   "message": "Credits purchased successfully",
 *   "credits_added": 15,
 *   "credits_remaining": 23,
 *   "package": "medium",
 *   "transaction_id": "NLJ7RT61SV",
 *   "amount_paid": 250
 * }
 * 
 * Example Response - Error:
 * {
 *   "success": false,
 *   "message": "No active subscription found. Please activate a plan first.",
 *   "credits_added": 0,
 *   "credits_remaining": 0
 * }
 */
?>

<?php
/**
 * Integration Notes:
 * 
 * 1. User must have an active subscription to purchase credits
 * 2. Credits are added to the existing subscription
 * 3. All transactions are logged for audit purposes
 * 4. Payment verification ensures amount matches package price
 * 5. Supports multiple credit packages with different pricing
 * 
 * Usage Flow:
 * 1. User selects credit package in mobile app
 * 2. App initiates M-Pesa payment
 * 3. After successful payment, call this API
 * 4. Credits are added to user's account
 * 5. User can immediately use credits for listings
 * 
 * Business Logic:
 * - Credits never expire (tied to subscription)
 * - Bulk packages offer better value per credit
 * - All purchases are tracked for analytics
 * - Supports refunds through transaction history
 */
?>
