<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Models\DeviceToken;
use Illuminate\Validation\ValidationException;

class LoginController extends Controller
{
    /**
     * Handle a user login request.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function __invoke(Request $request)
    {
        try {
            $request->validate([
                'email' => 'required|email',
                'password' => 'required|string',
                'fcm_token' => 'nullable|string',
                'platform' => 'nullable|string|in:android,ios',
            ]);

            $user = User::where('email', $request->email)->first();

            if (!$user || !Hash::check($request->password, $user->password)) {
                return response()->json(['error' => 'Invalid email or password'], 401);
            }

            // Check if email is verified
            if (!$user->email_verified) {
                return response()->json([
                    'error' => 'Please verify your email before logging in',
                    'email' => $user->email,
                    'requires_verification' => true,
                ], 403);
            }

            // Update login status
            $user->forceFill([
                'login_status' => 1,
                'last_login' => now(),
            ])->save();

            // Create Sanctum token
            $token = $user->createToken('cribs-arena-auth-token')->plainTextToken;

            // Handle FCM Token if provided
            if ($request->has('fcm_token') && $request->fcm_token) {
                DeviceToken::updateOrCreate(
                    [
                        'tokenable_id' => $user->id,
                        'tokenable_type' => 'user',
                        'fcm_token' => $request->fcm_token,
                    ],
                    [
                        'platform' => $request->platform,
                        'last_seen_at' => now(),
                    ]
                );
            }

            return response()->json([
                'status' => 'success',
                'token' => $token,
                'user' => $user
            ]);

        } catch (ValidationException $e) {
            return response()->json(['errors' => $e->errors()], 422);
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error('Login Error: ' . $e->getMessage());
            return response()->json(['error' => 'An unexpected error occurred during login.'], 500);
        }
    }
}
