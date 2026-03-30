<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\Rule;
use App\Models\NotificationSetting;
use Illuminate\Support\Facades\Log;

class NotificationSettingsController extends Controller
{
    private function getOrCreateSettings($authenticatable)
    {
        if (!$authenticatable) {
            return null;
        }

        return $authenticatable->notificationSettings()->firstOrCreate(
            [], // No conditions needed to find, it's a morphOne relationship
            [
                // Default values if creating
                'push_notifications_enabled' => true,
                'new_messages_enabled' => true,
                'new_listings_enabled' => true,
                'price_changes_enabled' => false,
                'app_updates_enabled' => true,
            ]
        );
    }

    public function index(Request $request)
    {
        try {
            $authenticatable = Auth::user() ?? Auth::guard('agent')->user();

            if (!$authenticatable) {
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }

            $settings = $this->getOrCreateSettings($authenticatable);

            return response()->json($settings);
        } catch (\Exception $e) {
            Log::error('Failed to fetch notification settings: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while loading your notification settings.'
            ], 500);
        }
    }

    public function update(Request $request)
    {
        try {
            $authenticatable = Auth::user() ?? Auth::guard('agent')->user();

            if (!$authenticatable) {
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }

            $validated = $request->validate([
                'push_notifications_enabled' => 'sometimes|boolean',
                'new_messages_enabled' => 'sometimes|boolean',
                'new_listings_enabled' => 'sometimes|boolean',
                'price_changes_enabled' => 'sometimes|boolean',
                'app_updates_enabled' => 'sometimes|boolean',
            ]);

            $settings = $this->getOrCreateSettings($authenticatable);
            $settings->update($validated);

            return response()->json(['message' => 'Notification settings updated successfully.', 'settings' => $settings]);
        } catch (\Exception $e) {
            Log::error('Failed to update notification settings: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while updating your notification settings.'
            ], 500);
        }
    }
}
