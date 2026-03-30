<?php

use Illuminate\Support\Facades\Route;
use Mailtrap\Helper\ResponseHelper;
use Mailtrap\MailtrapClient;
use Mailtrap\Mime\MailtrapEmail;
use Symfony\Component\Mime\Address;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

// ============================================
// BASIC SYSTEM ROUTES
// ============================================

Route::get('/', function () {
    return view('welcome');
});

// Test basic email connectivity
Route::get('/test-email', function () {
    try {
        $email = (new MailtrapEmail())
            ->from(new Address('hello@cribsarena.com', 'Mailtrap Test'))
            ->to(new Address('obaruakpo@gmail.com'))
            ->subject('Test Email - Cribs Arena')
            ->category('Integration Test')
            ->text('🎉 Email system is working! This is a test email from Cribs Arena using the Mailtrap Client SDK.')
        ;

        $response = MailtrapClient::initSendingEmails(
            apiKey: '379315de1755dd013cd40eaa93a80876'
        )->send($email);

        return response()->json([
            'success' => true,
            'message' => 'Email sent successfully via Mailtrap Client!',
            'response' => ResponseHelper::toArray($response),
            'check_inbox' => 'https://mailtrap.io/inboxes/4215177',
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'error' => $e->getMessage(),
        ], 500);
    }
});

/*
|--------------------------------------------------------------------------
| USER REQUEST TESTING
|--------------------------------------------------------------------------
*/

Route::get('/test-fcm-specific', function () {
    try {
        $fcm = app(App\Services\FCMService::class);
        $token = 'cdP0swV6Rq-sm1V6Am22_l:APA91bGDS0lt5679RIz-c5ZleOE0HIH3doU2wCfb0wEUUqfM0opr7dn1tZWuXwuyH5NClW7GAj62VHwyslWwyPxN4gUZLwNOkpQR1Vr26eOD0knkKHJn3Y8';

        $fcm->sendMany(
            [$token],
            'Test Notification',
            'This is a specific test notification sent at ' . now(),
            ['type' => 'test_manual', 'click_action' => 'FLUTTER_NOTIFICATION_CLICK']
        );

        return response()->json([
            'success' => true,
            'message' => 'Notification triggered for specific token',
            'token_preview' => substr($token, 0, 30) . '...'
        ]);
    } catch (\Exception $e) {
        return response()->json(['success' => false, 'error' => $e->getMessage()], 500);
    }
});

/*
|--------------------------------------------------------------------------
| USER APP TEST ROUTES (CRIBS ARENA)
|--------------------------------------------------------------------------
| Test data based on:
| - User: Oka Ogbale (user_id: 973977, primary key id: 10)
| - Agent: Ogbafia Emmanuela (agent_id: 981497, primary key id: 32)
*/

Route::prefix('test-user')->group(function () {

    // --- Notification Tests ---
    Route::get('/notifications/booking-confirmed', function () {
        $userId = 973977;
        \App\Helpers\NotificationHelper::sendUserNotification(
            $userId,
            'booking_confirmed',
            'Booking Confirmed',
            'Your inspection booking with Ogbafia Emmanuela has been confirmed for Dec 15, 2025 at 2:00 PM.',
            [
                'inspection_id' => 1,
                'agent_id' => 981497,
                'agent_name' => 'Ogbafia Emmanuela',
                'property_id' => 32,
                'date' => '2025-12-15',
                'time' => '14:00',
            ]
        );
        return response()->json(['success' => true, 'message' => 'Booking confirmation notification sent to user!']);
    });

    Route::get('/notifications/payment-successful', function () {
        $userId = 973977;
        \App\Helpers\NotificationHelper::sendUserNotification(
            $userId,
            'payment_successful',
            'Payment Successful',
            'Your payment of ₦5,000.00 has been processed successfully.',
            [
                'transaction_id' => 5,
                'amount' => 5000,
                'reference' => 'cribs_arena_' . uniqid(),
            ]
        );
        return response()->json(['success' => true, 'message' => 'Payment successful notification sent to user!']);
    });

    Route::get('/notifications/inspection-cancelled', function () {
        $userId = 973977;
        \App\Helpers\NotificationHelper::sendUserNotification($userId, 'inspection_cancelled', 'Inspection Cancelled', 'Your inspection has been cancelled.', ['inspection_id' => 1, 'agent_id' => 981497, 'property_id' => 32]);
        return response()->json(['success' => true, 'message' => 'Inspection cancelled notification sent to user!']);
    });

    Route::get('/notifications/inspection-rescheduled', function () {
        $userId = 973977;
        \App\Helpers\NotificationHelper::sendUserNotification($userId, 'inspection_rescheduled', 'Inspection Rescheduled', 'Your inspection has been rescheduled to 2025-12-20 at 10:00.', ['inspection_id' => 1, 'agent_id' => 981497, 'property_id' => 32, 'new_date' => '2025-12-20', 'new_time' => '10:00']);
        return response()->json(['success' => true, 'message' => 'Inspection rescheduled notification sent to user!']);
    });

    Route::get('/notifications/inspection-completed', function () {
        $userId = 973977;
        \App\Helpers\NotificationHelper::sendUserNotification($userId, 'inspection_completed', 'Inspection Completed', 'Your inspection with Ogbafia Emmanuela has been marked as completed.', ['inspection_id' => 1, 'agent_id' => 981497, 'property_id' => 32]);
        return response()->json(['success' => true, 'message' => 'Inspection completed notification sent to user!']);
    });

    Route::get('/notifications/new-listing', function () {
        $userId = 973977;
        \App\Helpers\NotificationHelper::sendUserNotification($userId, 'new_listing', 'New Listing Near You!', 'Luxury 3-Bedroom Apartment in your area', ['property_id' => '92', 'type' => 'new_listing']);
        return response()->json(['success' => true, 'message' => 'New listing notification sent to user!']);
    });

    // --- Utility Routes ---
    Route::get('/notifications/check-count', function () {
        $count = \App\Models\Notification::where('receiver_id', 10)->where('receiver_type', 'user')->where('is_read', false)->count();
        return response()->json(['user_id' => 973977, 'unread_count' => $count]);
    });

    Route::get('/notifications/mark-all-read', function () {
        $updated = \App\Models\Notification::where('receiver_id', 10)->where('receiver_type', 'user')->where('is_read', false)->update(['is_read' => true]);
        return response()->json(['success' => true, 'message' => "Marked {$updated} notifications as read"]);
    });

    Route::get('/notifications/list-recent', function () {
        $notifications = \App\Models\Notification::where('receiver_id', 10)->where('receiver_type', 'user')->orderBy('created_at', 'desc')->limit(10)->get();
        return response()->json(['user_id' => 973977, 'notifications' => $notifications]);
    });

    // --- Verification Tests (QoreID) ---
    Route::prefix('verification')->group(function () {
        Route::get('/nin', function () {
            try {
                $user = \App\Models\User::find(10);
                $testData = ['nin' => '63184876213', 'firstname' => 'Bunch', 'lastname' => 'Dillon', 'dob' => '1974-01-06', 'phone' => '+2348000000000', 'email' => 'obaruakpo@gmail.com', 'gender' => 'Male'];
                $verification = \App\Models\Verification::create(['receiver_id' => $user->id, 'receiver_type' => 'user', 'type' => 'nin', 'value' => $testData['nin'], 'status' => 'pending', 'verification_id' => (string) \Illuminate\Support\Str::uuid()]);
                \App\Jobs\ProcessNinVerification::dispatch($verification, $testData);
                return response()->json(['success' => true, 'verification_id' => $verification->verification_id, 'check_status_url' => url('/test-user/verification/status/' . $verification->verification_id)]);
            } catch (\Exception $e) {
                return response()->json(['error' => $e->getMessage()], 500);
            }
        });

        Route::get('/vnin', function () {
            try {
                $user = \App\Models\User::find(10);
                $testData = ['vnin' => 'VNIN12345678901', 'firstname' => 'Oka', 'lastname' => 'Ogbale', 'dob' => '1990-01-01', 'gender' => 'Male'];
                $verification = \App\Models\Verification::create(['receiver_id' => $user->id, 'receiver_type' => 'user', 'type' => 'vnin', 'value' => $testData['vnin'], 'status' => 'pending', 'verification_id' => (string) \Illuminate\Support\Str::uuid()]);
                \App\Jobs\ProcessVninVerification::dispatch($verification, $testData);
                return response()->json(['success' => true, 'verification_id' => $verification->verification_id]);
            } catch (\Exception $e) {
                return response()->json(['error' => $e->getMessage()], 500);
            }
        });

        Route::get('/bvn', function () {
            try {
                $user = \App\Models\User::find(10);
                $testData = ['bvn' => '95888168924', 'firstname' => 'Bunch', 'lastname' => 'Dillon', 'dob' => '1995-07-07', 'phone' => '+2348000000000', 'email' => 'obaruakpo@gmail.com', 'gender' => 'Male'];
                $verification = \App\Models\Verification::create(['receiver_id' => $user->id, 'receiver_type' => 'user', 'type' => 'bvn', 'value' => $testData['bvn'], 'status' => 'pending', 'verification_id' => (string) \Illuminate\Support\Str::uuid()]);
                \App\Jobs\ProcessBvnVerification::dispatch($verification, $testData);
                return response()->json(['success' => true, 'verification_id' => $verification->verification_id]);
            } catch (\Exception $e) {
                return response()->json(['error' => $e->getMessage()], 500);
            }
        });

        Route::get('/status/{verification_id}', function ($v_id) {
            $v = \App\Models\Verification::where('verification_id', $v_id)->first();
            return $v ? response()->json($v) : response()->json(['error' => 'Not found'], 404);
        });

        Route::get('/list', function () {
            $v = \App\Models\Verification::where('receiver_id', 10)->where('receiver_type', 'user')->orderBy('created_at', 'desc')->get();
            return response()->json(['verifications' => $v]);
        });
    });
});

// Backward compatibility for old user test URLs (Redirects or keep same path but inside labels)
Route::get('/test-notification/booking-confirmed', function () {
    return redirect('/test-user/notifications/booking-confirmed');
});
Route::get('/test-notification/payment-successful', function () {
    return redirect('/test-user/notifications/payment-successful');
});
Route::get('/test-notification/inspection-cancelled-user', function () {
    return redirect('/test-user/notifications/inspection-cancelled');
});
Route::get('/test-notification/inspection-rescheduled-user', function () {
    return redirect('/test-user/notifications/inspection-rescheduled');
});
Route::get('/test-notification/inspection-completed-user', function () {
    return redirect('/test-user/notifications/inspection-completed');
});
Route::get('/test-notification/new-listing', function () {
    return redirect('/test-user/notifications/new-listing');
});

/*
|--------------------------------------------------------------------------
| AGENT APP TEST ROUTES (CRIBS AGENTS)
|--------------------------------------------------------------------------
*/

Route::prefix('test-agent')->group(function () {

    // --- Notification Tests ---
    Route::get('/notifications/new-booking', function () {
        $agentId = 981497;
        \App\Helpers\NotificationHelper::sendAgentNotification(
            $agentId,
            'new_booking_request',
            'New Booking Request',
            'Oka Ogbale has booked an inspection for 2025-12-15 at 14:00.',
            [
                'inspection_id' => 6,
                'user_id' => 973977,
                'user_name' => 'Oka Ogbale',
                'property_id' => 64,
                'date' => '2025-12-15',
                'time' => '14:00',
                'amount' => 5000,
            ]
        );
        return response()->json(['success' => true, 'message' => 'New booking notification sent to agent!']);
    });

    Route::get('/notifications/inspection-cancelled', function () {
        $agentId = 981497;
        \App\Helpers\NotificationHelper::sendAgentNotification($agentId, 'inspection_cancelled', 'Inspection Cancelled', 'Oka Ogbale has cancelled their inspection scheduled for Dec 15, 2025.', ['inspection_id' => 1, 'user_id' => 973977, 'user_name' => 'Oka Ogbale', 'reason' => 'Schedule conflict']);
        return response()->json(['success' => true, 'message' => 'Inspection cancelled notification sent to agent!']);
    });

    Route::get('/notifications/inspection-rescheduled', function () {
        $agentId = 981497;
        \App\Helpers\NotificationHelper::sendAgentNotification($agentId, 'inspection_rescheduled', 'Inspection Rescheduled', 'Oka Ogbale has rescheduled their inspection to Dec 20, 2025 at 3:00 PM.', ['inspection_id' => 1, 'user_id' => 973977, 'user_name' => 'Oka Ogbale', 'new_date' => '2025-12-20', 'new_time' => '15:00']);
        return response()->json(['success' => true, 'message' => 'Inspection rescheduled notification sent to agent!']);
    });

    Route::get('/notifications/inspection-completed', function () {
        $agentId = 981497;
        \App\Helpers\NotificationHelper::sendAgentNotification($agentId, 'inspection_completed', 'Inspection Completed', 'Inspection with Oka Ogbale has been marked as completed.', ['inspection_id' => 1, 'user_id' => 973977, 'user_name' => 'Oka Ogbale', 'property_id' => 32]);
        return response()->json(['success' => true, 'message' => 'Inspection completed notification sent to agent!']);
    });
});

// Backward compatibility for old agent test URLs
Route::get('/test-notification/new-booking-agent', function () {
    return redirect('/test-agent/notifications/new-booking');
});
Route::get('/test-notification/inspection-cancelled-agent', function () {
    return redirect('/test-agent/notifications/inspection-cancelled');
});
Route::get('/test-notification/inspection-rescheduled-agent', function () {
    return redirect('/test-agent/notifications/inspection-rescheduled');
});
Route::get('/test-notification/inspection-completed-agent', function () {
    return redirect('/test-agent/notifications/inspection-completed');
});

/*
|--------------------------------------------------------------------------
| EMAIL TEMPLATE TESTS (SHARED & SPECIFIC)
|--------------------------------------------------------------------------
*/

Route::get('/test-email/booking-user', function () {
    $data = ['bookingId' => 12345, 'userName' => 'Oka Ogbale', 'userPhone' => '+234 801 234 5678', 'agentName' => 'Ogbafia Emmanuela', 'propertyTitle' => '3 Bedroom Apartment', 'propertyLocation' => 'Lekki', 'inspectionDate' => 'Dec 20, 2024', 'inspectionTime' => '2:00 PM', 'amount' => 5000, 'meetingPoint' => 'Main Gate'];
    \Illuminate\Support\Facades\Mail::to('obaruakpo@gmail.com')->send(new \App\Mail\BookingConfirmationMail($data, 'user'));
    return response()->json(['success' => true, 'message' => 'User booking email sent']);
});

Route::get('/test-email/booking-agent', function () {
    $data = ['bookingId' => 12345, 'userName' => 'Oka Ogbale', 'userPhone' => '+234 801 234 5678', 'agentName' => 'Ogbafia Emmanuela', 'propertyTitle' => '3 Bedroom Apartment', 'propertyLocation' => 'Lekki', 'inspectionDate' => 'Dec 20, 2024', 'inspectionTime' => '2:00 PM', 'amount' => 5000, 'meetingPoint' => 'Main Gate', 'agentEarnings' => 4000];
    \Illuminate\Support\Facades\Mail::to('obaruakpo@gmail.com')->send(new \App\Mail\BookingConfirmationMail($data, 'agent'));
    return response()->json(['success' => true, 'message' => 'Agent booking email sent']);
});

Route::get('/test-email/booking-rescheduled', function () {
    $data = ['bookingId' => 12345, 'userName' => 'Oka Ogbale', 'agentName' => 'Ogbafia Emmanuela', 'propertyTitle' => '3 Bedroom Apartment', 'inspectionDate' => 'Dec 20', 'inspectionTime' => '2:00 PM', 'newInspectionDate' => 'Dec 22', 'newInspectionTime' => '3:00 PM'];
    \Illuminate\Support\Facades\Mail::to('obaruakpo@gmail.com')->send(new \App\Mail\BookingStatusMail($data, 'rescheduled', 'user'));
    return response()->json(['success' => true]);
});

Route::get('/test-email/booking-completed', function () {
    $data = ['bookingId' => 12345, 'userName' => 'Oka Ogbale', 'agentName' => 'Ogbafia Emmanuela', 'propertyTitle' => '3 Bedroom Apartment', 'inspectionDate' => 'Dec 20', 'inspectionTime' => '2:00 PM'];
    \Illuminate\Support\Facades\Mail::to('obaruakpo@gmail.com')->send(new \App\Mail\BookingStatusMail($data, 'completed', 'user'));
    return response()->json(['success' => true]);
});

Route::get('/test-email/booking-cancelled', function () {
    $data = ['bookingId' => 12345, 'userName' => 'Oka Ogbale', 'agentName' => 'Ogbafia Emmanuela', 'propertyTitle' => '3 Bedroom Apartment', 'inspectionDate' => 'Dec 20', 'inspectionTime' => '2:00 PM', 'cancellationReason' => 'Reschedule requested'];
    \Illuminate\Support\Facades\Mail::to('obaruakpo@gmail.com')->send(new \App\Mail\BookingStatusMail($data, 'cancelled', 'user'));
    return response()->json(['success' => true]);
});

Route::get('/test-email/payment-confirmation', function () {
    $data = ['userName' => 'Oka Ogbale', 'amount' => 5000, 'transactionId' => 'TXN' . time(), 'reference' => 'REF' . time(), 'paymentMethod' => 'Card', 'paymentDate' => now()->format('M d, Y h:i A'), 'description' => 'Inspection Fee', 'bookingId' => 12345];
    \Illuminate\Support\Facades\Mail::to('obaruakpo@gmail.com')->send(new \App\Mail\PaymentConfirmationMail($data));
    return response()->json(['success' => true]);
});

Route::get('/test-email/welcome', function () {
    \Illuminate\Support\Facades\Mail::to('obaruakpo@gmail.com')->send(new \App\Mail\WelcomeMail('Oka Ogbale'));
    return response()->json(['success' => true]);
});

Route::get('/preview-email/subscription', function () {
    $data = [
        'name' => 'Oka Ogbale',
        'plan_name' => 'Gold Agent Plan',
        'amount' => 15000,
        'start_date' => now()->format('M d, Y'),
        'end_date' => now()->addMonth()->format('M d, Y'),
        'reference' => 'SUB-' . time()
    ];
    return new \App\Mail\SubscriptionActivatedMail($data);
});

/*
|--------------------------------------------------------------------------
| CONFIG & SYSTEM DIAGNOSTICS
|--------------------------------------------------------------------------
*/

Route::prefix('test-system')->group(function () {
    Route::get('/qoreid-config', function () {
        return response()->json(['base_url' => config('qoreid.base_url'), 'public_key' => config('qoreid.public_key'), 'secret_key_set' => !empty(config('qoreid.secret_key')), 'webhook_secret_set' => !empty(config('qoreid.webhook_secret'))]);
    });

    Route::get('/qoreid-connection', function () {
        try {
            $service = app(\App\Services\VerificationService::class);
            $response = $service->verifyNin('63184876213', ['firstname' => 'Bunch', 'lastname' => 'Dillon']);
            return response()->json(['success' => true, 'test_response' => $response]);
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'error' => $e->getMessage()], 500);
        }
    });

    Route::get('/qoreid-token', function () {
        try {
            $token = app(\App\Services\QoreidTokenService::class)->getValidToken();
            return response()->json(['success' => true, 'token_preview' => substr($token, 0, 20) . '...']);
        } catch (\Exception $e) {
            return response()->json(['error' => $e->getMessage()], 500);
        }
    });

    Route::get('/logs', function () {
        $logFile = storage_path('logs/laravel.log');
        if (!file_exists($logFile))
            return "Log not found";
        $lines = array_slice(file($logFile), -100);
        return '<pre>' . implode('', $lines) . '</pre>';
    });

    Route::get('/full-booking-flow', function () {
        $userId = 973977;
        $agentId = 981497;
        // 1. Confirmed
        \App\Helpers\NotificationHelper::sendUserNotification($userId, 'booking_confirmed', 'Confirmed', 'Msg', ['inspection_id' => 1, 'agent_id' => 981497, 'agent_name' => 'Ogbafia', 'property_id' => 32]);
        sleep(1);
        // 2. Payment
        \App\Helpers\NotificationHelper::sendUserNotification($userId, 'payment_successful', 'Success', 'Paid', ['transaction_id' => 1, 'amount' => 5000]);
        sleep(1);
        // 3. Agent Request
        \App\Helpers\NotificationHelper::sendAgentNotification($agentId, 'new_booking_request', 'New Booking', 'Msg', ['inspection_id' => 1, 'user_id' => 973977, 'user_name' => 'Oka']);
        return response()->json(['success' => true, 'message' => 'Full booking flow notifications sent!']);
    });

    Route::get('/announcement', function () {
        \App\Helpers\NotificationHelper::sendGeneralNotification('general_announcement', 'New Feature', 'Virtual tours now available!', ['feature' => 'virtual_tours']);
        return response()->json(['success' => true, 'message' => 'General announcement sent!']);
    });
});

// Backward compatibility
Route::get('/test-notification/general-announcement', function () {
    return redirect('/test-system/announcement');
});
Route::get('/test-notification/full-booking-flow', function () {
    return redirect('/test-system/full-booking-flow');
});
Route::get('/test-verification/qoreid-config', function () {
    return redirect('/test-system/qoreid-config');
});
Route::get('/test-verification/qoreid-connection', function () {
    return redirect('/test-system/qoreid-connection');
});
Route::get('/test-qoreid-token', function () {
    return redirect('/test-system/qoreid-token');
});
Route::get('/test-verification/logs', function () {
    return redirect('/test-system/logs');
});

/*
|--------------------------------------------------------------------------
| LEGACY / MISC
|--------------------------------------------------------------------------
*/

Route::get('/test-fcm', function () {
    $fcm = app(App\Services\FCMService::class);
    $token = 'eSPO5QicRbqOrXaQ4aPUQ5:APA91bELhFz_oj5eyBT2lOMA-Nvf1JRr8Ly-OOqSwA7k6Q_E0B2i9V66q2_WTZcToD0p9NYy8UOUCsNts5cv-c8P_x-pyh_NUr7xsI4KatPXjmw4uEvDTYM';
    $fcm->sendMany([$token], 'Test', 'Direct FCM Body', ['type' => 'test']);
    return 'FCM test notification sent!';
});

Route::get('/test-properties', function () {
    return response()->json(App\Models\Property::latest()->take(40)->get());
});
