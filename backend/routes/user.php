<?php

use App\Http\Controllers\User\BookingFinalizationController;
use App\Http\Controllers\User\FirebaseTokenController;
use App\Http\Controllers\User\LoginController;
use App\Http\Controllers\User\LogoutController;
use App\Http\Controllers\User\NotificationSettingsController;
use App\Http\Controllers\User\PaystackController;
use App\Http\Controllers\User\RegisterController;
use App\Http\Controllers\User\ReviewController;
use App\Http\Controllers\User\SavedAgentController;
use App\Http\Controllers\User\SavedPropertyController;
use App\Http\Controllers\User\TransactionController;
use App\Http\Controllers\User\UserController;
use App\Http\Controllers\User\InspectionController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| User API Routes
|--------------------------------------------------------------------------
*/

// Public routes for authentication
Route::post('/register', RegisterController::class);
Route::post('/login', LoginController::class);

// Password Reset Routes
Route::post('/password/send-code', [App\Http\Controllers\User\PasswordResetController::class, 'sendResetCode']);
Route::post('/password/verify-code', [App\Http\Controllers\User\PasswordResetController::class, 'verifyResetCode']);
Route::post('/password/reset', [App\Http\Controllers\User\PasswordResetController::class, 'resetPassword']);

// Email Verification Routes
Route::post('/email/verify', [App\Http\Controllers\User\EmailVerificationController::class, 'verify']);
Route::post('/email/resend', [App\Http\Controllers\User\EmailVerificationController::class, 'resend']);

// Protected routes requiring authentication
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', LogoutController::class);

    // Profile
    Route::get('/profile', [UserController::class, 'profile']);
    Route::post('/profile-picture', [UserController::class, 'updateProfilePicture']);
    Route::put('/profile/update', [UserController::class, 'updateProfile']);
    Route::put('/password', [UserController::class, 'updatePassword']);
    Route::post('/agree-to-terms', [UserController::class, 'agreeToTerms']);
    Route::post('/profile/location', [UserController::class, 'updateLocation']);

    // Saved Properties
    Route::get('/saved-properties', [SavedPropertyController::class, 'index']);
    Route::post('/properties/{propertyId}/save', [SavedPropertyController::class, 'store']);
    Route::delete('/properties/{propertyId}/unsave', [SavedPropertyController::class, 'destroy']);
    Route::get('/properties/{propertyId}/is-saved', [SavedPropertyController::class, 'isSaved']);

    // Saved Agents
    Route::get('/saved-agents', [SavedAgentController::class, 'index']);
    Route::post('/agents/{agentId}/save', [SavedAgentController::class, 'store']);
    Route::delete('/agents/{agentId}/unsave', [SavedAgentController::class, 'destroy']);
    Route::get('/agents/{agentId}/is-saved', [SavedAgentController::class, 'isSaved']);

    // Bookings/Inspections
    Route::get('/bookings', [InspectionController::class, 'getUserBookings']);
    Route::post('/inspections', [InspectionController::class, 'store']); // User creates an inspection
    Route::post('/inspections/{inspection}/status', [InspectionController::class, 'updateStatus']); // Keep this one

    // Payments & Transactions
    Route::post('/transactions', [TransactionController::class, 'store']);
    Route::post('/paystack/initialize', [PaystackController::class, 'initializeTransaction']);
    Route::post('/bookings/finalize', [BookingFinalizationController::class, 'finalizeBooking']);

    // FCM Token
    Route::post('/firebase-token', [FirebaseTokenController::class, 'store']);

    // Reviews and Reports
    Route::post('/agents/{agentId}/reviews', [ReviewController::class, 'storeReview']);
    Route::post('/agents/{agentId}/reports', [ReviewController::class, 'storeReport']);

    // Notification Settings
    Route::get('/notification-settings', [NotificationSettingsController::class, 'getSettings']);
    Route::put('/notification-settings', [NotificationSettingsController::class, 'updateSettings']);
});
