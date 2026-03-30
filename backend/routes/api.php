<?php

use App\Http\Controllers\User\PublicAgentController;
use App\Http\Controllers\User\PropertyController;
use App\Http\Controllers\User\PropertyTrackingController;
use App\Http\Controllers\User\RecommendedPropertyController;
use App\Http\Controllers\General\LegalDocumentController;
use App\Http\Controllers\General\WebhookController;
use App\Http\Controllers\User\ReviewController;
use App\Http\Controllers\User\NewListingController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\NotificationSettingsController; // Add this line
use App\Http\Controllers\User\NotificationCountController; // Add this line
use App\Http\Controllers\User\ReportController;
use App\Http\Controllers\Verification\NinController;
use App\Http\Controllers\Verification\VninController;
use App\Http\Controllers\Verification\BvnController;
use App\Http\Controllers\Verification\VerificationStatusController;
use App\Http\Controllers\PaymentController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| General API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register general API routes for your application.
| These routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. For role-specific routes,
| see user.php, agent.php, and admin.php.
|
*/

// Public Agent Endpoints
Route::get('/agents/nearby', [PublicAgentController::class, 'findNearby']);
Route::get('/agents/recommended', [PublicAgentController::class, 'recommended']);
Route::get('/agents', [PublicAgentController::class, 'index']);
Route::get('/agents/{agentId}', [PublicAgentController::class, 'show']);
Route::get('/agents/{agentId}/reviews', [ReviewController::class, 'getAgentReviews']);
Route::post('/agents/{agentId}/report', [ReportController::class, 'store'])->middleware('auth:sanctum');

// Public Property Browsing Endpoints
Route::get('/properties', [PropertyController::class, 'index']);
Route::get('/properties/recommended', RecommendedPropertyController::class);
Route::get('/properties/new-listings-nearby', NewListingController::class);
Route::get('/properties/{propertyId}', [PropertyController::class, 'show']);
Route::get('/agents/{agentId}/properties', [PropertyController::class, 'getPropertiesByAgent']);
Route::get('/agents/{agentId}/properties/new', [PropertyController::class, 'getNewPropertiesByAgent']);

// Property Tracking Endpoints (Analytics)
Route::post('/property/increment-view-count', [PropertyTrackingController::class, 'incrementViewCount']);
Route::post('/property/increment-inspection-booking-count', [PropertyTrackingController::class, 'incrementInspectionBookingCount']);
Route::post('/property/increment-leads-count', [PropertyTrackingController::class, 'incrementLeadsCount']);
Route::post('/property/decrement-leads-count', [PropertyTrackingController::class, 'decrementLeadsCount']);
Route::get('/property/stats', [PropertyTrackingController::class, 'getPropertyStats']);

// Public Legal Documents Endpoint
Route::get('/legal/{type}', [LegalDocumentController::class, 'show']);

// Paystack Webhook
Route::post('/paystack/webhook', [WebhookController::class, 'handleWebhook']);

// Payment Keys
Route::get('/payment-keys', [PaymentController::class, 'getPaymentKeys']);

// Platform Fees
Route::get('/general/platform-fee', [App\Http\Controllers\General\PlatformFeeController::class, 'getPlatformFee']);
Route::post('/general/platform-fee/log', [App\Http\Controllers\General\PlatformFeeController::class, 'logPlatformFee']);

// Public webhook route (QoreID cannot provide Sanctum token)
Route::match(['get', 'post'], '/verify/webhook', [WebhookController::class, 'handleQoreIdWebhook']);

// Protected verification endpoints
Route::group(['prefix' => 'verify', 'middleware' => 'auth:sanctum'], function () {
    // Check if user has existing verification for a type
    Route::get('/check/{type}', [App\Http\Controllers\Verification\UserVerificationStatusController::class, 'getUserVerificationStatus']);

    // Initiate new verification
    Route::post('/nin', [NinController::class, 'verify']);
    Route::post('/vnin', [VninController::class, 'verify']);
    Route::post('/bvn', [BvnController::class, 'verify']);

    // Check specific verification status
    Route::get('/status/{verification_id}', [VerificationStatusController::class, 'status']);
});



// Notification Endpoints
Route::group(['prefix' => 'notifications', 'middleware' => 'auth:sanctum'], function () {
    Route::get('/', [NotificationController::class, 'index']);
    Route::post('/{id}/mark-as-read', [NotificationController::class, 'markAsRead']);
    Route::get('/unread-count', [NotificationCountController::class, 'getUnreadCount']); // Added this line
    Route::post('/mark-all-as-read', [NotificationController::class, 'markAllAsRead']); // Added this line
});

// Chat Notification Endpoint (No auth - uses API key)
Route::post('/chat/send-notification', [\App\Http\Controllers\ChatNotificationController::class, 'sendChatNotification']);


// Notification Settings Endpoints
Route::group(['prefix' => 'notification-settings', 'middleware' => 'auth:sanctum'], function () {
    Route::get('/', [NotificationSettingsController::class, 'index']);
    Route::put('/', [NotificationSettingsController::class, 'update']);
});

// Device Token Endpoints
Route::post('/device-tokens', [NotificationController::class, 'storeDeviceToken'])->middleware('auth:sanctum');

// Test endpoint for API connectivity
Route::get('/test', function () {
    return response()->json(['status' => 'success', 'message' => 'API test passed']);
});
