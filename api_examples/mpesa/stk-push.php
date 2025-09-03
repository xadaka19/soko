<?php
/**
 * M-Pesa STK Push API Endpoint
 * URL: /api/mpesa/stk-push.php
 * Method: POST
 * 
 * This endpoint initiates an M-Pesa STK Push payment request.
 * It integrates with Safaricom's Daraja API to process payments.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// M-Pesa API Configuration
define('MPESA_CONSUMER_KEY', 'your_consumer_key_here');
define('MPESA_CONSUMER_SECRET', 'your_consumer_secret_here');
define('MPESA_SHORTCODE', 'your_shortcode_here');
define('MPESA_PASSKEY', 'your_passkey_here');
define('MPESA_CALLBACK_URL', 'https://yourdomain.com/api/mpesa/callback.php');
define('MPESA_ENVIRONMENT', 'sandbox'); // 'sandbox' or 'production'

// API URLs
$auth_url = MPESA_ENVIRONMENT === 'production' 
    ? 'https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials'
    : 'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials';

$stk_url = MPESA_ENVIRONMENT === 'production'
    ? 'https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest'
    : 'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest';

try {
    // Get request data
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        throw new Exception('Invalid JSON input');
    }
    
    // Validate required fields
    $required_fields = ['phone_number', 'amount', 'plan_id', 'user_id', 'account_reference'];
    foreach ($required_fields as $field) {
        if (!isset($input[$field]) || empty($input[$field])) {
            throw new Exception("Missing required field: $field");
        }
    }
    
    $phone_number = $input['phone_number'];
    $amount = (int)$input['amount'];
    $plan_id = $input['plan_id'];
    $user_id = $input['user_id'];
    $account_reference = $input['account_reference'];
    $transaction_desc = $input['transaction_desc'] ?? 'Payment for plan';
    
    // Validate phone number format
    if (!preg_match('/^254[0-9]{9}$/', $phone_number)) {
        throw new Exception('Invalid phone number format. Use 254XXXXXXXXX');
    }
    
    // Validate amount
    if ($amount < 1) {
        throw new Exception('Amount must be at least 1 KES');
    }
    
    // Step 1: Get OAuth token
    $credentials = base64_encode(MPESA_CONSUMER_KEY . ':' . MPESA_CONSUMER_SECRET);
    
    $auth_headers = [
        'Authorization: Basic ' . $credentials,
        'Content-Type: application/json'
    ];
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $auth_url);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $auth_headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    
    $auth_response = curl_exec($ch);
    $auth_http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($auth_http_code !== 200) {
        throw new Exception('Failed to get OAuth token: ' . $auth_response);
    }
    
    $auth_data = json_decode($auth_response, true);
    if (!isset($auth_data['access_token'])) {
        throw new Exception('No access token received');
    }
    
    $access_token = $auth_data['access_token'];
    
    // Step 2: Generate timestamp and password
    $timestamp = date('YmdHis');
    $password = base64_encode(MPESA_SHORTCODE . MPESA_PASSKEY . $timestamp);
    
    // Step 3: Prepare STK Push request
    $stk_data = [
        'BusinessShortCode' => MPESA_SHORTCODE,
        'Password' => $password,
        'Timestamp' => $timestamp,
        'TransactionType' => 'CustomerPayBillOnline',
        'Amount' => $amount,
        'PartyA' => $phone_number,
        'PartyB' => MPESA_SHORTCODE,
        'PhoneNumber' => $phone_number,
        'CallBackURL' => MPESA_CALLBACK_URL,
        'AccountReference' => $account_reference,
        'TransactionDesc' => $transaction_desc
    ];
    
    $stk_headers = [
        'Authorization: Bearer ' . $access_token,
        'Content-Type: application/json'
    ];
    
    // Step 4: Send STK Push request
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $stk_url);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $stk_headers);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($stk_data));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    
    $stk_response = curl_exec($ch);
    $stk_http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($stk_http_code !== 200) {
        throw new Exception('STK Push request failed: ' . $stk_response);
    }
    
    $stk_data_response = json_decode($stk_response, true);
    
    // Step 5: Save transaction to database
    $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $stmt = $pdo->prepare("
        INSERT INTO mpesa_transactions (
            user_id, plan_id, phone_number, amount, 
            checkout_request_id, merchant_request_id,
            account_reference, transaction_desc, status,
            created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending', NOW())
    ");
    
    $stmt->execute([
        $user_id,
        $plan_id,
        $phone_number,
        $amount,
        $stk_data_response['CheckoutRequestID'] ?? null,
        $stk_data_response['MerchantRequestID'] ?? null,
        $account_reference,
        $transaction_desc
    ]);
    
    // Step 6: Return response
    echo json_encode([
        'success' => true,
        'message' => 'STK Push sent successfully',
        'checkout_request_id' => $stk_data_response['CheckoutRequestID'] ?? null,
        'merchant_request_id' => $stk_data_response['MerchantRequestID'] ?? null,
        'response_code' => $stk_data_response['ResponseCode'] ?? null,
        'response_description' => $stk_data_response['ResponseDescription'] ?? null,
        'customer_message' => $stk_data_response['CustomerMessage'] ?? null
    ]);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'checkout_request_id' => null,
        'merchant_request_id' => null,
        'response_code' => null,
        'response_description' => null
    ]);
}
?>

<?php
/**
 * Database Schema for mpesa_transactions table:
 * 
 * CREATE TABLE mpesa_transactions (
 *     id INT AUTO_INCREMENT PRIMARY KEY,
 *     user_id INT NOT NULL,
 *     plan_id VARCHAR(50) NOT NULL,
 *     phone_number VARCHAR(15) NOT NULL,
 *     amount DECIMAL(10,2) NOT NULL,
 *     checkout_request_id VARCHAR(100),
 *     merchant_request_id VARCHAR(100),
 *     mpesa_receipt_number VARCHAR(100),
 *     transaction_date DATETIME,
 *     account_reference VARCHAR(100),
 *     transaction_desc TEXT,
 *     status ENUM('pending', 'completed', 'failed', 'cancelled') DEFAULT 'pending',
 *     result_code INT,
 *     result_desc TEXT,
 *     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 *     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 *     INDEX idx_user_id (user_id),
 *     INDEX idx_checkout_request_id (checkout_request_id),
 *     INDEX idx_status (status)
 * );
 *
 * CREATE TABLE user_subscriptions (
 *     id INT AUTO_INCREMENT PRIMARY KEY,
 *     user_id INT NOT NULL,
 *     plan_id VARCHAR(50) NOT NULL,
 *     transaction_id INT,
 *     start_date DATETIME NOT NULL,
 *     end_date DATETIME,
 *     status ENUM('active', 'expired', 'cancelled') DEFAULT 'active',
 *     credits_remaining INT DEFAULT 0,
 *     auto_renew BOOLEAN DEFAULT FALSE,
 *     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 *     updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 *     INDEX idx_user_id (user_id),
 *     INDEX idx_status (status),
 *     FOREIGN KEY (user_id) REFERENCES users(id),
 *     FOREIGN KEY (transaction_id) REFERENCES mpesa_transactions(id)
 * );
 */
?>
