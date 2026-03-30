<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Log; // Added this line
use App\Helpers\NotificationHelper;

class ChatNotificationController extends Controller
{
    /**
     * Receive chat notification from Node.js chat server
     * and send push notification to recipient
     */
    public function sendChatNotification(Request $request): JsonResponse
    {
        // Validate API key
        $apiKey = $request->header('X-API-Key');
        $expectedKey = env('CHAT_API_KEY');

        if ($apiKey !== $expectedKey) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized: Invalid API key'
            ], 401);
        }

        // Validate request data
        $validated = $request->validate([
            'receiver_id' => 'required',
            'receiver_type' => 'required|in:user,agent',
            'sender_name' => 'required|string',
            'message' => 'required|string',
            'conversation_id' => 'required|string',
        ]);

        try {
            // Send push notification based on receiver type (NO database storage for chat)
            Log::info('📩 Incoming chat notification request', [
                'receiver_id' => $validated['receiver_id'],
                'receiver_type' => $validated['receiver_type'],
                'sender_name' => $validated['sender_name'],
            ]);

            if ($validated['receiver_type'] === 'user') {
                // Extract integer ID for user (format: user_123 -> 123)
                $userId = preg_replace('/[^0-9]/', '', $validated['receiver_id']);
                Log::info('📩 Sending chat notification to user', ['raw_receiver_id' => $validated['receiver_id'], 'resolved_user_id' => $userId]);

                NotificationHelper::sendUserPushOnly(
                    $userId,
                    'chat',
                    "New message from {$validated['sender_name']}",
                    $this->truncateMessage($validated['message']),
                    [
                        'conversationId' => $validated['conversation_id'],
                        'senderName' => $validated['sender_name'],
                        'messagePreview' => $this->truncateMessage($validated['message'], 50),
                    ]
                );
            } else {
                // For agents, strip any prefix to get numeric ID
                $agentId = (int) preg_replace('/[^0-9]/', '', $validated['receiver_id']);
                Log::info('📩 Sending chat notification to agent', ['raw_receiver_id' => $validated['receiver_id'], 'resolved_agent_id' => $agentId]);

                NotificationHelper::sendAgentPushOnly(
                    $agentId,
                    'chat',
                    "New message from {$validated['sender_name']}",
                    $this->truncateMessage($validated['message']),
                    [
                        'conversationId' => $validated['conversation_id'],
                        'senderName' => $validated['sender_name'],
                        'messagePreview' => $this->truncateMessage($validated['message'], 50),
                    ]
                );
            }

            return response()->json([
                'success' => true,
                'message' => 'Chat notification sent successfully'
            ]);

        } catch (\Exception $e) {
            Log::error('Chat notification error: ' . $e->getMessage());
            return response()->json([
                'success' => false,
                'message' => 'An error occurred while sending the notification.'
            ], 500);
        }
    }

    /**
     * Truncate message for notification preview
     */
    private function truncateMessage(string $message, int $length = 100): string
    {
        if (strlen($message) <= $length) {
            return $message;
        }

        return substr($message, 0, $length) . '...';
    }
}
