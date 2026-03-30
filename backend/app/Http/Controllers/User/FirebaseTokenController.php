<?php

namespace App\Http\Controllers\User;

use Illuminate\Http\Request;
use App\Models\FirebaseToken;
use Illuminate\Support\Facades\Log;
use Exception;
use App\Http\Controllers\Controller;

class FirebaseTokenController extends Controller
{
    public function store(Request $request)
    {
        try {
            $request->validate([
                'fcm_token' => 'required|string',
            ]);

            $user = $request->user();

            if (!$user) {
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }

            Log::info('FCM token store request:', $request->all());
            Log::info('User authenticated:', ['user_id' => $user->id]);

            $userType = get_class($user);

            Log::info('User type:', ['user_type' => $userType]);

            FirebaseToken::updateOrCreate(
                ['tokenable_id' => $user->id, 'tokenable_type' => $userType],
                ['fcm_token' => $request->fcm_token]
            );

            return response()->json(['message' => 'FCM token stored successfully.']);
        } catch (\Exception $e) {
            Log::error('FCM token store error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while saving your notification token. Please try again later.'
            ], 500);
        }
    }
}
