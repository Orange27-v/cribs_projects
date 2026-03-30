<?php

namespace App\Http\Controllers\Agent;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class AgentNotificationController extends Controller
{
    /**
     * Get unread notifications count for the authenticated agent
     */
    public function getUnreadCount(Request $request)
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            // Count unread notifications for this agent
            $unreadCount = DB::table('notifications')
                ->where('receiver_id', $agent->id)
                ->where('receiver_type', 'agent')
                ->where('is_read', 0)
                ->count();

            return response()->json([
                'success' => true,
                'data' => [
                    'unread_count' => $unreadCount
                ]
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to fetch unread notifications count: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while loading notification counts. Please try again later.'
            ], 500);
        }
    }

    /**
     * Get all notifications for the authenticated agent
     */
    public function getNotifications(Request $request)
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $perPage = $request->input('per_page', 20);

            $notifications = DB::table('notifications')
                ->where('receiver_id', $agent->id)
                ->where('receiver_type', 'agent')
                ->orderBy('created_at', 'desc')
                ->paginate($perPage);

            return response()->json([
                'success' => true,
                'data' => $notifications
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to fetch notifications: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while loading your notifications. Please try again later.'
            ], 500);
        }
    }

    /**
     * Mark notification as read
     */
    public function markAsRead(Request $request, $notificationId)
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            $updated = DB::table('notifications')
                ->where('id', $notificationId)
                ->where('receiver_id', $agent->id)
                ->where('receiver_type', 'agent')
                ->update([
                    'is_read' => 1,
                    'updated_at' => now()
                ]);

            if ($updated) {
                return response()->json([
                    'success' => true,
                    'message' => 'Notification marked as read'
                ], 200);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'Notification not found'
                ], 404);
            }

        } catch (\Exception $e) {
            Log::error('Failed to mark notification as read: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while updating the notification status. Please try again later.'
            ], 500);
        }
    }

    /**
     * Mark all notifications as read
     */
    public function markAllAsRead(Request $request)
    {
        try {
            $agent = Auth::guard('agent')->user();

            if (!$agent) {
                return response()->json([
                    'success' => false,
                    'message' => 'Unauthorized'
                ], 401);
            }

            DB::table('notifications')
                ->where('receiver_id', $agent->id)
                ->where('receiver_type', 'agent')
                ->where('is_read', 0)
                ->update([
                    'is_read' => 1,
                    'updated_at' => now()
                ]);

            return response()->json([
                'success' => true,
                'message' => 'All notifications marked as read'
            ], 200);

        } catch (\Exception $e) {
            Log::error('Failed to mark all notifications as read: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while updating notification statuses. Please try again later.'
            ], 500);
        }
    }
}
