<?php

namespace App\Helpers;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class ChatSyncHelper
{
    /**
     * Synchronize user/agent profile changes to MongoDB
     * 
     * @param string $id The user or agent ID (e.g. user_123, agent_456)
     * @param string|null $name Full name
     * @param string|null $avatar Relative or absolute URL to profile picture
     */
    public static function syncProfile($id, $name = null, $avatar = null)
    {
        try {
            $chatServerUrl = env('CHAT_SERVER_URL', 'http://127.0.0.1:5001');

            $payload = [];
            if ($name)
                $payload['name'] = $name;
            if ($avatar) {
                // If avatar is a relative path, convert to full URL
                if (!str_starts_with($avatar, 'http')) {
                    $avatar = asset('storage/' . $avatar);
                }
                $payload['avatar'] = $avatar;
            }

            if (empty($payload)) {
                return;
            }

            $response = Http::timeout(5)
                ->withHeaders([
                    'x-api-key' => env('CHAT_API_KEY'),
                ])
                ->put("{$chatServerUrl}/conversations/participant/{$id}", $payload);

            if ($response->failed()) {
                Log::error("ChatSyncHelper: Failed to sync profile for {$id}. Status: {$response->status()}, Body: {$response->body()}");
            } else {
                Log::info("ChatSyncHelper: Successfully synced profile for {$id}");
            }
        } catch (\Exception $e) {
            Log::error("ChatSyncHelper: Exception during sync for {$id}: " . $e->getMessage());
        }
    }
}
