<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use App\Services\FCMService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class NotificationSettingsController extends Controller
{
    protected $fcmService;

    public function __construct(FCMService $fcmService)
    {
        $this->fcmService = $fcmService;
    }
    /**
     * Get the user's current notification settings.
     */
    public function getSettings(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'status' => 'success',
            'data' => [
                'notif_push_notifications' => (bool)$user->notif_push_notifications,
                'notif_new_messages' => (bool)$user->notif_new_messages,
                'notif_new_listings' => (bool)$user->notif_new_listings,
                'notif_price_changes' => (bool)$user->notif_price_changes,
                'notif_app_updates' => (bool)$user->notif_app_updates,
            ]
        ]);
    }

    /**
     * Update the user's notification settings.
     */
    public function updateSettings(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'notif_push_notifications' => 'sometimes|boolean',
            'notif_new_messages' => 'sometimes|boolean',
            'notif_new_listings' => 'sometimes|boolean',
            'notif_price_changes' => 'sometimes|boolean',
            'notif_app_updates' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid data provided.',
                'errors' => $validator->errors()
            ], 422);
        }

        $validatedData = $validator->validated();
        
        $user->fill($validatedData);
        $user->save();

        // Send FCM Notification
        $userTokens = $user->tokens->pluck('fcm_token')->toArray();

        if (!empty($userTokens)) {
            $title = 'Preferences Updated';
            $body = 'You changed your inspection preferences.';
            $data = [
                'type' => 'preferences_updated',
            ];
            $this->fcmService->sendMany($userTokens, $title, $body, $data);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Notification settings updated successfully.',
            'data' => $validatedData
        ]);
    }
}
