<?php
/**
 * M-Pesa Callback Handler
 * URL: /api/mpesa/callback.php
 * Method: POST
 * 
 * This endpoint receives M-Pesa payment callbacks from Safaricom.
 * It processes the payment result and updates the database accordingly.
 */

header('Content-Type: application/json');

// Log all incoming requests for debugging
$log_data = [
    'timestamp' => date('Y-m-d H:i:s'),
    'method' => $_SERVER['REQUEST_METHOD'],
    'headers' => getallheaders(),
    'body' => file_get_contents('php://input')
];
file_put_contents('mpesa_callback.log', json_encode($log_data) . "\n", FILE_APPEND);

try {
    // Get callback data
    $callback_data = json_decode(file_get_contents('php://input'), true);
    
    if (!$callback_data) {
        throw new Exception('Invalid callback data');
    }
    
    // Extract callback information
    $body = $callback_data['Body'] ?? [];
    $stk_callback = $body['stkCallback'] ?? [];
    
    $merchant_request_id = $stk_callback['MerchantRequestID'] ?? '';
    $checkout_request_id = $stk_callback['CheckoutRequestID'] ?? '';
    $result_code = $stk_callback['ResultCode'] ?? -1;
    $result_desc = $stk_callback['ResultDesc'] ?? '';
    
    // Database connection
    $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Find the transaction
    $stmt = $pdo->prepare("
        SELECT * FROM mpesa_transactions 
        WHERE checkout_request_id = ? OR merchant_request_id = ?
    ");
    $stmt->execute([$checkout_request_id, $merchant_request_id]);
    $transaction = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$transaction) {
        throw new Exception('Transaction not found');
    }
    
    // Process based on result code
    if ($result_code == 0) {
        // Payment successful
        $callback_metadata = $stk_callback['CallbackMetadata'] ?? [];
        $items = $callback_metadata['Item'] ?? [];
        
        $amount = null;
        $mpesa_receipt_number = null;
        $transaction_date = null;
        $phone_number = null;
        
        // Extract metadata
        foreach ($items as $item) {
            switch ($item['Name']) {
                case 'Amount':
                    $amount = $item['Value'];
                    break;
                case 'MpesaReceiptNumber':
                    $mpesa_receipt_number = $item['Value'];
                    break;
                case 'TransactionDate':
                    $transaction_date = DateTime::createFromFormat('YmdHis', $item['Value'])->format('Y-m-d H:i:s');
                    break;
                case 'PhoneNumber':
                    $phone_number = $item['Value'];
                    break;
            }
        }
        
        // Update transaction as completed
        $stmt = $pdo->prepare("
            UPDATE mpesa_transactions 
            SET status = 'completed',
                result_code = ?,
                result_desc = ?,
                mpesa_receipt_number = ?,
                transaction_date = ?,
                updated_at = NOW()
            WHERE id = ?
        ");
        $stmt->execute([
            $result_code,
            $result_desc,
            $mpesa_receipt_number,
            $transaction_date,
            $transaction['id']
        ]);
        
        // Activate user subscription
        activateUserSubscription($pdo, $transaction);
        
        // Send success notification (optional)
        sendPaymentNotification($transaction['user_id'], 'success', $mpesa_receipt_number);
        
    } else {
        // Payment failed or cancelled
        $status = ($result_code == 1032) ? 'cancelled' : 'failed';
        
        $stmt = $pdo->prepare("
            UPDATE mpesa_transactions 
            SET status = ?,
                result_code = ?,
                result_desc = ?,
                updated_at = NOW()
            WHERE id = ?
        ");
        $stmt->execute([
            $status,
            $result_code,
            $result_desc,
            $transaction['id']
        ]);
        
        // Send failure notification (optional)
        sendPaymentNotification($transaction['user_id'], 'failed', null);
    }
    
    // Return success response to M-Pesa
    echo json_encode([
        'ResultCode' => 0,
        'ResultDesc' => 'Callback processed successfully'
    ]);
    
} catch (Exception $e) {
    // Log error
    error_log('M-Pesa Callback Error: ' . $e->getMessage());
    
    // Return error response to M-Pesa
    echo json_encode([
        'ResultCode' => 1,
        'ResultDesc' => 'Callback processing failed: ' . $e->getMessage()
    ]);
}

/**
 * Activate user subscription after successful payment
 */
function activateUserSubscription($pdo, $transaction) {
    try {
        // Get plan details
        $stmt = $pdo->prepare("SELECT * FROM subscription_plans WHERE id = ?");
        $stmt->execute([$transaction['plan_id']]);
        $plan = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$plan) {
            throw new Exception('Plan not found');
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
        
        // Deactivate existing subscriptions for this user
        $stmt = $pdo->prepare("
            UPDATE user_subscriptions 
            SET status = 'expired', updated_at = NOW()
            WHERE user_id = ? AND status = 'active'
        ");
        $stmt->execute([$transaction['user_id']]);
        
        // Create new subscription
        $stmt = $pdo->prepare("
            INSERT INTO user_subscriptions (
                user_id, plan_id, transaction_id, start_date, end_date,
                status, credits_remaining, auto_renew, created_at
            ) VALUES (?, ?, ?, ?, ?, 'active', ?, FALSE, NOW())
        ");
        $stmt->execute([
            $transaction['user_id'],
            $transaction['plan_id'],
            $transaction['id'],
            $start_date,
            $end_date,
            $credits
        ]);
        
    } catch (Exception $e) {
        error_log('Subscription activation error: ' . $e->getMessage());
    }
}

/**
 * Send payment notification to user (implement as needed)
 */
function sendPaymentNotification($user_id, $status, $receipt_number) {
    // Implement notification logic here
    // Could be email, SMS, push notification, etc.
    
    // Example: Log notification
    $message = $status === 'success' 
        ? "Payment successful. Receipt: $receipt_number"
        : "Payment failed or was cancelled";
        
    error_log("Notification for user $user_id: $message");
}
?>

<?php
/**
 * Common M-Pesa Result Codes:
 * 
 * 0 - Success
 * 1 - Insufficient Funds
 * 2 - Less Than Minimum Transaction Value
 * 3 - More Than Maximum Transaction Value
 * 4 - Would Exceed Daily Transfer Limit
 * 5 - Would Exceed Minimum Balance
 * 6 - Unresolved Primary Party
 * 7 - Unresolved Receiver Party
 * 8 - Would Exceed Maximum Balance
 * 11 - Debit Account Invalid
 * 12 - Credit Account Invalid
 * 13 - Unresolved Debit Account
 * 14 - Unresolved Credit Account
 * 15 - Duplicate Detected
 * 17 - Internal Failure
 * 20 - Unresolved Initiator
 * 26 - Traffic Blocking Condition In Place
 * 1032 - Cancelled by user
 * 1037 - Timeout
 */
?>

<?php
/**
 * Example Callback Data Structure:
 * 
 * {
 *   "Body": {
 *     "stkCallback": {
 *       "MerchantRequestID": "29115-34620561-1",
 *       "CheckoutRequestID": "ws_CO_191220191020363925",
 *       "ResultCode": 0,
 *       "ResultDesc": "The service request is processed successfully.",
 *       "CallbackMetadata": {
 *         "Item": [
 *           {
 *             "Name": "Amount",
 *             "Value": 1.00
 *           },
 *           {
 *             "Name": "MpesaReceiptNumber",
 *             "Value": "NLJ7RT61SV"
 *           },
 *           {
 *             "Name": "TransactionDate",
 *             "Value": 20191219102115
 *           },
 *           {
 *             "Name": "PhoneNumber",
 *             "Value": 254708374149
 *           }
 *         ]
 *       }
 *     }
 *   }
 * }
 */
?>
