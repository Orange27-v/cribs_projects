<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class AgentAuthController extends Controller
{
    public function profile(Request $request)
    {
        try {
            $agent = $request->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            // Load agent information relationship
            $agent->load('information');

            $agentData = $agent->toArray();

            // Add profile_picture_url from information table if exists
            if ($agent->information) {
                $agentData['profile_picture_url'] = $agent->information->profile_picture_url;
            }

            return response()->json([
                'success' => true,
                'data' => $agentData
            ], 200);
        } catch (\Exception $e) {
            Log::error('Failed to fetch agent details: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while retrieving your profile. Please try again later.'
            ], 500);
        }
    }

    public function updateProfile(Request $request)
    {
        try {
            $agent = $request->user();

            if (!$agent) {
                return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
            }

            $request->validate([
                'first_name' => 'required|string|max:255',
                'last_name' => 'required|string|max:255',
                'phone' => 'required|string|max:20',
                'area' => 'required|string|max:255',
            ]);

            $agent->first_name = $request->first_name;
            $agent->last_name = $request->last_name;
            $agent->phone = $request->phone;
            $agent->area = $request->area;
            $agent->save();

            return response()->json([
                'success' => true,
                'message' => 'Profile updated successfully',
                'data' => $agent
            ], 200);
        } catch (\Exception $e) {
            Log::error('Failed to update agent profile: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while updating your profile. Please try again later.'
            ], 500);
        }
    }

    /**
     * Update agent latitude and longitude
     */
    public function updateLocation(Request $request)
    {
        try {
            $agent = $request->user();

            if (!$agent) {
                return response()->json(['success' => false, 'message' => 'Unauthorized'], 401);
            }

            $request->validate([
                'latitude' => 'required|numeric|min:-90|max:90',
                'longitude' => 'required|numeric|min:-180|max:180',
            ]);

            $agent->latitude = $request->latitude;
            $agent->longitude = $request->longitude;
            $agent->save();

            return response()->json([
                'success' => true,
                'message' => 'Location updated successfully',
                'data' => [
                    'latitude' => $agent->latitude,
                    'longitude' => $agent->longitude
                ]
            ], 200);
        } catch (\Exception $e) {
            Log::error('Failed to update agent location: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while updating your location. Please try again later.'
            ], 500);
        }
    }
}
