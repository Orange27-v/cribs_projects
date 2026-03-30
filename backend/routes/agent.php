<?php

use App\Http\Controllers\Agent\RegisterAgentController;
use App\Http\Controllers\Agent\LoginAgentController;
use App\Http\Controllers\Agent\ForgotPasswordAgentController;
use App\Http\Controllers\Agent\AgentAuthController;
use App\Http\Controllers\Agent\ChangePasswordController;
use App\Http\Controllers\Agent\ProfilePictureController;
use App\Http\Controllers\Agent\AgreeToTermsController;
use App\Http\Controllers\Agent\AgentProfileController;
use App\Http\Controllers\Agent\AgentNotificationController;
use App\Http\Controllers\Agent\AgentInspectionController;
use App\Http\Controllers\Agent\AgentLeadsController;
use App\Http\Controllers\Agent\AgentFollowersController;
use App\Http\Controllers\Agent\AgentPropertyController;
use App\Http\Controllers\Agent\AgentWalletController;
use App\Http\Controllers\Agent\AgentWithdrawalController;
use App\Http\Controllers\Agent\AgentStatsController;
use App\Http\Controllers\Agent\AgentReviewController;
use App\Http\Controllers\Agent\AgentClientController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Agent API Routes
|--------------------------------------------------------------------------
*/

// Public Agent Routes
Route::post('/register', [RegisterAgentController::class, 'register']);
Route::post('/login', [LoginAgentController::class, 'login']);
Route::post('/check-email', [RegisterAgentController::class, 'checkEmail']);
Route::post('/verify-email', [RegisterAgentController::class, 'verifyEmail']);
Route::post('/resend-verification', [RegisterAgentController::class, 'resendVerificationCode']);
// Route::post('/check-uid', [RegisterAgentController::class, 'checkUid']); // If checking UID is needed
Route::post('/forgot-password', [ForgotPasswordAgentController::class, 'sendResetLink']);
Route::post('/verify-reset-token', [ForgotPasswordAgentController::class, 'verifyResetToken']);
Route::post('/reset-password', [ForgotPasswordAgentController::class, 'resetPassword']);

// Public route for bank list (no auth needed)
Route::get('/banks', [AgentWithdrawalController::class, 'getBanks']);

// Protected Agent Routes
Route::middleware('auth:sanctum')->group(function () {
    // Agent Profile & Auth
    Route::post('/logout', [LoginAgentController::class, 'logout']);
    Route::get('/profile', [AgentAuthController::class, 'profile']);
    Route::post('/device-tokens', [\App\Http\Controllers\NotificationController::class, 'storeDeviceToken']);
    Route::post('/update-profile-basic', [AgentAuthController::class, 'updateProfile']);
    Route::post('/profile/location', [AgentAuthController::class, 'updateLocation']);
    Route::post('/change-password', [ChangePasswordController::class, 'changePassword']);
    Route::post('/profile-picture', [ProfilePictureController::class, 'updateProfilePicture']);
    Route::post('/agree-to-terms', [AgreeToTermsController::class, 'agreeToTerms']);

    // Agent Information (Professional Profile)
    Route::get('/profile/information', [AgentProfileController::class, 'getAgentProfile']);
    Route::post('/profile/update', [AgentProfileController::class, 'updateAgentProfile']);
    Route::get('/profile/completion', [AgentProfileController::class, 'checkProfileCompletion']);

    // Agent Notifications
    Route::get('/notifications/unread-count', [AgentNotificationController::class, 'getUnreadCount']);
    Route::get('/notifications', [AgentNotificationController::class, 'getNotifications']);
    Route::post('/notifications/{notificationId}/read', [AgentNotificationController::class, 'markAsRead']);
    Route::post('/notifications/mark-all-read', [AgentNotificationController::class, 'markAllAsRead']);

    // Agent Inspections
    Route::get('/inspections/upcoming-count', [AgentInspectionController::class, 'getUpcomingCount']);
    Route::get('/inspections', [AgentInspectionController::class, 'getInspections']);
    Route::get('/inspections/{inspectionId}', [AgentInspectionController::class, 'getInspectionDetails']);
    Route::post('/inspections/{inspectionId}/status', [AgentInspectionController::class, 'updateInspectionStatus']);
    Route::post('/inspections/{inspectionId}/reschedule', [AgentInspectionController::class, 'rescheduleInspection']);

    // Agent Leads
    Route::get('/leads', [AgentLeadsController::class, 'index']);

    // Agent Followers (users who saved this agent)
    Route::get('/followers', [AgentFollowersController::class, 'index']);

    // Agent Properties
    Route::get('/properties', [AgentPropertyController::class, 'index']);
    Route::get('/properties/{propertyId}', [AgentPropertyController::class, 'show']);
    Route::post('/properties/add', [AgentPropertyController::class, 'store']);
    Route::post('/properties/{propertyId}/update', [AgentPropertyController::class, 'update']);
    Route::delete('/properties/{propertyId}', [AgentPropertyController::class, 'destroy']);

    // Map - Get Users
    Route::get('/map/users', [\App\Http\Controllers\Agent\AgentMapController::class, 'getUsers']);
    Route::post('/map/users/nearby', [\App\Http\Controllers\Agent\AgentMapController::class, 'getNearbyUsers']);

    // Subscription Plans
    Route::get('/plans', [\App\Http\Controllers\Agent\AgentSubscriptionController::class, 'index']);
    Route::get('/subscription/current', [\App\Http\Controllers\Agent\AgentSubscriptionController::class, 'current']);
    Route::get('/subscription/history', [\App\Http\Controllers\Agent\AgentSubscriptionController::class, 'history']);
    Route::post('/subscription/initialize', [\App\Http\Controllers\Agent\AgentSubscriptionController::class, 'initializeSubscription']);
    Route::post('/subscription/verify', [\App\Http\Controllers\Agent\AgentSubscriptionController::class, 'verifySubscription']);
    Route::post('/subscription/verify-google', [\App\Http\Controllers\Agent\GoogleBillingController::class, 'verifySubscription']);
    Route::post('/subscription/wallet-pay', [\App\Http\Controllers\Agent\AgentSubscriptionController::class, 'subscribeWithWallet']);

    // Wallet
    Route::get('/wallet', [AgentWalletController::class, 'getWallet']);
    Route::get('/wallet/transactions', [AgentWalletController::class, 'getTransactions']);
    Route::get('/wallet/transactions/{id}', [AgentWalletController::class, 'getTransactionDetails']);
    Route::get('/wallet/summary', [AgentWalletController::class, 'getSummary']);
    Route::post('/wallet/deposit/initialize', [AgentWalletController::class, 'initializeDeposit']);
    Route::post('/wallet/deposit/verify', [AgentWalletController::class, 'verifyDeposit']);

    // Bank Accounts (Transfer Recipients)
    Route::get('/bank-accounts', [AgentWithdrawalController::class, 'getBankAccounts']);
    Route::post('/bank-accounts/verify', [AgentWithdrawalController::class, 'verifyBankAccount']);
    Route::post('/bank-accounts', [AgentWithdrawalController::class, 'saveBankAccount']);
    Route::delete('/bank-accounts/{id}', [AgentWithdrawalController::class, 'deleteBankAccount']);

    // Withdrawals
    Route::post('/withdraw', [AgentWithdrawalController::class, 'withdraw']);
    Route::get('/withdrawals', [AgentWithdrawalController::class, 'getWithdrawals']);

    // Dashboard Stats
    Route::get('/stats', [AgentStatsController::class, 'getStats']);

    // Agent Reviews
    Route::get('/reviews', [AgentReviewController::class, 'getMyReviews']);

    // Agent Clients
    Route::get('/clients', [AgentClientController::class, 'getClients']);

    // Agent Leads
    Route::get('/leads', [AgentLeadsController::class, 'index']);
});