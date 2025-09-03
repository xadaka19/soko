<?php
/**
 * M-Pesa Payment History API
 * URL: /api/mpesa/payment-history.php
 * Method: GET
 * Parameters: user_id, page, limit
 * 
 * This endpoint returns the payment history for a user.
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
    $page = intval($_GET['page'] ?? 1);
    $limit = intval($_GET['limit'] ?? 20);
    $offset = ($page - 1) * $limit;
    
    // Database connection
    $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Get payment history
    $stmt = $pdo->prepare("
        SELECT 
            t.id,
            t.plan_id,
            t.amount,
            t.phone_number,
            t.mpesa_receipt_number,
            t.transaction_date,
            t.account_reference,
            t.transaction_desc,
            t.status,
            t.result_desc,
            t.created_at,
            p.name as plan_name,
            p.period as plan_period
        FROM mpesa_transactions t
        LEFT JOIN subscription_plans p ON t.plan_id = p.id
        WHERE t.user_id = ?
        ORDER BY t.created_at DESC
        LIMIT ? OFFSET ?
    ");
    $stmt->execute([$user_id, $limit, $offset]);
    $payments = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get total count
    $stmt = $pdo->prepare("
        SELECT COUNT(*) as total 
        FROM mpesa_transactions 
        WHERE user_id = ?
    ");
    $stmt->execute([$user_id]);
    $total_count = $stmt->fetch(PDO::FETCH_ASSOC)['total'];
    
    // Format payments
    $formatted_payments = [];
    foreach ($payments as $payment) {
        $formatted_payments[] = [
            'id' => $payment['id'],
            'plan_id' => $payment['plan_id'],
            'plan_name' => $payment['plan_name'] ?? 'Unknown Plan',
            'plan_period' => $payment['plan_period'],
            'amount' => floatval($payment['amount']),
            'phone_number' => $payment['phone_number'],
            'mpesa_receipt_number' => $payment['mpesa_receipt_number'],
            'transaction_date' => $payment['transaction_date'],
            'account_reference' => $payment['account_reference'],
            'transaction_desc' => $payment['transaction_desc'],
            'status' => $payment['status'],
            'status_display' => ucfirst($payment['status']),
            'result_desc' => $payment['result_desc'],
            'created_at' => $payment['created_at'],
            'formatted_amount' => 'KES ' . number_format($payment['amount'], 0),
            'formatted_date' => date('M j, Y g:i A', strtotime($payment['created_at']))
        ];
    }
    
    // Return response
    echo json_encode([
        'success' => true,
        'message' => 'Payment history retrieved successfully',
        'payments' => $formatted_payments,
        'pagination' => [
            'current_page' => $page,
            'per_page' => $limit,
            'total' => intval($total_count),
            'total_pages' => ceil($total_count / $limit),
            'has_more' => ($page * $limit) < $total_count
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'payments' => [],
        'pagination' => [
            'current_page' => 1,
            'per_page' => 20,
            'total' => 0,
            'total_pages' => 0,
            'has_more' => false
        ]
    ]);
}
?>

<?php
/**
 * Example Response:
 * {
 *   "success": true,
 *   "message": "Payment history retrieved successfully",
 *   "payments": [
 *     {
 *       "id": 123,
 *       "plan_id": "starter",
 *       "plan_name": "Starter Plan",
 *       "plan_period": "month",
 *       "amount": 3000,
 *       "phone_number": "254712345678",
 *       "mpesa_receipt_number": "NLJ7RT61SV",
 *       "transaction_date": "2024-01-15 14:30:00",
 *       "account_reference": "PLAN_STARTER",
 *       "transaction_desc": "Payment for starter plan",
 *       "status": "completed",
 *       "status_display": "Completed",
 *       "result_desc": "The service request is processed successfully.",
 *       "created_at": "2024-01-15 14:25:00",
 *       "formatted_amount": "KES 3,000",
 *       "formatted_date": "Jan 15, 2024 2:25 PM"
 *     }
 *   ],
 *   "pagination": {
 *     "current_page": 1,
 *     "per_page": 20,
 *     "total": 5,
 *     "total_pages": 1,
 *     "has_more": false
 *   }
 * }
 */
?>
