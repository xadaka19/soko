<?php
/**
 * Consume Credit API
 * URL: /api/consume-credit.php
 * Method: POST
 * 
 * This endpoint consumes a credit when a user creates a listing.
 * It decrements the user's credit count and logs the usage.
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
    $required_fields = ['user_id', 'listing_id'];
    foreach ($required_fields as $field) {
        if (!isset($input[$field]) || empty($input[$field])) {
            throw new Exception("Missing required field: $field");
        }
    }
    
    $user_id = intval($input['user_id']);
    $listing_id = intval($input['listing_id']);
    
    // Database connection
    $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Start transaction
    $pdo->beginTransaction();
    
    try {
        // Get user's active subscription
        $stmt = $pdo->prepare("
            SELECT 
                s.*,
                p.name as plan_name
            FROM user_subscriptions s
            JOIN subscription_plans p ON s.plan_id = p.id
            WHERE s.user_id = ? AND s.status = 'active'
            ORDER BY s.created_at DESC
            LIMIT 1
        ");
        $stmt->execute([$user_id]);
        $subscription = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$subscription) {
            throw new Exception('No active subscription found');
        }
        
        // Check if user has credits
        $credits_remaining = intval($subscription['credits_remaining']);
        if ($credits_remaining <= 0) {
            throw new Exception('No credits remaining');
        }
        
        // Check if subscription has expired (for paid plans)
        if ($subscription['end_date'] !== null) {
            $end_date = strtotime($subscription['end_date']);
            $current_time = time();
            if ($current_time > $end_date) {
                // Mark as expired
                $stmt = $pdo->prepare("
                    UPDATE user_subscriptions 
                    SET status = 'expired', updated_at = NOW()
                    WHERE id = ?
                ");
                $stmt->execute([$subscription['id']]);
                
                throw new Exception('Subscription has expired');
            }
        }
        
        // Check if credit has already been consumed for this listing
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as count 
            FROM credit_history 
            WHERE user_id = ? AND listing_id = ? AND action_type = 'listing_creation'
        ");
        $stmt->execute([$user_id, $listing_id]);
        $existing_usage = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
        
        if ($existing_usage > 0) {
            throw new Exception('Credit already consumed for this listing');
        }
        
        // Consume one credit
        $new_credits = $credits_remaining - 1;
        $stmt = $pdo->prepare("
            UPDATE user_subscriptions 
            SET credits_remaining = ?, updated_at = NOW()
            WHERE id = ?
        ");
        $stmt->execute([$new_credits, $subscription['id']]);
        
        // Log credit usage
        $stmt = $pdo->prepare("
            INSERT INTO credit_history (
                user_id, subscription_id, listing_id, credits_added, credits_used,
                action_type, description, created_at
            ) VALUES (?, ?, ?, 0, 1, 'listing_creation', ?, NOW())
        ");
        $stmt->execute([
            $user_id,
            $subscription['id'],
            $listing_id,
            "Credit used for listing creation (ID: {$listing_id})"
        ]);
        
        // Get listing details for logging
        $stmt = $pdo->prepare("SELECT title FROM listings WHERE id = ?");
        $stmt->execute([$listing_id]);
        $listing = $stmt->fetch(PDO::FETCH_ASSOC);
        $listing_title = $listing ? $listing['title'] : "Listing #{$listing_id}";
        
        // Commit transaction
        $pdo->commit();
        
        // Return success response
        echo json_encode([
            'success' => true,
            'message' => 'Credit consumed successfully',
            'credits_remaining' => $new_credits,
            'credits_used' => 1,
            'listing_id' => $listing_id,
            'listing_title' => $listing_title,
            'subscription_id' => $subscription['id'],
            'plan_name' => $subscription['plan_name']
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
        'credits_remaining' => 0,
        'credits_used' => 0
    ]);
}
?>

<?php
/**
 * Example Response - Success:
 * {
 *   "success": true,
 *   "message": "Credit consumed successfully",
 *   "credits_remaining": 4,
 *   "credits_used": 1,
 *   "listing_id": 456,
 *   "listing_title": "iPhone 13 Pro Max",
 *   "subscription_id": 123,
 *   "plan_name": "Starter Plan"
 * }
 * 
 * Example Response - No Credits:
 * {
 *   "success": false,
 *   "message": "No credits remaining",
 *   "credits_remaining": 0,
 *   "credits_used": 0
 * }
 * 
 * Example Response - No Subscription:
 * {
 *   "success": false,
 *   "message": "No active subscription found",
 *   "credits_remaining": 0,
 *   "credits_used": 0
 * }
 */
?>

<?php
/**
 * Usage in Mobile App:
 * 
 * Call this endpoint after successfully creating a listing:
 * 
 * 1. User creates listing
 * 2. Listing is saved to database
 * 3. Call consume-credit API with listing_id
 * 4. Update local user session with new credit count
 * 5. Show success message with remaining credits
 * 
 * Error Handling:
 * - If credit consumption fails, consider reversing listing creation
 * - Or mark listing as "pending credit confirmation"
 * - Implement retry mechanism for network failures
 * 
 * Integration Points:
 * - CreateListingScreen: Call after successful listing creation
 * - ListingService: Include in createListing method
 * - SessionManager: Update local credit count
 * - UI: Show updated credit count to user
 * 
 * Security Considerations:
 * - Validate user owns the listing
 * - Prevent duplicate credit consumption
 * - Log all credit usage for audit trail
 * - Check subscription expiry before consuming
 */
?>

<?php
/**
 * Credit Consumption Flow:
 * 
 * 1. User fills out listing form
 * 2. App checks eligibility (check-listing-eligibility.php)
 * 3. If eligible, allow form submission
 * 4. Create listing in database
 * 5. Consume credit (this endpoint)
 * 6. Update UI with new credit count
 * 7. Show success message
 * 
 * Rollback Scenarios:
 * - If credit consumption fails after listing creation
 * - Consider implementing compensation transactions
 * - Or queue credit consumption for retry
 * 
 * Monitoring:
 * - Track credit consumption rates
 * - Monitor failed consumption attempts
 * - Alert on unusual patterns
 * - Generate usage reports for business analytics
 */
?>
