<?php
/**
 * API Endpoint: Get Profile
 * URL: /api/get-profile.php
 * Method: GET
 * Parameters: user_id (required)
 * 
 * This endpoint returns the latest user profile data from the database.
 * This ensures the mobile app always shows current data, even if updated
 * through the admin dashboard or web interface.
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type');

try {
    // Validate required parameters
    if (!isset($_GET['user_id']) || empty($_GET['user_id'])) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'User ID is required',
            'user' => null
        ]);
        exit;
    }

    $userId = intval($_GET['user_id']);

    // Database connection (adjust according to your setup)
    $pdo = new PDO("mysql:host=localhost;dbname=sokofiti", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Fetch user profile from database
    $stmt = $pdo->prepare("
        SELECT 
            id,
            first_name,
            last_name,
            email,
            phone,
            mpesa_phone,
            city,
            county,
            profile_picture,
            is_active,
            email_verified,
            phone_verified,
            created_at,
            updated_at,
            last_login
        FROM users 
        WHERE id = ? AND is_active = 1
    ");
    
    $stmt->execute([$userId]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$user) {
        http_response_code(404);
        echo json_encode([
            'success' => false,
            'message' => 'User not found or inactive',
            'user' => null
        ]);
        exit;
    }
    
    // Format user data for mobile app
    $formattedUser = [
        'id' => $user['id'],
        'first_name' => $user['first_name'],
        'last_name' => $user['last_name'],
        'email' => $user['email'],
        'phone' => $user['phone'],
        'mpesa_phone' => $user['mpesa_phone'],
        'city' => $user['city'],
        'county' => $user['county'],
        'profile_picture' => $user['profile_picture'],
        'is_active' => (bool)$user['is_active'],
        'email_verified' => (bool)$user['email_verified'],
        'phone_verified' => (bool)$user['phone_verified'],
        'created_at' => $user['created_at'],
        'updated_at' => $user['updated_at'],
        'last_login' => $user['last_login']
    ];
    
    // Return success response
    echo json_encode([
        'success' => true,
        'message' => 'Profile loaded successfully',
        'user' => $formattedUser,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    
} catch (PDOException $e) {
    // Database error
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage(),
        'user' => null
    ]);
    
} catch (Exception $e) {
    // General error
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage(),
        'user' => null
    ]);
}
?>

<?php
/**
 * Example Response:
 * {
 *   "success": true,
 *   "message": "Profile loaded successfully",
 *   "user": {
 *     "id": 123,
 *     "first_name": "John",
 *     "last_name": "Doe",
 *     "email": "john.doe@example.com",
 *     "phone": "+254712345678",
 *     "mpesa_phone": "+254712345678",
 *     "city": "Nairobi",
 *     "county": "Nairobi",
 *     "profile_picture": "https://example.com/profile.jpg",
 *     "is_active": true,
 *     "email_verified": true,
 *     "phone_verified": false,
 *     "created_at": "2024-01-01 10:00:00",
 *     "updated_at": "2024-01-15 14:30:00",
 *     "last_login": "2024-01-15 09:15:00"
 *   },
 *   "timestamp": "2024-01-15 14:35:00"
 * }
 */
?>

<?php
/**
 * Admin Dashboard Integration:
 * 
 * When admins update user profiles through the dashboard, the changes
 * are immediately available to the mobile app through this endpoint.
 * 
 * Use cases:
 * 1. Admin updates user information
 * 2. Admin verifies email/phone
 * 3. Admin activates/deactivates accounts
 * 4. Bulk profile updates
 * 5. Profile data corrections
 * 
 * The mobile app will automatically sync these changes when:
 * - User opens the profile screen
 * - App comes back to foreground
 * - Every 5 minutes (auto-refresh)
 * - User manually refreshes
 */
?>

<?php
/**
 * Security Considerations:
 * 
 * 1. Authentication: Verify user session/token before returning data
 * 2. Authorization: Users should only access their own profile
 * 3. Rate Limiting: Prevent excessive API calls
 * 4. Data Sanitization: Clean all output data
 * 5. Logging: Log all profile access attempts
 * 
 * Enhanced security example:
 * 
 * // Verify user session
 * $sessionToken = $_GET['session_token'] ?? '';
 * if (!validateSession($sessionToken, $userId)) {
 *     http_response_code(401);
 *     echo json_encode(['success' => false, 'message' => 'Unauthorized']);
 *     exit;
 * }
 * 
 * // Log access
 * logProfileAccess($userId, $_SERVER['REMOTE_ADDR']);
 */
?>
