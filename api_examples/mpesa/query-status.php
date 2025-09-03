<?php
/**
 * M-Pesa Payment Status Query
 * URL: /api/mpesa/query-status.php
 * Method: POST
 * 
 * This endpoint checks the status of an M-Pesa payment transaction.
 * Used by the mobile app to poll for payment completion.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

try {
    // Get request data
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input || !isset($input['checkout_request_id'])) {
        throw new Exception('Checkout Request ID is required');
    }
    
    $checkout_request_id = $input['checkout_request_id'];
    
    // Database connection
    $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Get transaction details
    $stmt = $pdo->prepare("
        SELECT 
            t.*,
            p.name as plan_name,
            u.first_name,
            u.last_name,
            u.email
        FROM mpesa_transactions t
        LEFT JOIN subscription_plans p ON t.plan_id = p.id
        LEFT JOIN users u ON t.user_id = u.id
        WHERE t.checkout_request_id = ?
    ");
    $stmt->execute([$checkout_request_id]);
    $transaction = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$transaction) {
        throw new Exception('Transaction not found');
    }
    
    // Determine payment status
    $payment_status = 'pending';
    switch ($transaction['status']) {
        case 'completed':
            $payment_status = 'completed';
            break;
        case 'failed':
            $payment_status = 'failed';
            break;
        case 'cancelled':
            $payment_status = 'cancelled';
            break;
        default:
            $payment_status = 'pending';
    }
    
    // If still pending and it's been more than 5 minutes, check with M-Pesa API
    if ($payment_status === 'pending') {
        $created_time = strtotime($transaction['created_at']);
        $current_time = time();
        $time_diff = $current_time - $created_time;
        
        // If more than 5 minutes old, query M-Pesa directly
        if ($time_diff > 300) {
            $mpesa_status = queryMpesaTransactionStatus($checkout_request_id);
            if ($mpesa_status) {
                // Update local database with M-Pesa response
                updateTransactionFromMpesa($pdo, $transaction['id'], $mpesa_status);
                $payment_status = $mpesa_status['payment_status'];
            }
        }
    }
    
    // Return response
    echo json_encode([
        'success' => true,
        'message' => 'Transaction status retrieved',
        'transaction_id' => $transaction['id'],
        'checkout_request_id' => $transaction['checkout_request_id'],
        'merchant_request_id' => $transaction['merchant_request_id'],
        'payment_status' => $payment_status,
        'result_code' => $transaction['result_code'],
        'result_desc' => $transaction['result_desc'],
        'amount' => $transaction['amount'],
        'phone_number' => $transaction['phone_number'],
        'mpesa_receipt_number' => $transaction['mpesa_receipt_number'],
        'transaction_date' => $transaction['transaction_date'],
        'plan_id' => $transaction['plan_id'],
        'plan_name' => $transaction['plan_name'],
        'created_at' => $transaction['created_at'],
        'updated_at' => $transaction['updated_at']
    ]);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'payment_status' => 'error',
        'result_code' => null,
        'result_desc' => null,
        'transaction_id' => null,
        'amount' => null,
        'phone_number' => null
    ]);
}

/**
 * Query M-Pesa API directly for transaction status
 * This is used as a fallback when callback hasn't been received
 */
function queryMpesaTransactionStatus($checkout_request_id) {
    // M-Pesa API Configuration (same as stk-push.php)
    define('MPESA_CONSUMER_KEY', 'your_consumer_key_here');
    define('MPESA_CONSUMER_SECRET', 'your_consumer_secret_here');
    define('MPESA_SHORTCODE', 'your_shortcode_here');
    define('MPESA_PASSKEY', 'your_passkey_here');
    define('MPESA_ENVIRONMENT', 'sandbox'); // 'sandbox' or 'production'
    
    try {
        // Get OAuth token
        $auth_url = MPESA_ENVIRONMENT === 'production' 
            ? 'https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials'
            : 'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials';
            
        $credentials = base64_encode(MPESA_CONSUMER_KEY . ':' . MPESA_CONSUMER_SECRET);
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $auth_url);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Authorization: Basic ' . $credentials]);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        
        $auth_response = curl_exec($ch);
        curl_close($ch);
        
        $auth_data = json_decode($auth_response, true);
        if (!isset($auth_data['access_token'])) {
            return null;
        }
        
        // Query transaction status
        $query_url = MPESA_ENVIRONMENT === 'production'
            ? 'https://api.safaricom.co.ke/mpesa/stkpushquery/v1/query'
            : 'https://sandbox.safaricom.co.ke/mpesa/stkpushquery/v1/query';
            
        $timestamp = date('YmdHis');
        $password = base64_encode(MPESA_SHORTCODE . MPESA_PASSKEY . $timestamp);
        
        $query_data = [
            'BusinessShortCode' => MPESA_SHORTCODE,
            'Password' => $password,
            'Timestamp' => $timestamp,
            'CheckoutRequestID' => $checkout_request_id
        ];
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $query_url);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $auth_data['access_token'],
            'Content-Type: application/json'
        ]);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($query_data));
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        
        $query_response = curl_exec($ch);
        curl_close($ch);
        
        $query_result = json_decode($query_response, true);
        
        if (isset($query_result['ResultCode'])) {
            $payment_status = 'pending';
            if ($query_result['ResultCode'] == '0') {
                $payment_status = 'completed';
            } elseif ($query_result['ResultCode'] == '1032') {
                $payment_status = 'cancelled';
            } elseif ($query_result['ResultCode'] != '1037') { // 1037 is timeout/pending
                $payment_status = 'failed';
            }
            
            return [
                'payment_status' => $payment_status,
                'result_code' => $query_result['ResultCode'],
                'result_desc' => $query_result['ResultDesc'] ?? '',
                'response_code' => $query_result['ResponseCode'] ?? null
            ];
        }
        
        return null;
        
    } catch (Exception $e) {
        error_log('M-Pesa query error: ' . $e->getMessage());
        return null;
    }
}

/**
 * Update transaction with M-Pesa API response
 */
function updateTransactionFromMpesa($pdo, $transaction_id, $mpesa_status) {
    try {
        $stmt = $pdo->prepare("
            UPDATE mpesa_transactions 
            SET status = ?,
                result_code = ?,
                result_desc = ?,
                updated_at = NOW()
            WHERE id = ?
        ");
        
        $status = $mpesa_status['payment_status'];
        if ($status === 'completed') {
            $status = 'completed';
        } elseif ($status === 'cancelled') {
            $status = 'cancelled';
        } elseif ($status === 'failed') {
            $status = 'failed';
        } else {
            $status = 'pending';
        }
        
        $stmt->execute([
            $status,
            $mpesa_status['result_code'],
            $mpesa_status['result_desc'],
            $transaction_id
        ]);
        
        // If completed, activate subscription
        if ($status === 'completed') {
            $stmt = $pdo->prepare("SELECT * FROM mpesa_transactions WHERE id = ?");
            $stmt->execute([$transaction_id]);
            $transaction = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if ($transaction) {
                // Include the activation function from callback.php
                // activateUserSubscription($pdo, $transaction);
            }
        }
        
    } catch (Exception $e) {
        error_log('Update transaction error: ' . $e->getMessage());
    }
}
?>

<?php
/**
 * Example Response - Pending:
 * {
 *   "success": true,
 *   "message": "Transaction status retrieved",
 *   "transaction_id": 123,
 *   "checkout_request_id": "ws_CO_191220191020363925",
 *   "payment_status": "pending",
 *   "result_code": null,
 *   "result_desc": null,
 *   "amount": "1000.00",
 *   "phone_number": "254712345678",
 *   "plan_id": "starter",
 *   "plan_name": "Starter Plan"
 * }
 * 
 * Example Response - Completed:
 * {
 *   "success": true,
 *   "message": "Transaction status retrieved",
 *   "transaction_id": 123,
 *   "checkout_request_id": "ws_CO_191220191020363925",
 *   "payment_status": "completed",
 *   "result_code": 0,
 *   "result_desc": "The service request is processed successfully.",
 *   "amount": "1000.00",
 *   "phone_number": "254712345678",
 *   "mpesa_receipt_number": "NLJ7RT61SV",
 *   "transaction_date": "2024-01-15 14:30:00",
 *   "plan_id": "starter",
 *   "plan_name": "Starter Plan"
 * }
 */
?>
