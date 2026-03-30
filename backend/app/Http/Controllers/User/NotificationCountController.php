<?php

namespace App\Http\Controllers\User;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\Notification; // Assuming this is the correct path to your Notification model
use Illuminate\Support\Facades\Log;

class NotificationCountController extends Controller
{
    /**
     * Get the count of unread notifications for the authenticated user.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getUnreadCount(Request $request)
    {
        try {
            $user = Auth::user();

            if (!$user) {
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }

            $unreadCount = Notification::where('receiver_id', $user->id)
                ->where('receiver_type', 'user') // Fixed: use 'user' not full class name
                ->where('is_read', false)
                ->count();

            return response()->json(['unread_count' => $unreadCount]);
        } catch (\Exception $e) {
            Log::error('Failed to fetch unread notification count: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'An error occurred while fetching your notifications.'
            ], 500);
        }
    }
}
