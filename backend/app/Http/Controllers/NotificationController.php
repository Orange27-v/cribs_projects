<?php

namespace App\Http\Controllers;

use App\Models\Notification;
use App\Models\DeviceToken;
use App\Jobs\SendChatNotificationJob; // Import the job
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log; // Import Log facade
use Illuminate\Validation\Rule;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        try {
            $user = Auth::user();
            $agent = Auth::guard('agent')->user();

            if (!$user && !$agent) {
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }

            $receiverId = $user ? $user->id : $agent->id;
            $receiverType = $user ? 'user' : 'agent';

            Log::info('? Fetching notifications', [
                'receiver_id' => $receiverId,
                'receiver_type' => $receiverType,
                'user_id_field' => $user ? $user->user_id : null,
            ]);

            $notifications = Notification::where('receiver_id', $receiverId)
                ->where('receiver_type', $receiverType)
                ->orderBy('created_at', 'desc')
                ->paginate(10); // Adjust pagination limit as needed

            return response()->json($notifications);
        } catch (\Exception $e) {
            Log::error('Failed to fetch notifications: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while loading your notifications. Please try again later.'
            ], 500);
        }
    }

    public function markAsRead(Request $request, $id)
    {
        try {
            $user = Auth::user();
            $agent = Auth::guard('agent')->user();

            if (!$user && !$agent) {
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }

            $receiverId = $user ? $user->id : $agent->id;
            $receiverType = $user ? 'user' : 'agent';

            $notification = Notification::where('id', $id)
                ->where('receiver_id', $receiverId)
                ->where('receiver_type', $receiverType)
                ->first();

            if (!$notification) {
                return response()->json(['message' => 'Notification not found or unauthorized.'], 404);
            }

            $notification->is_read = true;
            $notification->save();

            return response()->json(['message' => 'Notification marked as read.']);
        } catch (\Exception $e) {
            Log::error('Failed to mark notification as read: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while updating your notification. Please try again later.'
            ], 500);
        }
    }

    public function markAllAsRead(Request $request)
    {
        try {
            $user = Auth::user();
            $agent = Auth::guard('agent')->user();

            if (!$user && !$agent) {
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }

            $receiverId = $user ? $user->id : $agent->id;
            $receiverType = $user ? 'user' : 'agent';

            Notification::where('receiver_id', $receiverId)
                ->where('receiver_type', $receiverType)
                ->where('is_read', false)
                ->update(['is_read' => true]);

            return response()->json(['message' => 'All notifications marked as read.']);
        } catch (\Exception $e) {
            Log::error('Failed to mark all notifications as read: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while updating your notifications. Please try again later.'
            ], 500);
        }
    }

    public function storeDeviceToken(Request $request)
    {
        try {
            // Try to get authenticated entity from default guard (usually users)
            $authEntity = Auth::user();

            // If not found, try the agent guard specifically
            if (!$authEntity) {
                $authEntity = Auth::guard('agent')->user();
            }

            if (!$authEntity) {
                Log::warning('📲 Device token storage failed: Unauthenticated.', [
                    'headers' => $request->headers->all(),
                ]);
                return response()->json(['message' => 'Unauthenticated.'], 401);
            }

            $tokenableId = $authEntity->id;
            $tokenableType = ($authEntity instanceof \App\Models\Agent) ? 'agent' : 'user';

            $request->validate([
                'fcm_token' => 'required|string',
                'platform' => ['nullable', 'string', Rule::in(['android', 'ios'])],
            ]);

            DeviceToken::updateOrCreate(
                [
                    'tokenable_id' => $tokenableId,
                    'tokenable_type' => $tokenableType,
                    'fcm_token' => $request->fcm_token,
                ],
                [
                    'platform' => $request->platform,
                    'last_seen_at' => now(),
                ]
            );

            return response()->json(['message' => 'Device token stored successfully.']);
        } catch (\Exception $e) {
            Log::error('Failed to store device token: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while saving your notification identity. Please try again later.'
            ], 500);
        }
    }

    public function handleChatWebhook(Request $request)
    {
        try {
            // Validate API Key
            $apiKey = $request->header('X-API-KEY');
            if ($apiKey !== env('LARAVEL_API_KEY')) { // Ensure LARAVEL_API_KEY is set in .env
                Log::warning('Unauthorized chat webhook access attempt.', ['ip' => $request->ip()]);
                return response()->json(['message' => 'Unauthorized.'], 401);
            }

            $validated = $request->validate([
                'message_uuid' => 'required|string|unique:notifications,data->message_uuid', // Ensure message_uuid is unique
                'conversationId' => 'required|string',
                'senderId' => 'required|integer',
                'receiverId' => 'required|integer',
                'messageContent' => 'required|string',
                'timestamp' => 'required|date',
            ]);

            // Dispatch the job to send the notification
            SendChatNotificationJob::dispatch(
                $validated['message_uuid'],
                $validated['conversationId'],
                $validated['senderId'],
                $validated['receiverId'],
                $validated['messageContent'],
                $validated['timestamp']
            );

            return response()->json(['message' => 'Chat notification webhook received and job dispatched.']);
        } catch (\Exception $e) {
            Log::error('Chat webhook error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while processing the notification.'
            ], 500);
        }
    }
}
