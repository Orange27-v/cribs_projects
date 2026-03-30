<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class AgentMapController extends Controller
{
    /**
     * Get all users with valid location data for displaying on the map
     * 
     * @return \Illuminate\Http\JsonResponse
     */
    public function getUsers()
    {
        try {
            // Fetch users with valid latitude and longitude
            $users = DB::table('cribs_users')
                ->select(
                    'user_id',
                    'first_name',
                    'last_name',
                    'profile_picture_url',
                    'latitude',
                    'longitude',
                    'login_status',
                    'area'
                )
                ->whereNotNull('latitude')
                ->whereNotNull('longitude')
                ->where('latitude', '!=', '')
                ->where('longitude', '!=', '')
                ->get();

            // Format the data for map display
            $formattedUsers = $users->map(function ($user) {
                // Construct full profile picture URL if it's a relative path
                $profilePictureUrl = $user->profile_picture_url;
                if ($profilePictureUrl && !str_starts_with($profilePictureUrl, 'http')) {
                    $profilePictureUrl = url('storage/' . $profilePictureUrl);
                }

                return [
                    'id' => $user->user_id,
                    'name' => trim($user->first_name . ' ' . $user->last_name),
                    'image' => $profilePictureUrl,
                    'lat' => (float) $user->latitude,
                    'lon' => (float) $user->longitude,
                    'isOnline' => (bool) $user->login_status,
                    'location' => $user->area ?? 'Location not set',
                ];
            });

            return response()->json([
                'success' => true,
                'users' => $formattedUsers,
                'count' => $formattedUsers->count(),
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to fetch users: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while loading users. Please try again later.'
            ], 500);
        }
    }

    /**
     * Get users within a specific radius of a location
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getNearbyUsers(Request $request)
    {
        $request->validate([
            'latitude' => 'required|numeric|min:-90|max:90',
            'longitude' => 'required|numeric|min:-180|max:180',
            'radius' => 'nullable|numeric|min:1|max:100', // radius in kilometers, max 100km
        ]);

        $latitude = $request->latitude;
        $longitude = $request->longitude;
        $radius = $request->radius ?? 10; // default 50km

        try {
            // Using Haversine formula to calculate distance
            $users = DB::table('cribs_users')
                ->selectRaw('
                    user_id, 
                    first_name, 
                    last_name, 
                    profile_picture_url, 
                    latitude, 
                    longitude, 
                    login_status, 
                    area, 
                    (6371 * acos(
                        LEAST(1.0, GREATEST(-1.0, 
                            cos(radians(?)) * cos(radians(CAST(latitude AS DECIMAL(10,8)))) * 
                            cos(radians(CAST(longitude AS DECIMAL(10,8))) - radians(?)) + 
                            sin(radians(?)) * sin(radians(CAST(latitude AS DECIMAL(10,8))))
                        )
                    ))) AS distance',
                    [$latitude, $longitude, $latitude]
                )
                ->whereNotNull('latitude')
                ->whereNotNull('longitude')
                ->where('latitude', '!=', '')
                ->where('longitude', '!=', '')
                ->havingRaw('distance <= ?', [$radius])
                ->orderBy('distance')
                ->get();

            // Format the data for map display
            $formattedUsers = $users->map(function ($user) {
                // Construct full profile picture URL if it's a relative path
                $profilePictureUrl = $user->profile_picture_url;
                if ($profilePictureUrl && !str_starts_with($profilePictureUrl, 'http')) {
                    $profilePictureUrl = url('storage/' . $profilePictureUrl);
                }

                return [
                    'id' => $user->user_id,
                    'name' => trim($user->first_name . ' ' . $user->last_name),
                    'image' => $profilePictureUrl,
                    'lat' => (float) $user->latitude,
                    'lon' => (float) $user->longitude,
                    'isOnline' => (bool) $user->login_status,
                    'location' => $user->area ?? 'Location not set',
                    'distance' => round($user->distance, 2), // distance in km
                ];
            });

            return response()->json([
                'success' => true,
                'users' => $formattedUsers,
                'count' => $formattedUsers->count(),
            ]);

        } catch (\Exception $e) {
            Log::error('Failed to fetch nearby users: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while loading nearby users. Please try again later.'
            ], 500);
        }
    }
}
