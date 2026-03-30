<?php

namespace App\Helpers;

use App\Models\Notification;
use App\Services\FCMService;

class NotificationHelper
{
    /**
     * Send notification to a user
     */
    public static function sendUserNotification(
        $userId,
        string $type,
        string $title,
        string $body,
        array $data = []
    ) {
        // Find user by checking both primary key and custom user_id field
        $user = \App\Models\User::where('user_id', $userId)->orWhere('id', $userId)->first();

        if (!$user) {
            \Log::warning("User not found for ID: {$userId}");
            return null;
        }

        // Create database notification using the primary key
        $notification = Notification::create([
            'receiver_id' => $user->id, // Use primary key for notifications table
            'receiver_type' => 'user',
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'data' => $data,
            'is_read' => false,
        ]);

        // Send FCM push notification
        $tokens = $user->deviceTokens()->pluck('fcm_token')->toArray();

        \Log::info('📲 Preparing to send FCM notification to user', [
            'user_id' => $userId,
            'user_primary_key' => $user->id,
            'token_count' => count($tokens),
            'notification_type' => $type,
        ]);

        if (!empty($tokens)) {
            try {
                $fcm = app(FCMService::class);
                $fcm->sendMany($tokens, $title, $body, array_merge($data, [
                    'notification_id' => $notification->id,
                    'type' => $type,
                ]), 'user');
                \Log::info('📲 FCM notification sent successfully to user', [
                    'user_id' => $userId,
                    'notification_id' => $notification->id,
                ]);
            } catch (\Exception $e) {
                \Log::error("📲 Failed to send FCM notification to user {$userId}: " . $e->getMessage());
                // Don't fail the entire notification - database record is already created
            }
        } else {
            \Log::warning('📲 No FCM tokens found for user', [
                'user_id' => $userId,
                'user_primary_key' => $user->id,
            ]);
        }

        return $notification;
    }

    /**
     * Send notification to an agent
     */
    /**
     * Send notification to an agent
     */
    public static function sendAgentNotification(
        $agentId,
        string $type,
        string $title,
        string $body,
        array $data = []
    ) {
        // Resolve agent to ensure we have the correct primary key for the notification record
        // The $agentId passed might be the 'agent_id' (e.g. 900024) or the 'id'
        $agent = \App\Models\Agent::where('agent_id', $agentId)->orWhere('id', $agentId)->first();

        // Use the primary key if found, otherwise fallback to the passed ID
        $receiverId = $agent ? $agent->id : $agentId;

        // Create database notification
        $notification = Notification::create([
            'receiver_id' => $receiverId,
            'receiver_type' => 'agent',
            'type' => $type,
            'title' => $title,
            'body' => $body,
            'data' => $data,
            'is_read' => false,
        ]);

        // Send FCM push notification to agent app
        if ($agent) {
            $tokens = $agent->deviceTokens()->pluck('fcm_token')->toArray();
            if (!empty($tokens)) {
                try {
                    $fcm = app(FCMService::class);
                    $fcm->sendMany($tokens, $title, $body, array_merge($data, [
                        'notification_id' => $notification->id,
                        'type' => $type,
                    ]), 'agent');
                } catch (\Exception $e) {
                    \Log::error("Failed to send FCM notification to agent {$agentId}: " . $e->getMessage());
                    // Don't fail the entire notification - database record is already created
                }
            }
        }

        return $notification;
    }

    /**
     * Send general announcement to all users
     */
    public static function sendGeneralNotification(
        string $type,
        string $title,
        string $body,
        array $data = []
    ) {
        // Get all users with notifications enabled
        $users = \App\Models\User::whereHas('notificationSettings', function ($q) {
            $q->where('general_announcements_enabled', true);
        })->get();

        foreach ($users as $user) {
            self::sendUserNotification($user->id, $type, $title, $body, $data);
        }
    }

    /**
     * Send FCM push notification to user WITHOUT database storage
     * Used for chat notifications which don't need to be stored in SQL
     */
    public static function sendUserPushOnly(
        $userId,
        string $type,
        string $title,
        string $body,
        array $data = []
    ) {
        // Find user by checking both primary key and custom user_id field
        $user = \App\Models\User::where('user_id', $userId)->orWhere('id', $userId)->first();

        if (!$user) {
            \Log::warning("User not found for push-only notification, user_id: {$userId}");
            return false;
        }

        // Get FCM tokens
        $tokens = $user->deviceTokens()->pluck('fcm_token')->toArray();

        if (empty($tokens)) {
            \Log::info("No FCM tokens found for user {$userId} - push-only notification skipped");
            return false;
        }

        try {
            $fcm = app(FCMService::class);
            $fcm->sendMany($tokens, $title, $body, array_merge($data, [
                'type' => $type,
            ]), 'user');
            \Log::info("Push-only notification sent to user {$userId}");
            return true;
        } catch (\Exception $e) {
            \Log::error("Failed to send push-only notification to user {$userId}: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Send FCM push notification to agent WITHOUT database storage
     * Used for chat notifications which don't need to be stored in SQL
     */
    public static function sendAgentPushOnly(
        $agentId,
        string $type,
        string $title,
        string $body,
        array $data = []
    ) {
        // Resolve agent
        $agent = \App\Models\Agent::where('agent_id', $agentId)->orWhere('id', $agentId)->first();

        if (!$agent) {
            \Log::warning("Agent not found for push-only notification, agent_id: {$agentId}");
            return false;
        }

        // Get FCM tokens
        $tokens = $agent->deviceTokens()->pluck('fcm_token')->toArray();

        if (empty($tokens)) {
            \Log::info("No FCM tokens found for agent {$agentId} - push-only notification skipped");
            return false;
        }

        try {
            $fcm = app(FCMService::class);
            $fcm->sendMany($tokens, $title, $body, array_merge($data, [
                'type' => $type,
            ]), 'agent');
            \Log::info("Push-only notification sent to agent {$agentId}");
            return true;
        } catch (\Exception $e) {
            \Log::error("Failed to send push-only notification to agent {$agentId}: " . $e->getMessage());
            return false;
        }
    }
}
