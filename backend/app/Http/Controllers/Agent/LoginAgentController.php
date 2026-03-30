<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Agent;
use App\Models\DeviceToken;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;

class LoginAgentController extends Controller
{
    public function login(Request $request)
    {
        try {
            $request->validate([
                'email' => 'required|email',
                'password' => 'required|string',
                'fcm_token' => 'nullable|string',
                'platform' => 'nullable|string|in:android,ios',
            ]);

            $agent = Agent::where('email', $request->email)->first();

            if (!$agent || !Hash::check($request->password, $agent->password)) {
                return response()->json(['message' => 'Invalid login details'], 401);
            }

            // Check for email verification
            if (is_null($agent->email_verified_at)) {
                return response()->json([
                    'message' => 'Email not verified',
                    'requires_verification' => true
                ], 403);
            }

            $agent->login_status = 1;
            $agent->last_login = now();
            $agent->save();

            $token = $agent->createToken('auth_token', ['agent'])->plainTextToken;

            // Handle FCM Token if provided
            if ($request->has('fcm_token') && $request->fcm_token) {
                DeviceToken::updateOrCreate(
                    [
                        'tokenable_id' => $agent->id,
                        'tokenable_type' => 'agent',
                        'fcm_token' => $request->fcm_token,
                    ],
                    [
                        'platform' => $request->platform,
                        'last_seen_at' => now(),
                    ]
                );
            }

            $agent->load('information');
            $agentData = $agent->toArray();
            if ($agent->information) {
                $agentData['profile_picture_url'] = $agent->information->profile_picture_url;
            }

            return response()->json([
                'token' => $token,
                'token_type' => 'Bearer',
                'user' => $agentData
            ]);
        } catch (\Exception $e) {
            Log::error('Agent login error: ' . $e->getMessage());
            return response()->json([
                'message' => 'An error occurred during login. Please try again later.'
            ], 500);
        }
    }

    public function logout(Request $request)
    {
        try {
            $agent = $request->user();
            if ($agent) {
                $agent->login_status = 0;
                $agent->last_logout = now();
                $agent->save();

                $agent->tokens()->delete();
            }

            return response()->json(['message' => 'Logged out successfully']);
        } catch (\Exception $e) {
            Log::error('Agent logout error: ' . $e->getMessage());
            return response()->json(['message' => 'Logged out with local session cleared.'], 200);
        }
    }
}
