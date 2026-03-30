<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Helpers\ChatSyncHelper;
use Illuminate\Support\Facades\Log;

class ProfilePictureController extends Controller
{
    public function updateProfilePicture(Request $request)
    {
        try {
            $request->validate([
                'profile_picture' => 'required|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
            ]);

            $agent = $request->user();

            if ($request->hasFile('profile_picture')) {
                $path = $request->file('profile_picture')->store('agent_pictures', 'public');

                // Save to agent_information table
                $agent->information()->updateOrCreate(
                    ['agent_id' => $agent->agent_id],
                    ['profile_picture_url' => $path]
                );

                // Sync with ChatDB
                ChatSyncHelper::syncProfile(
                    "agent_{$agent->agent_id}",
                    "{$agent->first_name} {$agent->last_name}",
                    $path
                );

                return response()->json([
                    'success' => true,
                    'message' => 'Profile picture updated successfully',
                    'data' => [
                        'profile_picture_url' => $path,
                        'full_url' => asset('storage/' . $path)
                    ]
                ], 200);
            }

            return response()->json(['success' => false, 'message' => 'No image uploaded'], 400);
        } catch (\Exception $e) {
            Log::error('Failed to update profile picture: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while updating your profile picture. Please try again later.'
            ], 500);
        }
    }
}
